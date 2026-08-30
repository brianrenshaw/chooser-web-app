import CoreGraphics
import Foundation

/// Fully resolved mathematical outcome of one pinball draw.
public struct PinballRoundResult: Equatable, Sendable {
    public let trajectory: PinballTrajectory
    public let winningRegion: PinballRadialRegion

    /// The winner-defining point is always the trajectory's real endpoint.
    public var finalPoint: CGPoint { trajectory.endPoint }
    public var winningSeatID: Int { winningRegion.seat.seatID }
}

/// Connects launch sampling, analytic billiards, and radial ownership.
///
/// There is deliberately no separate "choose a winner" random call. Randomness
/// creates physical launch conditions; the final folded point alone determines
/// which equal-area region wins. This keeps the visible pinball outcome and the
/// reported seat mathematically identical. Uniform position paired with an
/// independent uniform direction is the invariant phase-space measure of
/// rectangle billiards. Evolving it by any independently sampled distance leaves
/// the endpoint's position uniform. Combining that endpoint with equal-area
/// regions therefore gives every seat equal probability.
public enum PinballRoundResolver {
    /// Resolves caller-supplied launch conditions, useful for deterministic tests
    /// and replays.
    public static func resolve(
        launch: PinballLaunch,
        partition: PinballRadialPartition,
        maximumSegments: Int = 10_000
    ) throws -> PinballRoundResult {
        let trajectory = try PinballBilliards.trajectory(
            for: launch,
            in: partition.bounds,
            maximumSegments: maximumSegments
        )
        let region = try partition.region(containing: trajectory.endPoint)
        return PinballRoundResult(trajectory: trajectory, winningRegion: region)
    }

    /// Samples independent launch conditions from `random`, then resolves the
    /// visible endpoint. Supplying a deterministic source makes the whole round
    /// reproducible without weakening the secure production default.
    public static func randomRound<R: PinballRandomSource>(
        partition: PinballRadialPartition,
        distanceRange: ClosedRange<CGFloat>,
        using random: inout R,
        maximumSegments: Int = 10_000
    ) throws -> PinballRoundResult {
        let launch = try PinballSampling.launch(
            in: partition.bounds,
            distanceRange: distanceRange,
            using: &random
        )
        return try resolve(
            launch: launch,
            partition: partition,
            maximumSegments: maximumSegments
        )
    }

    /// Production convenience that obtains every launch value from Apple's
    /// cryptographically secure system random generator.
    public static func secureRandomRound(
        partition: PinballRadialPartition,
        distanceRange: ClosedRange<CGFloat>,
        maximumSegments: Int = 10_000
    ) throws -> PinballRoundResult {
        var random = SecurePinballRandomSource()
        return try randomRound(
            partition: partition,
            distanceRange: distanceRange,
            using: &random,
            maximumSegments: maximumSegments
        )
    }
}
