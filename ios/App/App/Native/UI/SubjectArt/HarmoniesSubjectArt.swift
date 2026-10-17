import SwiftUI

// Harmonies: a meadow built from the game's wooden tokens. A lion-sun of
// alternating rays in the top right corner, two cranes in the sky, gray
// token mountains at the horizon, striped hills with a winding river across
// the foot, clusters of token trees at each side, a fox sitting in the
// meadow and a fringe of dark grass along the bottom edge. The middle of
// the board stays open sand.

extension BoardSubjectArtRenderer {
    static func drawTokenMeadow(in context: inout GraphicsContext, on board: BoardSubjectCanvas) {
        let p = board.point
        let s = board.scale
        let sunBlue = board.color("#3B6FC4")
        let gold = board.color("#F2C94C")
        let orange = board.color("#E08A3C")
        let ink = board.color("#3A2E1F")
        let violet = board.color("#7A5FB0")
        let teal = board.color("#3F9AA6")
        let tealLight = board.color("#7FC3CC")
        let bark = board.color("#8B5A3C")
        let leaf = board.color("#6BA35C")
        let leafDark = board.color("#4E8242")
        let leafLight = board.color("#86B874")
        let grass = board.color("#1E3A6E")
        let stoneDark = board.color("#7D8590")
        let stone = board.color("#8C949E")
        let stoneLight = board.color("#A9B1BA")

        // MARK: Lion-sun

        let sun = board.fromRight(72, 118)
        // Twenty-four rays, alternating gold and orange, tucked under the disc.
        var goldRays = Path()
        var orangeRays = Path()
        for index in 0..<24 {
            let angle = CGFloat(index) / 24 * 2 * .pi - .pi / 2
            let from = CGPoint(x: sun.x + cos(angle) * 58 * s, y: sun.y + sin(angle) * 58 * s)
            let to = CGPoint(x: sun.x + cos(angle) * 92 * s, y: sun.y + sin(angle) * 92 * s)
            if index.isMultiple(of: 2) {
                goldRays.move(to: from)
                goldRays.addLine(to: to)
            } else {
                orangeRays.move(to: from)
                orangeRays.addLine(to: to)
            }
        }
        let rayStyle = StrokeStyle(lineWidth: max(1, 6 * s), lineCap: .round)
        context.stroke(goldRays, with: .color(gold.opacity(0.92)), style: rayStyle)
        context.stroke(orangeRays, with: .color(orange.opacity(0.92)), style: rayStyle)
        context.fill(board.circle(at: sun, radius: 60), with: .color(sunBlue.opacity(0.92)))
        // A dotted ring for the mane.
        context.stroke(
            board.circle(at: sun, radius: 50),
            with: .color(gold.opacity(0.9)),
            style: StrokeStyle(
                lineWidth: max(1, 3.4 * s),
                lineCap: .round,
                dash: [max(0.1, 0.1 * s), max(1, 8.2 * s)]
            )
        )
        // The face: a round yellow token with two ears.
        var face = Path()
        face.addEllipse(in: CGRect(x: -33, y: -31, width: 66, height: 64))
        face.addEllipse(in: CGRect(x: -33, y: -36, width: 18, height: 18))
        face.addEllipse(in: CGRect(x: 15, y: -36, width: 18, height: 18))
        context.fill(board.placed(face, at: sun), with: .color(gold.opacity(0.96)))
        var innerEars = Path()
        innerEars.addEllipse(in: CGRect(x: -28, y: -31, width: 8, height: 8))
        innerEars.addEllipse(in: CGRect(x: 20, y: -31, width: 8, height: 8))
        context.fill(board.placed(innerEars, at: sun), with: .color(orange.opacity(0.9)))
        // Closed eyes, a nose, a cat's mouth and whiskers.
        var eyes = Path()
        eyes.move(to: CGPoint(x: -19, y: -5))
        eyes.addQuadCurve(to: CGPoint(x: -6, y: -5), control: CGPoint(x: -12.5, y: -14))
        eyes.move(to: CGPoint(x: 6, y: -5))
        eyes.addQuadCurve(to: CGPoint(x: 19, y: -5), control: CGPoint(x: 12.5, y: -14))
        context.stroke(
            board.placed(eyes, at: sun),
            with: .color(ink.opacity(0.9)),
            style: StrokeStyle(lineWidth: max(0.8, 2.4 * s), lineCap: .round)
        )
        var nose = Path()
        nose.move(to: CGPoint(x: -5.5, y: 6))
        nose.addLine(to: CGPoint(x: 5.5, y: 6))
        nose.addLine(to: CGPoint(x: 0, y: 13))
        nose.closeSubpath()
        context.fill(board.placed(nose, at: sun), with: .color(orange.opacity(0.95)))
        var mouth = Path()
        mouth.move(to: CGPoint(x: 0, y: 13))
        mouth.addLine(to: CGPoint(x: 0, y: 16))
        mouth.move(to: CGPoint(x: -8, y: 16))
        mouth.addQuadCurve(to: CGPoint(x: 0, y: 16), control: CGPoint(x: -4, y: 22))
        mouth.addQuadCurve(to: CGPoint(x: 8, y: 16), control: CGPoint(x: 4, y: 22))
        context.stroke(
            board.placed(mouth, at: sun),
            with: .color(ink.opacity(0.8)),
            style: StrokeStyle(lineWidth: max(0.6, 1.6 * s), lineCap: .round)
        )
        var whiskers = Path()
        for side: CGFloat in [-1, 1] {
            for (fromY, toY) in [(CGFloat(8), CGFloat(3)), (11, 11), (14, 19)] {
                whiskers.move(to: CGPoint(x: side * 9, y: fromY))
                whiskers.addLine(to: CGPoint(x: side * 29, y: toY))
            }
        }
        context.stroke(
            board.placed(whiskers, at: sun),
            with: .color(ink.opacity(0.7)),
            style: StrokeStyle(lineWidth: max(0.5, 1.3 * s), lineCap: .round)
        )

        // MARK: Cranes

        var crane = Path()
        crane.move(to: CGPoint(x: -16, y: 2))
        crane.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: -8, y: -10))
        crane.addQuadCurve(to: CGPoint(x: 16, y: 2), control: CGPoint(x: 8, y: -10))
        for (position, size) in [(p(72, 190), CGFloat(1)), (p(116, 150), 0.8)] {
            context.stroke(
                board.placed(crane, at: position, rotation: -0.12, scale: size),
                with: .color(ink.opacity(0.85)),
                style: StrokeStyle(lineWidth: max(0.8, 2.4 * s * size), lineCap: .round, lineJoin: .round)
            )
        }

        // MARK: Mountains

        // Three gray tokens stacked, each with a darker side showing below.
        let mountainLevels: [(radius: CGFloat, lift: CGFloat, color: Color)] = [
            (19, 0, stoneDark), (16, 13, stone), (13, 25, stoneLight)
        ]
        for base in [p(60, 738), board.fromRight(54, 736)] {
            for level in mountainLevels {
                let top = CGPoint(x: base.x, y: base.y - level.lift * s)
                let side = board.circle(at: CGPoint(x: top.x, y: top.y + 5 * s), radius: level.radius)
                context.fill(side, with: .color(level.color))
                context.fill(side, with: .color(ink.opacity(0.3)))
                context.fill(board.circle(at: top, radius: level.radius), with: .color(level.color.opacity(0.96)))
                // A glint along the upper left rim of each token.
                var glint = Path()
                glint.addArc(
                    center: top, radius: (level.radius - 3) * s,
                    startAngle: .degrees(190), endAngle: .degrees(250), clockwise: false
                )
                context.stroke(
                    glint,
                    with: .color(.white.opacity(0.35)),
                    style: StrokeStyle(lineWidth: max(0.6, 2 * s), lineCap: .round)
                )
            }
        }

        // MARK: Striped hills

        let hillBands: [(top: CGFloat, color: Color, phase: CGFloat)] = [
            (742, violet, 0), (776, teal, 0.5), (806, sunBlue, 1.0)
        ]
        let waveWidth = board.width / 4
        let floor = board.height + 2 * s
        for band in hillBands {
            let edge = p(0, band.top).y
            var hill = Path()
            hill.move(to: CGPoint(x: -2 * s, y: floor))
            var x = -waveWidth * band.phase
            hill.addLine(to: CGPoint(x: x, y: edge))
            var crest = true
            while x < board.width + waveWidth {
                hill.addQuadCurve(
                    to: CGPoint(x: x + waveWidth, y: edge),
                    control: CGPoint(x: x + waveWidth / 2, y: edge + (crest ? -10 : 8) * s)
                )
                x += waveWidth
                crest.toggle()
            }
            hill.addLine(to: CGPoint(x: x, y: floor))
            hill.closeSubpath()
            context.fill(hill, with: .color(band.color.opacity(0.9)))
            // Faint vertical hatching, like the grain of a painted token.
            var hatch = Path()
            var hx = 3 * s
            while hx < board.width {
                hatch.move(to: CGPoint(x: hx, y: edge - 12 * s))
                hatch.addLine(to: CGPoint(x: hx, y: floor))
                hx += 7 * s
            }
            var hatched = context
            hatched.clip(to: hill)
            hatched.stroke(hatch, with: .color(.white.opacity(0.22)), lineWidth: max(0.5, 1 * s))
        }

        // MARK: River

        var river = Path()
        river.move(to: p(-12, 796))
        river.addCurve(to: p(140, 778), control1: p(40, 800), control2: p(92, 772))
        river.addCurve(to: p(268, 796), control1: p(190, 786), control2: p(230, 804))
        river.addCurve(to: p(402, 774), control1: p(312, 788), control2: p(352, 768))
        context.stroke(
            river,
            with: .color(ink.opacity(0.22)),
            style: StrokeStyle(lineWidth: max(1, 27 * s), lineCap: .round)
        )
        context.stroke(
            river,
            with: .color(teal.opacity(0.95)),
            style: StrokeStyle(lineWidth: max(1, 25 * s), lineCap: .round)
        )
        context.stroke(
            river,
            with: .color(tealLight.opacity(0.9)),
            style: StrokeStyle(lineWidth: max(0.6, 2.4 * s), lineCap: .round)
        )
        var ripples = Path()
        for (from, control, to) in [
            (p(48, 788), p(58, 782), p(68, 788)),
            (p(118, 776), p(128, 770), p(138, 776)),
            (p(226, 798), p(236, 792), p(246, 798)),
            (p(336, 774), p(346, 768), p(356, 774))
        ] {
            ripples.move(to: from)
            ripples.addQuadCurve(to: to, control: control)
        }
        context.stroke(
            ripples,
            with: .color(tealLight.opacity(0.9)),
            style: StrokeStyle(lineWidth: max(0.6, 1.8 * s), lineCap: .round)
        )

        // MARK: Token trees

        let trees: [(base: CGPoint, tall: Bool)] = [
            (p(34, 822), true), (p(60, 836), false), (p(86, 824), true),
            (board.fromRight(98, 824), true), (board.fromRight(70, 838), false), (board.fromRight(42, 822), true)
        ]
        for tree in trees {
            let base = tree.base
            let trunk = Path(
                roundedRect: CGRect(x: base.x - 4 * s, y: base.y - 24 * s, width: 8 * s, height: 24 * s),
                cornerRadius: 3 * s
            )
            context.fill(trunk, with: .color(bark.opacity(0.95)))
            let canopy = CGPoint(x: base.x, y: base.y - 28 * s)
            context.fill(
                board.circle(at: CGPoint(x: canopy.x, y: canopy.y + 4 * s), radius: 12),
                with: .color(leafDark.opacity(0.95))
            )
            context.fill(board.circle(at: canopy, radius: 12), with: .color(leaf.opacity(0.95)))
            if tree.tall {
                let crown = CGPoint(x: base.x, y: canopy.y - 15 * s)
                context.fill(
                    board.circle(at: CGPoint(x: crown.x, y: crown.y + 4 * s), radius: 10),
                    with: .color(leaf.opacity(0.95))
                )
                context.fill(board.circle(at: crown, radius: 10), with: .color(leafLight.opacity(0.95)))
            }
        }

        // MARK: Fox

        let foxAt = p(222, 819)
        let foxScale: CGFloat = 0.8
        var tail = Path()
        tail.addEllipse(in: CGRect(x: 2, y: 2, width: 40, height: 18))
        context.fill(
            board.placed(tail, at: foxAt, rotation: -0.35, scale: foxScale),
            with: .color(orange.opacity(0.95))
        )
        let tailTip = board.placed(
            Path(ellipseIn: CGRect(x: 33, y: 4, width: 12, height: 12)),
            at: foxAt, rotation: -0.35, scale: foxScale
        )
        context.fill(tailTip, with: .color(.white.opacity(0.92)))
        var foxBody = Path()
        foxBody.addEllipse(in: CGRect(x: -15, y: -18, width: 30, height: 40))
        foxBody.addEllipse(in: CGRect(x: -11, y: -35, width: 22, height: 22))
        foxBody.move(to: CGPoint(x: -11, y: -30))
        foxBody.addLine(to: CGPoint(x: -13, y: -44))
        foxBody.addLine(to: CGPoint(x: -2, y: -34))
        foxBody.closeSubpath()
        foxBody.move(to: CGPoint(x: 11, y: -30))
        foxBody.addLine(to: CGPoint(x: 13, y: -44))
        foxBody.addLine(to: CGPoint(x: 2, y: -34))
        foxBody.closeSubpath()
        context.fill(board.placed(foxBody, at: foxAt, scale: foxScale), with: .color(orange.opacity(0.95)))
        var foxChest = Path()
        foxChest.addEllipse(in: CGRect(x: -8, y: -6, width: 16, height: 24))
        foxChest.addEllipse(in: CGRect(x: -5, y: -24, width: 10, height: 8))
        context.fill(board.placed(foxChest, at: foxAt, scale: foxScale), with: .color(.white.opacity(0.9)))
        var foxFace = Path()
        foxFace.addEllipse(in: CGRect(x: -5.4, y: -27.4, width: 2.8, height: 2.8))
        foxFace.addEllipse(in: CGRect(x: 2.6, y: -27.4, width: 2.8, height: 2.8))
        foxFace.addEllipse(in: CGRect(x: -1.8, y: -22.2, width: 3.6, height: 3.2))
        context.fill(board.placed(foxFace, at: foxAt, scale: foxScale), with: .color(ink.opacity(0.95)))

        // MARK: Grass fringe

        var blades = board.generator(salt: 0x4841_524D_0001)
        var fringe = Path()
        fringe.move(to: CGPoint(x: -2 * s, y: floor))
        var gx: CGFloat = 0
        var step = 9 * s
        while gx < board.width + step {
            step = blades.range(6...12) * s
            let height = blades.range(6...18) * s
            let lean = blades.range(-0.25...0.25)
            fringe.addLine(to: CGPoint(x: gx + step * (0.5 + lean), y: board.height - height))
            fringe.addLine(to: CGPoint(x: gx + step, y: board.height - 2 * s))
            gx += step
        }
        fringe.addLine(to: CGPoint(x: gx, y: floor))
        fringe.closeSubpath()
        context.fill(fringe, with: .color(grass.opacity(0.9)))
    }
}
