import CoreGraphics
import Foundation

/// A stable seat identity and its physical tap position.
public struct PinballSeatTap: Equatable, Sendable {
    public let seatID: Int
    public let point: CGPoint

    public init(seatID: Int, point: CGPoint) {
        self.seatID = seatID
        self.point = point
    }
}

/// One equal-area radial region of the playfield.
///
/// Phases are normalized swept *area* in [0, 1), not raw angles. Moving from
/// `startPhase` to `endPhase` in the positive direction follows clockwise screen
/// order and always sweeps exactly `1 / seatCount` of the rectangle.
public struct PinballRadialRegion: Equatable, Sendable {
    public let seat: PinballSeatTap
    public let clockwiseIndex: Int
    public let startPhase: CGFloat
    public let endPhase: CGFloat
    public let startBoundaryPoint: CGPoint
    public let endBoundaryPoint: CGPoint
    public let area: CGFloat
}

/// Equal-area radial ownership of an axis-aligned rectangle.
///
/// Rays from the rectangle center divide the playfield. Equal angles would be
/// biased on a non-square screen because a ray near a long corner sweeps more
/// area. This type instead parameterizes each ray by the exact area swept around
/// the clipped rectangle and places boundaries one `1 / N` area unit apart.
///
/// Seat IDs are associated with regions in the taps' physical clockwise order.
/// A single phase offset aligns the equal-area region centers to the taps as a
/// group while preserving that circular order. The construction is independent
/// of portrait or landscape orientation; callers simply provide the current
/// bounds and current tap coordinates.
///
/// A useful exact special case falls out of the same general math: for two taps
/// centered above and below the rectangle center, region centers land at swept
/// phases 3/4 and 1/4, while boundaries land at the left and right midpoints.
/// The result is therefore the required horizontal 50/50 split.
public struct PinballRadialPartition: Equatable, Sendable {
    public let bounds: CGRect
    public let center: CGPoint
    public let regions: [PinballRadialRegion]

    /// Phase at which region zero begins, exposed for deterministic tests and
    /// debug rendering.
    public let originPhase: CGFloat

    private let areaMap: RectangleRadialAreaMap

    /// Creates regions for 2 through 12 unique seats.
    ///
    /// Taps must be finite, inside `bounds`, and not exactly at the partition
    /// center, where circular orientation would be undefined. Equal-angle taps
    /// are stably ordered by their original array position.
    public init(bounds: CGRect, taps: [PinballSeatTap]) throws {
        try PinballValidation.validate(bounds: bounds)
        guard (2...12).contains(taps.count) else {
            throw PinballMathError.invalidSeatCount(taps.count)
        }

        var seenIDs = Set<Int>()
        let map = RectangleRadialAreaMap(bounds: bounds)
        let centerTolerance = max(bounds.width, bounds.height) * 1e-14

        struct OrientedTap {
            let tap: PinballSeatTap
            let originalIndex: Int
            let phase: CGFloat
        }

        var oriented: [OrientedTap] = []
        oriented.reserveCapacity(taps.count)
        for (index, tap) in taps.enumerated() {
            guard seenIDs.insert(tap.seatID).inserted else {
                throw PinballMathError.duplicateSeatID(tap.seatID)
            }
            try PinballValidation.validate(point: tap.point)
            guard PinballValidation.contains(tap.point, in: bounds) else {
                throw PinballMathError.pointOutsideBounds
            }

            let dx = tap.point.x - map.center.x
            let dy = tap.point.y - map.center.y
            guard hypot(dx, dy) > centerTolerance else {
                throw PinballMathError.tapAtPartitionCenter(tap.seatID)
            }
            oriented.append(
                OrientedTap(
                    tap: tap,
                    originalIndex: index,
                    phase: map.phase(for: tap.point)
                )
            )
        }

        oriented.sort {
            if $0.phase == $1.phase { return $0.originalIndex < $1.originalIndex }
            return $0.phase < $1.phase
        }

        let seatCount = CGFloat(oriented.count)

        // Fit one cyclic offset between equal-area region centers and taps. Each
        // raw offset is unwrapped near the first before averaging so a phase just
        // below 1 remains adjacent to a phase just above 0.
        var offsets: [CGFloat] = []
        offsets.reserveCapacity(oriented.count)
        let reference = oriented[0].phase - (0.5 / seatCount)
        for (index, item) in oriented.enumerated() {
            let targetCenter = (CGFloat(index) + 0.5) / seatCount
            var offset = item.phase - targetCenter
            while offset - reference > 0.5 { offset -= 1 }
            while offset - reference < -0.5 { offset += 1 }
            offsets.append(offset)
        }
        let fittedOrigin = RectangleRadialAreaMap.normalizePhase(
            offsets.reduce(0, +) / seatCount
        )

        let regionArea = bounds.width * bounds.height / seatCount
        var builtRegions: [PinballRadialRegion] = []
        builtRegions.reserveCapacity(oriented.count)
        for (index, item) in oriented.enumerated() {
            let start = RectangleRadialAreaMap.normalizePhase(
                fittedOrigin + CGFloat(index) / seatCount
            )
            let end = RectangleRadialAreaMap.normalizePhase(
                fittedOrigin + CGFloat(index + 1) / seatCount
            )
            builtRegions.append(
                PinballRadialRegion(
                    seat: item.tap,
                    clockwiseIndex: index,
                    startPhase: start,
                    endPhase: end,
                    startBoundaryPoint: map.boundaryPoint(atPhase: start),
                    endBoundaryPoint: map.boundaryPoint(atPhase: end),
                    area: regionArea
                )
            )
        }

        self.bounds = bounds
        self.center = map.center
        self.regions = builtRegions
        self.originPhase = fittedOrigin
        self.areaMap = map
    }

    /// Region containing an actual playfield point.
    ///
    /// Regions are half-open in clockwise order: a point exactly on a boundary
    /// belongs to the region beginning at that boundary. The exact center—a
    /// measure-zero endpoint where every radial boundary meets—uses the phase of
    /// the rightward ray, giving a deterministic result without another draw.
    public func region(containing point: CGPoint) throws -> PinballRadialRegion {
        try PinballValidation.validate(point: point)
        guard PinballValidation.contains(point, in: bounds) else {
            throw PinballMathError.pointOutsideBounds
        }

        let pointPhase = areaMap.phase(for: point)
        let relative = RectangleRadialAreaMap.normalizePhase(pointPhase - originPhase)
        let scaled = relative * CGFloat(regions.count)
        let index = min(Int(floor(scaled)), regions.count - 1)
        return regions[index]
    }

    public func seatID(containing point: CGPoint) throws -> Int {
        try region(containing: point).seat.seatID
    }

    /// Clockwise seat order, retaining each caller-supplied stable ID.
    public var clockwiseSeatIDs: [Int] {
        regions.map(\.seat.seatID)
    }
}

/// Exact conversion between ray angle and swept rectangle area.
///
/// Starting at the right-edge midpoint and moving clockwise, the ray endpoint
/// travels around five straight boundary pieces: half of the right edge, the
/// bottom, the left, the top, then the other half of the right edge. The signed
/// triangle area `cross(p, q) / 2` is linear along each piece, so both conversion
/// directions are analytic—no polygon clipping, lookup table, or iteration.
private struct RectangleRadialAreaMap: Equatable, Sendable {
    let bounds: CGRect
    let center: CGPoint
    let halfWidth: CGFloat
    let halfHeight: CGFloat
    let quarterUnit: CGFloat
    let totalArea: CGFloat

    init(bounds: CGRect) {
        self.bounds = bounds
        self.center = CGPoint(x: bounds.midX, y: bounds.midY)
        self.halfWidth = bounds.width / 2
        self.halfHeight = bounds.height / 2
        self.quarterUnit = (bounds.width / 2) * (bounds.height / 2)
        self.totalArea = bounds.width * bounds.height
    }

    func phase(for point: CGPoint) -> CGFloat {
        let vector = CGVector(dx: point.x - center.x, dy: point.y - center.y)
        guard vector.dx != 0 || vector.dy != 0 else { return 0 }

        let xScale = vector.dx == 0 ? CGFloat.infinity : halfWidth / abs(vector.dx)
        let yScale = vector.dy == 0 ? CGFloat.infinity : halfHeight / abs(vector.dy)
        let scale = min(xScale, yScale)
        let x = vector.dx * scale
        let y = vector.dy * scale
        let tolerance = max(halfWidth, halfHeight) * 1e-12

        let sweptArea: CGFloat
        if abs(x - halfWidth) <= tolerance, y >= 0 {
            // Right midpoint -> bottom-right.
            sweptArea = 0.5 * halfWidth * y
        } else if abs(y - halfHeight) <= tolerance {
            // Bottom-right -> bottom-left.
            sweptArea = 0.5 * quarterUnit + 0.5 * halfHeight * (halfWidth - x)
        } else if abs(x + halfWidth) <= tolerance {
            // Bottom-left -> top-left.
            sweptArea = 1.5 * quarterUnit + 0.5 * halfWidth * (halfHeight - y)
        } else if abs(y + halfHeight) <= tolerance {
            // Top-left -> top-right.
            sweptArea = 2.5 * quarterUnit + 0.5 * halfHeight * (halfWidth + x)
        } else {
            // Top-right -> right midpoint.
            sweptArea = 3.5 * quarterUnit + 0.5 * halfWidth * (halfHeight + y)
        }

        return Self.normalizePhase(sweptArea / totalArea)
    }

    func boundaryPoint(atPhase phase: CGFloat) -> CGPoint {
        let area = Self.normalizePhase(phase) * totalArea
        let local: CGPoint

        if area < 0.5 * quarterUnit {
            let fraction = area / (0.5 * quarterUnit)
            local = CGPoint(x: halfWidth, y: halfHeight * fraction)
        } else if area < 1.5 * quarterUnit {
            let fraction = (area - 0.5 * quarterUnit) / quarterUnit
            local = CGPoint(x: halfWidth - 2 * halfWidth * fraction, y: halfHeight)
        } else if area < 2.5 * quarterUnit {
            let fraction = (area - 1.5 * quarterUnit) / quarterUnit
            local = CGPoint(x: -halfWidth, y: halfHeight - 2 * halfHeight * fraction)
        } else if area < 3.5 * quarterUnit {
            let fraction = (area - 2.5 * quarterUnit) / quarterUnit
            local = CGPoint(x: -halfWidth + 2 * halfWidth * fraction, y: -halfHeight)
        } else {
            let fraction = (area - 3.5 * quarterUnit) / (0.5 * quarterUnit)
            local = CGPoint(x: halfWidth, y: -halfHeight + halfHeight * fraction)
        }

        return CGPoint(x: center.x + local.x, y: center.y + local.y)
    }

    static func normalizePhase(_ phase: CGFloat) -> CGFloat {
        var normalized = phase.truncatingRemainder(dividingBy: 1)
        if normalized < 0 { normalized += 1 }
        // Avoid returning 1 because regions are represented as half-open phases.
        return normalized == 1 ? 0 : normalized
    }
}
