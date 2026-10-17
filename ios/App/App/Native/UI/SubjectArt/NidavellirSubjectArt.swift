import SwiftUI

// Nidavellir: a dwarven hall, abstracted. A great segmental arch of stone
// blocks hangs across the top edge, two gold inlay channels running its
// length and a small carved mark on every block; its keystone carries a round
// shield mounted over crossed axes. At the foot an anvil stands on a stone
// block in the forge glow, sparks rising from its face and a hammer leaning
// against the block. The middle of the board stays open slate.

extension BoardSubjectArtRenderer {
    static func drawDwarvenForge(in context: inout GraphicsContext, on board: BoardSubjectCanvas) {
        let p = board.point
        let s = board.scale
        let stone = board.color("#2A3034")
        let stoneDark = board.color("#1E2226")
        let mortar = board.color("#9AA3AA")
        let inlay = board.color("#C9A03A")
        let spark = board.color("#D4A93A")
        let shieldField = board.participant(4)

        // The arch hangs from the top edge and the forge stands on the bottom
        // one, so both are measured from their edge (like `fromBottom`) rather
        // than squashed with the board's height.
        func top(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * board.sx, y: y * s) }
        func foot(_ x: CGFloat, _ y: CGFloat) -> CGPoint { board.fromBottom(x, 844 - y) }

        // MARK: The arch

        // The arch's circle sits above the board, so the band springs from the
        // top edge near x 40 and x 350 and dips to its keystone at y 60. Angles
        // are measured from the downward vertical, positive to the right.
        let archCenter = CGPoint(x: 195, y: -170)
        let innerRadius: CGFloat = 206
        let outerRadius: CGFloat = 256
        let reach = 52 * Double.pi / 180
        let steps = 22
        func archPoint(_ radius: CGFloat, _ angle: Double) -> CGPoint {
            top(archCenter.x + radius * CGFloat(sin(angle)), archCenter.y + radius * CGFloat(cos(angle)))
        }
        func arc(_ radius: CGFloat, from: Double, to: Double) -> Path {
            var path = Path()
            path.move(to: archPoint(radius, from))
            for index in 1...steps {
                path.addLine(to: archPoint(radius, from + (to - from) * Double(index) / Double(steps)))
            }
            return path
        }

        var band = Path()
        band.move(to: archPoint(outerRadius, -reach))
        for index in 1...steps {
            band.addLine(to: archPoint(outerRadius, -reach + 2 * reach * Double(index) / Double(steps)))
        }
        for index in 0...steps {
            band.addLine(to: archPoint(innerRadius, reach - 2 * reach * Double(index) / Double(steps)))
        }
        band.closeSubpath()

        // A soft shadow under the lower edge lifts the arch off the wall.
        var shadow = context
        shadow.addFilter(.blur(radius: max(2, 5 * s)))
        shadow.stroke(
            arc(outerRadius + 4, from: -reach, to: reach),
            with: .color(stoneDark.opacity(0.55)),
            lineWidth: max(2, 9 * s)
        )
        context.fill(band, with: .color(stone.opacity(0.94)))

        // Mortar: radial joints between the blocks, and both edges of the band.
        var joints = Path()
        for degrees in [6.0, 15.0, 24.0, 33.0, 42.0] {
            for sign in [-1.0, 1.0] {
                let angle = sign * degrees * Double.pi / 180
                joints.move(to: archPoint(innerRadius, angle))
                joints.addLine(to: archPoint(outerRadius, angle))
            }
        }
        context.stroke(joints, with: .color(mortar.opacity(0.55)), lineWidth: max(0.5, 1.3 * s))
        context.stroke(arc(innerRadius, from: -reach, to: reach), with: .color(mortar.opacity(0.3)), lineWidth: max(0.5, 1.2 * s))
        context.stroke(arc(outerRadius, from: -reach, to: reach), with: .color(mortar.opacity(0.6)), lineWidth: max(0.6, 1.6 * s))

        // Gold inlay channels following the arch.
        for radius in [innerRadius + 8, outerRadius - 8] {
            context.stroke(arc(radius, from: -reach, to: reach), with: .color(inlay.opacity(0.8)), lineWidth: max(0.6, 1.4 * s))
        }

        // Carved marks, one per block: abstract angular strokes, no alphabet.
        let marks: [Path] = {
            var upright = Path()
            upright.move(to: CGPoint(x: 0, y: -6)); upright.addLine(to: CGPoint(x: 0, y: 6))
            upright.move(to: CGPoint(x: 0, y: -6)); upright.addLine(to: CGPoint(x: 4, y: -2))
            upright.move(to: CGPoint(x: 0, y: 2)); upright.addLine(to: CGPoint(x: -4, y: 6))
            var chevrons = Path()
            chevrons.move(to: CGPoint(x: -4, y: -6)); chevrons.addLine(to: CGPoint(x: 0, y: -2)); chevrons.addLine(to: CGPoint(x: 4, y: -6))
            chevrons.move(to: CGPoint(x: -4, y: 2)); chevrons.addLine(to: CGPoint(x: 0, y: 6)); chevrons.addLine(to: CGPoint(x: 4, y: 2))
            var lozenge = Path()
            lozenge.move(to: CGPoint(x: 0, y: -6)); lozenge.addLine(to: CGPoint(x: 4, y: 0))
            lozenge.addLine(to: CGPoint(x: 0, y: 6)); lozenge.addLine(to: CGPoint(x: -4, y: 0)); lozenge.closeSubpath()
            lozenge.move(to: CGPoint(x: 0, y: -8)); lozenge.addLine(to: CGPoint(x: 0, y: 8))
            var slash = Path()
            slash.move(to: CGPoint(x: -4, y: -6)); slash.addLine(to: CGPoint(x: 4, y: 6))
            slash.move(to: CGPoint(x: -4, y: 6)); slash.addLine(to: CGPoint(x: 0, y: 0))
            return [upright, chevrons, lozenge, slash]
        }()
        var carvings = Path()
        for (index, degrees) in [10.5, 19.5, 28.5, 37.5].enumerated() {
            for sign in [-1.0, 1.0] {
                let angle = sign * degrees * Double.pi / 180
                carvings.addPath(board.placed(
                    marks[(index + (sign > 0 ? 2 : 0)) % marks.count],
                    at: archPoint((innerRadius + outerRadius) / 2, angle),
                    rotation: -angle
                ))
            }
        }
        context.stroke(
            carvings,
            with: .color(mortar.opacity(0.55)),
            style: StrokeStyle(lineWidth: max(0.5, 1.1 * s), lineCap: .round, lineJoin: .round)
        )

        // The keystone stands proud of the band on both edges.
        var keystone = Path()
        let keyOuterAngle = 9 * Double.pi / 180
        let keyInnerAngle = 6.5 * Double.pi / 180
        keystone.move(to: archPoint(outerRadius + 12, -keyOuterAngle))
        keystone.addLine(to: archPoint(outerRadius + 12, keyOuterAngle))
        keystone.addLine(to: archPoint(innerRadius - 12, keyInnerAngle))
        keystone.addLine(to: archPoint(innerRadius - 12, -keyInnerAngle))
        keystone.closeSubpath()
        context.fill(keystone, with: .color(stone.opacity(0.96)))
        context.stroke(keystone, with: .color(mortar.opacity(0.6)), style: StrokeStyle(lineWidth: max(0.6, 1.4 * s), lineJoin: .round))

        // MARK: Shield and crossed axes on the keystone

        let shieldCenter = top(195, 60)
        var blade = Path()
        blade.move(to: CGPoint(x: 0, y: -9))
        blade.addQuadCurve(to: CGPoint(x: 20, y: -17), control: CGPoint(x: 11, y: -17))
        blade.addQuadCurve(to: CGPoint(x: 20, y: 15), control: CGPoint(x: 28, y: -1))
        blade.addQuadCurve(to: CGPoint(x: 0, y: 7), control: CGPoint(x: 9, y: 11))
        blade.closeSubpath()
        let socket = Path(roundedRect: CGRect(x: -4, y: -11, width: 8, height: 20), cornerRadius: 2 * s)
        for sign in [-1.0, 1.0] {
            // Handle from below the shield up to the head, crossing behind it.
            var handle = Path()
            handle.move(to: CGPoint(x: shieldCenter.x - 56 * sign * s, y: shieldCenter.y + 56 * s))
            let head = CGPoint(x: shieldCenter.x + 40 * sign * s, y: shieldCenter.y - 40 * s)
            handle.addLine(to: head)
            context.stroke(handle, with: .color(mortar.opacity(0.6)), style: StrokeStyle(lineWidth: max(1, 7.5 * s), lineCap: .round))
            context.stroke(handle, with: .color(stone.opacity(0.95)), style: StrokeStyle(lineWidth: max(0.8, 5 * s), lineCap: .round))

            // The head: local "up" is along the handle, the blade faces outward.
            let placement = CGAffineTransform(scaleX: s * sign * 0.9, y: s * 0.9)
                .concatenating(CGAffineTransform(rotationAngle: sign * Double.pi / 4))
                .concatenating(CGAffineTransform(translationX: head.x, y: head.y))
            let placedBlade = blade.applying(placement)
            context.fill(placedBlade, with: .color(mortar.opacity(0.92)))
            context.stroke(placedBlade, with: .color(stoneDark.opacity(0.85)), style: StrokeStyle(lineWidth: max(0.5, 1.2 * s), lineJoin: .round))
            context.fill(socket.applying(placement), with: .color(stoneDark.opacity(0.95)))
        }

        let shield = board.circle(at: shieldCenter, radius: 27)
        context.fill(shield, with: .color(shieldField.opacity(0.9)))
        context.stroke(board.circle(at: shieldCenter, radius: 19), with: .color(stoneDark.opacity(0.45)), lineWidth: max(0.5, 1 * s))
        context.stroke(shield, with: .color(inlay.opacity(0.95)), lineWidth: max(0.8, 2.6 * s))
        var gleam = Path()
        gleam.addArc(
            center: shieldCenter, radius: 22 * s,
            startAngle: .degrees(200), endAngle: .degrees(250), clockwise: false
        )
        context.stroke(gleam, with: .color(.white.opacity(0.22)), style: StrokeStyle(lineWidth: max(0.8, 2.5 * s), lineCap: .round))
        context.fill(board.circle(at: shieldCenter, radius: 6.5), with: .color(inlay.opacity(0.95)))
        context.fill(board.circle(at: shieldCenter, radius: 2), with: .color(stoneDark.opacity(0.9)))

        // MARK: Anvil, block, hammer and sparks

        // The block the anvil stands on, running off the bottom edge.
        var block = Path()
        block.move(to: foot(143, 790))
        block.addLine(to: foot(247, 790))
        block.addLine(to: foot(247, 856))
        block.addLine(to: foot(143, 856))
        block.closeSubpath()
        context.fill(block, with: .color(stone.opacity(0.88)))
        var courses = Path()
        courses.move(to: foot(143, 818)); courses.addLine(to: foot(247, 818))
        courses.move(to: foot(195, 818)); courses.addLine(to: foot(195, 856))
        context.stroke(courses, with: .color(mortar.opacity(0.3)), lineWidth: max(0.5, 1 * s))
        var blockTop = Path()
        blockTop.move(to: foot(143, 790)); blockTop.addLine(to: foot(247, 790))
        context.stroke(blockTop, with: .color(mortar.opacity(0.45)), lineWidth: max(0.6, 1.5 * s))

        // A hammer leaning against the block, head on the ground.
        let hammerPosition = foot(298, 822)
        let hammerRotation = -55 * Double.pi / 180
        var hammerHandle = Path()
        hammerHandle.move(to: CGPoint(x: 0, y: 2))
        hammerHandle.addLine(to: CGPoint(x: 0, y: -62))
        let placedHandle = board.placed(hammerHandle, at: hammerPosition, rotation: hammerRotation)
        context.stroke(placedHandle, with: .color(mortar.opacity(0.55)), style: StrokeStyle(lineWidth: max(1, 7 * s), lineCap: .round))
        context.stroke(placedHandle, with: .color(stone.opacity(0.95)), style: StrokeStyle(lineWidth: max(0.8, 4.6 * s), lineCap: .round))
        let hammerHead = board.placed(
            Path(roundedRect: CGRect(x: -16, y: -4, width: 32, height: 15), cornerRadius: 2.5),
            at: hammerPosition, rotation: hammerRotation
        )
        context.fill(hammerHead, with: .color(stone.opacity(0.96)))
        context.stroke(hammerHead, with: .color(mortar.opacity(0.7)), lineWidth: max(0.5, 1.2 * s))

        // The anvil: horn to the left, heel to the right, a waist and a foot.
        let anvilPosition = foot(195, 736)
        var anvil = Path()
        anvil.move(to: CGPoint(x: -80, y: 6))
        anvil.addQuadCurve(to: CGPoint(x: -36, y: -6), control: CGPoint(x: -60, y: -8))
        anvil.addLine(to: CGPoint(x: 58, y: -6))
        anvil.addLine(to: CGPoint(x: 58, y: 14))
        anvil.addLine(to: CGPoint(x: 40, y: 14))
        anvil.addLine(to: CGPoint(x: 32, y: 30))
        anvil.addLine(to: CGPoint(x: 44, y: 44))
        anvil.addLine(to: CGPoint(x: 44, y: 55))
        anvil.addLine(to: CGPoint(x: -44, y: 55))
        anvil.addLine(to: CGPoint(x: -44, y: 44))
        anvil.addLine(to: CGPoint(x: -32, y: 30))
        anvil.addLine(to: CGPoint(x: -40, y: 14))
        anvil.addQuadCurve(to: CGPoint(x: -80, y: 6), control: CGPoint(x: -60, y: 18))
        anvil.closeSubpath()
        let placedAnvil = board.placed(anvil, at: anvilPosition)
        context.fill(placedAnvil, with: .color(stone.opacity(0.96)))
        context.stroke(placedAnvil, with: .color(stoneDark.opacity(0.8)), style: StrokeStyle(lineWidth: max(0.6, 1.4 * s), lineJoin: .round))
        // The lit edge along the face and the horn.
        var face = Path()
        face.move(to: CGPoint(x: -80, y: 6))
        face.addQuadCurve(to: CGPoint(x: -36, y: -6), control: CGPoint(x: -60, y: -8))
        face.addLine(to: CGPoint(x: 58, y: -6))
        face.move(to: CGPoint(x: 58, y: -6))
        face.addLine(to: CGPoint(x: 58, y: 14))
        context.stroke(
            board.placed(face, at: anvilPosition),
            with: .color(mortar.opacity(0.85)),
            style: StrokeStyle(lineWidth: max(0.8, 2.2 * s), lineCap: .round, lineJoin: .round)
        )

        // A hot spot on the face where the work sits, then sparks rising from
        // it: short radial strokes and a few dots.
        let origin = CGPoint(x: anvilPosition.x - 6 * s, y: anvilPosition.y - 10 * s)
        context.fill(board.circle(at: origin, radius: 24), with: .radialGradient(
            Gradient(colors: [spark.opacity(0.55), spark.opacity(0)]),
            center: origin,
            startRadius: 0,
            endRadius: 24 * s
        ))
        var sparks = board.generator(salt: 0x4E49_4441_5645)
        var strokes = Path()
        var dots = Path()
        for index in 0..<18 {
            let angle = sparks.range(-2.7...(-0.45))
            let distance = sparks.range(14...86) * s
            let start = CGPoint(x: origin.x + cos(angle) * distance, y: origin.y + sin(angle) * distance)
            if index < 12 {
                let length = sparks.range(5...14) * s
                strokes.move(to: start)
                strokes.addLine(to: CGPoint(x: start.x + cos(angle) * length, y: start.y + sin(angle) * length))
            } else {
                let r = sparks.range(1.2...2.4) * s
                dots.addEllipse(in: CGRect(x: start.x - r, y: start.y - r, width: r * 2, height: r * 2))
            }
        }
        var glow = context
        glow.addFilter(.blur(radius: max(1.5, 3 * s)))
        glow.stroke(strokes, with: .color(spark.opacity(0.7)), style: StrokeStyle(lineWidth: max(1.5, 4 * s), lineCap: .round))
        glow.fill(dots, with: .color(spark.opacity(0.7)))
        context.stroke(strokes, with: .color(spark.opacity(0.95)), style: StrokeStyle(lineWidth: max(0.6, 1.6 * s), lineCap: .round))
        context.fill(dots, with: .color(spark.opacity(0.95)))
    }
}
