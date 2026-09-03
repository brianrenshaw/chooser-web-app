import CoreGraphics
import Foundation

/// A normalized high-inertia rolling profile that comes smoothly to rest.
///
/// For normalized time `u`, velocity relative to launch speed is:
///
///     velocity(u) = e + (1 - e) * (1 - u^5)^2
///
/// where `e` is ``terminalSpeedFraction``. The default `e = 0` retains almost
/// all launch speed through the first half of the flight, then rolls down to a
/// true stop with zero slope at the endpoint. The exact polynomial integral is
/// normalized, so progress always lands on `1` without changing the analytic
/// trajectory, reflection points, or winning endpoint.
public struct PinballMotionProfile: Equatable, Sendable {
    /// The fifth-power coast is part of the authored Build 16 motion language.
    public static let defaultDecelerationExponent: CGFloat = 5
    public static let defaultTerminalSpeedFraction: CGFloat = 0

    public let duration: TimeInterval
    public let decelerationExponent: CGFloat
    public let terminalSpeedFraction: CGFloat

    public init(
        duration: TimeInterval,
        decelerationExponent: CGFloat = Self.defaultDecelerationExponent,
        terminalSpeedFraction: CGFloat = Self.defaultTerminalSpeedFraction
    ) throws {
        guard duration.isFinite,
              decelerationExponent.isFinite,
              terminalSpeedFraction.isFinite else {
            throw PinballMathError.nonFiniteValue
        }
        guard duration > 0,
              decelerationExponent > 1,
              terminalSpeedFraction >= 0,
              terminalSpeedFraction < 1 else {
            throw PinballMathError.invalidTimeCurve
        }
        self.duration = duration
        self.decelerationExponent = decelerationExponent
        self.terminalSpeedFraction = terminalSpeedFraction
    }

    /// Time clamped to `[0, 1]`.
    public func normalizedTime(at elapsed: TimeInterval) -> CGFloat {
        if elapsed.isNaN { return 0 }
        guard elapsed.isFinite else { return elapsed.sign == .minus ? 0 : 1 }
        return CGFloat(min(max(elapsed / duration, 0), 1))
    }

    /// Monotonic distance progress in `[0, 1]`.
    public func progress(at elapsed: TimeInterval) -> CGFloat {
        progress(atNormalizedTime: normalizedTime(at: elapsed))
    }

    public func progress(atNormalizedTime normalizedTime: CGFloat) -> CGFloat {
        let time = min(1, max(0, normalizedTime))
        if time <= 0 { return 0 }
        if time >= 1 { return 1 }

        // Integral of e + (1 - e)(1 - u^n)^2:
        // u - 2(1 - e)u^(n + 1)/(n + 1)
        //   + (1 - e)u^(2n + 1)/(2n + 1)
        let rollingShare = 1 - terminalSpeedFraction
        let firstResistance = 2 * rollingShare * power(
            time,
            decelerationExponent + 1
        ) / (decelerationExponent + 1)
        let easingTail = rollingShare * power(
            time,
            2 * decelerationExponent + 1
        ) / (2 * decelerationExponent + 1)
        let rawProgress = time - firstResistance + easingTail
        return rawProgress / normalizationArea
    }

    /// Current speed as a fraction of the initial cruising speed.
    ///
    /// The default reaches zero at the endpoint. Because both velocity and its
    /// slope are zero there, the visible stop has no discontinuous speed cut.
    public func remainingSpeedFraction(at elapsed: TimeInterval) -> CGFloat {
        speedFraction(atNormalizedTime: normalizedTime(at: elapsed))
    }

    public func speedFraction(atNormalizedTime normalizedTime: CGFloat) -> CGFloat {
        let time = min(1, max(0, normalizedTime))
        let coast = 1 - power(time, decelerationExponent)
        return terminalSpeedFraction +
            (1 - terminalSpeedFraction) * coast * coast
    }

    /// Instantaneous normalized path speed in progress units per second.
    public func normalizedSpeed(at elapsed: TimeInterval) -> CGFloat {
        remainingSpeedFraction(at: elapsed) /
            (normalizationArea * CGFloat(duration))
    }

    /// Exact path distance at `elapsed`, clamped to the launch's endpoints.
    public func distance(at elapsed: TimeInterval, totalDistance: CGFloat) throws -> CGFloat {
        guard totalDistance.isFinite else { throw PinballMathError.nonFiniteValue }
        guard totalDistance >= 0 else { throw PinballMathError.invalidDistance }
        return totalDistance * progress(at: elapsed)
    }

    /// Inverts the normalized progress mapping for collision scheduling.
    public func elapsedTime(atProgress rawProgress: CGFloat) -> TimeInterval {
        let target = min(1, max(0, rawProgress))
        if target <= 0 { return 0 }
        if target >= 1 { return duration }

        var lower: CGFloat = 0
        var upper: CGFloat = 1
        for _ in 0..<48 {
            let midpoint = (lower + upper) / 2
            if progress(atNormalizedTime: midpoint) < target {
                lower = midpoint
            } else {
                upper = midpoint
            }
        }
        return TimeInterval((lower + upper) / 2) * duration
    }

    private var normalizationArea: CGFloat {
        let rollingShare = 1 - terminalSpeedFraction
        return 1 - 2 * rollingShare / (decelerationExponent + 1) +
            rollingShare / (2 * decelerationExponent + 1)
    }

    private func power(_ base: CGFloat, _ exponent: CGFloat) -> CGFloat {
        CGFloat(Foundation.pow(Double(base), Double(exponent)))
    }
}

/// Source-compatible name for callers compiled against the Build 11 API.
public typealias PinballDecelerationCurve = PinballMotionProfile
