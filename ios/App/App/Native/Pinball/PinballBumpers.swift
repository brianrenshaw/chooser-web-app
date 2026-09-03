import CoreGraphics
import Foundation

/// One circular obstacle centred on a seat's drawn ring.
public struct PinballBumper: Equatable, Sendable {
    public let seatID: Int
    public let center: CGPoint
    /// The drawn ring's radius. Collision uses this inflated by the ball radius.
    public let radius: CGFloat

    public init(seatID: Int, center: CGPoint, radius: CGFloat) {
        self.seatID = seatID
        self.center = center
        self.radius = radius
    }
}

/// The set of seat rings a ball can bounce off during a round.
///
/// The ball is modelled as a dimensionless point tested against each bumper's
/// **Minkowski-inflated** radius (`radius + ballRadius`), which is the standard
/// way to keep a finite-size ball exact without integrating its body.
///
/// Overlapping inflated discs are explicitly allowed. A merged cluster is still
/// correct physics: the marcher always takes the nearest intersection, so the
/// ball simply treats the union as one convex obstacle. The only consequence is
/// that it cannot squeeze between those two rings, and that is harmless here
/// because regions are radial wedges meeting at the playfield centre — every
/// seat still owns area the ball can reach.
public struct PinballBumperField: Equatable, Sendable {
    public let bumpers: [PinballBumper]
    public let ballRadius: CGFloat

    public static let empty = PinballBumperField(bumpers: [], ballRadius: 0)

    public init(bumpers: [PinballBumper], ballRadius: CGFloat) {
        self.bumpers = bumpers
        self.ballRadius = ballRadius
    }

    public var isEmpty: Bool { bumpers.isEmpty }

    public func collisionRadius(for bumper: PinballBumper) -> CGFloat {
        bumper.radius + ballRadius
    }

    /// True when the point lies inside a bumper's collision disc.
    ///
    /// Used to ignore a disc the ball has somehow started inside, which can
    /// happen when a release point is clamped next to a seat. Ignoring is
    /// deliberate: reflecting off the inside of a circle would trap the ball.
    public func containsInCollisionDisc(_ point: CGPoint) -> Bool {
        bumpers.contains { bumper in
            let radius = collisionRadius(for: bumper)
            return hypot(point.x - bumper.center.x, point.y - bumper.center.y) < radius
        }
    }
}

/// What a trajectory vertex actually is.
///
/// Vertex kinds are recorded at construction rather than inferred later. The
/// replay scene used to derive wall identity from a direction-component sign
/// flip, which a circular bounce can defeat in both directions: a glancing hit
/// preserves both signs and would be dropped, and a steep hit looks exactly like
/// a wall and would draw its impact mark snapped to the playfield border, far
/// from the real contact point.
public enum PinballPathVertexKind: Equatable, Sendable {
    case wall(normal: CGVector)
    case bumper(seatID: Int, normal: CGVector)

    public var bumperSeatID: Int? {
        if case .bumper(let seatID, _) = self { return seatID }
        return nil
    }

    public var normal: CGVector {
        switch self {
        case .wall(let normal): normal
        case .bumper(_, let normal): normal
        }
    }
}

public enum PinballBumperGeometry {
    /// Nearest forward intersection with a bumper's collision disc.
    ///
    /// Closed form, not stepped: with a unit direction the quadratic reduces to
    /// `t² + 2(d·(p−c))t + (|p−c|² − R²) = 0`.
    static func nearestBumperHit(
        from start: CGPoint,
        direction: CGVector,
        field: PinballBumperField,
        maximumDistance: CGFloat,
        minimumDistance: CGFloat
    ) -> (distance: CGFloat, bumper: PinballBumper, normal: CGVector)? {
        var best: (distance: CGFloat, bumper: PinballBumper, normal: CGVector)?

        for bumper in field.bumpers {
            let radius = field.collisionRadius(for: bumper)
            let offsetX = start.x - bumper.center.x
            let offsetY = start.y - bumper.center.y
            let distanceToCenter = hypot(offsetX, offsetY)

            // Already inside: ignore this disc rather than reflecting off its
            // interior, which would trap the ball.
            if distanceToCenter < radius { continue }

            let halfB = direction.dx * offsetX + direction.dy * offsetY
            let c = distanceToCenter * distanceToCenter - radius * radius
            let discriminant = halfB * halfB - c
            guard discriminant > 0 else { continue }

            let root = sqrt(discriminant)
            // Near root first; it is the entry point of the disc.
            let candidates = [-halfB - root, -halfB + root]
            guard let hit = candidates.first(where: { $0 > minimumDistance && $0 < maximumDistance })
            else { continue }

            if best == nil || hit < best!.distance {
                let contactX = start.x + direction.dx * hit
                let contactY = start.y + direction.dy * hit
                var nx = contactX - bumper.center.x
                var ny = contactY - bumper.center.y
                let magnitude = hypot(nx, ny)
                guard magnitude > 0 else { continue }
                nx /= magnitude
                ny /= magnitude
                best = (hit, bumper, CGVector(dx: nx, dy: ny))
            }
        }

        return best
    }

    /// Specular reflection about a unit normal: `r = i - 2(i·n)n`.
    static func reflect(_ direction: CGVector, about normal: CGVector) -> CGVector {
        let dot = direction.dx * normal.dx + direction.dy * normal.dy
        return CGVector(
            dx: direction.dx - 2 * dot * normal.dx,
            dy: direction.dy - 2 * dot * normal.dy
        )
    }

    /// Forward distance to the nearest bounding wall, with its inward normal.
    static func nearestWallHit(
        from start: CGPoint,
        direction: CGVector,
        bounds: CGRect,
        maximumDistance: CGFloat,
        minimumDistance: CGFloat
    ) -> (distance: CGFloat, normal: CGVector)? {
        var distanceX = CGFloat.infinity
        var normalX = CGVector.zero
        if direction.dx > 0 {
            distanceX = (bounds.maxX - start.x) / direction.dx
            normalX = CGVector(dx: -1, dy: 0)
        } else if direction.dx < 0 {
            distanceX = (bounds.minX - start.x) / direction.dx
            normalX = CGVector(dx: 1, dy: 0)
        }

        var distanceY = CGFloat.infinity
        var normalY = CGVector.zero
        if direction.dy > 0 {
            distanceY = (bounds.maxY - start.y) / direction.dy
            normalY = CGVector(dx: 0, dy: -1)
        } else if direction.dy < 0 {
            distanceY = (bounds.minY - start.y) / direction.dy
            normalY = CGVector(dx: 0, dy: 1)
        }

        let cornerTolerance: CGFloat = 1e-9
        let nearest = min(distanceX, distanceY)
        guard nearest.isFinite, nearest > minimumDistance, nearest < maximumDistance else {
            return nil
        }

        // A corner reverses both components in one vertex, matching how the
        // unfolded rectangle solver merges coincident events.
        if abs(distanceX - distanceY) <= cornerTolerance * max(1, nearest) {
            let combined = CGVector(dx: normalX.dx, dy: normalY.dy)
            let magnitude = hypot(combined.dx, combined.dy)
            guard magnitude > 0 else { return nil }
            return (nearest, CGVector(dx: combined.dx / magnitude, dy: combined.dy / magnitude))
        }

        return distanceX < distanceY ? (distanceX, normalX) : (distanceY, normalY)
    }
}

public extension PinballBumperField {
    /// Builds the field from a settled seat token layout.
    ///
    /// Both the drawn chit and its bumper come from this one layout, so the
    /// physics circle can never disagree with the artwork the player sees.
    init(from layout: PinballSeatTokenLayout, ballRadius: CGFloat) {
        self.init(
            bumpers: layout.placements.map { placement in
                PinballBumper(
                    seatID: placement.seatID,
                    center: placement.center,
                    radius: layout.tokenDiameter / 2
                )
            },
            ballRadius: ballRadius
        )
    }
}

public extension PinballSeatTokenSizing {
    /// Gap the ball needs between two bumpers to have a way through.
    static let bumperPassageClearance: CGFloat = 8
    /// Below this the seat numerals stop being readable, so shrinking stops.
    static let bumperReadableFloorDiameter: CGFloat = 34

    /// The seat token layout, shrunk when necessary so the ball can pass
    /// between adjacent bumpers.
    ///
    /// Feasibility is monotonic in diameter — a smaller face gives a strictly
    /// smaller inflated disc — so a binary search retains the largest readable
    /// layout that still leaves a passage, exactly as `seatTokenLayout` argues
    /// for its own edge and divider clearances.
    ///
    /// Below the readable floor the search gives up and lets the inflated discs
    /// merge. That is deliberate and safe: a merged cluster is still correct
    /// physics because the marcher takes the nearest intersection, so the ball
    /// treats the union as one convex obstacle. It simply cannot squeeze
    /// between those two rings, which costs nothing because regions are radial
    /// wedges meeting at the centre and every seat still owns reachable area.
    static func bumperAwareLayout(
        for partition: PinballRadialPartition,
        in playfieldSize: CGSize,
        ballRadius: CGFloat,
        policy: PinballSeatTokenLayoutPolicy = .production
    ) -> PinballSeatTokenLayout? {
        let preferred = preferredDiameter(
            in: playfieldSize,
            seatCount: partition.regions.count
        )
        guard let unconstrained = partition.seatTokenLayout(
            preferredDiameter: preferred,
            policy: policy
        ) else { return nil }

        if bumpersLeaveAPassage(unconstrained, ballRadius: ballRadius) {
            return unconstrained
        }

        var low = bumperReadableFloorDiameter
        var high = max(bumperReadableFloorDiameter, preferred)
        var chosen: PinballSeatTokenLayout?
        for _ in 0..<24 {
            let mid = (low + high) / 2
            if let candidate = partition.seatTokenLayout(preferredDiameter: mid, policy: policy),
               bumpersLeaveAPassage(candidate, ballRadius: ballRadius) {
                chosen = candidate
                low = mid
            } else {
                high = mid
            }
        }

        return chosen
            ?? partition.seatTokenLayout(
                preferredDiameter: bumperReadableFloorDiameter,
                policy: policy
            )
            ?? unconstrained
    }

    /// True when every pair of inflated bumper discs is far enough apart for the
    /// ball to travel between them.
    static func bumpersLeaveAPassage(
        _ layout: PinballSeatTokenLayout,
        ballRadius: CGFloat
    ) -> Bool {
        let collisionRadius = layout.tokenDiameter / 2 + ballRadius
        let required = 2 * collisionRadius + bumperPassageClearance
        let centers = layout.placements.map(\.center)
        guard centers.count > 1 else { return true }
        for first in 0..<(centers.count - 1) {
            for second in (first + 1)..<centers.count {
                let separation = hypot(
                    centers[first].x - centers[second].x,
                    centers[first].y - centers[second].y
                )
                if separation < required { return false }
            }
        }
        return true
    }
}
