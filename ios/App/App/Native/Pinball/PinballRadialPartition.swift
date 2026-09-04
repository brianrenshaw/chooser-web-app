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
    /// Exact equal-area phase halfway between this region's boundaries.
    public let centerPhase: CGFloat
    public let startBoundaryPoint: CGPoint
    public let endBoundaryPoint: CGPoint
    /// Perimeter point reached by the region's center ray.
    public let centerBoundaryPoint: CGPoint
    public let area: CGFloat
}

/// One settled, geometry-safe position for a numbered Pinball seat token.
public struct PinballSeatTokenPlacement: Equatable, Sendable {
    public let seatID: Int
    public let center: CGPoint

    public init(seatID: Int, center: CGPoint) {
        self.seatID = seatID
        self.center = center
    }
}

/// A single token diameter and one safe center per equal-area seat region.
///
/// Pinball uses one uniform diameter so a seat never looks more important merely
/// because its wedge has a more favorable aspect ratio. The diameter describes
/// the authored face; `maximumRenderedScale` records the largest scale the face
/// can reach when its seat wins.
public struct PinballSeatTokenLayout: Equatable, Sendable {
    public let tokenDiameter: CGFloat
    public let maximumRenderedScale: CGFloat
    public let placements: [PinballSeatTokenPlacement]

    public init(
        tokenDiameter: CGFloat,
        maximumRenderedScale: CGFloat,
        placements: [PinballSeatTokenPlacement]
    ) {
        self.tokenDiameter = tokenDiameter
        self.maximumRenderedScale = maximumRenderedScale
        self.placements = placements
    }

    public func center(forSeatID seatID: Int) -> CGPoint? {
        placements.first(where: { $0.seatID == seatID })?.center
    }
}

/// Production clearances shared by the renderer and geometry tests.
///
/// The partition itself is already inset far enough to contain the authored
/// contact shadow. These values keep the *scaled token face* another six points
/// clear of both that inset edge and the two divider centerlines.
public struct PinballSeatTokenLayoutPolicy: Equatable, Sendable {
    public let preferredRadialFraction: CGFloat
    public let edgeClearance: CGFloat
    public let dividerClearance: CGFloat
    public let maximumRenderedScale: CGFloat

    public init(
        preferredRadialFraction: CGFloat,
        edgeClearance: CGFloat,
        dividerClearance: CGFloat,
        maximumRenderedScale: CGFloat
    ) {
        self.preferredRadialFraction = preferredRadialFraction
        self.edgeClearance = edgeClearance
        self.dividerClearance = dividerClearance
        self.maximumRenderedScale = maximumRenderedScale
    }

    public static let production = PinballSeatTokenLayoutPolicy(
        preferredRadialFraction: 0.82,
        edgeClearance: 6,
        dividerClearance: 6,
        maximumRenderedScale: 1.06
    )

    /// Clearances are lengths and scale with the board. The radial fraction and
    /// the rendered scale are ratios and must not.
    public func scaled(by scale: CGFloat) -> PinballSeatTokenLayoutPolicy {
        let s = max(1, scale)
        guard s != 1 else { return self }
        return PinballSeatTokenLayoutPolicy(
            preferredRadialFraction: preferredRadialFraction,
            edgeClearance: edgeClearance * s,
            dividerClearance: dividerClearance * s,
            maximumRenderedScale: maximumRenderedScale
        )
    }
}

/// The authored Pinball chit size before equal-area geometry applies a denser
/// uniform fit. Kept alongside the layout policy so production and tests use
/// exactly the same sizing path in every orientation.
public enum PinballSeatTokenSizing {
    /// Seat sizing at scale 1. `PinballBoardMetrics` evaluates this at the
    /// board's reference size and multiplies, so the authored expression —
    /// including which of its clamps binds — is always the phone expression.
    public static func referencePreferredDiameter(
        in playfieldSize: CGSize,
        seatCount: Int
    ) -> CGFloat {
        guard playfieldSize.width > 0, playfieldSize.height > 0 else { return 0 }
        let shortEdge = min(playfieldSize.width, playfieldSize.height)
        let isLandscape = playfieldSize.width > playfieldSize.height
        let crowdingReduction = CGFloat(max(0, seatCount - 6)) * 1.5
        let cap: CGFloat = isLandscape ? 76 : 88
        let floor: CGFloat = isLandscape ? 68 : 76
        return max(
            52,
            min(cap, max(floor, shortEdge * (isLandscape ? 0.24 : 0.23)))
                - crowdingReduction
        )
    }

    /// Seat sizing for a real board, scaled for its size.
    public static func preferredDiameter(
        in playfieldSize: CGSize,
        seatCount: Int
    ) -> CGFloat {
        PinballBoardMetrics(playfieldSize: playfieldSize)
            .preferredSeatDiameter(seatCount: seatCount)
    }

    public static func layout(
        for partition: PinballRadialPartition,
        in playfieldSize: CGSize,
        policy: PinballSeatTokenLayoutPolicy? = nil
    ) -> PinballSeatTokenLayout? {
        let metrics = PinballBoardMetrics(playfieldSize: playfieldSize)
        return partition.seatTokenLayout(
            preferredDiameter: metrics.preferredSeatDiameter(
                seatCount: partition.regions.count
            ),
            policy: policy ?? metrics.seatLayoutPolicy
        )
    }
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
            let centerPhase = RectangleRadialAreaMap.normalizePhase(
                fittedOrigin + (CGFloat(index) + 0.5) / seatCount
            )
            builtRegions.append(
                PinballRadialRegion(
                    seat: item.tap,
                    clockwiseIndex: index,
                    startPhase: start,
                    endPhase: end,
                    centerPhase: centerPhase,
                    startBoundaryPoint: map.boundaryPoint(atPhase: start),
                    endBoundaryPoint: map.boundaryPoint(atPhase: end),
                    centerBoundaryPoint: map.boundaryPoint(atPhase: centerPhase),
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

    /// Finds the largest uniform diameter no greater than `preferredDiameter`
    /// whose fully scaled face fits every region. Each center stays on a stable
    /// interior ray: the exact equal-area center for two seats and the angular
    /// bisector for denser groups, where it balances both divider gaps. It moves
    /// outward only as much as needed for divider clearance and inward whenever
    /// the edge requires.
    ///
    /// Dense, shallow landscape boards can make a requested diameter
    /// geometrically impossible. In that case this returns the largest fitting
    /// diameter instead of moving a token with an unrelated rectangular clamp,
    /// which could push it back across a divider.
    public func seatTokenLayout(
        preferredDiameter: CGFloat,
        policy: PinballSeatTokenLayoutPolicy = .production
    ) -> PinballSeatTokenLayout? {
        guard preferredDiameter.isFinite,
              preferredDiameter > 0,
              policy.preferredRadialFraction.isFinite,
              policy.edgeClearance.isFinite,
              policy.dividerClearance.isFinite,
              policy.maximumRenderedScale.isFinite,
              policy.maximumRenderedScale > 0 else {
            return nil
        }

        let maximumDiameter = max(0, preferredDiameter)
        if let placements = seatTokenPlacements(
            forDiameter: maximumDiameter,
            policy: policy
        ) {
            return PinballSeatTokenLayout(
                tokenDiameter: maximumDiameter,
                maximumRenderedScale: policy.maximumRenderedScale,
                placements: placements
            )
        }

        // Feasibility is monotonic with diameter: a smaller circular face has
        // no stricter edge or divider requirement. Binary search therefore
        // retains the largest readable result while keeping the proof simple.
        guard seatTokenPlacements(forDiameter: 0, policy: policy) != nil else {
            return nil
        }
        var lower: CGFloat = 0
        var upper = maximumDiameter
        for _ in 0..<52 {
            let candidate = (lower + upper) / 2
            if seatTokenPlacements(forDiameter: candidate, policy: policy) != nil {
                lower = candidate
            } else {
                upper = candidate
            }
        }

        guard lower > 0,
              let placements = seatTokenPlacements(forDiameter: lower, policy: policy) else {
            return nil
        }
        return PinballSeatTokenLayout(
            tokenDiameter: lower,
            maximumRenderedScale: policy.maximumRenderedScale,
            placements: placements
        )
    }

    /// Stable display anchor centered inside one seat's equal-area region.
    ///
    /// The preferred position is 82% of the way from the playfield center to
    /// the region's center-ray boundary. Dense layouts may move farther outward
    /// to clear both divider rays, while large tokens move inward enough to keep
    /// their complete face inside the playfield. If both clearances cannot be
    /// satisfied simultaneously, edge clearance wins; callers can then reduce
    /// the token diameter while retaining the same deterministic anchor.
    public func tokenAnchor(
        forSeatID seatID: Int,
        tokenDiameter: CGFloat,
        preferredRadialFraction: CGFloat = 0.82,
        edgePadding: CGFloat = 6,
        dividerPadding: CGFloat = 4
    ) -> CGPoint? {
        guard let region = regions.first(where: { $0.seat.seatID == seatID }),
              tokenDiameter.isFinite,
              preferredRadialFraction.isFinite,
              edgePadding.isFinite,
              dividerPadding.isFinite else {
            return nil
        }

        let ray = CGVector(
            dx: region.centerBoundaryPoint.x - center.x,
            dy: region.centerBoundaryPoint.y - center.y
        )
        let rayLength = hypot(ray.dx, ray.dy)
        guard rayLength > 0, rayLength.isFinite else { return nil }
        let direction = CGVector(dx: ray.dx / rayLength, dy: ray.dy / rayLength)

        let tokenRadius = max(0, tokenDiameter / 2)
        let safeEdgePadding = max(0, edgePadding)
        let inset = tokenRadius + safeEdgePadding
        let maximumDistance = maximumRayDistance(
            from: center,
            direction: direction,
            inside: bounds.insetBy(dx: inset, dy: inset)
        ) ?? 0

        let preferredDistance = rayLength * min(1, max(0, preferredRadialFraction))
        let dividerClearance = tokenRadius + max(0, dividerPadding)
        let requiredDividerDistance = dividerClearance / max(
            0.000_001,
            min(
                sineBetweenCenterRay(
                    direction,
                    andBoundaryPoint: region.startBoundaryPoint
                ),
                sineBetweenCenterRay(
                    direction,
                    andBoundaryPoint: region.endBoundaryPoint
                )
            )
        )

        let distance = min(
            maximumDistance,
            max(preferredDistance, requiredDividerDistance)
        )
        return CGPoint(
            x: center.x + direction.dx * distance,
            y: center.y + direction.dy * distance
        )
    }

    private func seatTokenPlacements(
        forDiameter tokenDiameter: CGFloat,
        policy: PinballSeatTokenLayoutPolicy
    ) -> [PinballSeatTokenPlacement]? {
        let faceRadius = max(0, tokenDiameter / 2) * policy.maximumRenderedScale
        let safeEdgeClearance = max(0, policy.edgeClearance)
        let safeDividerClearance = max(0, policy.dividerClearance)
        let edgeInset = faceRadius + safeEdgeClearance
        let safeBounds = bounds.insetBy(dx: edgeInset, dy: edgeInset)
        guard !safeBounds.isNull,
              !safeBounds.isEmpty,
              safeBounds.contains(center) else {
            return nil
        }

        var placements: [PinballSeatTokenPlacement] = []
        placements.reserveCapacity(regions.count)
        for region in regions {
            guard let direction = tokenDisplayDirection(for: region),
                  let rayLength = maximumRayDistance(
                    from: center,
                    direction: direction,
                    inside: bounds
                  ) else {
                return nil
            }
            let minimumSine = min(
                sineBetweenCenterRay(direction, andBoundaryPoint: region.startBoundaryPoint),
                sineBetweenCenterRay(direction, andBoundaryPoint: region.endBoundaryPoint)
            )
            guard minimumSine > 0, minimumSine.isFinite,
                  let maximumDistance = maximumRayDistance(
                    from: center,
                    direction: direction,
                    inside: safeBounds
                  ) else {
                return nil
            }

            let minimumDistance = (faceRadius + safeDividerClearance) / minimumSine
            guard minimumDistance <= maximumDistance + 1e-9 else { return nil }
            let preferredDistance = rayLength * min(
                1,
                max(0, policy.preferredRadialFraction)
            )
            let distance = min(maximumDistance, max(preferredDistance, minimumDistance))
            let tokenCenter = CGPoint(
                x: center.x + direction.dx * distance,
                y: center.y + direction.dy * distance
            )
            placements.append(
                PinballSeatTokenPlacement(
                    seatID: region.seat.seatID,
                    center: tokenCenter
                )
            )
        }
        return placements
    }

    /// The area-midpoint ray is the right ownership primitive, but on a very
    /// wide rectangle it is not necessarily the visual angle halfway between
    /// the two dividers. Tokens use that angular bisector so the two visible
    /// gaps are balanced and the available wedge width is not needlessly lost.
    /// The two-seat case has opposite boundaries, so its exact area-center ray
    /// remains the deterministic half-plane bisector.
    private func tokenDisplayDirection(for region: PinballRadialRegion) -> CGVector? {
        let centerRay = CGVector(
            dx: region.centerBoundaryPoint.x - center.x,
            dy: region.centerBoundaryPoint.y - center.y
        )
        let centerLength = hypot(centerRay.dx, centerRay.dy)
        guard centerLength > 0, centerLength.isFinite else { return nil }
        let centerDirection = CGVector(
            dx: centerRay.dx / centerLength,
            dy: centerRay.dy / centerLength
        )
        guard regions.count > 2,
              let start = unitDirection(to: region.startBoundaryPoint),
              let end = unitDirection(to: region.endBoundaryPoint) else {
            return centerDirection
        }

        var bisector = CGVector(dx: start.dx + end.dx, dy: start.dy + end.dy)
        let length = hypot(bisector.dx, bisector.dy)
        guard length > 1e-9, length.isFinite else { return centerDirection }
        bisector = CGVector(dx: bisector.dx / length, dy: bisector.dy / length)
        if bisector.dx * centerDirection.dx + bisector.dy * centerDirection.dy < 0 {
            bisector = CGVector(dx: -bisector.dx, dy: -bisector.dy)
        }
        return bisector
    }

    private func unitDirection(to point: CGPoint) -> CGVector? {
        let vector = CGVector(dx: point.x - center.x, dy: point.y - center.y)
        let length = hypot(vector.dx, vector.dy)
        guard length > 0, length.isFinite else { return nil }
        return CGVector(dx: vector.dx / length, dy: vector.dy / length)
    }

    private func sineBetweenCenterRay(
        _ centerDirection: CGVector,
        andBoundaryPoint boundaryPoint: CGPoint
    ) -> CGFloat {
        let boundary = CGVector(
            dx: boundaryPoint.x - center.x,
            dy: boundaryPoint.y - center.y
        )
        let length = hypot(boundary.dx, boundary.dy)
        guard length > 0 else { return 0 }
        let unit = CGVector(dx: boundary.dx / length, dy: boundary.dy / length)
        return abs(centerDirection.dx * unit.dy - centerDirection.dy * unit.dx)
    }

    private func maximumRayDistance(
        from origin: CGPoint,
        direction: CGVector,
        inside rectangle: CGRect
    ) -> CGFloat? {
        guard !rectangle.isNull,
              !rectangle.isEmpty,
              rectangle.contains(origin) else {
            return nil
        }

        var distances: [CGFloat] = []
        if direction.dx > 0 {
            distances.append((rectangle.maxX - origin.x) / direction.dx)
        } else if direction.dx < 0 {
            distances.append((rectangle.minX - origin.x) / direction.dx)
        }
        if direction.dy > 0 {
            distances.append((rectangle.maxY - origin.y) / direction.dy)
        } else if direction.dy < 0 {
            distances.append((rectangle.minY - origin.y) / direction.dy)
        }
        return distances.filter { $0 >= 0 && $0.isFinite }.min()
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
