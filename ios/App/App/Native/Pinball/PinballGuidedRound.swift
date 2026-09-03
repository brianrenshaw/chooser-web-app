import CoreGraphics
import Foundation

/// Winner-first construction with a conditional, visible fairness intervention.
///
/// A user's ball begins at the real release point and first resolves as an
/// entirely natural specular trajectory at the committed direction and strength.
/// When that endpoint already belongs to the independently selected `1 / N`
/// winner, that untouched trajectory is used. Otherwise the ball preserves its
/// exact first leg and receives one visible first-wall impulse whose genuine
/// reflected suffix ends in the selected region. Every later wall event is a
/// normal specular reflection. There is no hidden spawn or mid-flight steering.
enum PinballSpecularFlickResolver {
    /// Retained for source compatibility with deterministic tests from the
    /// hidden-spawn implementation. Candidate counts no longer affect the
    /// exact inverse construction.
    static let narrowCandidateLimit = 4_096
    static let wideCandidateLimit = 4_096

    private static let targetSamplingLimit = 256
    private static let mirroredTileRadius = 8

    static func resolve<R: PinballRandomSource>(
        partition: PinballRadialPartition,
        intent: PinballFlickIntent,
        using random: inout R,
        maximumSegments: Int,
        bumpers: PinballBumperField = .empty,
        narrowAttempts: Int = narrowCandidateLimit,
        wideAttempts: Int = wideCandidateLimit
    ) throws -> PinballRoundResult {
        guard maximumSegments > 0 else {
            throw PinballMathError.reflectionLimitExceeded(maximumSegments)
        }
        _ = narrowAttempts
        _ = wideAttempts

        // Commit every player-controlled value before consuming randomness.
        let committedDirection = try PinballFlickLaunchPolicy.normalizedDirection(
            intent.direction
        )
        let strength = try PinballFlickLaunchPolicy.normalizedStrength(
            forSpeed: intent.speed
        )
        let releasePoint = try PinballFlickLaunchPolicy.clampedReleasePoint(
            intent.releasePoint,
            to: partition.bounds
        )
        // This is the sole winner draw. All later randomness only varies the
        // physical endpoint inside the already-selected region when the natural
        // endpoint does not already agree with it.
        let winnerIndex = try random.nextUnbiasedIndex(
            upperBound: partition.regions.count
        )
        let selectedRegion = partition.regions[winnerIndex]

        // Give the unmodified physical result the first opportunity to own the
        // selected outcome. This path consumes no endpoint-variation randomness,
        // which also keeps natural rounds exactly reproducible from the flick and
        // the one winner draw.
        let naturalLaunch = try PinballLaunch(
            start: releasePoint,
            direction: committedDirection,
            distance: PinballFlickLaunchPolicy.perimeter(of: partition.bounds) *
                PinballFlickLaunchPolicy.centerDistanceInPerimeters(strength: strength)
        )
        let naturalTrajectory = try PinballBilliards.trajectory(
            for: naturalLaunch,
            in: partition.bounds,
            bumpers: bumpers,
            maximumSegments: maximumSegments
        )
        let naturalRegion = try partition.region(containing: naturalTrajectory.endPoint)
        if naturalRegion.seat.seatID == selectedRegion.seat.seatID {
            return PinballRoundResult(
                trajectory: naturalTrajectory,
                winningRegion: naturalRegion,
                fairnessDeflectorVertexIndex: nil
            )
        }

        // With obstacles present the rectangle's reflection lattice no longer
        // predicts where a ray lands, so the closed-form inverse below cannot be
        // used. Search instead, and verify every candidate against the polyline
        // that will actually be rendered.
        if !bumpers.isEmpty {
            return try bumperDeflectedResult(
                releasePoint: releasePoint,
                committedDirection: committedDirection,
                totalDistance: naturalLaunch.distance,
                selectedRegion: selectedRegion,
                partition: partition,
                bumpers: bumpers,
                maximumSegments: maximumSegments
            )
        }

        let firstContact = try firstWallContact(
            from: releasePoint,
            direction: committedDirection,
            in: partition.bounds
        )
        let target = try sampledInteriorTarget(
            in: selectedRegion,
            partition: partition,
            using: &random
        )
        let suffix = try inverseSpecularSuffix(
            from: firstContact.point,
            target: target,
            selectedRegion: selectedRegion,
            partition: partition,
            naturalDirection: firstContact.naturalReflectedDirection,
            firstLegDistance: firstContact.distance,
            strength: strength,
            maximumSegments: maximumSegments
        )

        return try compositeResult(
            releasePoint: releasePoint,
            committedDirection: committedDirection,
            firstContact: firstContact,
            suffix: suffix,
            selectedRegion: selectedRegion,
            partition: partition,
            maximumSegments: maximumSegments
        )
    }

    // MARK: - Bumper rounds

    /// Directions tried at the deflecting wall. 0.25° steps over the inward
    /// half-plane; dense enough that a region covering 1/N of the board is hit
    /// many times over, which is what keeps the fail-closed path from becoming
    /// region dependent.
    private static let bumperSweepSteps = 1_440

    /// Builds a round that reaches the already-selected region through a bumper
    /// field.
    ///
    /// The disclosed mechanism is unchanged: the committed release point and
    /// flick direction are preserved exactly, ordinary bounces stay specular,
    /// and exactly one wall deflects. What changes is how that wall's outgoing
    /// direction is found. A rectangle's mirror images make the bumper-free case
    /// solvable in closed form; circles have no such lattice, so this sweeps
    /// candidate directions, marches each one, and accepts only a candidate
    /// whose **computed endpoint** already lies in the selected region. The
    /// winner is therefore verified against the exact path that will be
    /// rendered, never inferred.
    private static func bumperDeflectedResult(
        releasePoint: CGPoint,
        committedDirection: CGVector,
        totalDistance: CGFloat,
        selectedRegion: PinballRadialRegion,
        partition: PinballRadialPartition,
        bumpers: PinballBumperField,
        maximumSegments: Int
    ) throws -> PinballRoundResult {
        // Travel the committed flick until the first WALL. Bumpers struck on the
        // way are ordinary specular bounces, so the deflection stays on a wall
        // where the authored flex artwork belongs.
        let prefix = try marchToFirstWall(
            from: releasePoint,
            direction: committedDirection,
            limit: totalDistance,
            bounds: partition.bounds,
            bumpers: bumpers,
            maximumSegments: maximumSegments
        )

        guard let prefix, prefix.travelled < totalDistance else {
            throw PinballMathError.specularTrajectoryUnavailable
        }

        let suffixDistance = totalDistance - prefix.travelled
        let naturalOutgoing = PinballBumperGeometry.reflect(
            prefix.incoming,
            about: prefix.wallNormal
        )

        var best: (score: CGFloat, trajectory: PinballTrajectory)?

        for step in 0..<bumperSweepSteps {
            let angle = CGFloat(step) * 2 * .pi / CGFloat(bumperSweepSteps)
            let candidate = CGVector(dx: cos(angle), dy: sin(angle))
            // Must leave the wall, not burrow into it.
            let inward = candidate.dx * prefix.wallNormal.dx + candidate.dy * prefix.wallNormal.dy
            guard inward > 1e-4 else { continue }

            guard let launch = try? PinballLaunch(
                start: prefix.contact,
                direction: candidate,
                distance: suffixDistance
            ) else { continue }
            guard let trajectory = try? PinballBilliards.trajectory(
                for: launch,
                in: partition.bounds,
                bumpers: bumpers,
                maximumSegments: maximumSegments
            ) else { continue }
            guard let region = try? partition.region(containing: trajectory.endPoint),
                  region.seat.seatID == selectedRegion.seat.seatID else { continue }

            // Prefer the least surprising deflection from the natural specular
            // reflection, matching the aesthetic rule the closed-form solver uses.
            let dot = max(-1, min(1, candidate.dx * naturalOutgoing.dx + candidate.dy * naturalOutgoing.dy))
            let score = acos(dot)
            if best == nil || score < best!.score {
                best = (score, trajectory)
            }
        }

        guard let best else {
            // Fail closed, exactly as the bumper-free path does. Never redraw a
            // winner to make a path easier to find.
            throw PinballMathError.specularTrajectoryUnavailable
        }

        var segments = prefix.segments
        var vertexKinds = prefix.vertexKinds
        let deflectorVertexIndex = segments.count

        for segment in best.trajectory.segments {
            segments.append(
                PinballPathSegment(
                    start: segment.start,
                    end: segment.end,
                    startDistance: segment.startDistance + prefix.travelled,
                    endDistance: segment.endDistance + prefix.travelled
                )
            )
        }
        // The deflecting wall itself, then the suffix's own ordinary vertices.
        vertexKinds.append(.wall(normal: prefix.wallNormal))
        vertexKinds.append(contentsOf: best.trajectory.vertexKinds)

        let launch = try PinballLaunch(
            start: releasePoint,
            direction: committedDirection,
            distance: totalDistance
        )
        let trajectory = PinballTrajectory(
            bounds: partition.bounds,
            launch: launch,
            segments: segments,
            endPoint: best.trajectory.endPoint,
            vertexKinds: vertexKinds
        )

        // Same hard verification the closed-form path performs: the displayed
        // endpoint must own the result, or the round throws.
        let endpointRegion = try partition.region(containing: trajectory.endPoint)
        guard endpointRegion.seat.seatID == selectedRegion.seat.seatID else {
            throw PinballMathError.specularTrajectoryUnavailable
        }

        return PinballRoundResult(
            trajectory: trajectory,
            winningRegion: selectedRegion,
            fairnessDeflectorVertexIndex: deflectorVertexIndex
        )
    }

    private struct BumperPrefix {
        let segments: [PinballPathSegment]
        let vertexKinds: [PinballPathVertexKind]
        let contact: CGPoint
        let incoming: CGVector
        let wallNormal: CGVector
        let travelled: CGFloat
    }

    /// Marches the committed flick until it first touches a wall, bouncing off
    /// any bumpers on the way. Returns nil when no wall is reached within the
    /// launch distance.
    private static func marchToFirstWall(
        from start: CGPoint,
        direction: CGVector,
        limit: CGFloat,
        bounds: CGRect,
        bumpers: PinballBumperField,
        maximumSegments: Int
    ) throws -> BumperPrefix? {
        let epsilon = max(1e-7, max(bounds.width, bounds.height) * 1e-9)
        var position = start
        var heading = direction
        var travelled: CGFloat = 0
        var segments: [PinballPathSegment] = []
        var vertexKinds: [PinballPathVertexKind] = []

        while travelled < limit {
            let remaining = limit - travelled
            let wall = PinballBumperGeometry.nearestWallHit(
                from: position,
                direction: heading,
                bounds: bounds,
                maximumDistance: remaining,
                minimumDistance: epsilon
            )
            let bumper = PinballBumperGeometry.nearestBumperHit(
                from: position,
                direction: heading,
                field: bumpers,
                maximumDistance: remaining,
                minimumDistance: epsilon
            )

            let wallDistance = wall?.distance ?? .infinity
            let bumperDistance = bumper?.distance ?? .infinity

            guard min(wallDistance, bumperDistance).isFinite else { return nil }
            guard segments.count + 1 <= maximumSegments else {
                throw PinballMathError.reflectionLimitExceeded(maximumSegments)
            }

            if bumperDistance < wallDistance, let bumper {
                let contact = CGPoint(
                    x: position.x + heading.dx * bumperDistance,
                    y: position.y + heading.dy * bumperDistance
                )
                segments.append(
                    PinballPathSegment(
                        start: position,
                        end: contact,
                        startDistance: travelled,
                        endDistance: travelled + bumperDistance
                    )
                )
                vertexKinds.append(.bumper(seatID: bumper.bumper.seatID, normal: bumper.normal))
                heading = PinballBumperGeometry.reflect(heading, about: bumper.normal)
                position = contact
                travelled += bumperDistance
                continue
            }

            guard let wall else { return nil }
            let contact = CGPoint(
                x: position.x + heading.dx * wallDistance,
                y: position.y + heading.dy * wallDistance
            )
            segments.append(
                PinballPathSegment(
                    start: position,
                    end: contact,
                    startDistance: travelled,
                    endDistance: travelled + wallDistance
                )
            )
            return BumperPrefix(
                segments: segments,
                vertexKinds: vertexKinds,
                contact: contact,
                incoming: heading,
                wallNormal: wall.normal,
                travelled: travelled + wallDistance
            )
        }

        return nil
    }

    private struct FirstWallContact {
        let point: CGPoint
        let distance: CGFloat
        let naturalReflectedDirection: CGVector
    }

    /// Analytic first collision. No randomness or correction angle can alter
    /// this leg, so the visible ball is a literal continuation of the finger.
    private static func firstWallContact(
        from start: CGPoint,
        direction: CGVector,
        in bounds: CGRect
    ) throws -> FirstWallContact {
        try PinballValidation.validate(bounds: bounds)
        guard PinballValidation.contains(start, in: bounds) else {
            throw PinballMathError.pointOutsideBounds
        }

        let xDistance: CGFloat
        if direction.dx > 0 {
            xDistance = (bounds.maxX - start.x) / direction.dx
        } else if direction.dx < 0 {
            xDistance = (bounds.minX - start.x) / direction.dx
        } else {
            xDistance = .infinity
        }

        let yDistance: CGFloat
        if direction.dy > 0 {
            yDistance = (bounds.maxY - start.y) / direction.dy
        } else if direction.dy < 0 {
            yDistance = (bounds.minY - start.y) / direction.dy
        } else {
            yDistance = .infinity
        }

        let distance = min(xDistance, yDistance)
        guard distance.isFinite, distance >= 0 else {
            throw PinballMathError.specularTrajectoryUnavailable
        }
        let rawContact = CGPoint(
            x: start.x + direction.dx * distance,
            y: start.y + direction.dy * distance
        )
        let point = CGPoint(
            x: min(max(rawContact.x, bounds.minX), bounds.maxX),
            y: min(max(rawContact.y, bounds.minY), bounds.maxY)
        )
        let tolerance = max(1e-8, max(bounds.width, bounds.height) * 1e-10)
        let hitsVertical = abs(point.x - bounds.minX) <= tolerance ||
            abs(point.x - bounds.maxX) <= tolerance
        let hitsHorizontal = abs(point.y - bounds.minY) <= tolerance ||
            abs(point.y - bounds.maxY) <= tolerance
        let reflected = CGVector(
            dx: hitsVertical ? -direction.dx : direction.dx,
            dy: hitsHorizontal ? -direction.dy : direction.dy
        )
        return FirstWallContact(
            point: point,
            distance: distance,
            naturalReflectedDirection: reflected
        )
    }

    /// Samples a varied endpoint strictly inside the selected region. Failure
    /// to obtain one within the bounded random budget falls back to a stable
    /// interior center ray; it never changes the already-selected winner.
    private static func sampledInteriorTarget<R: PinballRandomSource>(
        in selectedRegion: PinballRadialRegion,
        partition: PinballRadialPartition,
        using random: inout R
    ) throws -> CGPoint {
        for _ in 0..<targetSamplingLimit {
            let point = try PinballSampling.uniformStart(
                in: partition.bounds,
                using: &random
            )
            if try partition.seatID(containing: point) == selectedRegion.seat.seatID {
                return point
            }
        }
        return interiorCenterPoint(of: selectedRegion, partition: partition)
    }

    private struct InverseCandidate {
        let direction: CGVector
        let distance: CGFloat
        let score: CGFloat
    }

    /// Solves the outgoing ray in an unfolded grid of mirrored rectangles.
    /// Each mirror image of `target` folds back onto that exact physical point,
    /// so choosing one changes only the fair-bumper impulse, never the winner.
    private static func inverseSpecularSuffix(
        from contact: CGPoint,
        target: CGPoint,
        selectedRegion: PinballRadialRegion,
        partition: PinballRadialPartition,
        naturalDirection: CGVector,
        firstLegDistance: CGFloat,
        strength: CGFloat,
        maximumSegments: Int
    ) throws -> PinballTrajectory {
        let bounds = partition.bounds
        let width = bounds.width
        let height = bounds.height
        let start = CGPoint(x: contact.x - bounds.minX, y: contact.y - bounds.minY)
        let localTarget = CGPoint(x: target.x - bounds.minX, y: target.y - bounds.minY)
        let perimeter = PinballFlickLaunchPolicy.perimeter(of: bounds)
        let desiredTotalDistance = perimeter *
            PinballFlickLaunchPolicy.centerDistanceInPerimeters(strength: strength)
        let desiredSuffixDistance = max(
            max(width, height) * 0.25,
            desiredTotalDistance - firstLegDistance
        )
        let preferredHalfWidth = perimeter * PinballFlickLaunchPolicy.inverseDistanceVariation
        let preferredRange: ClosedRange<CGFloat> = (desiredSuffixDistance - preferredHalfWidth)...(desiredSuffixDistance + preferredHalfWidth)
        var best: InverseCandidate?

        for xTile in -mirroredTileRadius...mirroredTileRadius {
            for yTile in -mirroredTileRadius...mirroredTileRadius {
                for xSign: CGFloat in [-1, 1] {
                    for ySign: CGFloat in [-1, 1] {
                        let image = CGPoint(
                            x: 2 * CGFloat(xTile) * width + xSign * localTarget.x,
                            y: 2 * CGFloat(yTile) * height + ySign * localTarget.y
                        )
                        let vector = CGVector(dx: image.x - start.x, dy: image.y - start.y)
                        let distance = hypot(vector.dx, vector.dy)
                        guard distance > 1e-8, distance.isFinite else { continue }

                        let segmentEstimate = Int(ceil(abs(vector.dx) / width)) +
                            Int(ceil(abs(vector.dy) / height)) + 1
                        guard segmentEstimate <= maximumSegments else { continue }

                        let unfoldedDirection = CGVector(
                            dx: vector.dx / distance,
                            dy: vector.dy / distance
                        )
                        let visibleOutgoing = visibleOutgoingDirection(
                            unfoldedDirection,
                            from: contact,
                            in: bounds
                        )
                        let deflection = angularDistance(
                            visibleOutgoing,
                            naturalDirection
                        )
                        let outsideRangePenalty: CGFloat
                        if distance < preferredRange.lowerBound {
                            outsideRangePenalty = preferredRange.lowerBound - distance
                        } else if distance > preferredRange.upperBound {
                            outsideRangePenalty = distance - preferredRange.upperBound
                        } else {
                            outsideRangePenalty = 0
                        }
                        // Keep strength legible first, then choose the least
                        // surprising fair-bumper impulse among similar routes.
                        let score = outsideRangePenalty * 8 +
                            abs(distance - desiredSuffixDistance) +
                            perimeter * 0.32 * deflection / .pi
                        let candidate = InverseCandidate(
                            direction: unfoldedDirection,
                            distance: distance,
                            score: score
                        )
                        if best == nil || candidate.score < best!.score {
                            best = candidate
                        }
                    }
                }
            }
        }

        guard let best else {
            throw PinballMathError.specularTrajectoryUnavailable
        }
        let launch = try PinballLaunch(
            start: contact,
            direction: best.direction,
            distance: best.distance
        )
        let trajectory = try PinballBilliards.trajectory(
            for: launch,
            in: bounds,
            maximumSegments: maximumSegments
        )
        let endpointRegion = try partition.region(containing: trajectory.endPoint)
        guard endpointRegion.seat.seatID == selectedRegion.seat.seatID else {
            throw PinballMathError.specularTrajectoryUnavailable
        }
        return trajectory
    }

    private static func compositeResult(
        releasePoint: CGPoint,
        committedDirection: CGVector,
        firstContact: FirstWallContact,
        suffix: PinballTrajectory,
        selectedRegion: PinballRadialRegion,
        partition: PinballRadialPartition,
        maximumSegments: Int
    ) throws -> PinballRoundResult {
        let hasVisibleFirstLeg = firstContact.distance > 1e-8
        var segments: [PinballPathSegment] = []
        segments.reserveCapacity(suffix.segments.count + (hasVisibleFirstLeg ? 1 : 0))
        var distanceOffset: CGFloat = 0

        if hasVisibleFirstLeg {
            segments.append(
                PinballPathSegment(
                    start: releasePoint,
                    end: firstContact.point,
                    startDistance: 0,
                    endDistance: firstContact.distance
                )
            )
            distanceOffset = firstContact.distance
        }
        for segment in suffix.segments {
            segments.append(
                PinballPathSegment(
                    start: segment.start,
                    end: segment.end,
                    startDistance: distanceOffset + segment.startDistance,
                    endDistance: distanceOffset + segment.endDistance
                )
            )
        }
        guard segments.count <= maximumSegments else {
            throw PinballMathError.reflectionLimitExceeded(maximumSegments)
        }

        let totalDistance = firstContact.distance + suffix.launch.distance
        let compositeLaunch = try PinballLaunch(
            start: releasePoint,
            direction: committedDirection,
            distance: totalDistance
        )
        let trajectory = PinballTrajectory(
            bounds: partition.bounds,
            launch: compositeLaunch,
            segments: segments,
            endPoint: suffix.endPoint
        )
        let endpointRegion = try partition.region(containing: trajectory.endPoint)
        guard endpointRegion.seat.seatID == selectedRegion.seat.seatID else {
            throw PinballMathError.specularTrajectoryUnavailable
        }
        return PinballRoundResult(
            trajectory: trajectory,
            winningRegion: endpointRegion,
            fairnessDeflectorVertexIndex: hasVisibleFirstLeg ? 1 : 0
        )
    }

    /// Converts an unfolded launch vector into the first direction a player
    /// will actually see when the suffix begins on a wall.
    private static func visibleOutgoingDirection(
        _ unfolded: CGVector,
        from point: CGPoint,
        in bounds: CGRect
    ) -> CGVector {
        let tolerance = max(1e-8, max(bounds.width, bounds.height) * 1e-10)
        var dx = unfolded.dx
        var dy = unfolded.dy
        if abs(point.x - bounds.minX) <= tolerance {
            dx = abs(dx)
        } else if abs(point.x - bounds.maxX) <= tolerance {
            dx = -abs(dx)
        }
        if abs(point.y - bounds.minY) <= tolerance {
            dy = abs(dy)
        } else if abs(point.y - bounds.maxY) <= tolerance {
            dy = -abs(dy)
        }
        return CGVector(dx: dx, dy: dy)
    }

    private static func interiorCenterPoint(
        of region: PinballRadialRegion,
        partition: PinballRadialPartition
    ) -> CGPoint {
        let radialFraction: CGFloat = 0.62
        return CGPoint(
            x: partition.center.x +
                (region.centerBoundaryPoint.x - partition.center.x) * radialFraction,
            y: partition.center.y +
                (region.centerBoundaryPoint.y - partition.center.y) * radialFraction
        )
    }

    private static func angularDistance(
        _ first: CGVector,
        _ second: CGVector
    ) -> CGFloat {
        let dot = min(1, max(-1, first.dx * second.dx + first.dy * second.dy))
        return acos(dot)
    }
}
