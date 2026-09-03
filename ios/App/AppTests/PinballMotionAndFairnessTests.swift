import CoreGraphics
import SpriteKit
import XCTest
@testable import App

final class PinballMotionAndFairnessTests: XCTestCase {
    func testDividerGeometryShowsOnlyExactInternalOwnershipRays() throws {
        let partition = try PinballRadialPartition(
            bounds: CGRect(x: 13, y: 13, width: 364, height: 674),
            taps: [
                PinballSeatTap(seatID: 1, point: CGPoint(x: 195, y: 40)),
                PinballSeatTap(seatID: 2, point: CGPoint(x: 350, y: 350)),
                PinballSeatTap(seatID: 3, point: CGPoint(x: 195, y: 660)),
                PinballSeatTap(seatID: 4, point: CGPoint(x: 40, y: 350))
            ]
        )

        let base = PinballDividerGeometry.baseRays(for: partition)
        XCTAssertEqual(base.count, partition.regions.count)
        XCTAssertTrue(base.allSatisfy { $0.start == partition.center })
        XCTAssertEqual(Set(base.map(\.end)), Set(partition.regions.map(\.startBoundaryPoint)))

        let winner = try XCTUnwrap(partition.regions.first)
        let highlighted = PinballDividerGeometry.winnerRays(
            for: winner.seat.seatID,
            in: partition
        )
        XCTAssertEqual(highlighted.count, 2)
        XCTAssertEqual(highlighted.map(\.end), [winner.startBoundaryPoint, winner.endBoundaryPoint])
        XCTAssertTrue(
            PinballDividerGeometry.winnerRays(for: 999, in: partition).isEmpty
        )
    }

    func testMotionProfileSpendsMomentumContinuouslyAndEndsExactly() throws {
        let curve = try PinballMotionProfile(duration: 5)
        let samples = stride(from: 0.0, through: 5.0, by: 0.05).map { Double($0) }
        let progress = samples.map(curve.progress(at:))
        let speed = samples.map(curve.remainingSpeedFraction(at:))

        XCTAssertEqual(progress.first, 0)
        XCTAssertEqual(progress.last, 1)
        XCTAssertEqual(speed.first, 1)
        XCTAssertEqual(try XCTUnwrap(speed.last), 0, accuracy: 1e-12)
        for pair in zip(progress, progress.dropFirst()) {
            XCTAssertLessThanOrEqual(pair.0, pair.1)
        }
        for pair in zip(speed, speed.dropFirst()) {
            XCTAssertGreaterThanOrEqual(pair.0, pair.1)
        }
        XCTAssertGreaterThan(
            curve.normalizedSpeed(at: 0),
            curve.normalizedSpeed(at: curve.duration)
        )
        XCTAssertGreaterThan(curve.remainingSpeedFraction(at: curve.duration * 0.10), 0.999)
        XCTAssertGreaterThan(curve.remainingSpeedFraction(at: curve.duration * 0.50), 0.93)
        XCTAssertEqual(
            curve.remainingSpeedFraction(at: curve.duration * 0.90),
            0.167_698_440_1,
            accuracy: 1e-10
        )

        let speedDrops = zip(speed, speed.dropFirst()).map { earlier, later in
            earlier - later
        }
        XCTAssertLessThan(try XCTUnwrap(speedDrops.max()), 0.04)
        XCTAssertEqual(try curve.distance(at: 5, totalDistance: 9_876), 9_876, accuracy: 1e-9)
        XCTAssertEqual(try curve.distance(at: 50, totalDistance: 9_876), 9_876, accuracy: 1e-9)
    }

    func testMotionProfileHasContinuousLateSpeedAndAZeroSlopeStop() throws {
        let curve = try PinballMotionProfile(duration: 4)

        XCTAssertEqual(
            curve.progress(atNormalizedTime: 0.50),
            0.653_183_593_75,
            accuracy: 1e-12,
            "Progress must use the exactly normalized polynomial integral."
        )
        XCTAssertEqual(
            curve.progress(atNormalizedTime: 0.80),
            0.950_964_561_510_4,
            accuracy: 1e-12
        )
        XCTAssertEqual(
            curve.remainingSpeedFraction(at: curve.duration * 0.80),
            0.452_014_182_4,
            accuracy: 1e-10
        )
        XCTAssertEqual(
            curve.remainingSpeedFraction(at: curve.duration * 0.95),
            0.051_175_064_24,
            accuracy: 1e-10
        )
        XCTAssertEqual(
            curve.remainingSpeedFraction(at: curve.duration * 0.99),
            0.002_401_975_209,
            accuracy: 1e-11
        )
        XCTAssertEqual(curve.remainingSpeedFraction(at: curve.duration), 0, accuracy: 1e-12)

        let normalizedStep: CGFloat = 0.000_1
        let penultimateSpeed = curve.speedFraction(
            atNormalizedTime: 1 - normalizedStep
        )
        let terminalSlope = penultimateSpeed / normalizedStep
        XCTAssertLessThan(
            terminalSlope,
            0.006,
            "Velocity must ease into zero with no visible endpoint speed cut."
        )

        let before = curve.progress(atNormalizedTime: 0.75 - normalizedStep)
        let center = curve.progress(atNormalizedTime: 0.75)
        let after = curve.progress(atNormalizedTime: 0.75 + normalizedStep)
        XCTAssertEqual(
            center - before,
            after - center,
            accuracy: 4e-8,
            "Integrated progress should remain first-derivative continuous."
        )
    }

    func testMotionProfileInverseReturnsTheOriginalTime() throws {
        let curve = try PinballMotionProfile(duration: 2.4)
        for normalizedTime in stride(from: 0.0, through: 1.0, by: 0.01) {
            let elapsed = normalizedTime * curve.duration
            let progress = curve.progress(at: elapsed)
            XCTAssertEqual(
                curve.elapsedTime(atProgress: progress),
                elapsed,
                accuracy: 0.000_001
            )
        }
    }

    func testSixtyAndOneHundredTwentyHertzPlaybackReachIdenticalEndpoint() throws {
        let bounds = PinballTestFixtures.landscapeBounds
        let launch = try PinballLaunch(
            start: CGPoint(x: bounds.midX, y: bounds.midY),
            direction: CGVector(dx: -0.61, dy: 0.79),
            distance: 5_250
        )
        let curve = try PinballMotionProfile(duration: 5)

        func replay(frameInterval: TimeInterval) throws -> CGPoint {
            var elapsed: TimeInterval = 0
            var point = launch.start
            while elapsed < curve.duration {
                elapsed = min(curve.duration, elapsed + frameInterval)
                let distance = try curve.distance(at: elapsed, totalDistance: launch.distance)
                point = try PinballBilliards.point(atDistance: distance, along: launch, in: bounds)
            }
            return point
        }

        let expected = try PinballBilliards.endPoint(for: launch, in: bounds)
        XCTAssertEqual(try replay(frameInterval: 1.0 / 60.0).x, expected.x, accuracy: 1e-9)
        XCTAssertEqual(try replay(frameInterval: 1.0 / 60.0).y, expected.y, accuracy: 1e-9)
        XCTAssertEqual(try replay(frameInterval: 1.0 / 120.0).x, expected.x, accuracy: 1e-9)
        XCTAssertEqual(try replay(frameInterval: 1.0 / 120.0).y, expected.y, accuracy: 1e-9)
    }

    func testUniformStartCoversPortraitPlayfieldWithoutEdgesOrAxisBias() throws {
        let bounds = PinballTestFixtures.portraitBounds
        var random = SplitMix64RandomSource(seed: 0xC0FFEE)
        let sampleCount = 20_000
        var sumX: CGFloat = 0
        var sumY: CGFloat = 0
        var quadrants = [Int](repeating: 0, count: 4)

        for _ in 0..<sampleCount {
            let point = try PinballSampling.uniformStart(in: bounds, using: &random)
            XCTAssertGreaterThan(point.x, bounds.minX)
            XCTAssertLessThan(point.x, bounds.maxX)
            XCTAssertGreaterThan(point.y, bounds.minY)
            XCTAssertLessThan(point.y, bounds.maxY)
            sumX += point.x
            sumY += point.y
            let quadrant = (point.x >= bounds.midX ? 1 : 0) + (point.y >= bounds.midY ? 2 : 0)
            quadrants[quadrant] += 1
        }

        XCTAssertEqual(sumX / CGFloat(sampleCount), bounds.midX, accuracy: bounds.width * 0.01)
        XCTAssertEqual(sumY / CGFloat(sampleCount), bounds.midY, accuracy: bounds.height * 0.01)
        for count in quadrants {
            XCTAssertEqual(Double(count), Double(sampleCount) / 4, accuracy: Double(sampleCount) * 0.02)
        }
    }

    func testAnalyticEndpointWinnersAreStatisticallyFairAcrossTenEqualAreas() throws {
        let bounds = PinballTestFixtures.landscapeBounds
        let seatCount = 10
        let partition = try PinballRadialPartition(
            bounds: bounds,
            taps: PinballTestFixtures.radialTaps(count: seatCount, in: bounds)
        )
        var random = SplitMix64RandomSource(seed: 0xF17E_CAFE_BA11)
        let sampleCount = 30_000
        var wins = [Int](repeating: 0, count: seatCount)

        for _ in 0..<sampleCount {
            let launch = try PinballSampling.launch(
                in: bounds,
                distanceRange: 400...4_000,
                using: &random
            )
            let endpoint = try PinballBilliards.endPoint(for: launch, in: bounds)
            let seatID = try partition.seatID(containing: endpoint)
            wins[seatID - 1] += 1
        }

        let expected = Double(sampleCount) / Double(seatCount)
        for (index, winsForSeat) in wins.enumerated() {
            XCTAssertEqual(
                Double(winsForSeat),
                expected,
                accuracy: expected * 0.08,
                "Seat \(index + 1) departed materially from its exact equal-area expectation"
            )
        }
    }

    func testInvalidPinballInputsFailExplicitly() throws {
        XCTAssertThrowsError(
            try PinballLaunch(
                start: .zero,
                direction: .zero,
                distance: 10
            )
        ) { error in
            XCTAssertEqual(error as? PinballMathError, .zeroDirection)
        }
        XCTAssertThrowsError(
            try PinballRadialPartition(bounds: .zero, taps: [])
        ) { error in
            XCTAssertEqual(error as? PinballMathError, .invalidBounds)
        }
        XCTAssertThrowsError(try PinballMotionProfile(duration: 0)) { error in
            XCTAssertEqual(error as? PinballMathError, .invalidTimeCurve)
        }
        XCTAssertThrowsError(
            try PinballMotionProfile(duration: 1, decelerationExponent: 1)
        ) { error in
            XCTAssertEqual(error as? PinballMathError, .invalidTimeCurve)
        }
    }

    func testReplayTailIsDistanceBoundedAndSplitIntoContiguousBands() {
        let sampler = PolylineSampler(points: [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 50, y: 0),
            CGPoint(x: 50, y: 100),
            CGPoint(x: 150, y: 100)
        ])

        let bands = sampler.tailBands(at: 1, maximumLength: 90, bandCount: 4)

        XCTAssertEqual(bands.count, 4)
        XCTAssertEqual(bands.first?.first?.x ?? -1, 60, accuracy: 1e-9)
        XCTAssertEqual(bands.first?.first?.y ?? -1, 100, accuracy: 1e-9)
        XCTAssertEqual(bands.last?.last?.x ?? -1, 150, accuracy: 1e-9)
        XCTAssertEqual(bands.last?.last?.y ?? -1, 100, accuracy: 1e-9)
        XCTAssertEqual(bands.reduce(0) { $0 + polylineLength($1) }, 90, accuracy: 1e-9)

        for pair in zip(bands, bands.dropFirst()) {
            XCTAssertEqual(pair.0.last?.x ?? -1, pair.1.first?.x ?? -2, accuracy: 1e-9)
            XCTAssertEqual(pair.0.last?.y ?? -1, pair.1.first?.y ?? -2, accuracy: 1e-9)
        }
    }

    func testReplayTailPreservesCornersInsideVisibleWindow() {
        let corner = CGPoint(x: 50, y: 100)
        let sampler = PolylineSampler(points: [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 50, y: 0),
            corner,
            CGPoint(x: 150, y: 100)
        ])

        let bands = sampler.tailBands(at: 0.72, maximumLength: 90, bandCount: 4)

        XCTAssertTrue(bands.joined().contains(corner))
        XCTAssertEqual(bands.reduce(0) { $0 + polylineLength($1) }, 90, accuracy: 1e-9)
    }

    func testReplayTailResetsAtTheMostRecentWallAndUsesBuildTwelveMetrics() {
        let sampler = PolylineSampler(points: [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 50, y: 0),
            CGPoint(x: 50, y: 100),
            CGPoint(x: 150, y: 100)
        ])

        let bands = sampler.tailBandsSinceLastVertex(
            at: 0.72,
            maximumLength: NativePinballReplayMetrics.maximumTailLength,
            bandCount: 1
        )

        XCTAssertEqual(bands.count, 1)
        XCTAssertEqual(bands[0].first, CGPoint(x: 50, y: 100))
        XCTAssertFalse(bands[0].contains(CGPoint(x: 50, y: 0)))
        XCTAssertEqual(NativePinballReplayMetrics.ballDiameter, 30)
        XCTAssertEqual(NativePinballReplayMetrics.collisionInset, 18)
        XCTAssertEqual(NativePinballReplayMetrics.minimumTailLength, 12)
        XCTAssertEqual(NativePinballReplayMetrics.maximumTailLength, 40)
        XCTAssertEqual(NativePinballReplayMetrics.compressionDuration, 0.025)
        XCTAssertEqual(NativePinballReplayMetrics.reboundDuration, 0.060)
        XCTAssertEqual(NativePinballReplayMetrics.settleDuration, 0.080)
        XCTAssertEqual(NativePinballReplayMetrics.endpointCompressionDuration, 0.060)
        XCTAssertEqual(NativePinballReplayMetrics.endpointReboundDuration, 0.090)
        XCTAssertEqual(NativePinballReplayMetrics.endpointRecoveryDuration, 0.120)
        XCTAssertEqual(NativePinballReplayMetrics.endpointSettleDuration, 0.270)
        XCTAssertLessThanOrEqual(
            NativePinballReplayMetrics.maximumRenderedRadius,
            NativePinballReplayMetrics.collisionInset,
            "The authored ball face, edge, contact shadow, and impact squash must stay inside the board."
        )
    }

    func testImpactMarksProjectFromTheCollisionInsetToTheVisiblePlayfieldEdge() {
        let size = CGSize(width: 390, height: 700)
        let impact = CGPoint(x: 18, y: 682)

        XCTAssertEqual(
            PolylineImpactPresentation.visibleEdgePoint(
                for: .left,
                impactPoint: impact,
                sceneSize: size
            ),
            CGPoint(x: 0, y: 682)
        )
        XCTAssertEqual(
            PolylineImpactPresentation.visibleEdgePoint(
                for: .right,
                impactPoint: impact,
                sceneSize: size
            ),
            CGPoint(x: 390, y: 682)
        )
        XCTAssertEqual(
            PolylineImpactPresentation.visibleEdgePoint(
                for: .top,
                impactPoint: impact,
                sceneSize: size
            ),
            CGPoint(x: 18, y: 700)
        )
        XCTAssertEqual(
            PolylineImpactPresentation.visibleEdgePoint(
                for: .bottom,
                impactPoint: impact,
                sceneSize: size
            ),
            CGPoint(x: 18, y: 0)
        )
    }

    func testRunningReplayOwnsEndpointSettleWhileStaticResultDoesNotRepeatIt() {
        XCTAssertFalse(NativeReplayVisualStyle().settlesAtEndpoint)
        XCTAssertTrue(NativeReplayVisualStyle(settlesAtEndpoint: true).settlesAtEndpoint)
        XCTAssertTrue(NativePinballReplayPresentation.running.settlesAtEndpoint)
        XCTAssertFalse(NativePinballReplayPresentation.finalStatic.settlesAtEndpoint)
        XCTAssertTrue(NativePinballReplayPresentation.running.dependsOnReduceMotion)
        XCTAssertFalse(NativePinballReplayPresentation.finalStatic.dependsOnReduceMotion)
    }

    func testPolylineImpactsIdentifyReflectedWallAndProgress() {
        let impacts = PolylineImpactAnalysis.impacts(in: [
            CGPoint(x: 2, y: 3),
            CGPoint(x: 10, y: 3),
            CGPoint(x: 0, y: 3),
            CGPoint(x: 4, y: 3)
        ])

        XCTAssertEqual(impacts.count, 2)
        XCTAssertEqual(impacts[0].vertexIndex, 1)
        XCTAssertEqual(impacts[0].point, CGPoint(x: 10, y: 3))
        XCTAssertEqual(impacts[0].edges, [.right])
        XCTAssertEqual(impacts[0].wallNormalImpulseFraction, 1, accuracy: 1e-12)
        XCTAssertEqual(impacts[0].progress, 8.0 / 22.0, accuracy: 1e-12)
        XCTAssertEqual(impacts[1].vertexIndex, 2)
        XCTAssertEqual(impacts[1].point, CGPoint(x: 0, y: 3))
        XCTAssertEqual(impacts[1].edges, [.left])
        XCTAssertEqual(impacts[1].wallNormalImpulseFraction, 1, accuracy: 1e-12)
        XCTAssertEqual(impacts[1].progress, 18.0 / 22.0, accuracy: 1e-12)
    }

    func testPolylineImpactCanRepresentAReflectedCorner() {
        let impacts = PolylineImpactAnalysis.impacts(in: [
            CGPoint(x: 5, y: 5),
            CGPoint(x: 10, y: 10),
            CGPoint(x: 7, y: 7)
        ])

        XCTAssertEqual(impacts.count, 1)
        XCTAssertEqual(impacts[0].edges, [.right, .top])
        XCTAssertEqual(impacts[0].wallNormalImpulseFraction, 1, accuracy: 1e-12)
    }

    func testPolylineImpactNormalImpulseDistinguishesGlancingAndHeadOnContacts() throws {
        let glancing = try XCTUnwrap(
            PolylineImpactAnalysis.impacts(in: [
                CGPoint(x: 9, y: 0),
                CGPoint(x: 10, y: 10),
                CGPoint(x: 9, y: 20)
            ]).first
        )
        let headOn = try XCTUnwrap(
            PolylineImpactAnalysis.impacts(in: [
                CGPoint(x: 0, y: 5),
                CGPoint(x: 10, y: 5),
                CGPoint(x: 0, y: 5)
            ]).first
        )

        XCTAssertEqual(glancing.edges, [.right])
        XCTAssertEqual(glancing.wallNormalImpulseFraction, 1 / sqrt(101), accuracy: 1e-12)
        XCTAssertEqual(headOn.wallNormalImpulseFraction, 1, accuracy: 1e-12)
        XCTAssertLessThan(glancing.wallNormalImpulseFraction, headOn.wallNormalImpulseFraction)
    }

    func testCollinearPolylineVerticesAreNotWallImpacts() {
        let impacts = PolylineImpactAnalysis.impacts(in: [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 5, y: 5),
            CGPoint(x: 10, y: 10)
        ])

        XCTAssertTrue(impacts.isEmpty)
    }

    @MainActor
    func testReplayEmitsRenderedImpactsAndCompletionExactlyOnce() {
        let scene = NativeAnalyticPolylineReplayScene(
            size: CGSize(width: 12, height: 8)
        )
        var renderedImpacts: [NativeAnalyticReplayImpact] = []
        var finishCount = 0
        scene.replay(
            NativeAnalyticReplayPlan(
                polyline: [
                    CGPoint(x: 2, y: 3),
                    CGPoint(x: 10, y: 3),
                    CGPoint(x: 0, y: 3),
                    CGPoint(x: 4, y: 3)
                ],
                duration: 1
            ),
            callbacks: NativeAnalyticReplayCallbacks(
                onImpact: { renderedImpacts.append($0) },
                onFinished: { finishCount += 1 }
            )
        )

        scene.update(10)
        XCTAssertTrue(renderedImpacts.isEmpty)
        XCTAssertEqual(finishCount, 0)

        scene.update(10.50)
        XCTAssertEqual(renderedImpacts.map(\.vertexIndex), [1])
        scene.update(10.90)
        XCTAssertEqual(renderedImpacts.map(\.vertexIndex), [1, 2])
        scene.update(11)
        scene.update(12)

        XCTAssertEqual(renderedImpacts.map(\.vertexIndex), [1, 2])
        XCTAssertEqual(renderedImpacts.map(\.isCorner), [false, false])
        XCTAssertEqual(renderedImpacts[0].progress, 8.0 / 22.0, accuracy: 1e-12)
        XCTAssertEqual(renderedImpacts[1].progress, 18.0 / 22.0, accuracy: 1e-12)
        XCTAssertTrue(renderedImpacts.allSatisfy { abs($0.speedFraction - 1) < 1e-9 })
        XCTAssertTrue(
            renderedImpacts.allSatisfy { abs($0.wallNormalImpulseFraction - 1) < 1e-9 }
        )
        XCTAssertEqual(finishCount, 1)
    }

    // MARK: - Bumper strikes

    /// A glancing circular bounce preserves both direction-component signs, so
    /// the geometric layer finds nothing. Authored metadata has to carry it.
    @MainActor
    func testAGlancingBumperVertexStillEmitsARenderedImpact() throws {
        let polyline = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 5),
            CGPoint(x: 21, y: 9)
        ]
        XCTAssertTrue(
            PolylineImpactAnalysis.impacts(in: polyline).isEmpty,
            "The geometric layer is deliberately unchanged and still finds no turn here."
        )

        let scene = NativeAnalyticPolylineReplayScene(size: CGSize(width: 40, height: 40))
        var renderedImpacts: [NativeAnalyticReplayImpact] = []
        scene.replay(
            NativeAnalyticReplayPlan(
                polyline: polyline,
                duration: 1,
                bumperMarks: [
                    1: NativeReplayBumperMark(
                        seatID: 7,
                        center: CGPoint(x: 10, y: 25),
                        radius: 5
                    )
                ]
            ),
            callbacks: NativeAnalyticReplayCallbacks(
                onImpact: { renderedImpacts.append($0) }
            )
        )

        scene.update(10)
        XCTAssertTrue(renderedImpacts.isEmpty)
        scene.update(10.6)

        XCTAssertEqual(renderedImpacts.map(\.vertexIndex), [1])
        XCTAssertNotNil(scene.childNode(withName: "//bumper-strike:7"))
        XCTAssertNil(
            scene.childNode(withName: "//impact-edge"),
            "A seat contact must never be drawn as a wall mark."
        )
    }

    /// A steep bounce IS found geometrically, but attributed to a wall, which
    /// would snap its mark to the playfield border far from the seat.
    @MainActor
    func testASteepBumperHitDrawsAtTheSeatNotTheBorder() throws {
        let scene = NativeAnalyticPolylineReplayScene(size: CGSize(width: 12, height: 8))
        var renderedImpacts: [NativeAnalyticReplayImpact] = []
        let center = CGPoint(x: 10, y: 23)
        scene.replay(
            NativeAnalyticReplayPlan(
                polyline: [
                    CGPoint(x: 2, y: 3),
                    CGPoint(x: 10, y: 3),
                    CGPoint(x: 0, y: 3)
                ],
                duration: 1,
                bumperMarks: [1: NativeReplayBumperMark(seatID: 2, center: center, radius: 5)]
            ),
            callbacks: NativeAnalyticReplayCallbacks(
                onImpact: { renderedImpacts.append($0) }
            )
        )

        scene.update(10)
        scene.update(10.6)

        XCTAssertEqual(renderedImpacts.map(\.vertexIndex), [1])
        XCTAssertNil(scene.childNode(withName: "//impact-edge"))
        let strike = try XCTUnwrap(scene.childNode(withName: "//bumper-strike:2"))
        XCTAssertEqual(strike.position.x, center.x, accuracy: 1e-6)
        XCTAssertEqual(strike.position.y, center.y, accuracy: 1e-6)
        XCTAssertTrue(
            strike.children.allSatisfy { !($0 is SKLabelNode) },
            "The strike must explain itself through shape and motion, never text."
        )
    }

    /// A round contact has one normal, so it is never a corner, and its impulse
    /// comes from that normal rather than from a wall axis.
    @MainActor
    func testABumperStrikeIsNeverACornerAndUsesTheContactNormal() {
        let scene = NativeAnalyticPolylineReplayScene(size: CGSize(width: 40, height: 40))
        var renderedImpacts: [NativeAnalyticReplayImpact] = []
        // Contact normal points straight down from a centre directly above.
        scene.replay(
            NativeAnalyticReplayPlan(
                polyline: [
                    CGPoint(x: 0, y: 0),
                    CGPoint(x: 10, y: 5),
                    CGPoint(x: 21, y: 9)
                ],
                duration: 1,
                bumperMarks: [
                    1: NativeReplayBumperMark(
                        seatID: 3,
                        center: CGPoint(x: 10, y: 25),
                        radius: 5
                    )
                ]
            ),
            callbacks: NativeAnalyticReplayCallbacks(
                onImpact: { renderedImpacts.append($0) }
            )
        )
        scene.update(10)
        scene.update(10.6)

        XCTAssertEqual(renderedImpacts.count, 1)
        XCTAssertFalse(renderedImpacts[0].isCorner)
        // incoming (10,5) normalized dotted with normal (0,-1) => 5/sqrt(125).
        XCTAssertEqual(
            renderedImpacts[0].wallNormalImpulseFraction,
            5.0 / (125.0 as Double).squareRoot(),
            accuracy: 1e-9
        )
    }

    @MainActor
    func testRepeatedStrikesOnOneSeatKeepASinglePulse() {
        let scene = NativeAnalyticPolylineReplayScene(size: CGSize(width: 60, height: 60))
        let center = CGPoint(x: 10, y: 30)
        scene.replay(
            NativeAnalyticReplayPlan(
                polyline: [
                    CGPoint(x: 0, y: 0),
                    CGPoint(x: 10, y: 5),
                    CGPoint(x: 21, y: 9),
                    CGPoint(x: 31, y: 14)
                ],
                duration: 1,
                bumperMarks: [
                    1: NativeReplayBumperMark(seatID: 5, center: center, radius: 5),
                    2: NativeReplayBumperMark(seatID: 5, center: center, radius: 5)
                ]
            )
        )
        scene.update(10)
        scene.update(10.9)

        let strikes = scene.children
            .flatMap(\.children)
            .filter { $0.name == "bumper-strike:5" }
        XCTAssertEqual(strikes.count, 1, "A re-strike restarts the pulse rather than stacking.")
    }

    @MainActor
    func testCancellingAReplayRemovesInFlightBumperStrikes() {
        let scene = NativeAnalyticPolylineReplayScene(size: CGSize(width: 40, height: 40))
        scene.replay(
            NativeAnalyticReplayPlan(
                polyline: [
                    CGPoint(x: 0, y: 0),
                    CGPoint(x: 10, y: 5),
                    CGPoint(x: 21, y: 9)
                ],
                duration: 1,
                bumperMarks: [
                    1: NativeReplayBumperMark(
                        seatID: 9,
                        center: CGPoint(x: 10, y: 25),
                        radius: 5
                    )
                ]
            )
        )
        scene.update(10)
        scene.update(10.6)
        XCTAssertNotNil(scene.childNode(withName: "//bumper-strike:9"))

        scene.cancelReplay()
        XCTAssertNil(scene.childNode(withName: "//bumper-strike:9"))
    }

    @MainActor
    func testIncreasedContrastThickensTheStrikeWithoutChangingItsHue() throws {
        func strokeWidths(increasedContrast: Bool) throws -> [CGFloat] {
            let scene = NativeAnalyticPolylineReplayScene(size: CGSize(width: 40, height: 40))
            scene.replay(
                NativeAnalyticReplayPlan(
                    polyline: [
                        CGPoint(x: 0, y: 0),
                        CGPoint(x: 10, y: 5),
                        CGPoint(x: 21, y: 9)
                    ],
                    duration: 1,
                    bumperMarks: [
                        1: NativeReplayBumperMark(
                            seatID: 1,
                            center: CGPoint(x: 10, y: 25),
                            radius: 5
                        )
                    ],
                    style: NativeReplayVisualStyle(
                        impactColor: .systemOrange,
                        increasesContrast: increasedContrast
                    )
                )
            )
            scene.update(10)
            scene.update(10.6)
            let strike = try XCTUnwrap(scene.childNode(withName: "//bumper-strike:1"))
            return strike.children.compactMap { ($0 as? SKShapeNode)?.lineWidth }
        }

        let plain = try strokeWidths(increasedContrast: false)
        let contrasted = try strokeWidths(increasedContrast: true)
        XCTAssertEqual(plain.count, contrasted.count)
        XCTAssertFalse(plain.isEmpty)
        for (plainWidth, contrastedWidth) in zip(plain, contrasted) {
            XCTAssertGreaterThan(contrastedWidth, plainWidth)
        }
    }

    @MainActor
    func testAPlanWithoutBumperMarksIsUnchanged() {
        let scene = NativeAnalyticPolylineReplayScene(size: CGSize(width: 12, height: 8))
        var renderedImpacts: [NativeAnalyticReplayImpact] = []
        scene.replay(
            NativeAnalyticReplayPlan(
                polyline: [
                    CGPoint(x: 2, y: 3),
                    CGPoint(x: 10, y: 3),
                    CGPoint(x: 0, y: 3)
                ],
                duration: 1
            ),
            callbacks: NativeAnalyticReplayCallbacks(
                onImpact: { renderedImpacts.append($0) }
            )
        )
        scene.update(10)
        scene.update(10.6)

        XCTAssertEqual(renderedImpacts.map(\.vertexIndex), [1])
        XCTAssertNotNil(scene.childNode(withName: "//impact-edge"))
        XCTAssertTrue(renderedImpacts.allSatisfy { $0.isCorner == false })
    }

    @MainActor
    func testFairnessDeflectorGetsDistinctRenderedImpactAndWallTransformation() throws {
        let scene = NativeAnalyticPolylineReplayScene(
            size: CGSize(width: 12, height: 8)
        )
        var renderedImpacts: [NativeAnalyticReplayImpact] = []
        scene.replay(
            NativeAnalyticReplayPlan(
                polyline: [
                    CGPoint(x: 2, y: 3),
                    CGPoint(x: 10, y: 3),
                    CGPoint(x: 0, y: 5),
                    CGPoint(x: 4, y: 5)
                ],
                duration: 1,
                fairnessDeflectorVertexIndex: 1,
                style: NativeReplayVisualStyle(
                    impactColor: .systemOrange,
                    reducesMotion: false
                )
            ),
            callbacks: NativeAnalyticReplayCallbacks(
                onImpact: { renderedImpacts.append($0) }
            )
        )

        scene.update(10)
        XCTAssertNil(scene.childNode(withName: "//fairness-wall-transform"))
        scene.update(10.50)

        XCTAssertEqual(renderedImpacts.map(\.vertexIndex), [1])
        XCTAssertTrue(renderedImpacts[0].isFairnessDeflection)
        let transformedWall = try XCTUnwrap(
            scene.childNode(withName: "//fairness-wall-transform")
        )
        XCTAssertNotNil(transformedWall.childNode(withName: "fairness-wall-depth"))
        XCTAssertNotNil(transformedWall.childNode(withName: "fairness-wall-face"))
        XCTAssertNotNil(transformedWall.childNode(withName: "fairness-wall-inlay"))
        XCTAssertTrue(transformedWall.hasActions())
        XCTAssertNotEqual(
            transformedWall.xScale,
            1,
            "A vertical wall should already be visibly flexed on the rendered turn frame."
        )
        XCTAssertTrue(
            transformedWall.children.allSatisfy { !($0 is SKLabelNode) },
            "The wall change must explain itself through motion and color, never text."
        )
        XCTAssertNil(scene.childNode(withName: "//fair-bounce-stamp"))
        XCTAssertNil(scene.childNode(withName: "//fair-bounce-label"))
        XCTAssertNil(
            scene.childNode(withName: "//impact-edge"),
            "The disclosed deflector must not masquerade as an ordinary wall impact."
        )

        scene.update(10.95)
        XCTAssertEqual(renderedImpacts.map(\.vertexIndex), [1, 2])
        XCTAssertFalse(renderedImpacts[1].isFairnessDeflection)
    }

    @MainActor
    func testNaturalReflectionNeverShowsFairnessWallTransformation() {
        let scene = NativeAnalyticPolylineReplayScene(
            size: CGSize(width: 12, height: 8)
        )
        scene.replay(
            NativeAnalyticReplayPlan(
                polyline: [
                    CGPoint(x: 2, y: 3),
                    CGPoint(x: 10, y: 3),
                    CGPoint(x: 0, y: 5),
                    CGPoint(x: 4, y: 5)
                ],
                duration: 1,
                fairnessDeflectorVertexIndex: nil,
                style: NativeReplayVisualStyle(
                    impactColor: .systemOrange,
                    reducesMotion: true
                )
            )
        )

        scene.update(20)
        scene.update(20.50)

        XCTAssertNil(scene.childNode(withName: "//fairness-wall-transform"))
        XCTAssertNotNil(
            scene.childNode(withName: "//impact-edge"),
            "A natural wall reflection should retain the ordinary localized impact mark."
        )
    }

    @MainActor
    func testFairnessDeflectorAtReleaseIsDeliveredOnce() {
        let scene = NativeAnalyticPolylineReplayScene(
            size: CGSize(width: 100, height: 80)
        )
        var renderedImpacts: [NativeAnalyticReplayImpact] = []
        scene.replay(
            NativeAnalyticReplayPlan(
                polyline: [
                    CGPoint(x: 18, y: 40),
                    CGPoint(x: 70, y: 50)
                ],
                duration: 1,
                fairnessDeflectorVertexIndex: 0
            ),
            callbacks: NativeAnalyticReplayCallbacks(
                onImpact: { renderedImpacts.append($0) }
            )
        )

        scene.update(20)
        scene.update(20.5)

        XCTAssertEqual(renderedImpacts.count, 1)
        XCTAssertEqual(renderedImpacts[0].vertexIndex, 0)
        XCTAssertTrue(renderedImpacts[0].isFairnessDeflection)
    }

    @MainActor
    func testTaggedNearTangentFairnessDeflectorIsNotLostToImpactTolerance() {
        let scene = NativeAnalyticPolylineReplayScene(
            size: CGSize(width: 12, height: 10)
        )
        var renderedImpacts: [NativeAnalyticReplayImpact] = []
        scene.replay(
            NativeAnalyticReplayPlan(
                polyline: [
                    CGPoint(x: 9.999_999, y: 0),
                    CGPoint(x: 10, y: 5),
                    CGPoint(x: 9.999_999, y: 9)
                ],
                duration: 1,
                fairnessDeflectorVertexIndex: 1
            ),
            callbacks: NativeAnalyticReplayCallbacks(
                onImpact: { renderedImpacts.append($0) }
            )
        )

        scene.update(30)
        scene.update(30.60)

        XCTAssertEqual(renderedImpacts.count, 1)
        XCTAssertEqual(renderedImpacts[0].vertexIndex, 1)
        XCTAssertTrue(renderedImpacts[0].isFairnessDeflection)
    }

    @MainActor
    func testEndpointSettleDeliversCompressionThenFinishesAfterFullRenderedSettle() {
        let scene = NativeAnalyticPolylineReplayScene(
            size: CGSize(width: 20, height: 20)
        )
        var compressionCount = 0
        var finishCount = 0
        scene.replay(
            NativeAnalyticReplayPlan(
                polyline: [CGPoint(x: 2, y: 10), CGPoint(x: 18, y: 10)],
                duration: 1,
                style: NativeReplayVisualStyle(settlesAtEndpoint: true)
            ),
            callbacks: NativeAnalyticReplayCallbacks(
                onEndpointCompression: { compressionCount += 1 },
                onFinished: { finishCount += 1 }
            )
        )

        scene.update(10)
        scene.update(11)
        XCTAssertEqual(compressionCount, 0)
        XCTAssertEqual(finishCount, 0)

        scene.update(11 + NativePinballReplayMetrics.endpointCompressionDuration - 0.001)
        XCTAssertEqual(compressionCount, 0)
        scene.update(11 + NativePinballReplayMetrics.endpointCompressionDuration)
        XCTAssertEqual(compressionCount, 1)
        XCTAssertEqual(finishCount, 0)

        scene.update(11 + NativePinballReplayMetrics.endpointSettleDuration - 0.001)
        XCTAssertEqual(finishCount, 0)
        scene.update(11 + NativePinballReplayMetrics.endpointSettleDuration)
        scene.update(12)
        XCTAssertEqual(compressionCount, 1)
        XCTAssertEqual(finishCount, 1)
    }

    @MainActor
    func testZeroDurationEndpointPlanFinishesWithoutAFalseCompressionCue() {
        let scene = NativeAnalyticPolylineReplayScene(
            size: CGSize(width: 20, height: 20)
        )
        var compressionCount = 0
        var finishCount = 0
        scene.replay(
            NativeAnalyticReplayPlan(
                polyline: [CGPoint(x: 2, y: 10), CGPoint(x: 18, y: 10)],
                duration: 0,
                style: NativeReplayVisualStyle(settlesAtEndpoint: true)
            ),
            callbacks: NativeAnalyticReplayCallbacks(
                onEndpointCompression: { compressionCount += 1 },
                onFinished: { finishCount += 1 }
            )
        )
        scene.update(10)

        XCTAssertEqual(compressionCount, 0)
        XCTAssertEqual(finishCount, 1)
    }

    @MainActor
    func testCancellingEndpointSettleSuppressesCompressionAndCompletion() {
        let scene = NativeAnalyticPolylineReplayScene(
            size: CGSize(width: 20, height: 20)
        )
        var compressionCount = 0
        var finishCount = 0
        var cancellationCount = 0
        scene.replay(
            NativeAnalyticReplayPlan(
                polyline: [CGPoint(x: 2, y: 10), CGPoint(x: 18, y: 10)],
                duration: 1,
                style: NativeReplayVisualStyle(settlesAtEndpoint: true)
            ),
            callbacks: NativeAnalyticReplayCallbacks(
                onEndpointCompression: { compressionCount += 1 },
                onFinished: { finishCount += 1 },
                onCancelled: { cancellationCount += 1 }
            )
        )

        scene.update(10)
        scene.update(11)
        scene.cancelReplay()
        scene.update(12)

        XCTAssertEqual(compressionCount, 0)
        XCTAssertEqual(finishCount, 0)
        XCTAssertEqual(cancellationCount, 1)
    }

    func testRollingMaterialMarkUsesTravelledDistanceAndCurrentDirection() {
        let radius: CGFloat = 15
        let start = RollingMaterialMarkPresentation.sample(
            distance: 0,
            tangent: CGVector(dx: 1, dy: 0),
            ballRadius: radius
        )
        let edge = RollingMaterialMarkPresentation.sample(
            distance: .pi * radius / 2,
            tangent: CGVector(dx: 1, dy: 0),
            ballRadius: radius
        )
        let fullTurn = RollingMaterialMarkPresentation.sample(
            distance: .pi * radius * 2,
            tangent: CGVector(dx: 1, dy: 0),
            ballRadius: radius
        )
        let reflected = RollingMaterialMarkPresentation.sample(
            distance: .pi * radius / 2,
            tangent: CGVector(dx: 0, dy: 1),
            ballRadius: radius
        )

        XCTAssertEqual(start.position.x, fullTurn.position.x, accuracy: 1e-9)
        XCTAssertEqual(start.position.y, fullTurn.position.y, accuracy: 1e-9)
        XCTAssertEqual(start.alpha, fullTurn.alpha, accuracy: 1e-9)
        XCTAssertEqual(edge.position.x, radius * 0.54, accuracy: 1e-9)
        XCTAssertLessThan(edge.alpha, 0.001)
        XCTAssertEqual(reflected.position.y, radius * 0.54, accuracy: 1e-9)
        XCTAssertNotEqual(edge.position, reflected.position)
    }

    @MainActor
    func testCancelledReplayNeverEmitsLateImpactOrFinishCallbacks() {
        let scene = NativeAnalyticPolylineReplayScene(
            size: CGSize(width: 12, height: 8)
        )
        var impactCount = 0
        var finishCount = 0
        var cancellationCount = 0
        scene.replay(
            NativeAnalyticReplayPlan(
                polyline: [
                    CGPoint(x: 2, y: 3),
                    CGPoint(x: 10, y: 3),
                    CGPoint(x: 0, y: 3)
                ],
                duration: 1
            ),
            callbacks: NativeAnalyticReplayCallbacks(
                onImpact: { _ in impactCount += 1 },
                onFinished: { finishCount += 1 },
                onCancelled: { cancellationCount += 1 }
            )
        )

        scene.update(20)
        scene.cancelReplay()
        scene.cancelReplay()
        scene.update(22)

        XCTAssertEqual(impactCount, 0)
        XCTAssertEqual(finishCount, 0)
        XCTAssertEqual(cancellationCount, 1)
    }

    func testFlickCoachShowsTwoWordlessPassesWithAQuietPause() throws {
        let timeline = PinballFlickCoachTimeline(reduceMotion: false)

        XCTAssertEqual(PinballFlickCoachTimeline.travelDistance, 52)
        XCTAssertNotNil(timeline.sample(at: 0.20))
        XCTAssertNil(timeline.sample(at: 0.80))
        XCTAssertNotNil(timeline.sample(at: 1.30))
        XCTAssertNil(timeline.sample(at: PinballFlickCoachTimeline.totalDuration + 0.01))

        let firstEnd = try XCTUnwrap(
            timeline.sample(at: PinballFlickCoachTimeline.passDuration)
        )
        let secondStart = try XCTUnwrap(
            timeline.sample(
                at: PinballFlickCoachTimeline.passDuration +
                    PinballFlickCoachTimeline.pauseDuration
            )
        )
        XCTAssertEqual(firstEnd.progress, 1, accuracy: 1e-12)
        XCTAssertEqual(secondStart.progress, 0, accuracy: 1e-12)
    }

    func testReducedMotionFlickCoachIsStaticForOnePointTwoSeconds() throws {
        let timeline = PinballFlickCoachTimeline(reduceMotion: true)
        let start = try XCTUnwrap(timeline.sample(at: 0))
        let end = try XCTUnwrap(timeline.sample(at: 1.20))

        XCTAssertEqual(start.progress, 1)
        XCTAssertEqual(end.progress, 1)
        XCTAssertEqual(start.opacity, end.opacity)
        XCTAssertNil(timeline.sample(at: 1.201))
    }

    private func polylineLength(_ points: [CGPoint]) -> CGFloat {
        zip(points, points.dropFirst()).reduce(0) { partial, pair in
            partial + hypot(pair.1.x - pair.0.x, pair.1.y - pair.0.y)
        }
    }
}
