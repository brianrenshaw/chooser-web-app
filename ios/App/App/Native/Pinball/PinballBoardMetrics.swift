import CoreGraphics
import Foundation

/// Every length Pinball needs, resolved for one board size.
///
/// ## Why the law is linear
///
/// A uniform scale is an exact **similarity transform** of Pinball's entire
/// reachability problem, so the set of regions a flick can reach — and
/// therefore the fairness of the round — is invariant under it. That is
/// provable from the code rather than assumed:
///
/// - `RectangleRadialAreaMap.phase` returns a ratio of *areas*, so partition
///   phases are identical, not scaled.
/// - `nearestWallHit` and `nearestBumperHit` are homogeneous of degree 1;
///   `reflect` is degree 0.
/// - The solver's tolerances are already relative to the board.
/// - The deflection sweep enumerates *angles*, the wall search counts *walls*,
///   and launch distance is expressed in *perimeters*. All dimensionless.
///
/// Reachability therefore depends only on a dimensionless tuple — aspect ratio,
/// seat count, diameter over width, ball radius over width, clearances over
/// width. Scale is not in that list. **Aspect ratio is.**
///
/// Two consequences worth stating plainly, because both are easy to undo by
/// accident:
///
/// 1. **One factor must multiply every length.** Scaling seats but not the
///    ball, or the ball but not the passage clearance, changes a ratio in that
///    tuple and lands the app in a dimensionless configuration no test has ever
///    covered. The fairness guarantee is forfeit at that point.
/// 2. **Damping the law is safe but expensive.** A sublinear law is still one
///    factor, so it is sound — but it makes a large board a *different* point in
///    the family, and the honest price is re-running the per-region reachability
///    matrix at the new ratio, not a visual review.
///
/// This is deliberately *not* the law `BoardPieceVisualMetrics.boardScale` uses.
/// Chooser and Tap In have no fairness constraint — their winner comes from
/// touch identities and the entry list, never from geometry — so they damp their
/// growth to keep pieces sane on a large canvas. The two laws answer different
/// questions and must not be unified.
public struct PinballBoardMetrics: Equatable, Sendable {
    /// Board short edge at and below which every length is exactly what it has
    /// always been. Sits above the largest iPhone playfield short edge in either
    /// orientation, and above every raw size used in the geometry fixtures, so
    /// phones and their tests resolve to scale 1 by construction rather than by
    /// a device check. A narrow iPad Slide Over column lands here too, which is
    /// correct: a phone-sized column should play like a phone.
    public static let referenceShortEdge: CGFloat = 440

    public static let referenceBallDiameter: CGFloat = 30
    public static let referenceCollisionInset: CGFloat = 18
    public static let referencePassageClearance: CGFloat = 8
    public static let referenceMinimumTailLength: CGFloat = 12
    public static let referenceMaximumTailLength: CGFloat = 40

    /// The linear factor. Never below 1 — see `bumperAwareLayout`, which takes
    /// `max(readableFloor, preferred)` as its upper bound and could otherwise
    /// return a layout larger than the caller asked for.
    public let scale: CGFloat

    /// The board as it would be at scale 1. Aspect ratio is preserved, so the
    /// portrait/landscape branch in seat sizing picks the same side it does
    /// today — orientation is a scale-invariant predicate.
    public let referenceSize: CGSize

    public init(playfieldSize: CGSize) {
        let shortEdge = min(playfieldSize.width, playfieldSize.height)
        let raw = shortEdge.isFinite && shortEdge > 0
            ? shortEdge / Self.referenceShortEdge
            : 1
        let scale = max(1, raw)
        self.scale = scale
        self.referenceSize = CGSize(
            width: playfieldSize.width / scale,
            height: playfieldSize.height / scale
        )
    }

    // MARK: - Lengths (scale)

    public var ballDiameter: CGFloat { Self.referenceBallDiameter * scale }
    public var ballRadius: CGFloat { ballDiameter / 2 }
    public var collisionInset: CGFloat { Self.referenceCollisionInset * scale }
    public var passageClearance: CGFloat { Self.referencePassageClearance * scale }
    public var minimumTailLength: CGFloat { Self.referenceMinimumTailLength * scale }
    public var maximumTailLength: CGFloat { Self.referenceMaximumTailLength * scale }

    /// The authored seat sizing evaluated at reference size, then scaled — so
    /// the whole expression, including which branch of its clamps binds, is the
    /// phone expression.
    public func preferredSeatDiameter(seatCount: Int) -> CGFloat {
        PinballSeatTokenSizing.referencePreferredDiameter(
            in: referenceSize,
            seatCount: seatCount
        ) * scale
    }

    public var seatLayoutPolicy: PinballSeatTokenLayoutPolicy {
        .production.scaled(by: scale)
    }

    /// Same safety property as the fixed version: the fully compressed,
    /// aura-lit ball must stay inside the collision inset. Both sides scale, so
    /// the ratio — and therefore the guarantee — is preserved at every size.
    public var maximumRenderedRadius: CGFloat {
        let faceAndEdge = (ballRadius + 1.25 * scale)
            * NativePinballReplayMetrics.maximumImpactTangentScale
        let aura = (ballRadius * NativePinballReplayMetrics.auraRadiusScale
            + NativePinballReplayMetrics.auraOffset * scale)
            * NativePinballReplayMetrics.maximumImpactTangentScale
        return max(faceAndEdge, aura)
    }

    // MARK: - Times (do NOT scale)

    /// Flight duration grows, but far more slowly than the board.
    ///
    /// Holding apparent speed constant would mean `T ∝ s`, which on a 13-inch
    /// iPad is an eight-to-nine second flight — a cutscene, not a chooser.
    /// Holding duration fixed is more defensible than it looks: because the iPad
    /// path is an exact scaled copy of the phone path, the bounce sequence is
    /// identical and lands at the same fractional progress, so a fixed duration
    /// keeps the whole impact cadence bit-identical across devices. Every
    /// increase dilutes that. The cube root is biased toward the fixed end for
    /// exactly that reason, and it preserves the ~1.105 weak-to-strong ratio,
    /// which is the part a player can actually perceive.
    ///
    /// This is the one number here that no test can adjudicate.
    public var flightDurationRange: ClosedRange<TimeInterval> {
        let factor = pow(Double(scale), 1.0 / 3.0)
        let reference = PinballFlickLaunchPolicy.referenceFlightDurationRange
        let lower = reference.lowerBound * factor
        let upper = reference.upperBound * factor
        return lower...upper
    }

    /// Impact compression, rebound and settle durations are deliberately absent.
    /// Those are *times*, not lengths: keeping them fixed is precisely what
    /// preserves the tactile and lighting cadence across board sizes. A later
    /// refactor will be tempted to scale them "for consistency" — do not.
    public static let reference = PinballBoardMetrics(
        playfieldSize: CGSize(width: referenceShortEdge, height: referenceShortEdge)
    )
}
