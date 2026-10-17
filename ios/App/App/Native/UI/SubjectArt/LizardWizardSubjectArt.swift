import SwiftUI

// Lizard Wizard: a gecko in a wizard's hat climbing the left edge of the
// board, seen from above with four splayed, pad-toed feet and a curling tail;
// a crescent moon and seven stars across the top; at the lower right a
// cauldron of teal brew with bubbles rising and a round flask of green potion
// beside it, with a few gold sparkles.

extension BoardSubjectArtRenderer {
    static func drawLizardWizardry(in context: inout GraphicsContext, on board: BoardSubjectCanvas) {
        let p = board.point
        let s = board.scale
        let skin = board.color("#2F6FB5")
        let stripe = board.color("#72813A")
        let gold = board.color("#F0C060")
        let felt = board.color("#5A3A5E")
        let shadow = board.color("#2A1A30")
        let moon = board.color("#F6E6C6")
        let brew = board.color("#1697A9")
        let potion = board.color("#9BB33A")

        func star(_ radius: CGFloat, at center: CGPoint) -> Path {
            var path = Path()
            let waist = radius * 0.32
            path.move(to: CGPoint(x: center.x, y: center.y - radius))
            path.addLine(to: CGPoint(x: center.x + waist, y: center.y - waist))
            path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
            path.addLine(to: CGPoint(x: center.x + waist, y: center.y + waist))
            path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
            path.addLine(to: CGPoint(x: center.x - waist, y: center.y + waist))
            path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
            path.addLine(to: CGPoint(x: center.x - waist, y: center.y - waist))
            path.closeSubpath()
            return path
        }
        func stroked(_ path: Path, width: CGFloat) -> Path {
            path.strokedPath(StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        }

        // MARK: Moon and stars

        // A crescent: the outer circle's arc around its left side, then the
        // bite circle's arc back, sampled so no arc-direction convention matters.
        let outerRadius: CGFloat = 33
        let biteRadius: CGFloat = 29
        let bite: CGFloat = 13
        let meetX = (bite * bite + outerRadius * outerRadius - biteRadius * biteRadius) / (2 * bite)
        let meetY = (outerRadius * outerRadius - meetX * meetX).squareRoot()
        let outerStart = atan2(-meetY, meetX)
        let outerSweep = -(2 * Double.pi - 2 * abs(outerStart))
        let innerStart = atan2(meetY, meetX - bite)
        let innerSweep = 2 * Double.pi - 2 * innerStart
        let arcSteps = 24
        var crescent = Path()
        crescent.move(to: CGPoint(x: cos(outerStart) * outerRadius, y: sin(outerStart) * outerRadius))
        for index in 1...arcSteps {
            let angle = outerStart + outerSweep * Double(index) / Double(arcSteps)
            crescent.addLine(to: CGPoint(x: cos(angle) * outerRadius, y: sin(angle) * outerRadius))
        }
        for index in 0...arcSteps {
            let angle = innerStart + innerSweep * Double(index) / Double(arcSteps)
            crescent.addLine(to: CGPoint(x: bite + cos(angle) * biteRadius, y: sin(angle) * biteRadius))
        }
        crescent.closeSubpath()
        let moonCenter = p(320, 90)
        var halo = context
        halo.addFilter(.blur(radius: max(4, 10 * s)))
        halo.fill(board.circle(at: moonCenter, radius: 38), with: .color(moon.opacity(0.22)))
        context.fill(
            board.placed(crescent, at: moonCenter, rotation: -25 * Double.pi / 180),
            with: .color(moon.opacity(0.94))
        )

        var paleStars = Path()
        var goldStars = Path()
        let starField: [(x: CGFloat, y: CGFloat, radius: CGFloat)] = [
            (36, 52, 5), (92, 118, 3.5), (146, 36, 4.5), (206, 96, 3), (256, 44, 5.5), (372, 36, 3.5), (360, 160, 4)
        ]
        for (index, item) in starField.enumerated() {
            let placed = board.placed(star(item.radius, at: .zero), at: p(item.x, item.y))
            if index.isMultiple(of: 2) { paleStars.addPath(placed) } else { goldStars.addPath(placed) }
        }
        context.fill(paleStars, with: .color(moon.opacity(0.9)))
        context.fill(goldStars, with: .color(gold.opacity(0.9)))

        // MARK: The lizard

        // Authored around its own origin pointing up the board, then leaned a
        // little to the right and set on the left edge.
        let lizardOrigin = p(72, 545)
        let lizardPlacement = CGAffineTransform(scaleX: s, y: s)
            .concatenating(CGAffineTransform(rotationAngle: 10 * Double.pi / 180))
            .concatenating(CGAffineTransform(translationX: lizardOrigin.x, y: lizardOrigin.y))

        var body = Path()
        body.move(to: CGPoint(x: 0, y: -82))
        body.addQuadCurve(to: CGPoint(x: 14, y: -50), control: CGPoint(x: 13, y: -72))
        body.addQuadCurve(to: CGPoint(x: 10, y: -44), control: CGPoint(x: 14, y: -46))
        body.addCurve(to: CGPoint(x: 9, y: 50), control1: CGPoint(x: 28, y: -20), control2: CGPoint(x: 24, y: 30))
        body.addQuadCurve(to: CGPoint(x: -9, y: 50), control: CGPoint(x: 0, y: 58))
        body.addCurve(to: CGPoint(x: -10, y: -44), control1: CGPoint(x: -24, y: 30), control2: CGPoint(x: -28, y: -20))
        body.addQuadCurve(to: CGPoint(x: -14, y: -50), control: CGPoint(x: -14, y: -46))
        body.addQuadCurve(to: CGPoint(x: 0, y: -82), control: CGPoint(x: -13, y: -72))
        body.closeSubpath()

        var flesh = Path()
        flesh.addPath(body)
        // The tail: thinning segments, swinging left and curling back.
        let tailSegments: [(to: CGPoint, control1: CGPoint, control2: CGPoint, width: CGFloat)] = [
            (to: CGPoint(x: -6, y: 112), control1: CGPoint(x: 4, y: 78), control2: CGPoint(x: 2, y: 100), width: 14),
            (to: CGPoint(x: -34, y: 146), control1: CGPoint(x: -16, y: 126), control2: CGPoint(x: -24, y: 140), width: 9),
            (to: CGPoint(x: -20, y: 176), control1: CGPoint(x: -46, y: 156), control2: CGPoint(x: -38, y: 176), width: 6),
            (to: CGPoint(x: -4, y: 158), control1: CGPoint(x: -6, y: 176), control2: CGPoint(x: -2, y: 168), width: 3.5)
        ]
        var tailFrom = CGPoint(x: 0, y: 46)
        for segment in tailSegments {
            var piece = Path()
            piece.move(to: tailFrom)
            piece.addCurve(to: segment.to, control1: segment.control1, control2: segment.control2)
            flesh.addPath(stroked(piece, width: segment.width))
            tailFrom = segment.to
        }
        // Four legs: front pair reaching up and out, hind pair back and out,
        // each foot fanning four toes with round pads.
        var pads = Path()
        for sign in [-1.0, 1.0] as [CGFloat] {
            for (shoulder, joint, foot) in [
                (CGPoint(x: 14, y: -40), CGPoint(x: 36, y: -30), CGPoint(x: 50, y: -50)),
                (CGPoint(x: 14, y: 24), CGPoint(x: 40, y: 14), CGPoint(x: 50, y: 42))
            ] {
                let a = CGPoint(x: shoulder.x * sign, y: shoulder.y)
                let b = CGPoint(x: joint.x * sign, y: joint.y)
                let c = CGPoint(x: foot.x * sign, y: foot.y)
                var limb = Path()
                limb.move(to: a)
                limb.addLine(to: b)
                limb.addLine(to: c)
                flesh.addPath(stroked(limb, width: 8))
                let heading = atan2(c.y - b.y, c.x - b.x)
                for spread in [-0.95, -0.32, 0.32, 0.95] as [CGFloat] {
                    let angle = heading + spread
                    let tip = CGPoint(x: c.x + cos(angle) * 11, y: c.y + sin(angle) * 11)
                    var toe = Path()
                    toe.move(to: c)
                    toe.addLine(to: tip)
                    flesh.addPath(stroked(toe, width: 3.2))
                    pads.addEllipse(in: CGRect(x: tip.x - 2.4, y: tip.y - 2.4, width: 4.8, height: 4.8))
                }
            }
        }
        flesh.addPath(pads)
        let placedFlesh = flesh.applying(lizardPlacement)
        context.stroke(placedFlesh, with: .color(shadow.opacity(0.75)), style: StrokeStyle(lineWidth: max(0.8, 1.8 * s), lineJoin: .round))
        context.fill(placedFlesh, with: .color(skin.opacity(0.93)))

        var spine = Path()
        spine.move(to: CGPoint(x: 0, y: -46))
        spine.addCurve(to: CGPoint(x: 0, y: 48), control1: CGPoint(x: 3, y: -10), control2: CGPoint(x: -3, y: 20))
        context.fill(stroked(spine, width: 7).applying(lizardPlacement), with: .color(stripe.opacity(0.88)))
        var eye = Path()
        eye.addEllipse(in: CGRect(x: 4, y: -67, width: 6, height: 6))
        eye.addEllipse(in: CGRect(x: -10, y: -67, width: 6, height: 6))
        context.fill(eye.applying(lizardPlacement), with: .color(gold.opacity(0.97)))
        var pupil = Path()
        pupil.addEllipse(in: CGRect(x: 6.2, y: -65.6, width: 1.8, height: 3.4))
        pupil.addEllipse(in: CGRect(x: -8, y: -65.6, width: 1.8, height: 3.4))
        context.fill(pupil.applying(lizardPlacement), with: .color(shadow.opacity(0.95)))

        // The hat, drawn in profile and tilted over the left of the head so the
        // snout and one eye stay clear: a cone with a drooping tip, a band and
        // a brim.
        let hatPlacement = CGAffineTransform(rotationAngle: -50 * Double.pi / 180)
            .concatenating(CGAffineTransform(translationX: -9, y: -58))
            .concatenating(lizardPlacement)
        var cone = Path()
        cone.move(to: CGPoint(x: -14, y: -2))
        cone.addQuadCurve(to: CGPoint(x: -2, y: -44), control: CGPoint(x: -11, y: -30))
        cone.addQuadCurve(to: CGPoint(x: -18, y: -62), control: CGPoint(x: -5, y: -54))
        cone.addQuadCurve(to: CGPoint(x: -15, y: -65), control: CGPoint(x: -21, y: -66))
        cone.addQuadCurve(to: CGPoint(x: 8, y: -46), control: CGPoint(x: -2, y: -62))
        cone.addQuadCurve(to: CGPoint(x: 14, y: -2), control: CGPoint(x: 14, y: -28))
        cone.closeSubpath()
        var hatBand = Path()
        hatBand.move(to: CGPoint(x: -12.5, y: -5))
        hatBand.addLine(to: CGPoint(x: 12.5, y: -5))
        hatBand.addLine(to: CGPoint(x: 11, y: -11))
        hatBand.addLine(to: CGPoint(x: -11, y: -11))
        hatBand.closeSubpath()
        let brim = Path(ellipseIn: CGRect(x: -22, y: -6, width: 44, height: 12))
        var hatStars = Path()
        hatStars.addPath(star(5, at: CGPoint(x: -2, y: -24)))
        hatStars.addPath(star(3.5, at: CGPoint(x: 3, y: -36)))
        let placedCone = cone.applying(hatPlacement)
        context.fill(placedCone, with: .color(felt.opacity(0.95)))
        context.stroke(placedCone, with: .color(shadow.opacity(0.8)), style: StrokeStyle(lineWidth: max(0.6, 1.4 * s), lineJoin: .round))
        context.fill(hatBand.applying(hatPlacement), with: .color(shadow.opacity(0.8)))
        let placedBrim = brim.applying(hatPlacement)
        context.fill(placedBrim, with: .color(felt.opacity(0.97)))
        context.stroke(placedBrim, with: .color(shadow.opacity(0.8)), lineWidth: max(0.6, 1.4 * s))
        context.fill(hatStars.applying(hatPlacement), with: .color(gold.opacity(0.95)))

        // MARK: Cauldron and flask

        let potCenter = p(300, 770)
        var legs = Path()
        for x in [-28.0, -4.5, 19.0] as [CGFloat] {
            legs.addRoundedRect(in: CGRect(x: x, y: x == -4.5 ? 22 : 16, width: 9, height: 14), cornerSize: CGSize(width: 3, height: 3))
        }
        context.fill(board.placed(legs, at: potCenter), with: .color(shadow.opacity(0.95)))
        var pot = Path()
        pot.move(to: CGPoint(x: -38, y: -26))
        pot.addCurve(to: CGPoint(x: 38, y: -26), control1: CGPoint(x: -58, y: 42), control2: CGPoint(x: 58, y: 42))
        pot.closeSubpath()
        let placedPot = board.placed(pot, at: potCenter)
        context.fill(placedPot, with: .color(shadow.opacity(0.96)))
        var potLight = Path()
        potLight.move(to: CGPoint(x: -36, y: -20))
        potLight.addQuadCurve(to: CGPoint(x: -12, y: 20), control: CGPoint(x: -44, y: 12))
        context.stroke(
            board.placed(potLight, at: potCenter),
            with: .color(felt.opacity(0.85)),
            style: StrokeStyle(lineWidth: max(0.8, 2.6 * s), lineCap: .round)
        )
        let rim = board.placed(Path(ellipseIn: CGRect(x: -44, y: -34, width: 88, height: 16)), at: potCenter)
        context.fill(rim, with: .color(shadow.opacity(0.97)))
        context.stroke(rim, with: .color(felt.opacity(0.85)), lineWidth: max(0.5, 1.3 * s))
        context.fill(
            board.placed(Path(ellipseIn: CGRect(x: -36, y: -31, width: 72, height: 10)), at: potCenter),
            with: .color(brew.opacity(0.85))
        )
        var bubbles = Path()
        for (x, y, radius) in [(-10, -42, 5), (9, -54, 3.6), (-3, -70, 4.6), (14, -86, 3), (-13, -98, 2.6), (3, -114, 2)] as [(CGFloat, CGFloat, CGFloat)] {
            bubbles.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        }
        let placedBubbles = board.placed(bubbles, at: potCenter)
        context.fill(placedBubbles, with: .color(brew.opacity(0.35)))
        context.stroke(placedBubbles, with: .color(brew.opacity(0.9)), lineWidth: max(0.5, 1.2 * s))

        let flaskCenter = p(236, 804)
        let bulb = Path(ellipseIn: CGRect(x: -16, y: -16, width: 32, height: 32))
        var liquid = context
        liquid.clip(to: board.placed(Path(CGRect(x: -20, y: -3, width: 40, height: 30)), at: flaskCenter))
        liquid.fill(board.placed(bulb, at: flaskCenter), with: .color(potion.opacity(0.9)))
        var glass = Path()
        glass.addPath(bulb)
        glass.addRoundedRect(in: CGRect(x: -5, y: -36, width: 10, height: 22), cornerSize: CGSize(width: 2, height: 2))
        let placedGlass = board.placed(glass, at: flaskCenter)
        context.fill(placedGlass, with: .color(moon.opacity(0.14)))
        context.stroke(placedGlass, with: .color(moon.opacity(0.78)), lineWidth: max(0.5, 1.3 * s))
        context.fill(board.placed(Path(roundedRect: CGRect(x: -4.5, y: -43, width: 9, height: 8), cornerRadius: 1.5), at: flaskCenter), with: .color(gold.opacity(0.9)))
        var glint = Path()
        glint.move(to: CGPoint(x: -11, y: -4))
        glint.addQuadCurve(to: CGPoint(x: -4, y: -11), control: CGPoint(x: -10, y: -10))
        context.stroke(board.placed(glint, at: flaskCenter), with: .color(moon.opacity(0.6)), style: StrokeStyle(lineWidth: max(0.5, 1.6 * s), lineCap: .round))

        // MARK: Sparkles

        var sparkles = board.generator(salt: 0x4C49_5A41_5244)
        var dots = Path()
        var glints = Path()
        for (index, anchor) in [p(30, 452), p(300, 640)].enumerated() {
            for count in 0..<6 {
                let angle = sparkles.range(0...(2 * .pi))
                let distance = sparkles.range(10...(index == 0 ? 34 : 48)) * s
                let center = CGPoint(x: anchor.x + cos(angle) * distance, y: anchor.y + sin(angle) * distance)
                if count < 2 {
                    glints.addPath(board.placed(star(sparkles.range(3...4.5), at: .zero), at: center))
                } else {
                    let r = sparkles.range(1.2...2.4) * s
                    dots.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
                }
            }
        }
        context.fill(dots, with: .color(gold.opacity(0.9)))
        context.fill(glints, with: .color(gold.opacity(0.9)))
    }
}
