import SwiftUI

// Wyrmspan: the cover dragon, abstracted. Spread wings with dark bones and
// pale membranes across the upper board, a scaled body coiling down the
// middle to a tail flick at the lower left, a crimson ruff at the throat, a
// gold belly, and a clutch of speckled eggs resting in the lower right.

extension BoardSubjectArtRenderer {
    static func drawWyrmDragon(in context: inout GraphicsContext, on board: BoardSubjectCanvas) {
        let p = board.point
        let s = board.scale
        let bone = board.color("#6E4631")
        let hide = board.color("#A87A5A")
        let hideDark = board.color("#5A3A28")
        let belly = board.color("#B9A64A")
        let ruff = board.color("#B23A3C")
        let membraneTop = board.color("#E6EAE4")
        let membraneBottom = board.color("#BFD6D8")
        let gold = board.color("#D9B44A")

        // MARK: Wings

        let shoulder = p(235, 300)
        let leftTips = [p(30, 40), p(-12, 150), p(-6, 270), p(50, 370)]
        let leftControls = [p(150, 180), p(100, 220), p(100, 290), p(140, 350)]
        let leftScallops = [p(77, 156), p(64, 237), p(86, 314)]
        let rightTips = [p(360, 20), p(404, 130), p(404, 260), p(350, 360)]
        let rightControls = [p(310, 160), p(330, 200), p(330, 280), p(300, 340)]
        let rightScallops = [p(338, 142), p(353, 226), p(334, 307)]

        for (tips, controls, scallops) in [
            (leftTips, leftControls, leftScallops),
            (rightTips, rightControls, rightScallops)
        ] {
            var membrane = Path()
            membrane.move(to: shoulder)
            membrane.addQuadCurve(to: tips[0], control: controls[0])
            for index in 1..<tips.count {
                membrane.addQuadCurve(to: tips[index], control: scallops[index - 1])
            }
            membrane.addQuadCurve(to: shoulder, control: controls[3])
            membrane.closeSubpath()
            context.fill(membrane, with: .linearGradient(
                Gradient(colors: [membraneTop.opacity(0.85), membraneBottom.opacity(0.85)]),
                startPoint: p(195, 0),
                endPoint: p(195, 370)
            ))

            // Veins between the bones.
            var veins = Path()
            for (index, scallop) in scallops.enumerated() {
                let along = CGFloat(index + 1) / CGFloat(scallops.count + 1)
                veins.move(to: CGPoint(
                    x: shoulder.x + (scallop.x - shoulder.x) * 0.22 * along,
                    y: shoulder.y + (scallop.y - shoulder.y) * 0.22 * along
                ))
                veins.addLine(to: scallop)
            }
            context.stroke(veins, with: .color(bone.opacity(0.32)), lineWidth: max(0.5, 1 * s))

            // Bones: the leading arm heavier than the fingers.
            for (index, tip) in tips.enumerated() {
                var boneLine = Path()
                boneLine.move(to: shoulder)
                boneLine.addQuadCurve(to: tip, control: controls[index])
                context.stroke(
                    boneLine,
                    with: .color(bone.opacity(0.8)),
                    style: StrokeStyle(lineWidth: max(0.8, (index == 0 ? 5 : 3) * s), lineCap: .round)
                )
            }
            // The membrane's trailing edge.
            var edge = Path()
            edge.move(to: tips[0])
            for index in 1..<tips.count {
                edge.addQuadCurve(to: tips[index], control: scallops[index - 1])
            }
            context.stroke(edge, with: .color(bone.opacity(0.5)), lineWidth: max(0.5, 1.2 * s))
        }

        // MARK: Body

        let neck = board.taperedStroke(
            from: shoulder,
            segments: [(to: p(262, 222), control1: p(250, 260), control2: p(256, 240), width: 20)]
        )
        let body = board.taperedStroke(
            from: shoulder,
            segments: [
                (to: p(270, 520), control1: p(290, 360), control2: p(330, 440), width: 34),
                (to: p(120, 660), control1: p(230, 575), control2: p(150, 585), width: 24),
                (to: p(110, 800), control1: p(100, 720), control2: p(150, 760), width: 14),
                (to: p(56, 806), control1: p(80, 820), control2: p(66, 814), width: 6)
            ]
        )
        var whole = Path()
        whole.addPath(neck)
        whole.addPath(body)

        // Outline, then hide, then the lighter belly along the inside of the curve.
        context.stroke(whole, with: .color(hideDark.opacity(0.9)), lineWidth: max(1, 3 * s))
        context.fill(whole, with: .color(hide))
        var bellyLine = Path()
        bellyLine.move(to: p(243, 318))
        bellyLine.addCurve(to: p(262, 514), control1: p(290, 372), control2: p(318, 440))
        bellyLine.addCurve(to: p(126, 646), control1: p(226, 566), control2: p(154, 578))
        context.stroke(
            bellyLine,
            with: .color(belly.opacity(0.75)),
            style: StrokeStyle(lineWidth: max(1, 9 * s), lineCap: .round)
        )

        // Scales: rows of small arcs clipped to the body.
        var scales = Path()
        let scaleWidth = 14 * s
        let rowStep = 11 * s
        let box = body.boundingRect.union(neck.boundingRect)
        var y = box.minY
        var row = 0
        while y < box.maxY + rowStep {
            var x = box.minX - (row.isMultiple(of: 2) ? 0 : scaleWidth / 2)
            while x < box.maxX + scaleWidth {
                scales.move(to: CGPoint(x: x, y: y))
                scales.addQuadCurve(
                    to: CGPoint(x: x + scaleWidth, y: y),
                    control: CGPoint(x: x + scaleWidth / 2, y: y + scaleWidth * 0.9)
                )
                x += scaleWidth
            }
            y += rowStep
            row += 1
        }
        var clipped = context
        clipped.clip(to: whole)
        clipped.stroke(scales, with: .color(hideDark.opacity(0.5)), lineWidth: max(0.5, 1 * s))
        // A soft highlight along the top of the back.
        var highlight = Path()
        highlight.move(to: p(228, 296))
        highlight.addCurve(to: p(266, 514), control1: p(280, 350), control2: p(322, 430))
        clipped.stroke(
            highlight,
            with: .color(.white.opacity(0.22)),
            style: StrokeStyle(lineWidth: max(1, 6 * s), lineCap: .round)
        )

        // Dorsal spines along the outside of the curve.
        var spines = Path()
        for (from, to) in [
            (p(292, 404), p(306, 392)), (p(300, 440), p(316, 434)), (p(296, 470), p(312, 472)),
            (p(274, 504), p(288, 512)), (p(232, 560), p(240, 576)), (p(196, 578), p(200, 594)),
            (p(160, 598), p(158, 614))
        ] {
            spines.move(to: from)
            spines.addLine(to: to)
        }
        context.stroke(
            spines,
            with: .color(hideDark.opacity(0.6)),
            style: StrokeStyle(lineWidth: max(0.8, 1.6 * s), lineCap: .round)
        )

        // Crimson ruff at the throat.
        var ruffPath = Path()
        ruffPath.move(to: p(226, 294))
        ruffPath.addQuadCurve(to: p(244, 286), control: p(234, 270))
        ruffPath.addQuadCurve(to: p(258, 288), control: p(248, 262))
        ruffPath.addQuadCurve(to: p(270, 292), control: p(264, 268))
        ruffPath.addQuadCurve(to: p(226, 294), control: p(252, 302))
        ruffPath.closeSubpath()
        context.fill(ruffPath, with: .color(ruff.opacity(0.92)))

        // MARK: Head

        var head = Path()
        head.move(to: CGPoint(x: -18, y: -14))
        head.addQuadCurve(to: CGPoint(x: 42, y: -4), control: CGPoint(x: 8, y: -24))
        head.addQuadCurve(to: CGPoint(x: -18, y: 14), control: CGPoint(x: 8, y: 18))
        head.closeSubpath()
        let headPosition = p(262, 215)
        let headRotation = -115 * Double.pi / 180
        let headScale: CGFloat = 1.18
        // Horns sweep back from the crown, away from the snout; on this
        // rotation the crown is the +y side of the head's own frame.
        var horns = Path()
        horns.move(to: CGPoint(x: -14, y: 10))
        horns.addQuadCurve(to: CGPoint(x: -26, y: 46), control: CGPoint(x: -32, y: 26))
        horns.move(to: CGPoint(x: -2, y: 14))
        horns.addQuadCurve(to: CGPoint(x: -6, y: 50), control: CGPoint(x: -16, y: 34))
        context.stroke(
            board.placed(horns, at: headPosition, rotation: headRotation, scale: headScale),
            with: .color(hideDark),
            style: StrokeStyle(lineWidth: max(1, 3 * s), lineCap: .round)
        )
        let placedHead = board.placed(head, at: headPosition, rotation: headRotation, scale: headScale)
        context.fill(placedHead, with: .color(hide))
        context.stroke(placedHead, with: .color(hideDark), style: StrokeStyle(lineWidth: max(0.8, 2.2 * s), lineJoin: .round))
        var brow = Path()
        brow.move(to: CGPoint(x: -6, y: -12))
        brow.addQuadCurve(to: CGPoint(x: 36, y: -4), control: CGPoint(x: 10, y: -18))
        context.stroke(
            board.placed(brow, at: headPosition, rotation: headRotation, scale: headScale),
            with: .color(.white.opacity(0.3)),
            lineWidth: max(0.8, 2 * s)
        )
        let eye = board.placed(
            Path(ellipseIn: CGRect(x: 4, y: -7, width: 8, height: 8)),
            at: headPosition, rotation: headRotation, scale: headScale
        )
        context.fill(eye, with: .color(gold))
        let pupil = board.placed(
            Path(ellipseIn: CGRect(x: 6.8, y: -6.4, width: 2.4, height: 6.8)),
            at: headPosition, rotation: headRotation, scale: headScale
        )
        context.fill(pupil, with: .color(board.color("#2A1A10")))

        // MARK: A clutch of eggs

        let eggColors = [board.participant(0), board.participant(2), board.participant(3)]
        let nest = board.fromRight(74, 760)
        for (index, offset) in [CGPoint(x: -22, y: 6), CGPoint(x: 4, y: -10), CGPoint(x: 26, y: 8)].enumerated() {
            let center = CGPoint(x: nest.x + offset.x * s, y: nest.y + offset.y * s)
            let egg = board.ellipse(at: center, rx: 13, ry: 16)
            context.fill(egg, with: .color(eggColors[index]))
            context.fill(egg, with: .radialGradient(
                Gradient(colors: [.white.opacity(0.42), .white.opacity(0), .black.opacity(0.16)]),
                center: CGPoint(x: center.x - 4 * s, y: center.y - 6 * s),
                startRadius: 0,
                endRadius: 18 * s
            ))
            var speckles = board.generator(salt: 0x4547_4700 + UInt64(index))
            for _ in 0..<7 {
                let angle = speckles.range(0...(2 * .pi))
                let radius = speckles.range(2...11) * s
                let dot = CGPoint(x: center.x + cos(angle) * radius * 0.8, y: center.y + sin(angle) * radius)
                let r = speckles.range(0.6...1.3) * s
                context.fill(
                    Path(ellipseIn: CGRect(x: dot.x - r, y: dot.y - r, width: r * 2, height: r * 2)),
                    with: .color(hideDark.opacity(0.7))
                )
            }
            context.stroke(egg, with: .color(hideDark.opacity(0.5)), lineWidth: max(0.5, 1 * s))
        }
        // A shadow under the clutch.
        context.fill(
            board.ellipse(at: CGPoint(x: nest.x, y: nest.y + 20 * s), rx: 46, ry: 8),
            with: .color(hideDark.opacity(0.12))
        )
    }
}
