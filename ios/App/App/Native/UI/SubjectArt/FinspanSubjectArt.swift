import SwiftUI

// Finspan: a descent through the water column. Bubble rings and two faint
// light shafts in the sunlit top, a flying fish gliding at the top left, a
// loose shoal of small fish crossing the middle, a manta gliding below it,
// a shark cruising low in the dark, bubble columns rising at both edges and
// a scatter of bioluminescence in the deep. The band between the shoal and
// the shark stays open water.

extension BoardSubjectArtRenderer {
    static func drawOceanDescent(in context: inout GraphicsContext, on board: BoardSubjectCanvas) {
        let p = board.point
        let s = board.scale
        let foam = board.color("#E8F4F4")
        let fishPale = board.color("#D9E8EC")
        let fishDark = board.color("#1F3F5E")
        let pink = board.color("#F0A0A0")
        let shoalBlue = board.color("#9FC3D6")
        let mantaBlue = board.color("#2A6F8A")
        let sharkBlue = board.color("#22506C")
        let deep = board.color("#0A1C2E")
        let glow = board.color("#9FE8E0")

        // MARK: Light shafts

        for corners in [
            [p(118, -4), p(152, -4), p(198, 470), p(94, 470)],
            [p(262, -4), p(284, -4), p(374, 440), p(292, 440)]
        ] {
            var shaft = Path()
            shaft.move(to: corners[0])
            for corner in corners.dropFirst() { shaft.addLine(to: corner) }
            shaft.closeSubpath()
            // Fades out before the open water, so the shaft has no foot.
            context.fill(shaft, with: .linearGradient(
                Gradient(colors: [.white.opacity(0.08), .white.opacity(0)]),
                startPoint: corners[0],
                endPoint: corners[2]
            ))
        }

        // MARK: Bubbles in the sunlit top

        var surface = board.generator(salt: 0x4649_4E53_0001)
        var rings = Path()
        for _ in 0..<11 {
            let center = p(surface.range(16...374), surface.range(14...150))
            rings.addPath(board.circle(at: center, radius: surface.range(4...14)))
        }
        context.stroke(rings, with: .color(.white.opacity(0.7)), lineWidth: max(0.5, 1.2 * s))
        var motes = Path()
        for _ in 0..<8 {
            let center = p(surface.range(10...380), surface.range(10...170))
            motes.addPath(board.circle(at: center, radius: surface.range(1...2)))
        }
        context.fill(motes, with: .color(.white.opacity(0.8)))

        // MARK: Flying fish

        // Authored facing right with the tail root at the origin, then tilted
        // nose-up as it glides out of the top left.
        let fishAt = p(42, 196)
        let fishTilt = -16 * Double.pi / 180
        var farWing = Path()
        farWing.move(to: CGPoint(x: 70, y: -4))
        farWing.addQuadCurve(to: CGPoint(x: 12, y: -68), control: CGPoint(x: 54, y: -52))
        farWing.addQuadCurve(to: CGPoint(x: 46, y: -2), control: CGPoint(x: 20, y: -36))
        farWing.closeSubpath()
        context.fill(board.placed(farWing, at: fishAt, rotation: fishTilt), with: .color(foam.opacity(0.35)))

        var tailFin = Path()
        tailFin.move(to: CGPoint(x: 3, y: -3))
        tailFin.addLine(to: CGPoint(x: -17, y: -15))
        tailFin.addLine(to: CGPoint(x: -9, y: 0))
        tailFin.addLine(to: CGPoint(x: -21, y: 14))
        tailFin.addLine(to: CGPoint(x: 3, y: 3))
        tailFin.closeSubpath()
        tailFin.move(to: CGPoint(x: 42, y: 9))
        tailFin.addLine(to: CGPoint(x: 50, y: 21))
        tailFin.addLine(to: CGPoint(x: 60, y: 9.5))
        tailFin.closeSubpath()
        tailFin.move(to: CGPoint(x: 14, y: -5))
        tailFin.addLine(to: CGPoint(x: 20, y: -14))
        tailFin.addLine(to: CGPoint(x: 30, y: -4))
        tailFin.closeSubpath()
        context.fill(board.placed(tailFin, at: fishAt, rotation: fishTilt), with: .color(pink.opacity(0.9)))

        var fishBody = Path()
        fishBody.move(to: CGPoint(x: 0, y: 0))
        fishBody.addQuadCurve(to: CGPoint(x: 104, y: 0), control: CGPoint(x: 50, y: -23))
        fishBody.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: 50, y: 23))
        fishBody.closeSubpath()
        context.fill(board.placed(fishBody, at: fishAt, rotation: fishTilt), with: .color(fishPale.opacity(0.95)))
        var backStripe = Path()
        backStripe.move(to: CGPoint(x: 6, y: -1.5))
        backStripe.addQuadCurve(to: CGPoint(x: 100, y: -1.5), control: CGPoint(x: 50, y: -23))
        backStripe.addQuadCurve(to: CGPoint(x: 6, y: -1.5), control: CGPoint(x: 50, y: -10))
        backStripe.closeSubpath()
        context.fill(board.placed(backStripe, at: fishAt, rotation: fishTilt), with: .color(fishDark.opacity(0.85)))

        var nearWing = Path()
        nearWing.move(to: CGPoint(x: 66, y: -5))
        nearWing.addQuadCurve(to: CGPoint(x: -2, y: -54), control: CGPoint(x: 40, y: -44))
        nearWing.addQuadCurve(to: CGPoint(x: 40, y: -1), control: CGPoint(x: 8, y: -28))
        nearWing.closeSubpath()
        context.fill(board.placed(nearWing, at: fishAt, rotation: fishTilt), with: .color(foam.opacity(0.6)))
        var wingRays = Path()
        for tip in [CGPoint(x: 6, y: -49), CGPoint(x: 18, y: -43), CGPoint(x: 30, y: -34)] {
            wingRays.move(to: CGPoint(x: 58, y: -5))
            wingRays.addLine(to: tip)
        }
        context.stroke(
            board.placed(wingRays, at: fishAt, rotation: fishTilt),
            with: .color(.white.opacity(0.35)),
            lineWidth: max(0.4, 0.8 * s)
        )
        context.fill(
            board.placed(Path(ellipseIn: CGRect(x: 85.4, y: -5.1, width: 5.2, height: 5.2)), at: fishAt, rotation: fishTilt),
            with: .color(fishDark.opacity(0.95))
        )
        context.fill(
            board.placed(Path(ellipseIn: CGRect(x: 86.2, y: -4.4, width: 1.8, height: 1.8)), at: fishAt, rotation: fishTilt),
            with: .color(.white.opacity(0.9))
        )

        // MARK: Shoal

        var drift = board.generator(salt: 0x4649_4E53_0002)
        var smallFish = Path()
        smallFish.move(to: CGPoint(x: -7, y: 0))
        smallFish.addQuadCurve(to: CGPoint(x: 7, y: 0), control: CGPoint(x: 0, y: -5.5))
        smallFish.addQuadCurve(to: CGPoint(x: -7, y: 0), control: CGPoint(x: 0, y: 5.5))
        smallFish.closeSubpath()
        smallFish.move(to: CGPoint(x: -6, y: 0))
        smallFish.addLine(to: CGPoint(x: -12, y: -4.5))
        smallFish.addLine(to: CGPoint(x: -10.5, y: 0))
        smallFish.addLine(to: CGPoint(x: -12, y: 4.5))
        smallFish.closeSubpath()
        var shoal = Path()
        for index in 0..<14 {
            let t = CGFloat(index) / 13
            let phase = 2 * CGFloat.pi * t + .pi
            let x = 26 + t * 338 + drift.range(-5...5)
            let y = 356 + 30 * sin(phase) + drift.range(-9...9)
            let slope = 30 * 2 * CGFloat.pi / 338 * cos(phase)
            shoal.addPath(board.placed(
                smallFish,
                at: p(x, y),
                rotation: Double(atan(slope)) * 0.6,
                scale: drift.range(1.0...1.4)
            ))
        }
        context.fill(shoal, with: .color(shoalBlue.opacity(0.55)))

        // MARK: Manta

        let mantaAt = p(270, 520)
        let mantaTilt = -0.5
        var manta = Path()
        manta.move(to: CGPoint(x: 0, y: -26))
        manta.addCurve(to: CGPoint(x: 64, y: -4), control1: CGPoint(x: 18, y: -28), control2: CGPoint(x: 50, y: -20))
        manta.addCurve(to: CGPoint(x: 9, y: 20), control1: CGPoint(x: 54, y: 6), control2: CGPoint(x: 28, y: 16))
        manta.addLine(to: CGPoint(x: 0, y: 24))
        manta.addLine(to: CGPoint(x: -9, y: 20))
        manta.addCurve(to: CGPoint(x: -64, y: -4), control1: CGPoint(x: -28, y: 16), control2: CGPoint(x: -54, y: 6))
        manta.addCurve(to: CGPoint(x: 0, y: -26), control1: CGPoint(x: -50, y: -20), control2: CGPoint(x: -18, y: -28))
        manta.closeSubpath()
        // Cephalic lobes.
        manta.move(to: CGPoint(x: -9, y: -24))
        manta.addLine(to: CGPoint(x: -11, y: -37))
        manta.addLine(to: CGPoint(x: -3, y: -27))
        manta.closeSubpath()
        manta.move(to: CGPoint(x: 9, y: -24))
        manta.addLine(to: CGPoint(x: 11, y: -37))
        manta.addLine(to: CGPoint(x: 3, y: -27))
        manta.closeSubpath()
        context.fill(board.placed(manta, at: mantaAt, rotation: mantaTilt), with: .color(mantaBlue.opacity(0.85)))
        // A thin glint along the leading edge of both wings.
        var mantaEdge = Path()
        mantaEdge.move(to: CGPoint(x: -60, y: -5))
        mantaEdge.addCurve(to: CGPoint(x: -4, y: -25), control1: CGPoint(x: -48, y: -19), control2: CGPoint(x: -18, y: -27))
        mantaEdge.move(to: CGPoint(x: 4, y: -25))
        mantaEdge.addCurve(to: CGPoint(x: 60, y: -5), control1: CGPoint(x: 18, y: -27), control2: CGPoint(x: 48, y: -19))
        context.stroke(
            board.placed(mantaEdge, at: mantaAt, rotation: mantaTilt),
            with: .color(.white.opacity(0.22)),
            style: StrokeStyle(lineWidth: max(0.5, 1.4 * s), lineCap: .round)
        )
        var mantaTail = Path()
        mantaTail.move(to: CGPoint(x: 0, y: 22))
        mantaTail.addQuadCurve(to: CGPoint(x: 18, y: 92), control: CGPoint(x: -6, y: 60))
        context.stroke(
            board.placed(mantaTail, at: mantaAt, rotation: mantaTilt),
            with: .color(mantaBlue.opacity(0.85)),
            style: StrokeStyle(lineWidth: max(0.6, 1.8 * s), lineCap: .round)
        )

        // MARK: Bioluminescence

        var sparks = board.generator(salt: 0x4649_4E53_0003)
        for _ in 0..<26 {
            let center = p(sparks.range(10...380), sparks.range(590...840))
            context.fill(
                board.circle(at: center, radius: sparks.range(0.8...2.2)),
                with: .color(glow.opacity(sparks.range(0.45...0.9)))
            )
        }

        // MARK: Shark

        // Authored facing left with the body's middle at the origin.
        let sharkAt = p(230, 760)
        let sharkTilt = 0.03
        var shark = Path()
        shark.move(to: CGPoint(x: -135, y: 2))
        shark.addCurve(to: CGPoint(x: -30, y: -24), control1: CGPoint(x: -112, y: -8), control2: CGPoint(x: -72, y: -24))
        shark.addCurve(to: CGPoint(x: 98, y: -7), control1: CGPoint(x: 10, y: -24), control2: CGPoint(x: 66, y: -11))
        shark.addLine(to: CGPoint(x: 112, y: -6))
        shark.addQuadCurve(to: CGPoint(x: 154, y: -50), control: CGPoint(x: 126, y: -30))
        shark.addLine(to: CGPoint(x: 123, y: -1))
        shark.addLine(to: CGPoint(x: 148, y: 30))
        shark.addLine(to: CGPoint(x: 110, y: 8))
        shark.addCurve(to: CGPoint(x: -40, y: 21), control1: CGPoint(x: 60, y: 16), control2: CGPoint(x: 0, y: 24))
        shark.addCurve(to: CGPoint(x: -135, y: 2), control1: CGPoint(x: -92, y: 18), control2: CGPoint(x: -118, y: 10))
        shark.closeSubpath()
        // Dorsal fin: convex leading edge, concave trailing edge.
        shark.move(to: CGPoint(x: -24, y: -20))
        shark.addQuadCurve(to: CGPoint(x: 14, y: -60), control: CGPoint(x: -12, y: -48))
        shark.addQuadCurve(to: CGPoint(x: 36, y: -14), control: CGPoint(x: 16, y: -38))
        shark.closeSubpath()
        // Second dorsal and pelvic fin.
        shark.move(to: CGPoint(x: 70, y: -10))
        shark.addQuadCurve(to: CGPoint(x: 84, y: -26), control: CGPoint(x: 76, y: -22))
        shark.addLine(to: CGPoint(x: 92, y: -8))
        shark.closeSubpath()
        shark.move(to: CGPoint(x: 40, y: 18))
        shark.addLine(to: CGPoint(x: 52, y: 32))
        shark.addLine(to: CGPoint(x: 62, y: 16))
        shark.closeSubpath()
        // Pectoral fin sweeping down and back.
        shark.move(to: CGPoint(x: -74, y: 12))
        shark.addQuadCurve(to: CGPoint(x: -40, y: 50), control: CGPoint(x: -72, y: 40))
        shark.addLine(to: CGPoint(x: -22, y: 18))
        shark.closeSubpath()
        let placedShark = board.placed(shark, at: sharkAt, rotation: sharkTilt)
        context.fill(placedShark, with: .color(sharkBlue.opacity(0.95)))
        // A paler belly below a gently bowed countershading line.
        var belly = Path()
        belly.move(to: CGPoint(x: -140, y: 2))
        belly.addQuadCurve(to: CGPoint(x: 160, y: 2), control: CGPoint(x: 0, y: 12))
        belly.addLine(to: CGPoint(x: 160, y: 70))
        belly.addLine(to: CGPoint(x: -140, y: 70))
        belly.closeSubpath()
        var bellyMask = context
        bellyMask.clip(to: placedShark)
        bellyMask.fill(
            board.placed(belly, at: sharkAt, rotation: sharkTilt),
            with: .color(.white.opacity(0.1))
        )
        // Gills, mouth and eye in the dark of the water.
        var gills = Path()
        for x: CGFloat in [-94, -85, -76] {
            gills.move(to: CGPoint(x: x, y: -9))
            gills.addQuadCurve(to: CGPoint(x: x + 2, y: 11), control: CGPoint(x: x - 4, y: 1))
        }
        gills.move(to: CGPoint(x: -128, y: 9))
        gills.addQuadCurve(to: CGPoint(x: -102, y: 13), control: CGPoint(x: -116, y: 14))
        context.stroke(
            board.placed(gills, at: sharkAt, rotation: sharkTilt),
            with: .color(deep.opacity(0.65)),
            style: StrokeStyle(lineWidth: max(0.5, 1.4 * s), lineCap: .round)
        )
        context.fill(
            board.placed(Path(ellipseIn: CGRect(x: -115, y: -8, width: 6, height: 6)), at: sharkAt, rotation: sharkTilt),
            with: .color(deep.opacity(0.9))
        )
        context.fill(
            board.placed(Path(ellipseIn: CGRect(x: -114.2, y: -7.2, width: 2, height: 2)), at: sharkAt, rotation: sharkTilt),
            with: .color(.white.opacity(0.85))
        )

        // MARK: Bubble columns

        var columns = board.generator(salt: 0x4649_4E53_0004)
        var bubbles = Path()
        for edge in [0, 1] {
            var y: CGFloat = 822
            var count = 0
            while y > 420, count < 14 {
                let wobble = columns.range(-6...6)
                let center = edge == 0
                    ? p(22 + wobble, y)
                    : board.fromRight(26 - wobble, y)
                bubbles.addPath(board.circle(at: center, radius: columns.range(2...4)))
                y -= columns.range(26...46)
                count += 1
            }
        }
        context.fill(bubbles, with: .color(.white.opacity(0.08)))
        context.stroke(bubbles, with: .color(.white.opacity(0.45)), lineWidth: max(0.5, 0.9 * s))
    }
}
