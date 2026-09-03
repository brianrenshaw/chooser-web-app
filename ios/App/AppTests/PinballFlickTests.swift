import CoreGraphics
import XCTest
@testable import App

final class PinballFlickTests: XCTestCase {
    func testGestureClassifierKeepsSeatFlickAndAmbiguousBandsDistinct() throws {
        let seat = payload(
            end: CGPoint(x: 22, y: 0),
            velocity: CGVector(dx: 900, dy: 0),
            duration: 0.08
        )
        let flick = payload(
            end: CGPoint(x: 36, y: 0),
            velocity: CGVector(dx: 400, dy: 0),
            duration: 0.09
        )
        let ambiguousDistance = payload(
            end: CGPoint(x: 30, y: 0),
            velocity: CGVector(dx: 1_200, dy: 0),
            duration: 0.05
        )
        let ambiguousSpeed = payload(
            end: CGPoint(x: 60, y: 0),
            velocity: CGVector(dx: 399, dy: 0),
            duration: 0.15
        )

        XCTAssertEqual(NativePinballGestureClassifier.classify(seat), .seat(seat))
        XCTAssertEqual(NativePinballGestureClassifier.classify(flick), .flick(flick))
        XCTAssertNil(NativePinballGestureClassifier.classify(ambiguousDistance))
        XCTAssertNil(NativePinballGestureClassifier.classify(ambiguousSpeed))
        XCTAssertNil(NativePinballGestureClassifier.classify(seat, cancelled: true))
        XCTAssertNil(NativePinballGestureClassifier.classify(flick, cancelled: true))
    }

    func testGesturePayloadExposesCompleteMeasurement() {
        let payload = NativePinballGesturePayload(
            start: CGPoint(x: 12, y: 30),
            end: CGPoint(x: -24, y: 78),
            velocity: CGVector(dx: -480, dy: 640),
            duration: 0.125
        )

        XCTAssertEqual(payload.start, CGPoint(x: 12, y: 30))
        XCTAssertEqual(payload.end, CGPoint(x: -24, y: 78))
        XCTAssertEqual(payload.translation, CGVector(dx: -36, dy: 48))
        XCTAssertEqual(payload.velocity, CGVector(dx: -480, dy: 640))
        XCTAssertEqual(payload.duration, 0.125)
        XCTAssertEqual(payload.distance, 60, accuracy: 1e-12)
        XCTAssertEqual(payload.speed, 800, accuracy: 1e-12)
        XCTAssertEqual(payload.flickIntent?.releasePoint, payload.end)
        XCTAssertEqual(payload.flickIntent?.direction, payload.velocity)
        XCTAssertEqual(payload.flickIntent?.releasePoint, payload.end)
    }

    func testDirectManipulationTrackingUsesTheCommittedFlickThresholds() {
        let fastButShort = NativePinballGestureTracking(
            start: .zero,
            current: CGPoint(x: 35, y: 0),
            velocity: CGVector(dx: 900, dy: 0),
            duration: 0.05
        )
        let farButSlow = NativePinballGestureTracking(
            start: .zero,
            current: CGPoint(x: 80, y: 0),
            velocity: CGVector(dx: 399, dy: 0),
            duration: 0.20
        )
        let clearFlick = NativePinballGestureTracking(
            start: CGPoint(x: 12, y: 18),
            current: CGPoint(x: 48, y: 18),
            velocity: CGVector(dx: 400, dy: 0),
            duration: 0.09
        )

        XCTAssertFalse(fastButShort.isClearFlick)
        XCTAssertFalse(farButSlow.isClearFlick)
        XCTAssertTrue(clearFlick.isClearFlick)
        XCTAssertEqual(clearFlick.payload.end, clearFlick.current)
        XCTAssertEqual(clearFlick.payload.flickIntent?.releasePoint, clearFlick.current)
    }

    func testDirectManipulationBallUsesTheCollisionSafeReleasePoint() {
        let size = CGSize(width: 390, height: 700)

        XCTAssertEqual(
            PinballDirectManipulationGeometry.clampedBallCenter(
                for: CGPoint(x: -40, y: 760),
                in: size
            ),
            CGPoint(x: 18.5, y: 681.5)
        )
        XCTAssertEqual(
            PinballDirectManipulationGeometry.clampedBallCenter(
                for: CGPoint(x: 170, y: 240),
                in: size
            ),
            CGPoint(x: 170, y: 240)
        )
    }

    func testReleaseVelocityKeepsTheCommittedFlickThroughStationaryTouchUpSamples() {
        let velocity = NativePinballGestureVelocityEstimator.releaseVelocity(
            from: [
                .init(location: CGPoint(x: 0, y: 0), timestamp: 0),
                .init(location: CGPoint(x: 100, y: 0), timestamp: 0.86),
                .init(location: CGPoint(x: 140, y: 0), timestamp: 0.91),
                .init(location: CGPoint(x: 180, y: 0), timestamp: 0.96),
                .init(location: CGPoint(x: 180, y: 0), timestamp: 1.00)
            ],
            gestureDuration: 1
        )

        XCTAssertEqual(velocity.dx, 800, accuracy: 0.5)
        XCTAssertEqual(velocity.dy, 0, accuracy: 1e-12)
    }

    func testReleaseVelocityUsesFinalWeightedWindowAndRejectsAnIsolatedSpike() {
        let velocity = NativePinballGestureVelocityEstimator.releaseVelocity(
            from: [
                .init(location: CGPoint(x: 0, y: 0), timestamp: 0.88),
                .init(location: CGPoint(x: 16, y: 4), timestamp: 0.90),
                .init(location: CGPoint(x: 32, y: 8), timestamp: 0.92),
                .init(location: CGPoint(x: 180, y: -120), timestamp: 0.94),
                .init(location: CGPoint(x: 64, y: 16), timestamp: 0.96),
                .init(location: CGPoint(x: 80, y: 20), timestamp: 0.98),
                .init(location: CGPoint(x: 96, y: 24), timestamp: 1.00)
            ],
            gestureDuration: 0.12
        )

        XCTAssertEqual(velocity.dx, 800, accuracy: 6)
        XCTAssertEqual(velocity.dy, 200, accuracy: 6)
    }

    func testReleaseVelocityRejectsADragThatStoppedWellBeforeRelease() {
        let velocity = NativePinballGestureVelocityEstimator.releaseVelocity(
            from: [
                .init(location: CGPoint(x: 0, y: 0), timestamp: 0),
                .init(location: CGPoint(x: 100, y: 0), timestamp: 0.50),
                .init(location: CGPoint(x: 100, y: 0), timestamp: 1.00)
            ],
            gestureDuration: 1
        )

        XCTAssertEqual(velocity, .zero)
    }

    func testDirectionNormalizationPreservesAxesAndQuadrants() throws {
        let inputs = [
            CGVector(dx: 1_000, dy: 0),
            CGVector(dx: -1_000, dy: 0),
            CGVector(dx: 0, dy: 1_000),
            CGVector(dx: 0, dy: -1_000),
            CGVector(dx: -3, dy: 4)
        ]

        for input in inputs {
            let output = try PinballFlickLaunchPolicy.normalizedDirection(input)
            XCTAssertEqual(hypot(output.dx, output.dy), 1, accuracy: 1e-12)
            XCTAssertEqual(output.dx.sign, input.dx.sign)
            XCTAssertEqual(output.dy.sign, input.dy.sign)
        }

        let diagonal = try PinballFlickLaunchPolicy.normalizedDirection(
            CGVector(dx: -3, dy: 4)
        )
        XCTAssertEqual(diagonal.dx, -0.6, accuracy: 1e-12)
        XCTAssertEqual(diagonal.dy, 0.8, accuracy: 1e-12)
    }

    func testFlickSpeedMapsLinearlyOntoConfiguredPerimeterRange() throws {
        let bounds = CGRect(x: 10, y: -10, width: 300, height: 600)
        let perimeter = 2 * (bounds.width + bounds.height)

        XCTAssertEqual(
            try PinballFlickLaunchPolicy.travelDistance(forSpeed: 400, in: bounds),
            perimeter * 1.45,
            accuracy: 1e-10
        )
        XCTAssertEqual(
            try PinballFlickLaunchPolicy.travelDistance(forSpeed: 1_000, in: bounds),
            perimeter * 1.775,
            accuracy: 1e-10
        )
        XCTAssertEqual(
            try PinballFlickLaunchPolicy.travelDistance(forSpeed: 1_600, in: bounds),
            perimeter * 2.10,
            accuracy: 1e-10
        )
        XCTAssertEqual(
            try PinballFlickLaunchPolicy.travelDistance(forSpeed: 4_000, in: bounds),
            perimeter * 2.10,
            accuracy: 1e-10
        )
        XCTAssertEqual(
            try PinballFlickLaunchPolicy.flightDuration(forSpeed: 400),
            4.20,
            accuracy: 1e-12
        )
        XCTAssertEqual(
            try PinballFlickLaunchPolicy.flightDuration(forSpeed: 1_000),
            4.00,
            accuracy: 1e-12
        )
        XCTAssertEqual(
            try PinballFlickLaunchPolicy.flightDuration(forSpeed: 1_600),
            3.80,
            accuracy: 1e-12
        )
        XCTAssertEqual(
            PinballFlickLaunchPolicy.launchEnergy(forStrength: 0),
            0.62,
            accuracy: 1e-12
        )
        XCTAssertEqual(
            PinballFlickLaunchPolicy.launchEnergy(forStrength: 0.5),
            0.81,
            accuracy: 1e-12
        )
        XCTAssertEqual(
            PinballFlickLaunchPolicy.launchEnergy(forStrength: 1),
            1,
            accuracy: 1e-12
        )
    }

    func testFlickStartsAtReleaseAndKeepsExactDirectionThroughFirstWall() throws {
        let bounds = PinballTestFixtures.portraitBounds
        let partition = try PinballRadialPartition(
            bounds: bounds,
            taps: PinballTestFixtures.radialTaps(count: 8, in: bounds)
        )
        let release = CGPoint(x: bounds.minX + 91, y: bounds.minY + 277)
        let intent = try PinballFlickIntent(
            releasePoint: release,
            direction: CGVector(dx: 3, dy: -2),
            speed: 1_000
        )
        var random = SplitMix64RandomSource(seed: 0x51A7_0001)

        let result = try PinballRoundResolver.flickRound(
            partition: partition,
            intent: intent,
            using: &random
        )

        let launch = result.trajectory.launch
        XCTAssertEqual(launch.start, release)
        XCTAssertEqual(result.trajectory.points.first, release)
        XCTAssertEqual(angularDistance(launch.direction, intent.direction), 0, accuracy: 1e-12)
        let firstLeg = try XCTUnwrap(result.trajectory.segments.first)
        let firstSegmentDirection = CGVector(
            dx: firstLeg.end.x - firstLeg.start.x,
            dy: firstLeg.end.y - firstLeg.start.y
        )
        XCTAssertEqual(
            angularDistance(firstSegmentDirection, intent.direction),
            0,
            accuracy: 1e-12,
            "The first visible leg must be the committed release vector, not a similar random ray."
        )
        XCTAssertTrue(pointIsOnBoundary(firstLeg.end, of: bounds))
        let perimeter = PinballFlickLaunchPolicy.perimeter(of: bounds)
        XCTAssertEqual(launch.distance / perimeter, 1.775, accuracy: 0.350_001)
    }

    func testReleasePointIsClampedOnlyToCollisionBounds() throws {
        let bounds = PinballTestFixtures.portraitBounds
        let partition = try PinballRadialPartition(
            bounds: bounds,
            taps: PinballTestFixtures.radialTaps(count: 5, in: bounds)
        )
        let intent = try PinballFlickIntent(
            releasePoint: CGPoint(x: bounds.minX - 200, y: bounds.maxY + 300),
            direction: CGVector(dx: 1, dy: -1),
            speed: 900
        )
        var random = SplitMix64RandomSource(seed: 0xC1A0_0001)

        let result = try PinballRoundResolver.flickRound(
            partition: partition,
            intent: intent,
            using: &random
        )

        XCTAssertEqual(
            result.trajectory.points.first,
            CGPoint(
                x: bounds.minX + PinballFlickLaunchPolicy.releaseInteriorClearance,
                y: bounds.maxY - PinballFlickLaunchPolicy.releaseInteriorClearance
            )
        )
    }

    func testOutwardNearEdgeReleaseStillHasAVisibleFirstLegWhenInterventionIsNeeded() throws {
        let bounds = PinballTestFixtures.landscapeBounds
        let partition = try PinballRadialPartition(
            bounds: bounds,
            taps: PinballTestFixtures.radialTaps(count: 6, in: bounds)
        )
        let intent = try PinballFlickIntent(
            releasePoint: CGPoint(x: bounds.minX, y: bounds.midY),
            direction: CGVector(dx: -1, dy: 0.08),
            speed: 1_200
        )
        let naturalResult = try naturalFlickResult(partition: partition, intent: intent)
        let naturalWinnerIndex = try XCTUnwrap(
            partition.regions.firstIndex {
                $0.seat.seatID == naturalResult.winningSeatID
            }
        )
        let intervenedWinnerIndex = (naturalWinnerIndex + 1) % partition.regions.count
        var random = WinnerThenRandomSource(
            winnerIndex: intervenedWinnerIndex,
            upperBound: partition.regions.count,
            seed: 0xED6E_0001
        )

        let result = try PinballRoundResolver.flickRound(
            partition: partition,
            intent: intent,
            using: &random
        )
        let firstLeg = try XCTUnwrap(result.trajectory.segments.first)

        XCTAssertEqual(
            firstLeg.start.x,
            bounds.minX + PinballFlickLaunchPolicy.releaseInteriorClearance,
            accuracy: 1e-12
        )
        XCTAssertGreaterThan(firstLeg.length, 0)
        XCTAssertEqual(result.fairnessDeflectorVertexIndex, 1)
        XCTAssertEqual(
            angularDistance(
                CGVector(
                    dx: firstLeg.end.x - firstLeg.start.x,
                    dy: firstLeg.end.y - firstLeg.start.y
                ),
                intent.direction
            ),
            0,
            accuracy: 1e-7
        )
    }

    func testFixedUserFlickRemainsStatisticallyFairAcrossEqualAreas() throws {
        let bounds = PinballTestFixtures.landscapeBounds
        let seatCount = 10
        let partition = try PinballRadialPartition(
            bounds: bounds,
            taps: PinballTestFixtures.radialTaps(count: seatCount, in: bounds)
        )
        let intent = try PinballFlickIntent(
            releasePoint: CGPoint(x: bounds.minX + 160, y: bounds.minY + 140),
            direction: CGVector(dx: 0.93, dy: 0.17),
            speed: 1_130
        )
        var random = SplitMix64RandomSource(seed: 0xF11C_7E57)
        let sampleCount = 3_000
        var wins = [Int](repeating: 0, count: seatCount)
        var naturalRounds = 0

        for _ in 0..<sampleCount {
            let result = try PinballRoundResolver.flickRound(
                partition: partition,
                intent: intent,
                using: &random
            )
            wins[result.winningSeatID - 1] += 1
            if result.fairnessDeflectorVertexIndex == nil {
                naturalRounds += 1
            }
        }

        let expected = Double(sampleCount) / Double(seatCount)
        for (index, count) in wins.enumerated() {
            XCTAssertEqual(
                Double(count),
                expected,
                accuracy: expected * 0.15,
                "Seat \(index + 1) was biased by a fixed user flick"
            )
        }
        XCTAssertEqual(
            Double(naturalRounds),
            expected,
            accuracy: expected * 0.15,
            "The untouched natural path should be used exactly when the independent uniform winner agrees with it"
        )
    }

    func testFlickRoundWinnerIsTheActualAnalyticEndpointOwner() throws {
        let bounds = PinballTestFixtures.portraitBounds
        let partition = try PinballRadialPartition(
            bounds: bounds,
            taps: PinballTestFixtures.radialTaps(count: 8, in: bounds)
        )
        let intent = try PinballFlickIntent(
            releasePoint: CGPoint(x: bounds.minX + 80, y: bounds.maxY - 120),
            direction: CGVector(dx: -0.88, dy: 0.21),
            speed: 970
        )
        var random = SplitMix64RandomSource(seed: 0xE11D_9017)

        let result = try PinballRoundResolver.flickRound(
            partition: partition,
            intent: intent,
            using: &random
        )

        XCTAssertEqual(result.finalPoint, result.trajectory.endPoint)
        XCTAssertEqual(
            result.winningSeatID,
            try partition.seatID(containing: result.finalPoint)
        )

        XCTAssertEqual(result.trajectory.points.first, intent.releasePoint)
        XCTAssertEqual(
            angularDistance(result.trajectory.launch.direction, intent.direction),
            0,
            accuracy: 1e-12
        )
        assertEveryInternalVertexIsSpecular(
            result.trajectory,
            excludingVertex: result.fairnessDeflectorVertexIndex
        )
    }

    @MainActor
    func testNaturalEndpointUsesUntouchedSpecularTrajectoryWhenUniformWinnerMatches() throws {
        let bounds = PinballTestFixtures.landscapeBounds
        let partition = try PinballRadialPartition(
            bounds: bounds,
            taps: PinballTestFixtures.radialTaps(count: 7, in: bounds)
        )
        let intent = try PinballFlickIntent(
            releasePoint: CGPoint(x: bounds.minX + 97, y: bounds.minY + 143),
            direction: CGVector(dx: 0.67, dy: -0.42),
            speed: 1_180
        )
        let naturalResult = try naturalFlickResult(partition: partition, intent: intent)
        let naturalWinnerIndex = try XCTUnwrap(
            partition.regions.firstIndex {
                $0.seat.seatID == naturalResult.winningSeatID
            }
        )
        var random = WinnerThenRandomSource(
            winnerIndex: naturalWinnerIndex,
            upperBound: partition.regions.count,
            seed: 0xA11C_E001
        )

        let result = try PinballRoundResolver.flickRound(
            partition: partition,
            intent: intent,
            using: &random
        )

        XCTAssertEqual(result.trajectory, naturalResult.trajectory)
        XCTAssertEqual(result.winningSeatID, naturalResult.winningSeatID)
        XCTAssertNil(result.fairnessDeflectorVertexIndex)
        XCTAssertEqual(
            random.consumedCount,
            1,
            "An already-fair natural result needs only the single unbiased winner draw"
        )
        assertEveryInternalVertexIsSpecular(result.trajectory)

        let run = NativePinballRun(
            result: result,
            curve: try PinballMotionProfile(duration: 4)
        )
        XCTAssertFalse(
            ChooserAppModel.pinballCollisionFeedbackEvents(for: run)
                .contains(where: \.isFairnessDeflection),
            "Natural rounds must not route any special wall feedback"
        )
    }

    func testMismatchedUniformWinnerUsesOneFirstWallIntervention() throws {
        let bounds = PinballTestFixtures.landscapeBounds
        let partition = try PinballRadialPartition(
            bounds: bounds,
            taps: PinballTestFixtures.radialTaps(count: 12, in: bounds)
        )
        let release = CGPoint(x: bounds.midX - 50, y: bounds.midY + 80)
        let intent = try PinballFlickIntent(
            releasePoint: release,
            direction: CGVector(dx: 0.74, dy: -0.31),
            speed: 1_340
        )
        let naturalResult = try naturalFlickResult(partition: partition, intent: intent)
        let naturalWinnerIndex = try XCTUnwrap(
            partition.regions.firstIndex {
                $0.seat.seatID == naturalResult.winningSeatID
            }
        )
        let intervenedWinnerIndex = (naturalWinnerIndex + 1) % partition.regions.count
        var random = WinnerThenRandomSource(
            winnerIndex: intervenedWinnerIndex,
            upperBound: partition.regions.count,
            seed: 0x1A7E_25E0
        )

        let result = try PinballSpecularFlickResolver.resolve(
            partition: partition,
            intent: intent,
            using: &random,
            maximumSegments: 10_000,
            narrowAttempts: 0,
            wideAttempts: 0
        )

        XCTAssertEqual(
            result.winningSeatID,
            try partition.seatID(containing: result.finalPoint)
        )
        XCTAssertEqual(result.trajectory.points.first, release)
        XCTAssertEqual(
            result.winningSeatID,
            partition.regions[intervenedWinnerIndex].seat.seatID
        )
        let deflectorIndex = try XCTUnwrap(result.fairnessDeflectorVertexIndex)
        XCTAssertEqual(deflectorIndex, 1)
        XCTAssertTrue(pointIsOnBoundary(result.trajectory.points[deflectorIndex], of: bounds))
        assertEveryInternalVertexIsSpecular(
            result.trajectory,
            excludingVertex: deflectorIndex
        )
    }

    func testEveryPreselectedWinnerFromTwoThroughTwelveOwnsTheEndpoint() throws {
        let bounds = PinballTestFixtures.landscapeBounds
        for seatCount in 2...12 {
            let partition = try PinballRadialPartition(
                bounds: bounds,
                taps: PinballTestFixtures.radialTaps(count: seatCount, in: bounds)
            )
            let intent = try PinballFlickIntent(
                releasePoint: CGPoint(x: bounds.minX + 73, y: bounds.minY + 111),
                direction: CGVector(dx: 1, dy: 0.08),
                speed: 1_050
            )
            let naturalResult = try naturalFlickResult(partition: partition, intent: intent)

            for winnerIndex in partition.regions.indices {
                var random = WinnerThenRandomSource(
                    winnerIndex: winnerIndex,
                    upperBound: seatCount,
                    seed: UInt64(seatCount * 100 + winnerIndex)
                )
                let result = try PinballRoundResolver.flickRound(
                    partition: partition,
                    intent: intent,
                    using: &random
                )

                XCTAssertEqual(
                    result.winningSeatID,
                    partition.regions[winnerIndex].seat.seatID
                )
                XCTAssertEqual(
                    result.winningSeatID,
                    try partition.seatID(containing: result.finalPoint)
                )
                XCTAssertEqual(result.trajectory.points.first, intent.releasePoint)
                if result.winningSeatID == naturalResult.winningSeatID {
                    XCTAssertNil(result.fairnessDeflectorVertexIndex)
                    XCTAssertEqual(result.trajectory, naturalResult.trajectory)
                } else {
                    XCTAssertEqual(result.fairnessDeflectorVertexIndex, 1)
                }
            }
        }
    }

    func testUnbiasedIndexRejectsTheIncompleteModuloBucket() throws {
        var random = SequenceRandomSource(values: [0, 5, 16])

        XCTAssertEqual(try random.nextUnbiasedIndex(upperBound: 10), 6)
        XCTAssertEqual(random.consumedCount, 3)
        XCTAssertThrowsError(try random.nextUnbiasedIndex(upperBound: 0)) { error in
            XCTAssertEqual(error as? PinballMathError, .invalidRandomUpperBound(0))
        }
    }

    private func payload(
        end: CGPoint,
        velocity: CGVector,
        duration: TimeInterval
    ) -> NativePinballGesturePayload {
        NativePinballGesturePayload(
            start: .zero,
            end: end,
            velocity: velocity,
            duration: duration
        )
    }

    private func pointIsOnBoundary(_ point: CGPoint, of bounds: CGRect) -> Bool {
        let tolerance: CGFloat = 1e-8
        return abs(point.x - bounds.minX) <= tolerance ||
            abs(point.x - bounds.maxX) <= tolerance ||
            abs(point.y - bounds.minY) <= tolerance ||
            abs(point.y - bounds.maxY) <= tolerance
    }

    private func naturalFlickResult(
        partition: PinballRadialPartition,
        intent: PinballFlickIntent
    ) throws -> PinballRoundResult {
        let releasePoint = try PinballFlickLaunchPolicy.clampedReleasePoint(
            intent.releasePoint,
            to: partition.bounds
        )
        let direction = try PinballFlickLaunchPolicy.normalizedDirection(intent.direction)
        let launch = try PinballLaunch(
            start: releasePoint,
            direction: direction,
            distance: PinballFlickLaunchPolicy.travelDistance(
                forSpeed: intent.speed,
                in: partition.bounds
            )
        )
        return try PinballRoundResolver.resolve(
            launch: launch,
            partition: partition
        )
    }

    private func angularDistance(_ first: CGVector, _ second: CGVector) -> CGFloat {
        let firstMagnitude = hypot(first.dx, first.dy)
        let secondMagnitude = hypot(second.dx, second.dy)
        let dot = (first.dx * second.dx + first.dy * second.dy) /
            (firstMagnitude * secondMagnitude)
        return acos(min(1, max(-1, dot)))
    }

    private func assertEveryInternalVertexIsSpecular(
        _ trajectory: PinballTrajectory,
        excludingVertex excludedVertex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let points = trajectory.points
        guard points.count >= 3 else { return }
        let tolerance: CGFloat = 1e-7
        for index in 1..<(points.count - 1) {
            if index == excludedVertex { continue }
            let incomingLength = hypot(
                points[index].x - points[index - 1].x,
                points[index].y - points[index - 1].y
            )
            let outgoingLength = hypot(
                points[index + 1].x - points[index].x,
                points[index + 1].y - points[index].y
            )
            let incoming = CGVector(
                dx: (points[index].x - points[index - 1].x) / incomingLength,
                dy: (points[index].y - points[index - 1].y) / incomingLength
            )
            let outgoing = CGVector(
                dx: (points[index + 1].x - points[index].x) / outgoingLength,
                dy: (points[index + 1].y - points[index].y) / outgoingLength
            )
            let hitsVertical = abs(points[index].x - trajectory.bounds.minX) <= tolerance ||
                abs(points[index].x - trajectory.bounds.maxX) <= tolerance
            let hitsHorizontal = abs(points[index].y - trajectory.bounds.minY) <= tolerance ||
                abs(points[index].y - trajectory.bounds.maxY) <= tolerance
            XCTAssertTrue(hitsVertical || hitsHorizontal, file: file, line: line)
            XCTAssertEqual(
                outgoing.dx,
                hitsVertical ? -incoming.dx : incoming.dx,
                accuracy: 1e-8,
                file: file,
                line: line
            )
            XCTAssertEqual(
                outgoing.dy,
                hitsHorizontal ? -incoming.dy : incoming.dy,
                accuracy: 1e-8,
                file: file,
                line: line
            )
        }
    }
}

private struct SequenceRandomSource: PinballRandomSource {
    let values: [UInt64]
    private(set) var consumedCount = 0

    mutating func nextUInt64() -> UInt64 {
        defer { consumedCount += 1 }
        return values[min(consumedCount, values.count - 1)]
    }
}

private struct WinnerThenRandomSource: PinballRandomSource {
    private var firstValue: UInt64?
    private var tail: SplitMix64RandomSource
    private(set) var consumedCount = 0

    init(winnerIndex: Int, upperBound: Int, seed: UInt64) {
        let bound = UInt64(upperBound)
        let threshold = (0 &- bound) % bound
        let thresholdResidue = threshold % bound
        let desired = UInt64(winnerIndex)
        let offset = (desired &+ bound &- thresholdResidue) % bound
        firstValue = threshold &+ offset
        tail = SplitMix64RandomSource(seed: seed)
    }

    mutating func nextUInt64() -> UInt64 {
        consumedCount += 1
        if let firstValue {
            self.firstValue = nil
            return firstValue
        }
        return tail.nextUInt64()
    }
}
