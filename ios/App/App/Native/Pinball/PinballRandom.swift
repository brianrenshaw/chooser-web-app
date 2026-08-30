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
    case invalidDistance
    case invalidDistanceRange
    case invalidTimeCurve
    case invalidSeatCount(Int)
    case duplicateSeatID(Int)
    case tapAtPartitionCenter(Int)
    case reflectionLimitExceeded(Int)
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
