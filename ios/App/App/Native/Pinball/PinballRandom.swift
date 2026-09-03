import CoreGraphics
import Foundation

/// Errors produced by the pure pinball mathematics layer.
///
/// Keeping validation failures explicit makes the core safe to call from a UI
/// without relying on assertions or silently repairing invalid geometry.
public enum PinballMathError: Error, Equatable, Sendable {
    case nonFiniteValue
    case invalidBounds
    case pointOutsideBounds
    case zeroDirection
    case invalidFlickSpeed
    case invalidRandomUpperBound(Int)
    case targetSamplingLimitExceeded(Int)
    case guidedTrajectoryUnavailable
    case specularTrajectoryUnavailable
    case invalidDistance
    case invalidDistanceRange
    case invalidTimeCurve
    case invalidSeatCount(Int)
    case duplicateSeatID(Int)
    case tapAtPartitionCenter(Int)
    case reflectionLimitExceeded(Int)
}

/// Position, direction, and release speed committed by a player's flick before
/// any chooser randomness is consumed.
public struct PinballFlickIntent: Equatable, Sendable {
    public let releasePoint: CGPoint
    public let direction: CGVector
    public let speed: CGFloat

    public init(
        releasePoint: CGPoint,
        direction: CGVector,
        speed: CGFloat
    ) throws {
        guard releasePoint.x.isFinite,
              releasePoint.y.isFinite,
              direction.dx.isFinite,
              direction.dy.isFinite,
              speed.isFinite else {
            throw PinballMathError.nonFiniteValue
        }
        guard hypot(direction.dx, direction.dy) > 0 else {
            throw PinballMathError.zeroDirection
        }
        guard speed >= 0 else {
            throw PinballMathError.invalidFlickSpeed
        }
        self.releasePoint = releasePoint
        self.direction = direction
        self.speed = speed
    }
}

/// Converts a physical flick into readable, physically specular motion.
public enum PinballFlickLaunchPolicy {
    public static let speedRange: ClosedRange<CGFloat> = 400...1_600
    public static let distanceInPerimetersRange: ClosedRange<CGFloat> = 1.45...2.10
    /// Stronger flicks travel farther in less time. The stored range remains
    /// ascending, while ``flightDuration(forSpeed:)`` maps weak to its upper
    /// bound and strong to its lower bound.
    public static let flightDurationRange: ClosedRange<TimeInterval> = 3.80...4.20
    public static let launchEnergyRange: ClosedRange<CGFloat> = 0.62...1.0
    public static let narrowDirectionVariation: CGFloat = 1.5 * .pi / 180
    public static let wideDirectionVariation: CGFloat = 12 * .pi / 180
    public static let narrowDistanceVariation: CGFloat = 0.08
    public static let wideDistanceVariation: CGFloat = 0.20
    public static let inverseDistanceVariation: CGFloat = 0.35
    /// Imperceptible center clearance beyond the rendered ball's collision
    /// inset. It guarantees an outward edge release still has one real first
    /// leg before the visible fairness bumper.
    public static let releaseInteriorClearance: CGFloat = 0.5

    /// Normalizes without altering axis-hugging or exact axial flicks.
    public static func normalizedDirection(_ direction: CGVector) throws -> CGVector {
        guard direction.dx.isFinite, direction.dy.isFinite else {
            throw PinballMathError.nonFiniteValue
        }
        let magnitude = hypot(direction.dx, direction.dy)
        guard magnitude > 0, magnitude.isFinite else {
            throw PinballMathError.zeroDirection
        }
        return CGVector(
            dx: direction.dx / magnitude,
            dy: direction.dy / magnitude
        )
    }

    /// Legacy source-compatible spelling. It now only normalizes; Build 11 no
    /// longer forces a flick away from horizontal or vertical axes.
    public static func clampedDirection(_ direction: CGVector) throws -> CGVector {
        try normalizedDirection(direction)
    }

    public static func normalizedStrength(forSpeed speed: CGFloat) throws -> CGFloat {
        guard speed.isFinite else { throw PinballMathError.nonFiniteValue }
        guard speed >= 0 else { throw PinballMathError.invalidFlickSpeed }
        return min(
            1,
            max(0, (speed - speedRange.lowerBound) /
                (speedRange.upperBound - speedRange.lowerBound))
        )
    }

    public static func centerDistanceInPerimeters(strength: CGFloat) -> CGFloat {
        let clamped = min(1, max(0, strength))
        return distanceInPerimetersRange.lowerBound + clamped *
            (distanceInPerimetersRange.upperBound - distanceInPerimetersRange.lowerBound)
    }

    public static func perimeter(of bounds: CGRect) -> CGFloat {
        2 * (bounds.width + bounds.height)
    }

    /// Keeps the ball center at the physical release location whenever that
    /// point is drawable. Only the collision inset represented by `bounds` and
    /// a subpoint interior clearance may move it, so launching never teleports
    /// to a hidden random position.
    public static func clampedReleasePoint(
        _ point: CGPoint,
        to bounds: CGRect
    ) throws -> CGPoint {
        try PinballValidation.validate(bounds: bounds)
        try PinballValidation.validate(point: point)
        let clearance = min(
            releaseInteriorClearance,
            min(bounds.width / 4, bounds.height / 4)
        )
        let interior = bounds.insetBy(dx: clearance, dy: clearance)
        return CGPoint(
            x: min(max(point.x, interior.minX), interior.maxX),
            y: min(max(point.y, interior.minY), interior.maxY)
        )
    }

    /// Maps 400...1600 points/second linearly onto the center of the
    /// strength-appropriate travel band.
    public static func travelDistance(
        forSpeed speed: CGFloat,
        in bounds: CGRect
    ) throws -> CGFloat {
        try PinballValidation.validate(bounds: bounds)
        let strength = try normalizedStrength(forSpeed: speed)
        return perimeter(of: bounds) * centerDistanceInPerimeters(strength: strength)
    }

    public static func flightDuration(forSpeed speed: CGFloat) throws -> TimeInterval {
        let strength = try normalizedStrength(forSpeed: speed)
        return flightDurationRange.upperBound - TimeInterval(strength) *
            (flightDurationRange.upperBound - flightDurationRange.lowerBound)
    }

    /// Perceptual launch energy for material motion feedback. Analytic distance
    /// remains the source of truth; this only scales the visible tail and
    /// collision response so a soft flick cannot look identical to a hard one.
    public static func launchEnergy(forStrength strength: CGFloat) -> CGFloat {
        let clamped = min(1, max(0, strength))
        return launchEnergyRange.lowerBound + clamped *
            (launchEnergyRange.upperBound - launchEnergyRange.lowerBound)
    }

    /// Secure triangular angular variation centered on the committed flick.
    public static func sampledDirection<R: PinballRandomSource>(
        around direction: CGVector,
        halfWidth: CGFloat = narrowDirectionVariation,
        using random: inout R
    ) throws -> CGVector {
        guard halfWidth.isFinite, halfWidth >= 0 else {
            throw PinballMathError.nonFiniteValue
        }
        let unit = try normalizedDirection(direction)
        let triangular = random.nextUnitInterval() + random.nextUnitInterval() - 1
        let delta = triangular * halfWidth
        let cosine = cos(delta)
        let sine = sin(delta)
        return CGVector(
            dx: unit.dx * cosine - unit.dy * sine,
            dy: unit.dx * sine + unit.dy * cosine
        )
    }

    public static func sampledTravelDistance<R: PinballRandomSource>(
        strength: CGFloat,
        variation: CGFloat = narrowDistanceVariation,
        in bounds: CGRect,
        using random: inout R
    ) throws -> CGFloat {
        try PinballValidation.validate(bounds: bounds)
        guard strength.isFinite, variation.isFinite, variation >= 0 else {
            throw PinballMathError.nonFiniteValue
        }
        let center = centerDistanceInPerimeters(strength: strength)
        let offset: CGFloat
        if variation == 0 {
            offset = 0
        } else {
            offset = try random.nextCGFloat(in: (-variation)...variation)
        }
        return perimeter(of: bounds) * max(0, center + offset)
    }
}

/// Minimal random-source abstraction used by the pinball core.
///
/// Production code should normally use ``SecurePinballRandomSource``. Tests can
/// provide a tiny deterministic source that returns a known UInt64 sequence,
/// making every sampled launch exactly reproducible.
public protocol PinballRandomSource: Sendable {
    mutating func nextUInt64() -> UInt64
}

/// Cryptographically secure random bytes backed by Apple's system generator.
///
/// `SystemRandomNumberGenerator` is seeded and supplied by the operating system
/// on Apple platforms. The wrapper exists so geometry code never reaches for a
/// global random function and deterministic tests can inject their own source.
public struct SecurePinballRandomSource: PinballRandomSource, Sendable {
    private var generator = SystemRandomNumberGenerator()

    public init() {}

    public mutating func nextUInt64() -> UInt64 {
        generator.next()
    }
}

public extension PinballRandomSource {
    /// Exact rejection-sampled index without modulo bias.
    mutating func nextUnbiasedIndex(upperBound: Int) throws -> Int {
        guard upperBound > 0 else {
            throw PinballMathError.invalidRandomUpperBound(upperBound)
        }
        let bound = UInt64(upperBound)
        let threshold = (0 &- bound) % bound
        while true {
            let value = nextUInt64()
            if value >= threshold {
                return Int(value % bound)
            }
        }
    }

    /// A uniformly distributed binary64 value in the half-open interval [0, 1).
    ///
    /// Using the high 53 bits matches `Double`'s significand precision. Every
    /// representable output bucket therefore has exactly the same probability.
    mutating func nextUnitInterval() -> CGFloat {
        let significand = nextUInt64() >> 11
        let value = Double(significand) * (1.0 / 9_007_199_254_740_992.0)
        return CGFloat(value)
    }

    /// A uniform value strictly inside (0, 1).
    ///
    /// This uses the midpoint of one of 2^52 equal buckets. All midpoints are
    /// exactly representable by `Double`, including the two extreme buckets, so
    /// the result can never round back to zero or one. Removing a measure-zero
    /// boundary does not change area uniformity and avoids an unnecessary
    /// immediate reflection at launch.
    mutating func nextOpenUnitInterval() -> CGFloat {
        let bucket = nextUInt64() >> 12
        let value = (Double(bucket) + 0.5) * (1.0 / 4_503_599_627_370_496.0)
        return CGFloat(value)
    }

    /// Uniformly samples a finite range. The upper endpoint is approached but
    /// not returned, which is the conventional continuous-uniform model.
    mutating func nextCGFloat(in range: ClosedRange<CGFloat>) throws -> CGFloat {
        guard range.lowerBound.isFinite, range.upperBound.isFinite else {
            throw PinballMathError.nonFiniteValue
        }
        guard range.lowerBound < range.upperBound else {
            throw PinballMathError.invalidDistanceRange
        }

        let sampled = range.lowerBound + nextUnitInterval() * (range.upperBound - range.lowerBound)
        // The affine operation can round a value just below the upper bound back
        // onto it. Clamp by one representable step to retain half-open semantics.
        return max(range.lowerBound, min(sampled, range.upperBound.nextDown))
    }
}

/// Stateless sampling helpers. Each launch component consumes a separate random
/// draw, so start position, direction, and travel distance are independent.
public enum PinballSampling {
    /// Samples a point uniformly by area from the strict interior of `bounds`.
    public static func uniformStart<R: PinballRandomSource>(
        in bounds: CGRect,
        using random: inout R
    ) throws -> CGPoint {
        try PinballValidation.validate(bounds: bounds)

        let rawX = bounds.minX + random.nextOpenUnitInterval() * bounds.width
        let rawY = bounds.minY + random.nextOpenUnitInterval() * bounds.height
        let x = min(max(rawX, bounds.minX.nextUp), bounds.maxX.nextDown)
        let y = min(max(rawY, bounds.minY.nextUp), bounds.maxY.nextDown)
        return CGPoint(x: x, y: y)
    }

    /// Samples a direction uniformly over the full circle.
    ///
    /// Core Graphics uses a downward-positive y axis on screen. Increasing
    /// angles consequently appear clockwise, which is also the orientation used
    /// by the radial seat partition.
    public static func uniformDirection<R: PinballRandomSource>(
        using random: inout R
    ) -> CGVector {
        let angle = random.nextUnitInterval() * 2 * .pi
        return CGVector(dx: cos(angle), dy: sin(angle))
    }

    /// Samples a nonnegative travel distance independently of direction.
    public static func uniformDistance<R: PinballRandomSource>(
        in range: ClosedRange<CGFloat>,
        using random: inout R
    ) throws -> CGFloat {
        guard range.lowerBound >= 0 else {
            throw PinballMathError.invalidDistanceRange
        }
        return try random.nextCGFloat(in: range)
    }

    /// Creates a complete independent random launch specification.
    ///
    /// Four unrelated source values are consumed in a fixed order: start x,
    /// start y, direction angle, then distance. Tests may rely on that order.
    public static func launch<R: PinballRandomSource>(
        in bounds: CGRect,
        distanceRange: ClosedRange<CGFloat>,
        using random: inout R
    ) throws -> PinballLaunch {
        let start = try uniformStart(in: bounds, using: &random)
        let direction = uniformDirection(using: &random)
        let distance = try uniformDistance(in: distanceRange, using: &random)
        return try PinballLaunch(start: start, direction: direction, distance: distance)
    }

    /// Creates the unconditioned first-leg launch seed from a committed flick.
    ///
    /// Direction and strength are resolved before this function consumes any
    /// random values. The launch point is the player's release, clamped only to
    /// the ball's collision bounds plus its subpoint interior clearance. A
    /// fixed-direction reflecting path is not by itself a fair chooser;
    /// ``PinballRoundResolver.flickRound`` preserves this first leg, then uses
    /// one explicit first-wall deflector to reach an independently selected
    /// equal-probability region.
    public static func flickLaunch<R: PinballRandomSource>(
        in bounds: CGRect,
        intent: PinballFlickIntent,
        using random: inout R
    ) throws -> PinballLaunch {
        _ = random
        let direction = try PinballFlickLaunchPolicy.normalizedDirection(intent.direction)
        let distance = try PinballFlickLaunchPolicy.travelDistance(
            forSpeed: intent.speed,
            in: bounds
        )
        let start = try PinballFlickLaunchPolicy.clampedReleasePoint(
            intent.releasePoint,
            to: bounds
        )
        return try PinballLaunch(start: start, direction: direction, distance: distance)
    }
}

/// Shared finite-value and rectangle validation used across source files.
enum PinballValidation {
    static func validate(bounds: CGRect) throws {
        guard
            !bounds.isNull,
            !bounds.isInfinite,
            bounds.origin.x.isFinite,
            bounds.origin.y.isFinite,
            bounds.width.isFinite,
            bounds.height.isFinite
        else {
            throw PinballMathError.nonFiniteValue
        }

        guard
            bounds.width > 0,
            bounds.height > 0,
            bounds.maxX > bounds.minX,
            bounds.maxY > bounds.minY,
            bounds.minX.nextUp <= bounds.maxX.nextDown,
            bounds.minY.nextUp <= bounds.maxY.nextDown
        else {
            throw PinballMathError.invalidBounds
        }

        guard (bounds.width * bounds.height).isFinite else {
            throw PinballMathError.nonFiniteValue
        }
    }

    static func validate(point: CGPoint) throws {
        guard point.x.isFinite, point.y.isFinite else {
            throw PinballMathError.nonFiniteValue
        }
    }

    static func contains(_ point: CGPoint, in bounds: CGRect) -> Bool {
        point.x >= bounds.minX && point.x <= bounds.maxX &&
            point.y >= bounds.minY && point.y <= bounds.maxY
    }
}
