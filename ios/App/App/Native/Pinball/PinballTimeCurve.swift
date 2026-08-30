import CoreGraphics
import Foundation

/// A smooth, monotonic fast-to-zero motion curve.
///
/// For normalized time `u`, traveled distance is:
///
///     progress(u) = 1 - (1 - u)^exponent
///
/// Its derivative starts above the average speed, decreases monotonically, and
/// reaches exactly zero at the end when `exponent > 1`. This gives the pinball a
/// decisive initial launch followed by a readable coast to its actual endpoint.
/// The curve is a pure mapping: it owns no timer and is independent of refresh
/// rate, scene orientation, UIKit, or SwiftUI.
public struct PinballDecelerationCurve: Equatable, Sendable {
    public let duration: TimeInterval
    public let exponent: CGFloat

    /// - Parameters:
    ///   - duration: Positive animation duration in seconds.
    ///   - exponent: Shape greater than one. `3` is a strong but smooth default;
    ///     larger values spend more distance near the beginning.
    public init(duration: TimeInterval, exponent: CGFloat = 3) throws {
        guard duration.isFinite, exponent.isFinite else {
            throw PinballMathError.nonFiniteValue
        }
        guard duration > 0, exponent > 1 else {
            throw PinballMathError.invalidTimeCurve
        }
        self.duration = duration
        self.exponent = exponent
    }

    /// Time clamped to [0, 1].
    public func normalizedTime(at elapsed: TimeInterval) -> CGFloat {
        if elapsed.isNaN { return 0 }
        guard elapsed.isFinite else { return elapsed.sign == .minus ? 0 : 1 }
        return CGFloat(min(max(elapsed / duration, 0), 1))
    }

    /// Monotonic distance progress in [0, 1].
    public func progress(at elapsed: TimeInterval) -> CGFloat {
        let time = normalizedTime(at: elapsed)
        if time <= 0 { return 0 }
        if time >= 1 { return 1 }
        return 1 - power(1 - time, exponent)
    }

    /// Remaining speed as a fraction of initial speed.
    ///
    /// This value is exactly 1 at launch, monotonically decreases, and is exactly
    /// 0 at or after `duration`.
    public func remainingSpeedFraction(at elapsed: TimeInterval) -> CGFloat {
        let time = normalizedTime(at: elapsed)
        if time <= 0 { return 1 }
        if time >= 1 { return 0 }
        return power(1 - time, exponent - 1)
    }

    /// Instantaneous normalized speed, expressed in progress units per second.
    public func normalizedSpeed(at elapsed: TimeInterval) -> CGFloat {
        CGFloat(exponent) / CGFloat(duration) * remainingSpeedFraction(at: elapsed)
    }

    /// Exact path distance at `elapsed`, clamped to the launch's endpoints.
    public func distance(at elapsed: TimeInterval, totalDistance: CGFloat) throws -> CGFloat {
        guard totalDistance.isFinite else { throw PinballMathError.nonFiniteValue }
        guard totalDistance >= 0 else { throw PinballMathError.invalidDistance }
        return totalDistance * progress(at: elapsed)
    }

    private func power(_ base: CGFloat, _ exponent: CGFloat) -> CGFloat {
        CGFloat(Foundation.pow(Double(base), Double(exponent)))
    }
}
