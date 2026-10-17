import SwiftUI

// Res Arcana: an alchemist's table, abstracted. A lit candle in a shallow dish
// at the foot of the grimoire, its flame a teardrop from ember red to gold; a
// crystal orb on a small stand at the head with a dim halo and a slow swirl
// inside; and a bone element glyph drawn inside each of the five tooled nodes
// of the pentagon: fire, water, air, earth and quintessence. Nothing covers
// the tooling.

extension BoardSubjectArtRenderer {
    static func drawAlchemistsCandle(in context: inout GraphicsContext, on board: BoardSubjectCanvas) {
        let p = board.point
        let s = board.scale
        let bone = board.color("#E4D6BE")
        let boneShade = board.color("#CDB79A")
        let boneLight = board.color("#F2E8D6")
        let ember = board.color("#E0442C")
        let flameGold = board.color("#F6C86A")
        let garnet = board.color("#A3121F")
        let glass = board.color("#2E2024")

        // MARK: Element glyphs at the pentagon's nodes

        // The tooling's pentagon: centered at (width * 0.5, height * 0.51), with
        // its vertices at -90 + 72 k degrees on a radius fitted to the short
        // edge, exactly as the surface draws it.
        let diagramCenter = CGPoint(x: board.width * 0.5, y: board.height * 0.51)
        let vertexRadius = min(board.width, board.height) * 0.456 * 150 / 178
        let reach: CGFloat = 6.2
        let baseHalfWidth = reach * CGFloat(sin(Double.pi / 3))
        func triangle(up: Bool, bar: Bool) -> Path {
            var path = Path()
            let apex = up ? -reach : reach
            let base = up ? reach / 2 : -reach / 2
            path.move(to: CGPoint(x: 0, y: apex))
            path.addLine(to: CGPoint(x: baseHalfWidth, y: base))
            path.addLine(to: CGPoint(x: -baseHalfWidth, y: base))
            path.closeSubpath()
            if bar {
                let level = up ? -reach * 0.1 : reach * 0.1
                path.move(to: CGPoint(x: -baseHalfWidth * 0.82, y: level))
                path.addLine(to: CGPoint(x: baseHalfWidth * 0.82, y: level))
            }
            return path
        }
        var quintessence = Path(ellipseIn: CGRect(x: -5.2, y: -5.2, width: 10.4, height: 10.4))
        quintessence.addEllipse(in: CGRect(x: -1.3, y: -1.3, width: 2.6, height: 2.6))
        let glyphs = [
            triangle(up: true, bar: false),
            triangle(up: false, bar: false),
            triangle(up: true, bar: true),
            triangle(up: false, bar: true),
            quintessence
        ]
        var glyphInk = Path()
        for (index, glyph) in glyphs.enumerated() {
            let angle = (-90 + 72 * Double(index)) * Double.pi / 180
            let node = CGPoint(
                x: diagramCenter.x + vertexRadius * CGFloat(cos(angle)),
                y: diagramCenter.y + vertexRadius * CGFloat(sin(angle))
            )
            glyphInk.addPath(board.placed(glyph, at: node))
        }
        context.stroke(
            glyphInk,
            with: .color(bone.opacity(0.7)),
            style: StrokeStyle(lineWidth: max(0.5, 1.2 * s), lineCap: .round, lineJoin: .round)
        )

        // MARK: The orb

        let orbRadius: CGFloat = 34
        let ringRadius = min(board.width, board.height) * 0.456
        var orbCenter = p(195, 120)
        // On a wide board there is no room above the ring, so the orb steps
        // out to the bare leather left of it, when that slot exists.
        let leftSlot = diagramCenter.x - ringRadius - (orbRadius + 32) * s
        if orbCenter.y + orbRadius * s > diagramCenter.y - ringRadius - 4 * s, leftSlot > (orbRadius + 20) * s {
            orbCenter = CGPoint(x: leftSlot, y: max(orbCenter.y, (orbRadius + 40) * s))
        }
        var halo = context
        halo.addFilter(.blur(radius: max(4, 12 * s)))
        halo.fill(board.circle(at: orbCenter, radius: orbRadius + 14), with: .color(bone.opacity(0.18)))

        // A small stand under the orb: a dish on a short stem.
        var stand = Path()
        stand.addEllipse(in: CGRect(x: -20, y: 36, width: 40, height: 10))
        stand.addRoundedRect(in: CGRect(x: -6, y: 28, width: 12, height: 12), cornerSize: CGSize(width: 2, height: 2))
        let placedStand = board.placed(stand, at: orbCenter)
        context.fill(placedStand, with: .color(glass.opacity(0.95)))
        context.stroke(placedStand, with: .color(boneShade.opacity(0.5)), lineWidth: max(0.4, 0.9 * s))

        let orb = board.circle(at: orbCenter, radius: orbRadius)
        context.fill(orb, with: .color(glass.opacity(0.7)))
        // Two swirls inside the glass, garnet and bone, clipped to the orb.
        var inside = context
        inside.clip(to: orb)
        for (phase, color, opacity, width) in [
            (0.0, garnet, 0.85, 3.2), (Double.pi, bone, 0.42, 1.5)
        ] as [(Double, Color, Double, CGFloat)] {
            var swirl = Path()
            for index in 0...40 {
                let t = Double(index) / 40
                let radius = (3 + 28 * t) * s
                let angle = phase + t * 3 * Double.pi
                let point = CGPoint(
                    x: orbCenter.x + radius * CGFloat(cos(angle)) * 0.92,
                    y: orbCenter.y + radius * CGFloat(sin(angle))
                )
                if index == 0 { swirl.move(to: point) } else { swirl.addLine(to: point) }
            }
            inside.stroke(swirl, with: .color(color.opacity(opacity)), style: StrokeStyle(lineWidth: max(0.5, width * s), lineCap: .round))
        }
        // A deeper glow at the heart of the orb.
        inside.fill(orb, with: .radialGradient(
            Gradient(colors: [garnet.opacity(0.35), garnet.opacity(0)]),
            center: orbCenter,
            startRadius: 0,
            endRadius: orbRadius * s * 0.8
        ))
        context.stroke(orb, with: .color(bone.opacity(0.55)), lineWidth: max(0.5, 1.2 * s))
        var gleam = Path()
        gleam.addArc(
            center: orbCenter, radius: (orbRadius - 6) * s,
            startAngle: .degrees(200), endAngle: .degrees(255), clockwise: false
        )
        context.stroke(gleam, with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: max(0.8, 3 * s), lineCap: .round))

        // MARK: The candle

        // The candle stands on the bottom edge. On a wide board its flame would
        // cross the ring and the pentagon, so it steps out to the right of the
        // ring, when that slot exists.
        var candleCenter = board.fromBottom(195, 54)
        let rightSlot = diagramCenter.x + ringRadius + (orbRadius + 32) * s
        if candleCenter.y - 74 * s < diagramCenter.y + ringRadius + 4 * s, rightSlot + (orbRadius + 20) * s < board.width {
            candleCenter = CGPoint(x: rightSlot, y: candleCenter.y)
        }
        var flameGlow = context
        flameGlow.addFilter(.blur(radius: max(5, 14 * s)))
        flameGlow.fill(
            board.circle(at: CGPoint(x: candleCenter.x, y: candleCenter.y - 52 * s), radius: 34),
            with: .color(flameGold.opacity(0.32))
        )

        // The dish, then the stick with a melted cap and drips.
        let dish = board.placed(Path(ellipseIn: CGRect(x: -26, y: 22, width: 52, height: 13)), at: candleCenter)
        context.fill(dish, with: .color(glass.opacity(0.95)))
        context.stroke(dish, with: .color(boneShade.opacity(0.55)), lineWidth: max(0.4, 0.9 * s))

        var stick = Path(roundedRect: CGRect(x: -11, y: -30, width: 22, height: 58), cornerRadius: 2.5)
        stick.addEllipse(in: CGRect(x: -13, y: -35, width: 26, height: 10))
        for (x, length) in [(-11.0, 22.0), (3.0, 13.0), (8.0, 30.0)] as [(CGFloat, CGFloat)] {
            stick.addRoundedRect(in: CGRect(x: x - 2.4, y: -32, width: 4.8, height: length), cornerSize: CGSize(width: 2.4, height: 2.4))
        }
        let placedStick = board.placed(stick, at: candleCenter)
        context.fill(placedStick, with: .color(bone.opacity(0.88)))
        context.stroke(placedStick, with: .color(boneShade.opacity(0.75)), lineWidth: max(0.4, 0.9 * s))
        // Shade down the right side, light down the left.
        var shadeLine = Path()
        shadeLine.move(to: CGPoint(x: 8, y: -22))
        shadeLine.addLine(to: CGPoint(x: 8, y: 25))
        context.stroke(board.placed(shadeLine, at: candleCenter), with: .color(boneShade.opacity(0.6)), style: StrokeStyle(lineWidth: max(0.8, 3 * s), lineCap: .round))
        var lightLine = Path()
        lightLine.move(to: CGPoint(x: -7, y: -22))
        lightLine.addLine(to: CGPoint(x: -7, y: 25))
        context.stroke(board.placed(lightLine, at: candleCenter), with: .color(boneLight.opacity(0.7)), style: StrokeStyle(lineWidth: max(0.5, 2 * s), lineCap: .round))

        // Wick and flame: a teardrop from ember red at the base to gold at the
        // tip, with a brighter inner tongue.
        var wick = Path()
        wick.move(to: CGPoint(x: 0, y: -31))
        wick.addLine(to: CGPoint(x: 0.5, y: -39))
        context.stroke(board.placed(wick, at: candleCenter), with: .color(glass.opacity(0.95)), style: StrokeStyle(lineWidth: max(0.5, 1.6 * s), lineCap: .round))
        var flame = Path()
        flame.move(to: CGPoint(x: 0, y: -74))
        flame.addCurve(to: CGPoint(x: 0, y: -34), control1: CGPoint(x: 10, y: -56), control2: CGPoint(x: 9, y: -34))
        flame.addCurve(to: CGPoint(x: 0, y: -74), control1: CGPoint(x: -9, y: -34), control2: CGPoint(x: -10, y: -56))
        flame.closeSubpath()
        let placedFlame = board.placed(flame, at: candleCenter)
        context.fill(placedFlame, with: .linearGradient(
            Gradient(colors: [flameGold.opacity(0.96), ember.opacity(0.94)]),
            startPoint: CGPoint(x: candleCenter.x, y: candleCenter.y - 74 * s),
            endPoint: CGPoint(x: candleCenter.x, y: candleCenter.y - 34 * s)
        ))
        var tongue = Path()
        tongue.move(to: CGPoint(x: 0, y: -60))
        tongue.addCurve(to: CGPoint(x: 0, y: -36), control1: CGPoint(x: 5, y: -50), control2: CGPoint(x: 4.5, y: -36))
        tongue.addCurve(to: CGPoint(x: 0, y: -60), control1: CGPoint(x: -4.5, y: -36), control2: CGPoint(x: -5, y: -50))
        tongue.closeSubpath()
        context.fill(board.placed(tongue, at: candleCenter), with: .color(flameGold.opacity(0.92)))
    }
}
