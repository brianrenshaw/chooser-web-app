import SwiftUI

// Sagrada: the basilica's skyline along the foot of the window, and a dove.
// Six tapering towers with pinnacles and arched slots rise in lead black
// from the stone sill, joined by a low gabled nave, a few windows lit from
// inside; a white dove descends under a faint halo near the top, clear of
// the rose window.

extension BoardSubjectArtRenderer {
    static func drawBasilicaAndDove(in context: inout GraphicsContext, on board: BoardSubjectCanvas) {
        let p = board.point
        let s = board.scale
        let lead = board.color("#0D080A")
        let lit = board.color("#FFE7A8")
        let white = board.color("#F2EFE6")
        let shade = board.color("#A6A296")

        // MARK: Basilica

        // The skyline stands on the frame's inner sill and never climbs above
        // the rose window, whichever way the board is shaped: tower heights
        // are authored for a 230 pt reach and scaled by `k` to fit.
        let frameInset = 14 * s
        let sill = board.height - frameInset
        let roseRadius = min(board.width, board.height) * 0.40
        let roseBottom = board.height / 2 + roseRadius
        let apex = max(p(0, 600).y, roseBottom + 10 * s)
        let reach = max(10 * s, sill - apex)
        let k = reach / 230
        let left = frameInset
        let right = board.width - frameInset
        func up(_ units: CGFloat) -> CGFloat { sill - units * k }

        var masonry = Path()
        var openings = Path()
        var litSlots = Path()
        var glowCenters: [CGPoint] = []
        func slot(at x: CGFloat, base: CGFloat, width: CGFloat = 7, height: CGFloat = 14) -> Path {
            var arch = Path()
            arch.move(to: CGPoint(x: x - width / 2 * s, y: up(base)))
            arch.addLine(to: CGPoint(x: x - width / 2 * s, y: up(base + height - width / 2)))
            arch.addQuadCurve(
                to: CGPoint(x: x, y: up(base + height)),
                control: CGPoint(x: x - width / 2 * s, y: up(base + height))
            )
            arch.addQuadCurve(
                to: CGPoint(x: x + width / 2 * s, y: up(base + height - width / 2)),
                control: CGPoint(x: x + width / 2 * s, y: up(base + height))
            )
            arch.addLine(to: CGPoint(x: x + width / 2 * s, y: up(base)))
            arch.closeSubpath()
            return arch
        }

        // Towers: authored x, height above the sill, half width at the base,
        // and which of the three stacked slots is lit (0 for none).
        let towers: [(x: CGFloat, height: CGFloat, halfWidth: CGFloat, lit: Int)] = [
            (52, 170, 14, 0), (112, 200, 15, 1), (168, 226, 17, 2),
            (222, 230, 17, 1), (278, 202, 15, 3), (338, 174, 14, 0)
        ]
        var centers: [CGFloat] = []
        for tower in towers {
            let cx = p(tower.x, 0).x
            centers.append(cx)
            let hw = tower.halfWidth * s
            let shoulder = tower.height - 30
            var body = Path()
            body.move(to: CGPoint(x: cx - hw, y: sill))
            body.addLine(to: CGPoint(x: cx - hw * 0.55, y: up(shoulder)))
            // Left pinnacle, spire, right pinnacle.
            body.addLine(to: CGPoint(x: cx - hw * 0.55, y: up(shoulder + 10)))
            body.addLine(to: CGPoint(x: cx - hw * 0.55 + 3 * s, y: up(shoulder + 3)))
            body.addLine(to: CGPoint(x: cx - 2.2 * s, y: up(shoulder + 4)))
            body.addLine(to: CGPoint(x: cx, y: up(tower.height)))
            body.addLine(to: CGPoint(x: cx + 2.2 * s, y: up(shoulder + 4)))
            body.addLine(to: CGPoint(x: cx + hw * 0.55 - 3 * s, y: up(shoulder + 3)))
            body.addLine(to: CGPoint(x: cx + hw * 0.55, y: up(shoulder + 10)))
            body.addLine(to: CGPoint(x: cx + hw * 0.55, y: up(shoulder)))
            body.addLine(to: CGPoint(x: cx + hw, y: sill))
            body.closeSubpath()
            masonry.addPath(body)
            // A finial ball on the spire.
            masonry.addPath(board.circle(at: CGPoint(x: cx, y: up(tower.height) - 1.5 * s), radius: 2.4))
            // Stacked arched slots, the lit one remembered.
            for (index, base) in [34.0, 78.0, 122.0].enumerated() where base + 14 < shoulder - 10 {
                let arch = slot(at: cx, base: base)
                openings.addPath(arch)
                if index + 1 == tower.lit {
                    litSlots.addPath(arch)
                    glowCenters.append(CGPoint(x: cx, y: up(base + 7)))
                }
            }
        }

        // The nave: a low gabled roofline running between the towers.
        var nave = Path()
        nave.move(to: CGPoint(x: left, y: sill))
        nave.addLine(to: CGPoint(x: left, y: up(36)))
        for index in 0..<(centers.count - 1) {
            let mid = (centers[index] + centers[index + 1]) / 2
            nave.addLine(to: CGPoint(x: mid - 12 * s, y: up(36)))
            nave.addLine(to: CGPoint(x: mid, y: up(54)))
            nave.addLine(to: CGPoint(x: mid + 12 * s, y: up(36)))
            let arch = slot(at: mid, base: 14, width: 6, height: 12)
            openings.addPath(arch)
            if index == 2 {
                litSlots.addPath(arch)
                glowCenters.append(CGPoint(x: mid, y: up(20)))
            }
        }
        nave.addLine(to: CGPoint(x: right, y: up(36)))
        nave.addLine(to: CGPoint(x: right, y: sill))
        nave.closeSubpath()

        var skyline = context
        skyline.clip(to: Path(
            roundedRect: board.bounds.insetBy(dx: frameInset, dy: frameInset),
            cornerSize: CGSize(width: 30 * s, height: 30 * s)
        ))
        var silhouette = Path()
        silhouette.addPath(nave)
        silhouette.addPath(masonry)
        silhouette.addPath(openings)
        skyline.fill(silhouette, with: .color(lead.opacity(0.9)), style: FillStyle(eoFill: true))
        // Dusk light catching the stone edges.
        var edges = Path()
        edges.addPath(nave)
        edges.addPath(masonry)
        skyline.stroke(edges, with: .color(shade.opacity(0.28)), style: StrokeStyle(lineWidth: max(0.4, 0.8 * s), lineJoin: .round))
        // Windows lit from inside, with a soft glow over the stone.
        skyline.fill(litSlots, with: .color(lit.opacity(0.92)))
        var glow = skyline
        glow.addFilter(.blur(radius: max(2, 7 * s)))
        for center in glowCenters {
            glow.fill(board.circle(at: center, radius: 11), with: .color(lit.opacity(0.32)))
        }

        // MARK: Dove

        // Head in profile, wings spread high, tail fanned: the emblem dove.
        // Centred above the rose window; on a wide board, where the rose
        // fills the height, it flies beside the rose instead.
        let roseTop = board.height / 2 - roseRadius
        let flight: CGPoint
        // The dove is 86 pt tall as authored; where a squat board leaves less
        // room than that above the rose, it flies a little smaller.
        let d: CGFloat
        if board.width > board.height {
            flight = CGPoint(x: board.width / 2 - roseRadius - 120 * s, y: board.height * 0.32)
            d = 1
        } else {
            d = min(1, max(0.6, (roseTop - frameInset - 6 * s) / (86 * s)))
            flight = CGPoint(
                x: p(195, 110).x,
                y: max(frameInset + 40 * s * d, min(p(195, 110).y, roseTop - 46 * s * d))
            )
        }
        let ds = s * d

        var halo = context
        halo.addFilter(.blur(radius: max(3, 10 * ds)))
        halo.fill(
            board.circle(at: CGPoint(x: flight.x, y: flight.y - 8 * ds), radius: 46 * d),
            with: .color(lit.opacity(0.2))
        )
        context.stroke(
            board.circle(at: CGPoint(x: flight.x, y: flight.y - 24 * ds), radius: 13 * d),
            with: .color(lit.opacity(0.55)),
            lineWidth: max(0.5, 1.4 * ds)
        )

        var dove = Path()
        // Tail fan.
        dove.move(to: CGPoint(x: 0, y: 10))
        dove.addLine(to: CGPoint(x: -17, y: 38))
        dove.addQuadCurve(to: CGPoint(x: -6, y: 41), control: CGPoint(x: -12, y: 43))
        dove.addQuadCurve(to: CGPoint(x: 6, y: 41), control: CGPoint(x: 0, y: 46))
        dove.addQuadCurve(to: CGPoint(x: 17, y: 38), control: CGPoint(x: 12, y: 43))
        dove.closeSubpath()
        // Wings, mirrored.
        for side in [-1.0, 1.0] as [CGFloat] {
            var wing = Path()
            wing.move(to: CGPoint(x: side * -5, y: -10))
            wing.addQuadCurve(to: CGPoint(x: side * -62, y: -44), control: CGPoint(x: side * -34, y: -40))
            wing.addQuadCurve(to: CGPoint(x: side * -44, y: -24), control: CGPoint(x: side * -56, y: -28))
            wing.addQuadCurve(to: CGPoint(x: side * -28, y: -8), control: CGPoint(x: side * -40, y: -12))
            wing.addQuadCurve(to: CGPoint(x: side * -8, y: 8), control: CGPoint(x: side * -22, y: 4))
            wing.closeSubpath()
            dove.addPath(wing)
        }
        dove.addEllipse(in: CGRect(x: -9, y: -19, width: 18, height: 38))
        dove.addEllipse(in: CGRect(x: -7, y: -31, width: 14, height: 14))
        let placedDove = board.placed(dove, at: flight, scale: d)
        context.fill(placedDove, with: .color(white.opacity(0.95)))

        // Beak, eye and feather shading.
        var beak = Path()
        beak.move(to: CGPoint(x: -6, y: -27.5))
        beak.addLine(to: CGPoint(x: -14, y: -24.5))
        beak.addLine(to: CGPoint(x: -6, y: -22.5))
        beak.closeSubpath()
        context.fill(board.placed(beak, at: flight, scale: d), with: .color(shade.opacity(0.95)))
        context.fill(
            board.circle(at: CGPoint(x: flight.x - 2.5 * ds, y: flight.y - 26 * ds), radius: 1.4 * d),
            with: .color(lead.opacity(0.9))
        )
        var feathers = Path()
        for side in [-1.0, 1.0] as [CGFloat] {
            for (to, control) in [
                (CGPoint(x: side * -56, y: -39), CGPoint(x: side * -34, y: -30)),
                (CGPoint(x: side * -44, y: -24), CGPoint(x: side * -28, y: -20)),
                (CGPoint(x: side * -28, y: -8), CGPoint(x: side * -20, y: -8))
            ] {
                feathers.move(to: CGPoint(x: side * -10, y: -8))
                feathers.addQuadCurve(to: to, control: control)
            }
        }
        feathers.move(to: CGPoint(x: 0, y: 14))
        feathers.addLine(to: CGPoint(x: -10, y: 38))
        feathers.move(to: CGPoint(x: 0, y: 14))
        feathers.addLine(to: CGPoint(x: 10, y: 38))
        feathers.move(to: CGPoint(x: 0, y: 16))
        feathers.addLine(to: CGPoint(x: 0, y: 40))
        var plumage = context
        plumage.clip(to: placedDove)
        plumage.stroke(
            board.placed(feathers, at: flight, scale: d),
            with: .color(shade.opacity(0.65)),
            style: StrokeStyle(lineWidth: max(0.5, 1.2 * ds), lineCap: .round)
        )
        // A soft shadow where the wings meet the body.
        var shoulders = Path()
        shoulders.addEllipse(in: CGRect(x: -16, y: -14, width: 12, height: 8))
        shoulders.addEllipse(in: CGRect(x: 4, y: -14, width: 12, height: 8))
        plumage.fill(board.placed(shoulders, at: flight, scale: d), with: .color(shade.opacity(0.3)))
    }
}
