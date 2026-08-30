import CoreGraphics
import XCTest
@testable import App

final class PinballMotionAndFairnessTests: XCTestCase {
    func testDecelerationIsMonotonicFastToZeroAndEndsExactly() throws {
        let curve = try PinballDecelerationCurve(duration: 5, exponent: 3)
        let samples = stride(from: 0.0, through: 5.0, by: 0.05).map { Double($0) }
        let progress = samples.map(curve.progress(at:))
        let speed = samples.map(curve.remainingSpeedFraction(at:))

        XCTAssertEqual(progress.first, 0)
        XCTAssertEqual(progress.last, 1)
        XCTAssertEqual(speed.first, 1)
        XCTAssertEqual(speed.last, 0)
        for pair in zip(progress, progress.dropFirst()) {
            XCTAssertLessThanOrEqual(pair.0, pair.1)
        }
        for pair in zip(speed, speed.dropFirst()) {
            XCTAssertGreaterThanOrEqual(pair.0, pair.1)
        }
        XCTAssertGreaterThan(curve.normalizedSpeed(at: 0), curve.normalizedSpeed(at: 1))
        XCTAssertEqual(try curve.distance(at: 5, totalDistance: 9_876), 9_876, accuracy: 1e-9)
        XCTAssertEqual(try curve.distance(at: 50, totalDistance: 9_876), 9_876, accuracy: 1e-9)
    }

    func testSixtyAndOneHundredTwentyHertzPlaybackReachIdenticalEndpoint() throws {
        let bounds = PinballTestFixtures.landscapeBounds
        let launch = try PinballLaunch(
            start: CGPoint(x: bounds.midX, y: bounds.midY),
            direction: CGVector(dx: -0.61, dy: 0.79),
            distance: 5_250
        )
        let curve = try PinballDecelerationCurve(duration: 5, exponent: 3.4)

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
        XCTAssertThrowsError(try PinballDecelerationCurve(duration: 0)) { error in
            XCTAssertEqual(error as? PinballMathError, .invalidTimeCurve)
        }
    }
}
