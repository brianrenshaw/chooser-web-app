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
}
