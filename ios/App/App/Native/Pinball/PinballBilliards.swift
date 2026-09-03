import CoreGraphics
import Foundation

/// Immutable launch conditions for a reflected-rectangle trajectory.
public struct PinballLaunch: Equatable, Sendable {
    public let start: CGPoint
    public let direction: CGVector
    public let distance: CGFloat

    /// Creates a launch and normalizes `direction` to unit length.
    ///
    /// Normalization makes `distance` the literal geometric path length, so the
    /// same launch remains meaningful in portrait, landscape, and unit tests.
    public init(start: CGPoint, direction: CGVector, distance: CGFloat) throws {
        try PinballValidation.validate(point: start)
        guard direction.dx.isFinite, direction.dy.isFinite, distance.isFinite else {
            throw PinballMathError.nonFiniteValue
        }
        guard distance >= 0 else {
            throw PinballMathError.invalidDistance
        }

        let magnitude = hypot(direction.dx, direction.dy)
        guard magnitude > 0, magnitude.isFinite else {
            throw PinballMathError.zeroDirection
        }

        self.start = start
        self.direction = CGVector(dx: direction.dx / magnitude, dy: direction.dy / magnitude)
        self.distance = distance
    }
}

/// One straight portion of a reflected path.
///
/// `startDistance` and `endDistance` are distances along the complete billiards
/// path, not animation times. A caller can combine them with
/// ``PinballDecelerationCurve`` to animate without numerical physics stepping.
public struct PinballPathSegment: Equatable, Sendable {
    public let start: CGPoint
    public let end: CGPoint
    public let startDistance: CGFloat
    public let endDistance: CGFloat

    public var length: CGFloat { endDistance - startDistance }
}

/// Exact piecewise-linear analytic motion inside a rectangle, optionally
/// containing circular bumpers.
///
/// ``PinballBilliards`` produces a single-direction trajectory whose internal
/// vertices are all genuine specular wall events. A user-directed fair round is
/// left entirely specular when its natural endpoint agrees with the uniform
/// winner. Only when they differ may it compose an exact first leg with one
/// separately solved billiards suffix; that sole non-specular wall impulse is
/// tagged by
/// ``PinballRoundResult/fairnessDeflectorVertexIndex``. Playback never adds any
/// untagged splice or steering.
public struct PinballTrajectory: Equatable, Sendable {
    public let bounds: CGRect
    public let launch: PinballLaunch
    public let segments: [PinballPathSegment]
    public let endPoint: CGPoint
    /// What each internal vertex is, parallel to `segments.dropLast()`.
    ///
    /// Empty for a bumper-free round, where every internal vertex is a wall by
    /// construction. Populated whenever a bumper field is in play so playback
    /// never has to guess a vertex's identity from its direction change.
    public let vertexKinds: [PinballPathVertexKind]

    public init(
        bounds: CGRect,
        launch: PinballLaunch,
        segments: [PinballPathSegment],
        endPoint: CGPoint,
        vertexKinds: [PinballPathVertexKind] = []
    ) {
        self.bounds = bounds
        self.launch = launch
        self.segments = segments
        self.endPoint = endPoint
        self.vertexKinds = vertexKinds
    }

    /// All drawable vertices, including start and final endpoint.
    public var points: [CGPoint] {
        guard let first = segments.first else { return [launch.start] }
        return [first.start] + segments.map(\.end)
    }

    /// The vertex kind at an index into `points`, if it is a recorded internal
    /// vertex. `points[0]` is the launch and the last point is the endpoint, so
    /// only indices `1..<points.count-1` can have a kind.
    public func vertexKind(atPointIndex index: Int) -> PinballPathVertexKind? {
        let internalIndex = index - 1
        guard internalIndex >= 0, internalIndex < vertexKinds.count else { return nil }
        return vertexKinds[internalIndex]
    }
}

/// Analytic billiards inside an axis-aligned rectangle.
///
/// With no bumpers the implementation uses the standard "unfolded room"
/// construction. Instead of integrating velocity in tiny time steps, it extends
/// a straight ray across mirrored copies of the rectangle. A triangle-wave fold
/// maps every point on that ray back into the original bounds. This yields a
/// stable endpoint and exact wall events regardless of frame rate or device
/// orientation, and computes the endpoint in O(1).
///
/// A circle has no reflection lattice, so a bumper field cannot use the fold.
/// ``trajectory(for:in:bumpers:maximumSegments:)`` instead marches
/// segment by segment, taking the nearer of a closed-form wall crossing and a
/// closed-form ray/circle intersection. That is still analytic and still frame
/// rate independent — there is no timestep, no force integration, and no
/// mutable physics body — but the endpoint costs O(bounces) rather than O(1).
public enum PinballBilliards {
    /// Returns only the final folded point and never allocates reflection data.
    /// This remains O(1), even for a very long path.
    public static func endPoint(
        for launch: PinballLaunch,
        in bounds: CGRect
    ) throws -> CGPoint {
        try validate(launch: launch, bounds: bounds)
        return foldedPoint(
            atDistance: launch.distance,
            launch: launch,
            bounds: bounds
        )
    }

    /// Builds every straight segment of the reflected path.
    ///
    /// - Parameter maximumSegments: A defensive allocation ceiling. Normal UI
    ///   launches should use far fewer than the default 10,000 segments. Endpoint
    ///   calculation itself has no such limit; call ``endPoint(for:in:)`` when a
    ///   drawable path is unnecessary.
    public static func trajectory(
        for launch: PinballLaunch,
        in bounds: CGRect,
        maximumSegments: Int = 10_000
    ) throws -> PinballTrajectory {
        try validate(launch: launch, bounds: bounds)
        guard maximumSegments > 0 else {
            throw PinballMathError.reflectionLimitExceeded(maximumSegments)
        }

        if launch.distance == 0 {
            return PinballTrajectory(
                bounds: bounds,
                launch: launch,
                segments: [],
                endPoint: launch.start
            )
        }

        let localStartX = launch.start.x - bounds.minX
        let localStartY = launch.start.y - bounds.minY
        var breakpoints: [CGFloat] = [0, launch.distance]

        let xEvents = try collisionDistances(
            localPosition: localStartX,
            component: launch.direction.dx,
            extent: bounds.width,
            totalDistance: launch.distance,
            maximumEvents: maximumSegments
        )
        let yEvents = try collisionDistances(
            localPosition: localStartY,
            component: launch.direction.dy,
            extent: bounds.height,
            totalDistance: launch.distance,
            maximumEvents: maximumSegments
        )

        breakpoints.append(contentsOf: xEvents)
        breakpoints.append(contentsOf: yEvents)
        breakpoints.sort()

        // A corner hit appears once in each axis list. Merge those numerically
        // coincident events so it becomes one vertex that reflects both axes.
        let tolerance = max(
            1e-10,
            CGFloat.ulpOfOne * 64 * max(1, launch.distance)
        )
        var merged: [CGFloat] = []
        merged.reserveCapacity(breakpoints.count)
        for value in breakpoints {
            if let previous = merged.last, abs(value - previous) <= tolerance {
                // Keep the earlier event. The difference is floating-point noise,
                // and either value folds to the same corner within tolerance.
                continue
            }
            merged.append(value)
        }

        guard merged.count - 1 <= maximumSegments else {
            throw PinballMathError.reflectionLimitExceeded(maximumSegments)
        }

        var segments: [PinballPathSegment] = []
        segments.reserveCapacity(max(0, merged.count - 1))
        for index in 1..<merged.count {
            let startDistance = merged[index - 1]
            let endDistance = merged[index]
            let start = foldedPoint(atDistance: startDistance, launch: launch, bounds: bounds)
            let end = foldedPoint(atDistance: endDistance, launch: launch, bounds: bounds)
            segments.append(
                PinballPathSegment(
                    start: start,
                    end: end,
                    startDistance: startDistance,
                    endDistance: endDistance
                )
            )
        }

        let finalPoint = try endPoint(for: launch, in: bounds)
        return PinballTrajectory(
            bounds: bounds,
            launch: launch,
            segments: segments,
            endPoint: finalPoint
        )
    }

    /// Builds the reflected path through a field of circular bumpers.
    ///
    /// Falls through to the unfolded rectangle solver when the field is empty,
    /// so bumper-free rounds keep their exact previous behaviour and their O(1)
    /// endpoint. With bumpers it marches: at each step take the nearer of a
    /// closed-form wall crossing and a closed-form ray/circle intersection,
    /// emit that segment, reflect, and continue. Every vertex is recorded with
    /// its kind and contact normal so playback never has to infer them.
    public static func trajectory(
        for launch: PinballLaunch,
        in bounds: CGRect,
        bumpers: PinballBumperField,
        maximumSegments: Int = 10_000
    ) throws -> PinballTrajectory {
        guard !bumpers.isEmpty else {
            return try trajectory(for: launch, in: bounds, maximumSegments: maximumSegments)
        }
        try validate(launch: launch, bounds: bounds)
        guard maximumSegments > 0 else {
            throw PinballMathError.reflectionLimitExceeded(maximumSegments)
        }

        if launch.distance == 0 {
            return PinballTrajectory(
                bounds: bounds,
                launch: launch,
                segments: [],
                endPoint: launch.start
            )
        }

        // Scaled to the board so the epsilon means the same thing on any stage
        // size. It keeps a contact from immediately re-detecting itself.
        let epsilon = max(1e-7, max(bounds.width, bounds.height) * 1e-9)

        var segments: [PinballPathSegment] = []
        var vertexKinds: [PinballPathVertexKind] = []
        var position = launch.start
        var direction = launch.direction
        var travelled: CGFloat = 0

        while travelled < launch.distance {
            let remaining = launch.distance - travelled
            let wall = PinballBumperGeometry.nearestWallHit(
                from: position,
                direction: direction,
                bounds: bounds,
                maximumDistance: remaining,
                minimumDistance: epsilon
            )
            let bumper = PinballBumperGeometry.nearestBumperHit(
                from: position,
                direction: direction,
                field: bumpers,
                maximumDistance: remaining,
                minimumDistance: epsilon
            )

            let wallDistance = wall?.distance ?? .infinity
            let bumperDistance = bumper?.distance ?? .infinity
            let contactDistance = min(wallDistance, bumperDistance)

            guard contactDistance.isFinite, contactDistance < remaining else {
                // Nothing else in the way: run out the remaining distance.
                let end = CGPoint(
                    x: position.x + direction.dx * remaining,
                    y: position.y + direction.dy * remaining
                )
                segments.append(
                    PinballPathSegment(
                        start: position,
                        end: end,
                        startDistance: travelled,
                        endDistance: launch.distance
                    )
                )
                position = end
                travelled = launch.distance
                break
            }

            guard segments.count + 1 <= maximumSegments else {
                throw PinballMathError.reflectionLimitExceeded(maximumSegments)
            }

            let contact = CGPoint(
                x: position.x + direction.dx * contactDistance,
                y: position.y + direction.dy * contactDistance
            )
            segments.append(
                PinballPathSegment(
                    start: position,
                    end: contact,
                    startDistance: travelled,
                    endDistance: travelled + contactDistance
                )
            )

            let normal: CGVector
            if bumperDistance < wallDistance, let bumper {
                normal = bumper.normal
                vertexKinds.append(.bumper(seatID: bumper.bumper.seatID, normal: normal))
            } else if let wall {
                normal = wall.normal
                vertexKinds.append(.wall(normal: normal))
            } else {
                break
            }

            direction = PinballBumperGeometry.reflect(direction, about: normal)
            position = contact
            travelled += contactDistance
        }

        // The endpoint is the marched result, not a folded prediction: with
        // obstacles present the two are not the same construction.
        let finalPoint = segments.last?.end ?? launch.start
        return PinballTrajectory(
            bounds: bounds,
            launch: launch,
            segments: segments,
            endPoint: finalPoint,
            vertexKinds: vertexKinds
        )
    }

    /// Returns the position at a clamped distance along the exact path.
    ///
    /// This is useful for display-link animation: obtain distance from a time
    /// curve, then ask the billiards model for the corresponding physical point.
    public static func point(
        atDistance distance: CGFloat,
        along launch: PinballLaunch,
        in bounds: CGRect
    ) throws -> CGPoint {
        try validate(launch: launch, bounds: bounds)
        guard distance.isFinite else { throw PinballMathError.nonFiniteValue }
        let clamped = min(max(distance, 0), launch.distance)
        return foldedPoint(atDistance: clamped, launch: launch, bounds: bounds)
    }

    private static func validate(launch: PinballLaunch, bounds: CGRect) throws {
        try PinballValidation.validate(bounds: bounds)
        guard PinballValidation.contains(launch.start, in: bounds) else {
            throw PinballMathError.pointOutsideBounds
        }
    }

    /// Finds wall-crossing distances in one unfolded dimension. Events are
    /// generated analytically at a constant interval; there is no simulation.
    private static func collisionDistances(
        localPosition: CGFloat,
        component: CGFloat,
        extent: CGFloat,
        totalDistance: CGFloat,
        maximumEvents: Int
    ) throws -> [CGFloat] {
        let componentMagnitude = abs(component)
        guard componentMagnitude > 0 else { return [] }

        let interval = extent / componentMagnitude
        let firstBoundary: CGFloat
        if component > 0 {
            firstBoundary = (floor(localPosition / extent) + 1) * extent
        } else {
            firstBoundary = (ceil(localPosition / extent) - 1) * extent
        }

        var eventDistance = (firstBoundary - localPosition) / component
        let tolerance = max(
            1e-10,
            CGFloat.ulpOfOne * 64 * max(1, totalDistance)
        )

        // A caller may intentionally start on a wall pointing outward. In the
        // folded model that is an instantaneous reflection at distance zero, so
        // the first drawable collision is one full interval later.
        if eventDistance <= tolerance {
            eventDistance += interval
        }
        guard eventDistance < totalDistance - tolerance else { return [] }

        let approximateCount = floor((totalDistance - eventDistance) / interval) + 1
        guard approximateCount.isFinite, approximateCount <= CGFloat(maximumEvents) else {
            throw PinballMathError.reflectionLimitExceeded(maximumEvents)
        }

        var events: [CGFloat] = []
        events.reserveCapacity(Int(approximateCount))
        while eventDistance < totalDistance - tolerance {
            events.append(eventDistance)
            guard events.count <= maximumEvents else {
                throw PinballMathError.reflectionLimitExceeded(maximumEvents)
            }
            eventDistance += interval
        }
        return events
    }

    private static func foldedPoint(
        atDistance distance: CGFloat,
        launch: PinballLaunch,
        bounds: CGRect
    ) -> CGPoint {
        let unfoldedX = launch.start.x - bounds.minX + launch.direction.dx * distance
        let unfoldedY = launch.start.y - bounds.minY + launch.direction.dy * distance
        return CGPoint(
            x: bounds.minX + fold(unfoldedX, extent: bounds.width),
            y: bounds.minY + fold(unfoldedY, extent: bounds.height)
        )
    }

    /// Triangle-wave reflection into [0, extent].
    private static func fold(_ value: CGFloat, extent: CGFloat) -> CGFloat {
        let period = 2 * extent
        var remainder = value.truncatingRemainder(dividingBy: period)
        if remainder < 0 { remainder += period }
        return remainder <= extent ? remainder : period - remainder
    }
}
