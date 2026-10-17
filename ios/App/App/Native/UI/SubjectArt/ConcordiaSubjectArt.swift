import SwiftUI

// Concordia: abstract Rome on the map. A laurel wreath of two olive branches
// ringing the heart of the board and leaving the middle open, an aqueduct
// arcade along the foot inside the parchment frame, a trireme under a striped
// sail on the northern sea, and tiny coastal towns joined by dotted land
// routes and dashed sea lanes.

extension BoardSubjectArtRenderer {
    static func drawRomanMap(in context: inout GraphicsContext, on board: BoardSubjectCanvas) {
        let p = board.point
        let s = board.scale
        let olive = board.color("#7E8F4A")
        let oliveShade = board.color("#66753A")
        let stem = board.color("#5A3E22")
        let gold = board.color("#D7AA34")
        let stone = board.color("#D9C9A3")
        let stoneLine = board.color("#8C7A52")
        let town = board.color("#2A1E14")
        let seaLane = board.color("#1F4E6E")
        let sail = board.color("#D9B44A")
        let stripe = board.color("#C25A35")
        let parchment = board.color("#E8DDC0")

        // MARK: Routes and towns

        // Towns sit just inside the coasts of the province washes: four along
        // the northern shore, three along the southern land.
        let northTowns = [p(56, 294), p(168, 308), p(226, 322), p(346, 350)]
        let southTowns = [p(62, 648), p(196, 674), p(332, 696)]

        var landRoutes = Path()
        landRoutes.move(to: northTowns[0])
        landRoutes.addQuadCurve(to: northTowns[1], control: p(110, 318))
        landRoutes.addQuadCurve(to: northTowns[2], control: p(198, 318))
        landRoutes.addQuadCurve(to: northTowns[3], control: p(290, 352))
        landRoutes.move(to: southTowns[0])
        landRoutes.addQuadCurve(to: southTowns[1], control: p(130, 690))
        landRoutes.addQuadCurve(to: southTowns[2], control: p(262, 668))
        context.stroke(
            landRoutes,
            with: .color(stem.opacity(0.85)),
            style: StrokeStyle(lineWidth: max(0.8, 1.8 * s), lineCap: .round, dash: [0.1 * s, 6 * s])
        )

        // Sea lanes from the two outer ports to the ship.
        var seaLanes = Path()
        seaLanes.move(to: p(56, 286))
        seaLanes.addQuadCurve(to: p(138, 168), control: p(66, 196))
        seaLanes.move(to: p(346, 342))
        seaLanes.addQuadCurve(to: p(250, 168), control: p(334, 226))
        context.stroke(
            seaLanes,
            with: .color(seaLane.opacity(0.7)),
            style: StrokeStyle(lineWidth: max(0.6, 1.2 * s), lineCap: .round, dash: [8 * s, 5 * s])
        )

        // House glyphs: a square under a roof.
        var house = Path()
        house.move(to: CGPoint(x: -4.5, y: 0))
        house.addLine(to: CGPoint(x: -4.5, y: -6))
        house.addLine(to: CGPoint(x: -6.5, y: -6))
        house.addLine(to: CGPoint(x: 0, y: -12.5))
        house.addLine(to: CGPoint(x: 6.5, y: -6))
        house.addLine(to: CGPoint(x: 4.5, y: -6))
        house.addLine(to: CGPoint(x: 4.5, y: 0))
        house.closeSubpath()
        var towns = Path()
        for site in northTowns + southTowns {
            towns.addPath(board.placed(house, at: site))
        }
        context.fill(towns, with: .color(town.opacity(0.9)))

        // MARK: Laurel wreath

        // Two branches on a ring around the middle of the board: the left
        // grows from seven o'clock up to eleven, the right from five up to
        // one, so the wreath is open at the top and the bottom.
        let hub = CGPoint(x: 195, y: 470)
        let wreathRadius: CGFloat = 166
        func onRing(_ degrees: Double) -> CGPoint {
            let radians = degrees * .pi / 180
            return p(hub.x + cos(radians) * wreathRadius, hub.y + sin(radians) * wreathRadius)
        }
        func leaf(length: CGFloat, width: CGFloat) -> Path {
            var path = Path()
            path.move(to: .zero)
            path.addQuadCurve(to: CGPoint(x: length, y: 0), control: CGPoint(x: length * 0.45, y: -width))
            path.addQuadCurve(to: .zero, control: CGPoint(x: length * 0.45, y: width))
            path.closeSubpath()
            return path
        }

        var stems = Path()
        var outerLeaves = Path()
        var innerLeaves = Path()
        var ribs = Path()
        var berries: [CGPoint] = []
        for (base, tip) in [(120.0, 240.0), (60.0, -60.0)] {
            // An explicit move, or the second arc would join the first.
            let startRadians = min(base, tip) * .pi / 180
            var arc = Path()
            arc.move(to: CGPoint(x: hub.x + cos(startRadians) * wreathRadius, y: hub.y + sin(startRadians) * wreathRadius))
            arc.addArc(
                center: hub, radius: wreathRadius,
                startAngle: .degrees(min(base, tip)), endAngle: .degrees(max(base, tip)),
                clockwise: false
            )
            stems.addPath(arc.applying(CGAffineTransform(scaleX: board.sx, y: board.sy)))

            let leafCount = 34
            for index in 0..<leafCount {
                let along = 0.03 + 0.93 * CGFloat(index) / CGFloat(leafCount - 1)
                let degrees = base + (tip - base) * Double(along)
                let position = onRing(degrees)
                let ahead = onRing(degrees + (tip > base ? 1 : -1))
                let heading = atan2(ahead.y - position.y, ahead.x - position.x)
                // Alternate sides; the outside of the ring gets the lighter leaf.
                let outward = index.isMultiple(of: 2)
                let side: Double = (outward == (tip > base)) ? -1 : 1
                let rotation = heading + side * 0.66
                let length = 22 * (1 - 0.28 * along)
                let width = 7 * (1 - 0.2 * along)
                let shape = board.placed(leaf(length: length, width: width), at: position, rotation: rotation)
                if outward { outerLeaves.addPath(shape) } else { innerLeaves.addPath(shape) }
                var rib = Path()
                rib.move(to: CGPoint(x: 2, y: 0))
                rib.addLine(to: CGPoint(x: length * 0.8, y: 0))
                ribs.addPath(board.placed(rib, at: position, rotation: rotation))
            }

            // Berries: a cluster of three at the tip, a pair at the base.
            let tipPoint = onRing(tip)
            let tipHeading = atan2(tipPoint.y - onRing(tip - (tip > base ? 2 : -2)).y, tipPoint.x - onRing(tip - (tip > base ? 2 : -2)).x)
            for (forward, sideways) in [(6.0, 0.0), (-2.0, 6.0), (-2.0, -6.0)] as [(CGFloat, CGFloat)] {
                berries.append(CGPoint(
                    x: tipPoint.x + (cos(tipHeading) * forward - sin(tipHeading) * sideways) * s,
                    y: tipPoint.y + (sin(tipHeading) * forward + cos(tipHeading) * sideways) * s
                ))
            }
            let basePoint = onRing(base)
            for sideways in [-5.0, 5.0] as [CGFloat] {
                berries.append(CGPoint(
                    x: basePoint.x - sin(tipHeading) * sideways * s,
                    y: basePoint.y + cos(tipHeading) * sideways * s
                ))
            }
        }
        context.stroke(
            stems,
            with: .color(stem.opacity(0.9)),
            style: StrokeStyle(lineWidth: max(0.8, 2.4 * s), lineCap: .round)
        )
        context.fill(innerLeaves, with: .color(oliveShade.opacity(0.9)))
        context.fill(outerLeaves, with: .color(olive.opacity(0.92)))
        context.stroke(ribs, with: .color(parchment.opacity(0.5)), lineWidth: max(0.4, 0.8 * s))
        for berry in berries {
            context.fill(board.circle(at: berry, radius: 3.6), with: .color(gold.opacity(0.95)))
            context.fill(
                board.circle(at: CGPoint(x: berry.x - 1.1 * s, y: berry.y - 1.1 * s), radius: 1.1),
                with: .color(.white.opacity(0.55))
            )
        }

        // MARK: Trireme

        // Authored around mid-deck, prow to the left, stern curling at the
        // right. Held far enough down that the sail clears the frame on a
        // squashed landscape board.
        let ship = CGPoint(x: p(190, 150).x, y: max(p(190, 150).y, 98 * s))
        var hull = Path()
        hull.move(to: CGPoint(x: -62, y: -4))
        hull.addQuadCurve(to: CGPoint(x: 58, y: -4), control: CGPoint(x: 0, y: 4))
        hull.addQuadCurve(to: CGPoint(x: -62, y: -4), control: CGPoint(x: 0, y: 32))
        hull.closeSubpath()
        // The ram at the waterline.
        hull.move(to: CGPoint(x: -58, y: -2))
        hull.addLine(to: CGPoint(x: -76, y: 3))
        hull.addLine(to: CGPoint(x: -56, y: 7))
        hull.closeSubpath()
        let placedHull = board.placed(hull, at: ship)
        // A faint reflection under the keel.
        context.fill(
            board.ellipse(at: CGPoint(x: ship.x, y: ship.y + 22 * s), rx: 62, ry: 5),
            with: .color(seaLane.opacity(0.18))
        )
        // Oars dipping to the water, behind the hull.
        var oars = Path()
        for x in [-42.0, -24.0, -6.0, 12.0, 30.0] as [CGFloat] {
            oars.move(to: CGPoint(x: x, y: 4))
            oars.addLine(to: CGPoint(x: x - 12, y: 24))
        }
        context.stroke(
            board.placed(oars, at: ship),
            with: .color(stem.opacity(0.9)),
            style: StrokeStyle(lineWidth: max(0.6, 1.8 * s), lineCap: .round)
        )
        context.fill(placedHull, with: .color(stem.opacity(0.95)))
        // Stern post curling inward, and the stem post at the bow.
        var posts = Path()
        posts.move(to: CGPoint(x: 54, y: -4))
        posts.addQuadCurve(to: CGPoint(x: 68, y: -30), control: CGPoint(x: 72, y: -12))
        posts.addQuadCurve(to: CGPoint(x: 56, y: -34), control: CGPoint(x: 70, y: -42))
        posts.move(to: CGPoint(x: -58, y: -4))
        posts.addLine(to: CGPoint(x: -66, y: -20))
        context.stroke(
            board.placed(posts, at: ship),
            with: .color(stem.opacity(0.95)),
            style: StrokeStyle(lineWidth: max(1, 4.5 * s), lineCap: .round, lineJoin: .round)
        )
        // A light strake along the deck.
        var strake = Path()
        strake.move(to: CGPoint(x: -56, y: -1))
        strake.addQuadCurve(to: CGPoint(x: 52, y: -1), control: CGPoint(x: 0, y: 7))
        context.stroke(board.placed(strake, at: ship), with: .color(parchment.opacity(0.45)), lineWidth: max(0.5, 1.4 * s))

        // Mast and yard.
        var rig = Path()
        rig.move(to: CGPoint(x: -4, y: -2))
        rig.addLine(to: CGPoint(x: -4, y: -76))
        rig.move(to: CGPoint(x: -38, y: -66))
        rig.addLine(to: CGPoint(x: 30, y: -66))
        context.stroke(
            board.placed(rig, at: ship),
            with: .color(stem.opacity(0.95)),
            style: StrokeStyle(lineWidth: max(0.8, 2.6 * s), lineCap: .round)
        )
        // A bellied square sail with three stripes.
        var sailShape = Path()
        sailShape.move(to: CGPoint(x: -34, y: -64))
        sailShape.addLine(to: CGPoint(x: 26, y: -64))
        sailShape.addQuadCurve(to: CGPoint(x: 26, y: -16), control: CGPoint(x: 36, y: -40))
        sailShape.addQuadCurve(to: CGPoint(x: -34, y: -16), control: CGPoint(x: -4, y: -6))
        sailShape.addQuadCurve(to: CGPoint(x: -34, y: -64), control: CGPoint(x: -44, y: -40))
        sailShape.closeSubpath()
        let placedSail = board.placed(sailShape, at: ship)
        context.fill(placedSail, with: .color(sail.opacity(0.95)))
        var stripes = Path()
        for y in [-52.0, -40.0, -28.0] as [CGFloat] {
            stripes.move(to: CGPoint(x: -46, y: y))
            stripes.addQuadCurve(to: CGPoint(x: 38, y: y), control: CGPoint(x: -4, y: y + 5))
        }
        var sailClip = context
        sailClip.clip(to: placedSail)
        sailClip.stroke(board.placed(stripes, at: ship), with: .color(stripe.opacity(0.9)), lineWidth: max(1, 4.5 * s))
        context.stroke(placedSail, with: .color(stem.opacity(0.7)), lineWidth: max(0.5, 1 * s))

        // MARK: Aqueduct

        // Six round arches along the foot, flush with the parchment frame and
        // clipped to its rounded inner edge so the corners stay clean.
        let frameInset = 16 * s
        let left = frameInset
        let right = board.width - frameInset
        let bottom = board.height - frameInset
        let top = bottom - 72 * s
        let ledge = top + 12 * s
        let pitch = (right - left) / 6
        var arcade = Path(CGRect(x: left, y: top, width: right - left, height: bottom - top))
        var openings = Path()
        for bay in 0..<6 {
            let x0 = left + pitch * CGFloat(bay) + 7 * s
            let x1 = left + pitch * CGFloat(bay + 1) - 7 * s
            let radius = (x1 - x0) / 2
            let spring = ledge + 7 * s + radius
            openings.move(to: CGPoint(x: x0, y: bottom))
            openings.addLine(to: CGPoint(x: x0, y: spring))
            openings.addArc(
                center: CGPoint(x: (x0 + x1) / 2, y: spring), radius: radius,
                startAngle: .radians(.pi), endAngle: .radians(2 * .pi), clockwise: false
            )
            openings.addLine(to: CGPoint(x: x1, y: bottom))
            openings.closeSubpath()
        }
        arcade.addPath(openings)
        var masonry = context
        masonry.clip(to: Path(
            roundedRect: board.bounds.insetBy(dx: frameInset, dy: frameInset),
            cornerSize: CGSize(width: 26 * s, height: 26 * s)
        ))
        masonry.fill(arcade, with: .color(stone.opacity(0.93)), style: FillStyle(eoFill: true))
        masonry.stroke(openings, with: .color(stoneLine.opacity(0.85)), lineWidth: max(0.5, 1.2 * s))
        var courses = Path()
        courses.move(to: CGPoint(x: left, y: top))
        courses.addLine(to: CGPoint(x: right, y: top))
        courses.move(to: CGPoint(x: left, y: ledge))
        courses.addLine(to: CGPoint(x: right, y: ledge))
        masonry.stroke(courses, with: .color(stoneLine.opacity(0.85)), lineWidth: max(0.5, 1.2 * s))
        // Water in the channel: a thin blue line along the top course, and a
        // highlight under the ledge.
        var channel = Path()
        channel.move(to: CGPoint(x: left, y: top + 5 * s))
        channel.addLine(to: CGPoint(x: right, y: top + 5 * s))
        masonry.stroke(channel, with: .color(seaLane.opacity(0.45)), lineWidth: max(0.5, 2 * s))
        var ledgeLight = Path()
        ledgeLight.move(to: CGPoint(x: left, y: ledge + 2 * s))
        ledgeLight.addLine(to: CGPoint(x: right, y: ledge + 2 * s))
        masonry.stroke(ledgeLight, with: .color(.white.opacity(0.4)), lineWidth: max(0.4, 1 * s))
        // Block joints on each pier.
        var joints = Path()
        for pier in 1..<6 {
            let x = left + pitch * CGFloat(pier)
            for y in [ledge + 22 * s, ledge + 40 * s] {
                joints.move(to: CGPoint(x: x - 6 * s, y: y))
                joints.addLine(to: CGPoint(x: x + 6 * s, y: y))
            }
        }
        masonry.stroke(joints, with: .color(stoneLine.opacity(0.6)), lineWidth: max(0.4, 0.9 * s))
    }
}
