import CoreGraphics
import XCTest
@testable import App

final class PinballGeometryTests: XCTestCase {
    func testEqualAreaPartitionsForSupportedRepresentativeSeatCountsAndOrientations() throws {
        for bounds in [PinballTestFixtures.portraitBounds, PinballTestFixtures.landscapeBounds] {
            for count in [2, 4, 10, 12] {
                let taps = PinballTestFixtures.radialTaps(count: count, in: bounds)
                let partition = try PinballRadialPartition(bounds: bounds, taps: taps)
                let expectedArea = bounds.width * bounds.height / CGFloat(count)

                XCTAssertEqual(partition.regions.count, count)
                XCTAssertEqual(
                    partition.regions.reduce(0) { $0 + $1.area },
                    bounds.width * bounds.height,
                    accuracy: 0.000_001 * bounds.width * bounds.height
                )
                for region in partition.regions {
                    XCTAssertEqual(region.area, expectedArea, accuracy: expectedArea * 1e-12)
                }
                PinballTestFixtures.assertCyclicOrder(
                    partition.clockwiseSeatIDs,
                    matches: Array(1...count)
                )
            }
        }
    }

    func testTopAndBottomSeatsProduceHorizontalFiftyFiftySplit() throws {
        let bounds = PinballTestFixtures.portraitBounds
        let taps = [
            PinballSeatTap(seatID: 1, point: CGPoint(x: bounds.midX, y: bounds.minY + 20)),
            PinballSeatTap(seatID: 2, point: CGPoint(x: bounds.midX, y: bounds.maxY - 20))
        ]
        let partition = try PinballRadialPartition(bounds: bounds, taps: taps)

        for region in partition.regions {
            XCTAssertEqual(region.area, bounds.width * bounds.height / 2, accuracy: 1e-8)
            XCTAssertEqual(region.startBoundaryPoint.y, bounds.midY, accuracy: 1e-8)
            XCTAssertEqual(region.endBoundaryPoint.y, bounds.midY, accuracy: 1e-8)
        }
        XCTAssertEqual(
            try partition.seatID(containing: CGPoint(x: bounds.midX, y: bounds.minY + 1)),
            1
        )
        XCTAssertEqual(
            try partition.seatID(containing: CGPoint(x: bounds.midX, y: bounds.maxY - 1)),
            2
        )
    }

    func testGridCoverageCloselyMatchesExactTenWayArea() throws {
        let bounds = PinballTestFixtures.portraitBounds
        let count = 10
        let partition = try PinballRadialPartition(
            bounds: bounds,
            taps: PinballTestFixtures.radialTaps(count: count, in: bounds)
        )
        let columns = 180
        let rows = 300
        var ownership = Dictionary(uniqueKeysWithValues: (1...count).map { ($0, 0) })

        for row in 0..<rows {
            for column in 0..<columns {
                let point = CGPoint(
                    x: bounds.minX + (CGFloat(column) + 0.5) * bounds.width / CGFloat(columns),
                    y: bounds.minY + (CGFloat(row) + 0.5) * bounds.height / CGFloat(rows)
                )
                ownership[try partition.seatID(containing: point), default: 0] += 1
            }
        }

        let expected = Double(columns * rows) / Double(count)
        for seatID in 1...count {
            let observed = Double(try XCTUnwrap(ownership[seatID]))
            XCTAssertEqual(observed, expected, accuracy: expected * 0.025)
        }
    }

    func testRegionCentersAndTokenAnchorsStayStableAndClearInBothOrientations() throws {
        for bounds in [PinballTestFixtures.portraitBounds, PinballTestFixtures.landscapeBounds] {
            for count in [2, 4, 10, 12] {
                let partition = try PinballRadialPartition(
                    bounds: bounds,
                    taps: PinballTestFixtures.radialTaps(count: count, in: bounds)
                )
                let tokenDiameter: CGFloat = 32
                let edgePadding: CGFloat = 6
                let dividerPadding: CGFloat = 4
                let seatCount = CGFloat(count)

                for region in partition.regions {
                    let centerOffset = normalizedPhase(region.centerPhase - region.startPhase)
                    XCTAssertEqual(centerOffset, 0.5 / seatCount, accuracy: 1e-12)

                    let anchor = try XCTUnwrap(
                        partition.tokenAnchor(
                            forSeatID: region.seat.seatID,
                            tokenDiameter: tokenDiameter,
                            edgePadding: edgePadding,
                            dividerPadding: dividerPadding
                        )
                    )
                    XCTAssertEqual(
                        anchor,
                        partition.tokenAnchor(
                            forSeatID: region.seat.seatID,
                            tokenDiameter: tokenDiameter,
                            edgePadding: edgePadding,
                            dividerPadding: dividerPadding
                        )
                    )
                    XCTAssertEqual(
                        try partition.seatID(containing: anchor),
                        region.seat.seatID
                    )

                    let requiredEdgeInset = tokenDiameter / 2 + edgePadding
                    XCTAssertGreaterThanOrEqual(anchor.x, bounds.minX + requiredEdgeInset - 1e-9)
                    XCTAssertLessThanOrEqual(anchor.x, bounds.maxX - requiredEdgeInset + 1e-9)
                    XCTAssertGreaterThanOrEqual(anchor.y, bounds.minY + requiredEdgeInset - 1e-9)
                    XCTAssertLessThanOrEqual(anchor.y, bounds.maxY - requiredEdgeInset + 1e-9)

                    let requiredDividerClearance = tokenDiameter / 2 + dividerPadding
                    XCTAssertGreaterThanOrEqual(
                        distance(anchor, fromRay: partition.center, through: region.startBoundaryPoint),
                        requiredDividerClearance - 1e-7
                    )
                    XCTAssertGreaterThanOrEqual(
                        distance(anchor, fromRay: partition.center, through: region.endBoundaryPoint),
                        requiredDividerClearance - 1e-7
                    )
                }
            }
        }
    }

    func testProductionSeatTokenLayoutKeepsEveryRenderedChitClearForAllCountsAndStages() throws {
        let stageSizes = [
            CGSize(width: 393, height: 676),
            CGSize(width: 430, height: 748),
            CGSize(width: 874, height: 246),
            CGSize(width: 667, height: 219),
        ]
        let policy = PinballSeatTokenLayoutPolicy.production

        XCTAssertEqual(
            policy.maximumRenderedScale,
            BoardPieceVisualMetrics.maximumScale(for: .winner),
            accuracy: 1e-12
        )

        for stageSize in stageSizes {
            let stageBounds = CGRect(origin: .zero, size: stageSize)
            let collisionBounds = stageBounds.insetBy(
                dx: NativePinballReplayMetrics.collisionInset,
                dy: NativePinballReplayMetrics.collisionInset
            )
            for count in 2...12 {
                let partition = try PinballRadialPartition(
                    bounds: collisionBounds,
                    taps: productionPinballTaps(
                        count: count,
                        stageBounds: stageBounds,
                        collisionBounds: collisionBounds
                    )
                )
                let preferredDiameter = PinballSeatTokenSizing.preferredDiameter(
                    in: stageSize,
                    seatCount: count
                )
                let layout = try XCTUnwrap(
                    PinballSeatTokenSizing.layout(
                        for: partition,
                        in: stageSize,
                        policy: policy
                    ),
                    "Missing production layout for \(count) seats at \(stageSize)"
                )

                XCTAssertEqual(layout.placements.count, count)
                XCTAssertGreaterThanOrEqual(
                    layout.tokenDiameter,
                    36,
                    "Unreadable production chit for \(count) seats at \(stageSize)"
                )
                XCTAssertLessThanOrEqual(layout.tokenDiameter, preferredDiameter + 1e-8)
                if count == 12, stageSize.height < 250 {
                    let expectedDiameter: CGFloat = stageSize.width > 800
                        ? 48.673_505
                        : 40.078_742
                    XCTAssertEqual(
                        layout.tokenDiameter,
                        expectedDiameter,
                        accuracy: 0.001,
                        "Unexpected 12-seat production fit at \(stageSize)"
                    )
                }
                XCTAssertEqual(
                    Set(layout.placements.map(\.seatID)),
                    Set(1...count)
                )

                let scaledFaceRadius = layout.tokenDiameter / 2
                    * layout.maximumRenderedScale
                let completeWinnerRadius = BoardPieceVisualMetrics.footprintRadius(
                    diameter: layout.tokenDiameter,
                    emphasis: .winner
                )
                for region in partition.regions {
                    let finalCenter = try XCTUnwrap(
                        layout.center(forSeatID: region.seat.seatID)
                    )
                    XCTAssertEqual(
                        try partition.seatID(containing: finalCenter),
                        region.seat.seatID
                    )

                    XCTAssertGreaterThanOrEqual(
                        finalCenter.x - scaledFaceRadius,
                        collisionBounds.minX + policy.edgeClearance - 1e-6
                    )
                    XCTAssertLessThanOrEqual(
                        finalCenter.x + scaledFaceRadius,
                        collisionBounds.maxX - policy.edgeClearance + 1e-6
                    )
                    XCTAssertGreaterThanOrEqual(
                        finalCenter.y - scaledFaceRadius,
                        collisionBounds.minY + policy.edgeClearance - 1e-6
                    )
                    XCTAssertLessThanOrEqual(
                        finalCenter.y + scaledFaceRadius,
                        collisionBounds.maxY - policy.edgeClearance + 1e-6
                    )

                    XCTAssertGreaterThanOrEqual(
                        distance(
                            finalCenter,
                            fromRay: partition.center,
                            through: region.startBoundaryPoint
                        ) - scaledFaceRadius,
                        policy.dividerClearance - 1e-6
                    )
                    XCTAssertGreaterThanOrEqual(
                        distance(
                            finalCenter,
                            fromRay: partition.center,
                            through: region.endBoundaryPoint
                        ) - scaledFaceRadius,
                        policy.dividerClearance - 1e-6
                    )

                    // The collision partition's 18pt inset also leaves enough
                    // room for the complete scaled winner shadow at the actual
                    // clipped SwiftUI stage edge.
                    XCTAssertGreaterThanOrEqual(
                        finalCenter.x - completeWinnerRadius,
                        stageBounds.minX - 1e-6
                    )
                    XCTAssertLessThanOrEqual(
                        finalCenter.x + completeWinnerRadius,
                        stageBounds.maxX + 1e-6
                    )
                    XCTAssertGreaterThanOrEqual(
                        finalCenter.y - completeWinnerRadius,
                        stageBounds.minY - 1e-6
                    )
                    XCTAssertLessThanOrEqual(
                        finalCenter.y + completeWinnerRadius,
                        stageBounds.maxY + 1e-6
                    )
                }
            }
        }
    }

    func testProductionSeatTokenLayoutIsDeterministicAndUsesOneDiameter() throws {
        let stageSize = CGSize(width: 874, height: 246)
        let collisionBounds = CGRect(origin: .zero, size: stageSize).insetBy(
            dx: NativePinballReplayMetrics.collisionInset,
            dy: NativePinballReplayMetrics.collisionInset
        )
        let partition = try PinballRadialPartition(
            bounds: collisionBounds,
            taps: productionPinballTaps(
                count: 12,
                stageBounds: CGRect(origin: .zero, size: stageSize),
                collisionBounds: collisionBounds
            )
        )

        let first = try XCTUnwrap(
            PinballSeatTokenSizing.layout(for: partition, in: stageSize)
        )
        let second = try XCTUnwrap(
            PinballSeatTokenSizing.layout(for: partition, in: stageSize)
        )

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.placements.count, 12)
        XCTAssertGreaterThanOrEqual(first.tokenDiameter, 36)
    }

    func testHorizontalReflectionsProduceExactSegmentsAndEndpoint() throws {
        let bounds = CGRect(x: 0, y: 0, width: 10, height: 10)
        let launch = try PinballLaunch(
            start: CGPoint(x: 2, y: 3),
            direction: CGVector(dx: 7, dy: 0),
            distance: 22
        )
        let trajectory = try PinballBilliards.trajectory(for: launch, in: bounds)

        XCTAssertEqual(trajectory.segments.count, 3)
        XCTAssertEqual(trajectory.points[0].x, 2, accuracy: 1e-10)
        XCTAssertEqual(trajectory.points[1].x, 10, accuracy: 1e-10)
        XCTAssertEqual(trajectory.points[2].x, 0, accuracy: 1e-10)
        XCTAssertEqual(trajectory.endPoint.x, 4, accuracy: 1e-10)
        XCTAssertEqual(trajectory.endPoint.y, 3, accuracy: 1e-10)
        XCTAssertEqual(trajectory.segments.reduce(0) { $0 + $1.length }, 22, accuracy: 1e-10)
    }

    func testTwoAxisTrajectoryIsContinuousAndAlwaysInsideBounds() throws {
        let bounds = CGRect(x: -20, y: 30, width: 275, height: 143)
        let launch = try PinballLaunch(
            start: CGPoint(x: 11, y: 79),
            direction: CGVector(dx: -0.73, dy: 0.41),
            distance: 2_500
        )
        let trajectory = try PinballBilliards.trajectory(for: launch, in: bounds)

        XCTAssertEqual(trajectory.segments.first?.start, launch.start)
        XCTAssertEqual(trajectory.segments.last?.end, trajectory.endPoint)
        for index in trajectory.segments.indices {
            let segment = trajectory.segments[index]
            XCTAssertTrue(containsInclusively(segment.start, in: bounds))
            XCTAssertTrue(containsInclusively(segment.end, in: bounds))
            if index > 0 {
                XCTAssertEqual(segment.start, trajectory.segments[index - 1].end)
                XCTAssertEqual(segment.startDistance, trajectory.segments[index - 1].endDistance)
            }
        }
        XCTAssertEqual(
            try PinballBilliards.endPoint(for: launch, in: bounds),
            trajectory.endPoint
        )
    }

    func testResolvedWinnerIsDefinedOnlyByActualFinalPoint() throws {
        let bounds = PinballTestFixtures.landscapeBounds
        let partition = try PinballRadialPartition(
            bounds: bounds,
            taps: PinballTestFixtures.radialTaps(count: 12, in: bounds)
        )
        let launch = try PinballLaunch(
            start: CGPoint(x: bounds.midX + 7, y: bounds.midY - 11),
            direction: CGVector(dx: 0.31, dy: -0.89),
            distance: 4_321
        )

        let result = try PinballRoundResolver.resolve(launch: launch, partition: partition)

        XCTAssertEqual(result.finalPoint, result.trajectory.endPoint)
        XCTAssertEqual(result.winningSeatID, try partition.seatID(containing: result.finalPoint))
    }

    private func containsInclusively(_ point: CGPoint, in bounds: CGRect) -> Bool {
        point.x >= bounds.minX && point.x <= bounds.maxX &&
            point.y >= bounds.minY && point.y <= bounds.maxY
    }

    private func normalizedPhase(_ phase: CGFloat) -> CGFloat {
        let remainder = phase.truncatingRemainder(dividingBy: 1)
        return remainder < 0 ? remainder + 1 : remainder
    }

    /// Mirrors `configureAccessiblePinballSeats` followed by the production
    /// collision-bounds clamp in `makePinballPartition`.
    private func productionPinballTaps(
        count: Int,
        stageBounds: CGRect,
        collisionBounds: CGRect
    ) -> [PinballSeatTap] {
        (0..<count).map { index in
            let angle = -CGFloat.pi / 2
                + 2 * CGFloat.pi * CGFloat(index) / CGFloat(count)
            let raw = CGPoint(
                x: stageBounds.midX + cos(angle) * stageBounds.width * 0.43,
                y: stageBounds.midY + sin(angle) * stageBounds.height * 0.43
            )
            return PinballSeatTap(
                seatID: index + 1,
                point: CGPoint(
                    x: min(max(raw.x, collisionBounds.minX), collisionBounds.maxX),
                    y: min(max(raw.y, collisionBounds.minY), collisionBounds.maxY)
                )
            )
        }
    }

    private func distance(
        _ point: CGPoint,
        fromRay origin: CGPoint,
        through boundary: CGPoint
    ) -> CGFloat {
        let ray = CGVector(dx: boundary.x - origin.x, dy: boundary.y - origin.y)
        let offset = CGVector(dx: point.x - origin.x, dy: point.y - origin.y)
        return abs(ray.dx * offset.dy - ray.dy * offset.dx) / hypot(ray.dx, ray.dy)
    }
}
