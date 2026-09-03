import CoreGraphics
import Foundation

/// Fully resolved mathematical outcome of one pinball draw.
public struct PinballRoundResult: Equatable, Sendable {
    public let trajectory: PinballTrajectory
    public let winningRegion: PinballRadialRegion
    /// Index in `trajectory.points` of the one visible fair-bumper impulse.
    /// `nil` identifies ordinary fully specular rounds with no intervention.
    public let fairnessDeflectorVertexIndex: Int?

    public init(
        trajectory: PinballTrajectory,
        winningRegion: PinballRadialRegion,
        fairnessDeflectorVertexIndex: Int? = nil
    ) {
        self.trajectory = trajectory
        self.winningRegion = winningRegion
        self.fairnessDeflectorVertexIndex = fairnessDeflectorVertexIndex
    }

    /// The winner-defining point is always the trajectory's real endpoint.
    public var finalPoint: CGPoint { trajectory.endPoint }
    public var winningSeatID: Int { winningRegion.seat.seatID }
}

/// Connects launch sampling, analytic billiards, and radial ownership.
///
/// A fully random round obtains fairness from invariant rectangle-billiards
/// phase space. A user-directed flick cannot use that proof because its fixed
/// initial direction is not an invariant velocity distribution. Flick rounds
/// therefore select a winner uniformly and first try the exact natural specular
/// path. If its endpoint already agrees, the round remains completely untouched.
/// Only a disagreement adds one explicitly identified first-wall deflector and
/// a genuine specular suffix ending in the selected region. The reported winner
/// is always the owner of the displayed endpoint.
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

    /// Resolves a player's committed flick with an unbiased winner and exact
    /// natural trajectory whenever it already agrees. A disagreement preserves
    /// the release origin and first-leg direction, then uses one visible first-wall
    /// intervention and a physically specular suffix whose endpoint owns the result.
    public static func flickRound<R: PinballRandomSource>(
        partition: PinballRadialPartition,
        intent: PinballFlickIntent,
        using random: inout R,
        maximumSegments: Int = 10_000,
        bumpers: PinballBumperField = .empty
    ) throws -> PinballRoundResult {
        try PinballSpecularFlickResolver.resolve(
            partition: partition,
            intent: intent,
            using: &random,
            maximumSegments: maximumSegments,
            bumpers: bumpers
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

    /// Production convenience for a user-directed launch using Apple's secure
    /// random generator for the winner and endpoint variation.
    public static func secureFlickRound(
        partition: PinballRadialPartition,
        intent: PinballFlickIntent,
        maximumSegments: Int = 10_000,
        bumpers: PinballBumperField = .empty
    ) throws -> PinballRoundResult {
        var random = SecurePinballRandomSource()
        return try flickRound(
            partition: partition,
            intent: intent,
            using: &random,
            maximumSegments: maximumSegments,
            bumpers: bumpers
        )
    }
}
