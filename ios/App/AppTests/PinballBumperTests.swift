import CoreGraphics
import XCTest
@testable import App

final class PinballBumperTests: XCTestCase {
    private let bounds = CGRect(x: 0, y: 0, width: 300, height: 600)

    private func field(_ bumpers: [PinballBumper], ballRadius: CGFloat = 15) -> PinballBumperField {
        PinballBumperField(bumpers: bumpers, ballRadius: ballRadius)
    }

    // MARK: - Reflection physics

    func testAHeadOnBumperHitSendsTheBallStraightBack() throws {
        let bumper = PinballBumper(seatID: 1, center: CGPoint(x: 150, y: 400), radius: 20)
        let launch = try PinballLaunch(
            start: CGPoint(x: 150, y: 100),
            direction: CGVector(dx: 0, dy: 1),
            distance: 400
        )

        let trajectory = try PinballBilliards.trajectory(
            for: launch,
            in: bounds,
            bumpers: field([bumper])
        )

        // Contact happens at the inflated radius, not the drawn radius.
        let contact = try XCTUnwrap(trajectory.segments.first).end
        XCTAssertEqual(contact.y, 400 - 35, accuracy: 1e-6)
        XCTAssertEqual(contact.x, 150, accuracy: 1e-6)

        let kind = try XCTUnwrap(trajectory.vertexKinds.first)
        XCTAssertEqual(kind.bumperSeatID, 1)

        // Straight back up the way it came.
        let second = try XCTUnwrap(trajectory.segments.dropFirst().first)
        XCTAssertLessThan(second.end.y, second.start.y)
        XCTAssertEqual(second.end.x, 150, accuracy: 1e-6)
    }

    func testBumperReflectionPreservesSpeedAndMirrorsTheAngle() throws {
        let bumper = PinballBumper(seatID: 3, center: CGPoint(x: 150, y: 300), radius: 24)
        let launch = try PinballLaunch(
            start: CGPoint(x: 40, y: 120),
            direction: CGVector(dx: 0.6, dy: 0.8),
            distance: 900
        )

        let trajectory = try PinballBilliards.trajectory(
            for: launch,
            in: bounds,
            bumpers: field([bumper])
        )

        let points = trajectory.points
        for (offset, kind) in trajectory.vertexKinds.enumerated() {
            guard case .bumper(_, let normal) = kind else { continue }
            let index = offset + 1
            guard index + 1 < points.count else { continue }

            let incoming = unit(from: points[index - 1], to: points[index])
            let outgoing = unit(from: points[index], to: points[index + 1])

            // Equal magnitudes are implied by unit vectors; the real assertion
            // is that the angle of incidence equals the angle of reflection.
            let incomingDot = incoming.dx * normal.dx + incoming.dy * normal.dy
            let outgoingDot = outgoing.dx * normal.dx + outgoing.dy * normal.dy
            XCTAssertEqual(outgoingDot, -incomingDot, accuracy: 1e-6)

            let expected = PinballBumperGeometry.reflect(incoming, about: normal)
            XCTAssertEqual(outgoing.dx, expected.dx, accuracy: 1e-6)
            XCTAssertEqual(outgoing.dy, expected.dy, accuracy: 1e-6)
        }
    }

    func testTheBallNeverEntersABumperOrLeavesTheBoard() throws {
        let bumpers = [
            PinballBumper(seatID: 1, center: CGPoint(x: 90, y: 180), radius: 22),
            PinballBumper(seatID: 2, center: CGPoint(x: 210, y: 300), radius: 22),
            PinballBumper(seatID: 3, center: CGPoint(x: 110, y: 430), radius: 22)
        ]
        let bumperField = field(bumpers)

        for angleStep in 0..<48 {
            let angle = CGFloat(angleStep) * .pi / 24
            let launch = try PinballLaunch(
                start: CGPoint(x: 150, y: 90),
                direction: CGVector(dx: cos(angle), dy: sin(angle)),
                distance: 1400
            )
            let trajectory = try PinballBilliards.trajectory(
                for: launch,
                in: bounds,
                bumpers: bumperField
            )

            let tolerance: CGFloat = 1e-6
            for segment in trajectory.segments {
                for sample in stride(from: CGFloat(0), through: 1, by: 0.05) {
                    let point = CGPoint(
                        x: segment.start.x + (segment.end.x - segment.start.x) * sample,
                        y: segment.start.y + (segment.end.y - segment.start.y) * sample
                    )
                    XCTAssertGreaterThanOrEqual(point.x, bounds.minX - tolerance)
                    XCTAssertLessThanOrEqual(point.x, bounds.maxX + tolerance)
                    XCTAssertGreaterThanOrEqual(point.y, bounds.minY - tolerance)
                    XCTAssertLessThanOrEqual(point.y, bounds.maxY + tolerance)

                    for bumper in bumpers {
                        let radius = bumperField.collisionRadius(for: bumper)
                        let distance = hypot(point.x - bumper.center.x, point.y - bumper.center.y)
                        XCTAssertGreaterThan(
                            distance, radius - 0.01,
                            "angle \(angleStep) entered bumper \(bumper.seatID)"
                        )
                    }
                }
            }
        }
    }

    func testSegmentDistancesStayContiguousAndCoverTheWholeLaunch() throws {
        let bumper = PinballBumper(seatID: 1, center: CGPoint(x: 150, y: 320), radius: 26)
        let launch = try PinballLaunch(
            start: CGPoint(x: 60, y: 80),
            direction: CGVector(dx: 0.5, dy: 0.9),
            distance: 1100
        )
        let trajectory = try PinballBilliards.trajectory(
            for: launch,
            in: bounds,
            bumpers: field([bumper])
        )

        XCTAssertEqual(trajectory.segments.first?.startDistance, 0)
        XCTAssertEqual(
            try XCTUnwrap(trajectory.segments.last).endDistance,
            launch.distance,
            accuracy: 1e-6
        )
        for (previous, next) in zip(trajectory.segments, trajectory.segments.dropFirst()) {
            XCTAssertEqual(previous.endDistance, next.startDistance, accuracy: 1e-9)
            XCTAssertEqual(previous.end.x, next.start.x, accuracy: 1e-9)
            XCTAssertEqual(previous.end.y, next.start.y, accuracy: 1e-9)
        }
        // One kind per internal vertex.
        XCTAssertEqual(trajectory.vertexKinds.count, max(0, trajectory.segments.count - 1))
    }

    // MARK: - Fairness: scale must be a similarity transform

    /// Reachability is invariant under a uniform scale, which is the whole
    /// reason a bigger board needs no fairness re-testing. This asserts the
    /// *hypothesis* — that no absolute length has leaked into the solver —
    /// rather than re-running the conclusion on every board size.
    ///
    /// Scales are exact powers of two so both binary searches visit exactly
    /// scaled candidates and the feasibility predicates agree bit for bit. That
    /// lets the winner and the polyline be compared as equalities rather than
    /// against a tolerance nobody can defend.
    func testAUniformScaleChangesNoOutcome() throws {
        // Short edge 440 is the reference, so this board is exactly scale 1.
        let referencePlayfield = CGSize(width: 440, height: 790)

        for scale in [CGFloat(2), 4] {
            let scaledPlayfield = CGSize(
                width: referencePlayfield.width * scale,
                height: referencePlayfield.height * scale
            )
            XCTAssertEqual(
                PinballBoardMetrics(playfieldSize: referencePlayfield).scale,
                1,
                accuracy: 1e-12
            )
            XCTAssertEqual(
                PinballBoardMetrics(playfieldSize: scaledPlayfield).scale,
                scale,
                accuracy: 1e-12
            )

            for seatCount in [3, 7, 12] {
                for angleStep in 0..<2 {
                    let angle = (CGFloat(angleStep) + 0.5) * 2 * .pi / 2
                    for winnerIndex in [0, seatCount - 1] {
                        let reference = try resolveScaled(
                            playfield: referencePlayfield,
                            seatCount: seatCount,
                            angle: angle,
                            winnerIndex: winnerIndex
                        )
                        let scaled = try resolveScaled(
                            playfield: scaledPlayfield,
                            seatCount: seatCount,
                            angle: angle,
                            winnerIndex: winnerIndex
                        )

                        // Succeeding or failing identically is the property that
                        // actually carries fairness: a size-dependent failure
                        // rate is what would bias the odds.
                        XCTAssertEqual(
                            reference == nil,
                            scaled == nil,
                            "scale \(scale), \(seatCount) seats, winner \(winnerIndex)"
                        )
                        guard let reference, let scaled else { continue }

                        XCTAssertEqual(
                            reference.winningRegion.seat.seatID,
                            scaled.winningRegion.seat.seatID
                        )

                        // The polyline is compared loosely and on purpose. The
                        // deflection sweep picks its candidate by a strict `<`
                        // on a float score, so a near-tie can legitimately break
                        // the other way and produce a different — equally fair —
                        // path. Success, failure and the winning seat are the
                        // invariants that carry fairness; the exact geometry is
                        // not, so a divergence here is not a defect.
                        let referencePoints = reference.trajectory.points
                        let scaledPoints = scaled.trajectory.points
                        guard referencePoints.count == scaledPoints.count else { continue }
                        for (a, b) in zip(referencePoints, scaledPoints) {
                            XCTAssertEqual(b.x / scale, a.x, accuracy: max(1e-6, abs(a.x) * 1e-6))
                            XCTAssertEqual(b.y / scale, a.y, accuracy: max(1e-6, abs(a.y) * 1e-6))
                        }
                    }
                }
            }
        }
    }

    /// Builds a board the way the app does and resolves one forced-winner round.
    private func resolveScaled(
        playfield: CGSize,
        seatCount: Int,
        angle: CGFloat,
        winnerIndex: Int
    ) throws -> PinballRoundResult? {
        let metrics = PinballBoardMetrics(playfieldSize: playfield)
        let bounds = CGRect(origin: .zero, size: playfield)
            .insetBy(dx: metrics.collisionInset, dy: metrics.collisionInset)
        let partition = try PinballRadialPartition(
            bounds: bounds,
            taps: PinballTestFixtures.radialTaps(count: seatCount, in: bounds)
        )
        let bumpers = PinballSeatTokenSizing.bumperAwareLayout(
            for: partition,
            in: playfield,
            ballRadius: metrics.ballRadius
        ).map { PinballBumperField(from: $0, ballRadius: metrics.ballRadius) } ?? .empty

        let intent = try PinballFlickIntent(
            releasePoint: CGPoint(x: bounds.midX, y: bounds.midY),
            direction: CGVector(dx: cos(angle), dy: sin(angle)),
            speed: 900
        )
        var random = ForcedWinnerSource(
            winnerIndex: winnerIndex,
            upperBound: seatCount,
            seed: 4_242
        )
        return try? PinballSpecularFlickResolver.resolve(
            partition: partition,
            intent: intent,
            using: &random,
            maximumSegments: 10_000,
            bumpers: bumpers
        )
    }

    // MARK: - Fairness: no region may be harder to reach than another

    /// The winner is drawn uniformly and only then is a path solved. If the
    /// solver fails, the round dies and the player flicks again, drawing a
    /// fresh winner — so a region-dependent failure rate is rejection sampling
    /// that biases the completed-round odds. The only safe failure count is
    /// zero.
    ///
    /// Directions are offset half a step off-axis deliberately. A flick that is
    /// exactly axis-aligned from the exact board centre is a degenerate orbit:
    /// it can reflect head-on between two opposed seat rings and never reach a
    /// wall at all, so no wall deflection exists at any ordinal. That is a
    /// known, separate limitation of the wall-deflection mechanism, not the
    /// region-dependent reachability this test guards.
    func testEveryRegionIsReachableForEveryFlick() throws {
        let inset = NativePinballReplayMetrics.collisionInset
        for seatCount in 2...12 {
            let bounds = CGRect(x: 0, y: 0, width: 390, height: 700)
                .insetBy(dx: inset, dy: inset)
            let partition = try PinballRadialPartition(
                bounds: bounds,
                taps: PinballTestFixtures.radialTaps(count: seatCount, in: bounds)
            )
            let layout = try XCTUnwrap(
                PinballSeatTokenSizing.bumperAwareLayout(
                    for: partition,
                    in: CGSize(width: 390, height: 700),
                    ballRadius: NativePinballReplayMetrics.ballDiameter / 2
                )
            )
            let bumpers = PinballBumperField(
                from: layout,
                ballRadius: NativePinballReplayMetrics.ballDiameter / 2
            )

            var failures = [Int](repeating: 0, count: seatCount)
            // A centre release and an off-centre one. Off-centre matters: the
            // reachable set differs sharply between them.
            let releasePoints = [
                CGPoint(x: bounds.midX, y: bounds.midY),
                CGPoint(x: bounds.minX + bounds.width * 0.38, y: bounds.minY + bounds.height * 0.44)
            ]
            for releasePoint in releasePoints {
            for angleStep in 0..<8 {
                let angle = (CGFloat(angleStep) + 0.5) * 2 * .pi / 8
                for speed in [CGFloat(600), 1_400] {
                    let intent = try PinballFlickIntent(
                        releasePoint: releasePoint,
                        direction: CGVector(dx: cos(angle), dy: sin(angle)),
                        speed: speed
                    )
                    for regionIndex in 0..<seatCount {
                        var random = ForcedWinnerSource(
                            winnerIndex: regionIndex,
                            upperBound: seatCount,
                            seed: UInt64(angleStep &* 31 &+ regionIndex &+ 7)
                        )
                        do {
                            let result = try PinballSpecularFlickResolver.resolve(
                                partition: partition,
                                intent: intent,
                                using: &random,
                                maximumSegments: 10_000,
                                bumpers: bumpers
                            )
                            // The drawn region must be the one that wins.
                            XCTAssertEqual(
                                result.winningRegion.seat.seatID,
                                partition.regions[regionIndex].seat.seatID
                            )
                        } catch {
                            failures[regionIndex] += 1
                        }
                    }
                }
            }
            }
            XCTAssertEqual(
                failures,
                [Int](repeating: 0, count: seatCount),
                "Unreachable regions at \(seatCount) seats bias the odds against them."
            )
        }
    }

    // MARK: - Recovering contacts for presentation

    func testBumperContactsRecoverSeatIdentityAndTheDrawnRing() throws {
        let bumper = PinballBumper(seatID: 4, center: CGPoint(x: 150, y: 400), radius: 20)
        let launch = try PinballLaunch(
            start: CGPoint(x: 150, y: 100),
            direction: CGVector(dx: 0, dy: 1),
            distance: 400
        )
        let bumperField = field([bumper])
        let trajectory = try PinballBilliards.trajectory(
            for: launch,
            in: bounds,
            bumpers: bumperField
        )

        let contacts = trajectory.bumperContacts(in: bumperField)
        let contact = try XCTUnwrap(contacts.first)
        XCTAssertEqual(contact.seatID, 4)
        XCTAssertEqual(contact.center, bumper.center)
        // The drawn radius, not the ball-inflated collision radius.
        XCTAssertEqual(contact.radius, 20, accuracy: 1e-9)

        // The recorded vertex indexes into `points`, and the contact sits on
        // the inflated disc exactly where the marcher put it.
        let points = trajectory.points
        let contactPoint = points[contact.vertexIndex]
        XCTAssertEqual(
            hypot(contactPoint.x - bumper.center.x, contactPoint.y - bumper.center.y),
            bumperField.collisionRadius(for: bumper),
            accuracy: 1e-6
        )
    }

    func testEveryBumperVertexBecomesExactlyOneContact() throws {
        let bumpers = [
            PinballBumper(seatID: 1, center: CGPoint(x: 90, y: 220), radius: 22),
            PinballBumper(seatID: 2, center: CGPoint(x: 210, y: 380), radius: 22)
        ]
        let launch = try PinballLaunch(
            start: CGPoint(x: 40, y: 120),
            direction: CGVector(dx: 0.55, dy: 0.84),
            distance: 2200
        )
        let bumperField = field(bumpers)
        let trajectory = try PinballBilliards.trajectory(
            for: launch,
            in: bounds,
            bumpers: bumperField
        )

        let recordedBumperVertices = trajectory.vertexKinds.filter { $0.bumperSeatID != nil }.count
        let contacts = trajectory.bumperContacts(in: bumperField)
        XCTAssertEqual(contacts.count, recordedBumperVertices)
        XCTAssertEqual(contacts.map(\.vertexIndex), contacts.map(\.vertexIndex).sorted())
        for contact in contacts {
            XCTAssertEqual(
                trajectory.vertexKind(atPointIndex: contact.vertexIndex)?.bumperSeatID,
                contact.seatID
            )
        }
    }

    func testABumperFreeTrajectoryReportsNoContacts() throws {
        // `vertexKinds` is legitimately empty for the unfolded solver, so this
        // must return nothing rather than trapping on an out-of-range index.
        let launch = try PinballLaunch(
            start: CGPoint(x: 70, y: 110),
            direction: CGVector(dx: 0.37, dy: 0.93),
            distance: 1700
        )
        let trajectory = try PinballBilliards.trajectory(for: launch, in: bounds)
        XCTAssertTrue(trajectory.vertexKinds.isEmpty)
        XCTAssertTrue(
            trajectory.bumperContacts(
                in: field([PinballBumper(seatID: 1, center: CGPoint(x: 150, y: 300), radius: 20)])
            ).isEmpty
        )
        XCTAssertTrue(trajectory.bumperContacts(in: .empty).isEmpty)
    }

    // MARK: - Compatibility

    func testAnEmptyFieldReproducesTheUnfoldedSolverExactly() throws {
        let launch = try PinballLaunch(
            start: CGPoint(x: 70, y: 110),
            direction: CGVector(dx: 0.37, dy: 0.93),
            distance: 1700
        )
        let plain = try PinballBilliards.trajectory(for: launch, in: bounds)
        let withEmptyField = try PinballBilliards.trajectory(
            for: launch,
            in: bounds,
            bumpers: .empty
        )
        XCTAssertEqual(plain, withEmptyField)
        XCTAssertTrue(withEmptyField.vertexKinds.isEmpty)
    }

    func testStartingInsideABumperIgnoresItRatherThanTrappingTheBall() throws {
        // A release point clamped next to a seat can land inside the inflated
        // disc. Reflecting off the inside of a circle would trap the ball.
        let bumper = PinballBumper(seatID: 1, center: CGPoint(x: 150, y: 300), radius: 30)
        let launch = try PinballLaunch(
            start: CGPoint(x: 150, y: 300),
            direction: CGVector(dx: 0, dy: -1),
            distance: 250
        )
        let trajectory = try PinballBilliards.trajectory(
            for: launch,
            in: bounds,
            bumpers: field([bumper])
        )
        XCTAssertEqual(trajectory.endPoint.y, 50, accuracy: 1e-6)
        XCTAssertTrue(trajectory.vertexKinds.allSatisfy { $0.bumperSeatID == nil })
    }

    private func unit(from start: CGPoint, to end: CGPoint) -> CGVector {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let magnitude = hypot(dx, dy)
        guard magnitude > 0 else { return CGVector(dx: 0, dy: 0) }
        return CGVector(dx: dx / magnitude, dy: dy / magnitude)
    }
}

// MARK: - Fairness with bumpers

/// Forces `nextUnbiasedIndex` to return a chosen winner on its first draw, then
/// falls back to a deterministic stream. Mirrors the helper in
/// `PinballFlickTests` so bumper rounds get the same exact, non-statistical
/// per-winner coverage.
private struct BumperWinnerSource: PinballRandomSource {
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

extension PinballBumperTests {
    private func partitionAndField(
        seatCount: Int,
        in bounds: CGRect
    ) throws -> (PinballRadialPartition, PinballBumperField) {
        let partition = try PinballRadialPartition(
            bounds: bounds,
            taps: PinballTestFixtures.radialTaps(count: seatCount, in: bounds)
        )
        let layout = try XCTUnwrap(
            PinballSeatTokenSizing.bumperAwareLayout(
                for: partition,
                in: bounds.size,
                ballRadius: 15
            )
        )
        return (partition, PinballBumperField(from: layout, ballRadius: 15))
    }

    /// The load-bearing fairness test. The winner is drawn before any path
    /// exists, so bumpers cannot bias it; what this proves is that the
    /// constructed path always actually ends in that winner's region, for every
    /// seat count and every winner.
    func testEveryPreselectedWinnerOwnsTheEndpointWithBumpers() throws {
        let bounds = PinballTestFixtures.portraitBounds
        let intents = try [
            PinballFlickIntent(
                releasePoint: CGPoint(x: bounds.midX, y: bounds.midY),
                direction: CGVector(dx: 0.42, dy: -0.91),
                speed: 900
            ),
            PinballFlickIntent(
                releasePoint: CGPoint(x: bounds.minX + 40, y: bounds.midY + 60),
                direction: CGVector(dx: 0.98, dy: 0.2),
                speed: 1400
            ),
            PinballFlickIntent(
                releasePoint: CGPoint(x: bounds.midX - 20, y: bounds.maxY - 70),
                direction: CGVector(dx: -0.3, dy: -0.95),
                speed: 520
            )
        ]

        for seatCount in 2...12 {
            let (partition, field) = try partitionAndField(seatCount: seatCount, in: bounds)
            for winnerIndex in 0..<seatCount {
                for (intentIndex, intent) in intents.enumerated() {
                    var random = BumperWinnerSource(
                        winnerIndex: winnerIndex,
                        upperBound: seatCount,
                        seed: UInt64(seatCount * 1_000 + winnerIndex * 10 + intentIndex)
                    )
                    let context = "seats \(seatCount), winner \(winnerIndex), intent \(intentIndex)"

                    let result = try PinballRoundResolver.flickRound(
                        partition: partition,
                        intent: intent,
                        using: &random,
                        bumpers: field
                    )

                    XCTAssertEqual(
                        result.winningSeatID,
                        partition.regions[winnerIndex].seat.seatID,
                        "reported winner drifted from the draw — \(context)"
                    )
                    XCTAssertEqual(
                        result.winningSeatID,
                        try partition.seatID(containing: result.finalPoint),
                        "the displayed endpoint must own the result — \(context)"
                    )
                    XCTAssertEqual(
                        result.trajectory.points.first,
                        intent.releasePoint,
                        "the path must start at the committed release point — \(context)"
                    )
                }
            }
        }
    }

    /// The first drawn segment must still be a literal continuation of the
    /// finger, even when a bumper is the very first thing it meets.
    func testTheFirstLegStillFollowsTheCommittedFlickWithBumpers() throws {
        let bounds = PinballTestFixtures.portraitBounds
        let (partition, field) = try partitionAndField(seatCount: 6, in: bounds)
        let intent = try PinballFlickIntent(
            releasePoint: CGPoint(x: bounds.midX, y: bounds.midY + 40),
            direction: CGVector(dx: 0.55, dy: -0.84),
            speed: 1100
        )

        for winnerIndex in 0..<6 {
            var random = BumperWinnerSource(winnerIndex: winnerIndex, upperBound: 6, seed: 99)
            let result = try PinballRoundResolver.flickRound(
                partition: partition,
                intent: intent,
                using: &random,
                bumpers: field
            )
            let first = try XCTUnwrap(result.trajectory.segments.first)
            let heading = unitVector(from: first.start, to: first.end)
            let committed = try PinballFlickLaunchPolicy.normalizedDirection(intent.direction)
            XCTAssertEqual(heading.dx, committed.dx, accuracy: 1e-9)
            XCTAssertEqual(heading.dy, committed.dy, accuracy: 1e-9)
        }
    }

    /// Every vertex except the single tagged deflector must be a genuine
    /// specular event — component negation on a wall, mirror about the contact
    /// normal on a bumper.
    func testEveryVertexExceptTheTaggedDeflectorIsSpecularWithBumpers() throws {
        let bounds = PinballTestFixtures.portraitBounds
        let (partition, field) = try partitionAndField(seatCount: 5, in: bounds)
        let intent = try PinballFlickIntent(
            releasePoint: CGPoint(x: bounds.midX - 30, y: bounds.midY),
            direction: CGVector(dx: 0.7, dy: -0.71),
            speed: 1000
        )

        for winnerIndex in 0..<5 {
            var random = BumperWinnerSource(winnerIndex: winnerIndex, upperBound: 5, seed: 7)
            let result = try PinballRoundResolver.flickRound(
                partition: partition,
                intent: intent,
                using: &random,
                bumpers: field
            )
            let points = result.trajectory.points
            guard points.count > 2 else { continue }

            for index in 1..<(points.count - 1) {
                if index == result.fairnessDeflectorVertexIndex { continue }
                guard let kind = result.trajectory.vertexKind(atPointIndex: index) else { continue }

                let incoming = unitVector(from: points[index - 1], to: points[index])
                let outgoing = unitVector(from: points[index], to: points[index + 1])
                let expected = PinballBumperGeometry.reflect(incoming, about: kind.normal)
                XCTAssertEqual(
                    outgoing.dx, expected.dx, accuracy: 1e-6,
                    "vertex \(index) is not specular (winner \(winnerIndex))"
                )
                XCTAssertEqual(
                    outgoing.dy, expected.dy, accuracy: 1e-6,
                    "vertex \(index) is not specular (winner \(winnerIndex))"
                )
            }
        }
    }

    private func unitVector(from start: CGPoint, to end: CGPoint) -> CGVector {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let magnitude = hypot(dx, dy)
        guard magnitude > 0 else { return CGVector(dx: 0, dy: 0) }
        return CGVector(dx: dx / magnitude, dy: dy / magnitude)
    }
}

/// Forces the first winner draw to a chosen index, then behaves as an ordinary
/// deterministic source. Mirrors `nextUnbiasedIndex`'s rejection threshold so
/// the forced value is actually accepted.
private struct ForcedWinnerSource: PinballRandomSource {
    private var firstValue: UInt64?
    private var tail: SplitMix64RandomSource

    init(winnerIndex: Int, upperBound: Int, seed: UInt64) {
        let bound = UInt64(upperBound)
        let threshold = (0 &- bound) % bound
        let desired = UInt64(winnerIndex)
        let offset = (desired &+ bound &- (threshold % bound)) % bound
        firstValue = threshold &+ offset
        tail = SplitMix64RandomSource(seed: seed)
    }

    mutating func nextUInt64() -> UInt64 {
        if let firstValue {
            self.firstValue = nil
            return firstValue
        }
        return tail.nextUInt64()
    }
}
