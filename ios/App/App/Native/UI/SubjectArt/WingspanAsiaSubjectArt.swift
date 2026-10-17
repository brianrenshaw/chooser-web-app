import SwiftUI

// Wingspan Asia: a peacock's train fanned up from below the bottom edge. Nine
// slender quills radiate from a point under the board, bowing outward, each
// carrying a translucent vane fringed with barbs that lengthen toward a
// teardrop eye-spot of green, blue, teal and gold; a small teal peacock with
// a three-dot crest sits at the bottom center where the quills meet. The
// train stays translucent so the pieces sit on top of it.

extension BoardSubjectArtRenderer {
    static func drawPeacockFan(in context: inout GraphicsContext, on board: BoardSubjectCanvas) {
        let p = board.point
        let s = board.scale
        let green = board.color("#0C6B4D")
        let blue = board.color("#20539A")
        let teal = board.color("#2BA5A1")
        let gold = board.color("#D4A42E")
        // The bird and the root of the train are measured up from the bottom
        // edge, so the peacock keeps its full height on a wide board.
        let b = board.fromBottom
        let origin = b(195, -56)

        // MARK: Quills, vanes and barbs

        // Eye-spots sit on a tall arch; the quills reach them from the body.
        let tips = [
            p(30, 660), p(50, 480), p(84, 318), p(128, 178), p(195, 96),
            p(262, 178), p(306, 318), p(340, 480), p(360, 660)
        ]
        let vaneStart: CGFloat = 0.5
        let vaneEnd: CGFloat = 0.96
        var quills = Path()
        var vanes = Path()
        var barbs = Path()
        var rotations: [Double] = []
        for tip in tips {
            let dx = tip.x - origin.x
            let dy = tip.y - origin.y
            let length = max(1, hypot(dx, dy))
            let side: CGFloat = dx < -0.5 ? -1 : (dx > 0.5 ? 1 : 0)
            // Bow each quill away from the center line so the train opens.
            let control = CGPoint(
                x: origin.x + dx * 0.5 + side * (-dy / length) * length * 0.09,
                y: origin.y + dy * 0.5 + side * (dx / length) * length * 0.09
            )
            quills.move(to: origin)
            quills.addQuadCurve(to: tip, control: control)
            rotations.append(atan2(Double(-(origin.x - tip.x)), Double(origin.y - tip.y)))

            /// A point on the quill and the unit directions along and across it.
            func along(_ t: CGFloat) -> (point: CGPoint, ahead: CGPoint, across: CGPoint) {
                let u = 1 - t
                let point = CGPoint(
                    x: u * u * origin.x + 2 * u * t * control.x + t * t * tip.x,
                    y: u * u * origin.y + 2 * u * t * control.y + t * t * tip.y
                )
                let tangent = CGPoint(
                    x: 2 * u * (control.x - origin.x) + 2 * t * (tip.x - control.x),
                    y: 2 * u * (control.y - origin.y) + 2 * t * (tip.y - control.y)
                )
                let magnitude = max(1, hypot(tangent.x, tangent.y))
                let ahead = CGPoint(x: tangent.x / magnitude, y: tangent.y / magnitude)
                return (point, ahead, CGPoint(x: -ahead.y, y: ahead.x))
            }

            // The vane: a slender leaf that widens toward the eye.
            var leftEdge: [CGPoint] = []
            var rightEdge: [CGPoint] = []
            for step in 0...8 {
                let progress = CGFloat(step) / 8
                let (point, _, across) = along(vaneStart + (vaneEnd - vaneStart) * progress)
                let halfWidth = (1.5 + 10 * progress) * s
                leftEdge.append(CGPoint(x: point.x + across.x * halfWidth, y: point.y + across.y * halfWidth))
                rightEdge.append(CGPoint(x: point.x - across.x * halfWidth, y: point.y - across.y * halfWidth))
            }
            vanes.move(to: leftEdge[0])
            for point in leftEdge.dropFirst() { vanes.addLine(to: point) }
            for point in rightEdge.reversed() { vanes.addLine(to: point) }
            vanes.closeSubpath()

            // Barbs: short strokes leaning toward the tip, longer near the eye.
            let spacing = 20 * s
            let steps = max(2, Int(length * (vaneEnd - vaneStart) / spacing))
            for step in 0..<steps {
                let progress = CGFloat(step) / CGFloat(steps)
                let (point, ahead, across) = along(vaneStart + (vaneEnd - vaneStart) * progress)
                let reach = (4 + 11 * progress) * s
                for sign in [CGFloat(-1), 1] {
                    barbs.move(to: point)
                    barbs.addLine(to: CGPoint(
                        x: point.x + (ahead.x * 0.45 + across.x * 0.89 * sign) * reach,
                        y: point.y + (ahead.y * 0.45 + across.y * 0.89 * sign) * reach
                    ))
                }
            }
        }
        context.fill(vanes, with: .color(green.opacity(0.34)))
        context.stroke(barbs, with: .color(green.opacity(0.55)), style: StrokeStyle(lineWidth: max(0.4, 0.8 * s), lineCap: .round))
        context.stroke(quills, with: .color(teal.opacity(0.62)), style: StrokeStyle(lineWidth: max(0.6, 2.2 * s), lineCap: .round))

        // MARK: Eye-spots

        // Authored with the quill entering from below (+y) and the tip above.
        var drop = Path()
        drop.move(to: CGPoint(x: 0, y: 30))
        drop.addCurve(to: CGPoint(x: -20, y: -4), control1: CGPoint(x: -9, y: 22), control2: CGPoint(x: -20, y: 10))
        drop.addCurve(to: CGPoint(x: 0, y: -26), control1: CGPoint(x: -20, y: -16), control2: CGPoint(x: -11, y: -26))
        drop.addCurve(to: CGPoint(x: 20, y: -4), control1: CGPoint(x: 11, y: -26), control2: CGPoint(x: 20, y: -16))
        drop.addCurve(to: CGPoint(x: 0, y: 30), control1: CGPoint(x: 20, y: 10), control2: CGPoint(x: 9, y: 22))
        drop.closeSubpath()
        let eyeScale: CGFloat = 1.35

        // One soft halo of vane behind every eye.
        var halo = Path()
        for (tip, rotation) in zip(tips, rotations) {
            halo.addPath(board.placed(drop, at: tip, rotation: rotation, scale: eyeScale * 1.4))
        }
        var soft = context
        soft.addFilter(.blur(radius: 8 * s))
        soft.fill(halo, with: .color(green.opacity(0.42)))

        for (tip, rotation) in zip(tips, rotations) {
            func ring(_ path: Path) -> Path { board.placed(path, at: tip, rotation: rotation, scale: eyeScale) }
            let outer = ring(drop)
            context.fill(outer, with: .color(green.opacity(0.76)))
            context.stroke(outer, with: .color(green.opacity(0.95)), lineWidth: max(0.5, 1 * s))
            context.fill(ring(Path(ellipseIn: CGRect(x: -13, y: -20, width: 26, height: 30))), with: .color(blue.opacity(0.9)))
            context.fill(ring(Path(ellipseIn: CGRect(x: -8, y: -16.5, width: 16, height: 19))), with: .color(teal.opacity(0.92)))
            context.fill(ring(Path(ellipseIn: CGRect(x: -3.6, y: -11.6, width: 7.2, height: 7.2))), with: .color(gold.opacity(0.95)))
            context.fill(ring(Path(ellipseIn: CGRect(x: -4.6, y: -14, width: 3.4, height: 3.4))), with: .color(.white.opacity(0.5)))
        }

        // MARK: Peacock

        // In profile, facing left, rising from the bottom edge over the quills.
        let torso = board.ellipse(at: b(198, 2), rx: 46, ry: 34)
        let neck = board.taperedStroke(
            from: b(186, 20),
            segments: [(to: b(198, 66), control1: b(178, 38), control2: b(190, 54), width: 14)]
        )
        let head = board.circle(at: b(199, 72), radius: 10)
        var bird = Path()
        bird.addPath(torso)
        bird.addPath(neck)
        bird.addPath(head)
        var beak = Path()
        beak.move(to: b(192, 76))
        beak.addLine(to: b(176, 70))
        beak.addLine(to: b(192, 67))
        beak.closeSubpath()
        bird.addPath(beak)
        context.stroke(bird, with: .color(green.opacity(0.9)), lineWidth: max(0.8, 2.6 * s))
        context.fill(bird, with: .color(teal.opacity(0.95)))
        // A folded wing, and a light along the breast and the crown.
        var wing = Path()
        wing.move(to: b(206, 28))
        wing.addQuadCurve(to: b(246, -2), control: b(246, 32))
        wing.addQuadCurve(to: b(206, 28), control: b(214, 4))
        wing.closeSubpath()
        context.fill(wing, with: .color(green.opacity(0.55)))
        var sheen = Path()
        sheen.move(to: b(164, 8))
        sheen.addQuadCurve(to: b(180, 32), control: b(166, 24))
        sheen.move(to: b(193, 80))
        sheen.addQuadCurve(to: b(204, 81), control: b(198, 84))
        context.stroke(sheen, with: .color(.white.opacity(0.3)), style: StrokeStyle(lineWidth: max(0.6, 2.4 * s), lineCap: .round))
        context.fill(board.circle(at: b(196, 74), radius: 1.9), with: .color(.black.opacity(0.75)))

        // The crest: three stems, three dots.
        let crestTips = [b(189, 96), b(199, 101), b(209, 96)]
        var crestStems = Path()
        for end in crestTips {
            crestStems.move(to: b(199, 82))
            crestStems.addLine(to: end)
        }
        context.stroke(crestStems, with: .color(teal.opacity(0.95)), style: StrokeStyle(lineWidth: max(0.5, 1.2 * s), lineCap: .round))
        for end in crestTips {
            context.fill(board.circle(at: end, radius: 3.4), with: .color(teal.opacity(0.95)))
            context.fill(board.circle(at: end, radius: 1.4), with: .color(gold.opacity(0.95)))
        }
    }
}
