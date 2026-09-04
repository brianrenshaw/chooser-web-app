import CoreGraphics
import Foundation

/// Caps how square Pinball's playfield is allowed to be.
///
/// ## Why a board shape needs capping at all
///
/// A uniform scale is a similarity transform of Pinball's reachability problem,
/// so board *size* is free. Board *shape* is not: aspect ratio is the one member
/// of the dimensionless tuple that an iPad actually moves, and measurement shows
/// it matters. Under randomised realistic flicks the rate at which a flick fails
/// to start a round at all — the resolver finds no path to the drawn winner and
/// fails closed — is:
///
/// | board | ratio | dead flicks |
/// |---|---|---|
/// | iPhone SE 375x539 | 1.44 | 0.23% |
/// | iPhone 17 393x678 | 1.73 | 0.00% |
/// | iPhone 17 Pro Max 440x752 | 1.71 | 1.14% |
/// | iPad 11-inch portrait 820x1000 | 1.22 | 2.50% |
/// | iPad 13-inch portrait 1024x1266 | 1.24 | 5.23% |
///
/// A dead flick is not unfair by itself — the winner is drawn before any path is
/// solved, and the round fails closed rather than redrawing. The problem is what
/// follows: failure is region-dependent, the player flicks again, and the second
/// flick draws a *fresh* winner. Region-dependent rejection plus resampling is
/// exactly the shape of a biased die over completed rounds.
///
/// ## Why this rule, and not a simple cap
///
/// The obvious fix — cap every board at the reference ratio — narrows an iPhone
/// SE by 20% to solve a problem the SE does not have. So the cap is expressed as
/// two clauses that between them leave **every** phone untouched:
///
/// 1. Shrink the short edge until the ratio reaches the reference, but
/// 2. never below `PinballBoardMetrics.referenceShortEdge`, which sits above the
///    short edge of every iPhone playfield in either orientation.
///
/// Clause 2 is what makes the rule continuous. Without it a board would jump the
/// moment its short edge crossed 440, which on iPad is a Stage Manager drag away
/// — and a playfield that changes size cancels a running round. With it, the
/// transition happens exactly where the ratio crosses the reference, and the
/// size moves continuously through it.
///
/// The price of clause 2 is honest and worth stating: a mid-sized window whose
/// long edge is under ~789 points is only *partly* corrected, because reaching
/// the reference ratio there would mean a board narrower than a phone. Those
/// windows keep an elevated rate. Making them worse-shaped than a phone to chase
/// a ratio would be trading a real regression for a proof.
public enum PinballPlayfieldLetterbox {
    /// The shape every Pinball fairness guarantee is anchored to: the 390 x 700
    /// reference portrait playfield the per-region reachability matrix is run
    /// against. Capping to this ratio does not merely *measure* better — it puts
    /// a large board into a similarity transform of a board already proven fair.
    public static let referenceAspectRatio: CGFloat = 700.0 / 390.0

    /// The playfield Pinball should actually use inside a proposed area.
    ///
    /// Returns `proposed` unchanged for every iPhone, in both orientations, and
    /// for a phone-shaped iPad column such as Slide Over.
    public static func playfieldSize(fitting proposed: CGSize) -> CGSize {
        guard proposed.width.isFinite, proposed.height.isFinite,
              proposed.width > 0, proposed.height > 0 else {
            return proposed
        }

        let long = max(proposed.width, proposed.height)
        let short = min(proposed.width, proposed.height)

        // Never letterbox a board to be narrower than a phone's.
        let floor = min(short, PinballBoardMetrics.referenceShortEdge)
        let target = min(short, max(long / referenceAspectRatio, floor))
        guard target < short else { return proposed }

        return proposed.width > proposed.height
            ? CGSize(width: proposed.width, height: target)
            : CGSize(width: target, height: proposed.height)
    }
}
