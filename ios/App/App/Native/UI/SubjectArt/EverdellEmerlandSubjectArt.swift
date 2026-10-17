import SwiftUI

// Everdell Emerland: the animals of the valley. A toucan clinging to the
// right-hand vine with its oversized bill turned toward the board, a capybara
// standing on the river bank at the foot, a frog on the big lily pad, and
// five butterflies drifting along the river.

extension BoardSubjectArtRenderer {
    static func drawJungleCanopyAnimals(in context: inout GraphicsContext, on board: BoardSubjectCanvas) {
        let p = board.point
        let s = board.scale
        let plumage = board.color("#0E2A20")
        let wingTone = board.color("#1B4030")
        let cream = board.color("#F4F1DE")
        let billOrange = board.color("#F29B30")
        let billPink = board.color("#DE5A9E")
        let eyeRing = board.color("#0E97AA")
        let hide = board.color("#8A5A38")
        let hideDark = board.color("#5C3A22")
        let hideLight = board.color("#A8744A")
        let frogGreen = board.color("#5E8A4A")
        let frogLight = board.color("#8DB56A")
        let violet = board.color("#7E55BF")
        let pink = board.color("#DE5A9E")

        // MARK: Toucan

        // Authored around the body centre, facing left, feet gripping the vine
        // at the right. The vine hangs at x 344 and ends at y 280, so the bird
        // holds on near its lower end. Drawn a quarter larger than authored.
        let t: CGFloat = 1.25
        let perch = p(319, 258)
        var silhouette = Path()
        silhouette.addPath(board.blob(center: .zero, points: [
            CGPoint(x: 0, y: -24), CGPoint(x: 14, y: -16), CGPoint(x: 18, y: 0), CGPoint(x: 14, y: 18),
            CGPoint(x: 0, y: 26), CGPoint(x: -12, y: 18), CGPoint(x: -16, y: 0), CGPoint(x: -12, y: -16)
        ]))
        silhouette.addPath(Path(ellipseIn: CGRect(x: -17, y: -47, width: 26, height: 26)))
        // Tail hanging below the body.
        var tail = Path()
        tail.move(to: CGPoint(x: 4, y: 20))
        tail.addLine(to: CGPoint(x: 10, y: 48))
        tail.addLine(to: CGPoint(x: 20, y: 44))
        tail.addLine(to: CGPoint(x: 14, y: 16))
        tail.closeSubpath()
        silhouette.addPath(tail)
        let placedSilhouette = board.placed(silhouette, at: perch, scale: t)
        // A thin rim of light separates the black bird from the dark canopy.
        context.stroke(placedSilhouette, with: .color(cream.opacity(0.4)), lineWidth: max(0.6, 2 * s))
        context.fill(placedSilhouette, with: .color(plumage.opacity(0.95)))

        // Cream throat and chest, kept inside the silhouette.
        let chest = board.placed(board.blob(center: .zero, points: [
            CGPoint(x: -12, y: -30), CGPoint(x: -4, y: -24), CGPoint(x: 0, y: -12), CGPoint(x: 0, y: 4),
            CGPoint(x: -7, y: 14), CGPoint(x: -15, y: 6), CGPoint(x: -18, y: -10), CGPoint(x: -18, y: -24)
        ]), at: perch, scale: t)
        var breast = context
        breast.clip(to: placedSilhouette)
        breast.fill(chest, with: .color(cream.opacity(0.95)))
        // A folded wing for form, and a thin highlight along the back.
        let wing = board.placed(
            Path(ellipseIn: CGRect(x: -2, y: -20, width: 18, height: 36)),
            at: perch, rotation: 0.18, scale: t
        )
        breast.fill(wing, with: .color(wingTone.opacity(0.9)))
        var backline = Path()
        backline.move(to: CGPoint(x: 6, y: -30))
        backline.addQuadCurve(to: CGPoint(x: 14, y: 12), control: CGPoint(x: 20, y: -10))
        breast.stroke(board.placed(backline, at: perch, scale: t), with: .color(cream.opacity(0.25)), lineWidth: max(0.5, 1.6 * s))

        // The bill: a deep curved blade, pink at the tip, with the mandible seam.
        var bill = Path()
        bill.move(to: CGPoint(x: -12, y: -44))
        bill.addQuadCurve(to: CGPoint(x: -62, y: -24), control: CGPoint(x: -44, y: -48))
        bill.addQuadCurve(to: CGPoint(x: -12, y: -26), control: CGPoint(x: -40, y: -20))
        bill.closeSubpath()
        let placedBill = board.placed(bill, at: perch, scale: t)
        context.fill(placedBill, with: .color(billOrange.opacity(0.95)))
        var billTip = context
        billTip.clip(to: placedBill)
        billTip.fill(
            board.placed(Path(CGRect(x: -70, y: -60, width: 20, height: 50)), at: perch, scale: t),
            with: .color(billPink.opacity(0.95))
        )
        var seam = Path()
        seam.move(to: CGPoint(x: -14, y: -34))
        seam.addQuadCurve(to: CGPoint(x: -56, y: -27), control: CGPoint(x: -36, y: -32))
        billTip.stroke(board.placed(seam, at: perch, scale: t), with: .color(plumage.opacity(0.45)), lineWidth: max(0.5, 1.2 * s))
        var billLight = Path()
        billLight.move(to: CGPoint(x: -16, y: -41))
        billLight.addQuadCurve(to: CGPoint(x: -52, y: -28), control: CGPoint(x: -42, y: -42))
        billTip.stroke(board.placed(billLight, at: perch, scale: t), with: .color(cream.opacity(0.45)), lineWidth: max(0.5, 1.6 * s))

        // Eye ring, eye and a glint.
        let eye = CGPoint(x: perch.x - 7 * s * t, y: perch.y - 36 * s * t)
        context.fill(board.circle(at: eye, radius: 5.2 * t), with: .color(eyeRing.opacity(0.95)))
        context.fill(board.circle(at: eye, radius: 2.6 * t), with: .color(plumage))
        context.fill(board.circle(at: CGPoint(x: eye.x - 1 * s * t, y: eye.y - 1 * s * t), radius: 0.9 * t), with: .color(.white.opacity(0.8)))

        // Feet gripping the vine.
        var feet = Path()
        feet.move(to: CGPoint(x: 12, y: 2))
        feet.addQuadCurve(to: CGPoint(x: 24, y: 5), control: CGPoint(x: 18, y: 0))
        feet.move(to: CGPoint(x: 12, y: 10))
        feet.addQuadCurve(to: CGPoint(x: 24, y: 14), control: CGPoint(x: 18, y: 9))
        context.stroke(
            board.placed(feet, at: perch, scale: t),
            with: .color(plumage.opacity(0.95)),
            style: StrokeStyle(lineWidth: max(0.6, 2.4 * s), lineCap: .round)
        )

        // MARK: Capybara

        // Standing on the near bank, facing the river. Authored around the
        // body centre with the feet at y 24, and hung from the bottom edge so
        // it keeps its footing on a squashed landscape board.
        let c: CGFloat = 1.15
        let stance = board.fromBottom(150, 46 * c)
        context.fill(
            board.ellipse(at: CGPoint(x: stance.x + 4 * s * c, y: stance.y + 25 * s * c), rx: 50 * c, ry: 6 * c),
            with: .color(plumage.opacity(0.16))
        )
        // Short stout legs, the far pair a shade darker and set back.
        var farLegs = Path()
        for x in [-22.0, 14.0] as [CGFloat] {
            farLegs.addRoundedRect(in: CGRect(x: x, y: 8, width: 11, height: 16), cornerSize: CGSize(width: 4, height: 4))
        }
        context.fill(board.placed(farLegs, at: stance, scale: c), with: .color(hideDark.opacity(0.95)))
        var nearLegs = Path()
        for x in [-30.0, 24.0] as [CGFloat] {
            nearLegs.addRoundedRect(in: CGRect(x: x, y: 8, width: 11, height: 16), cornerSize: CGSize(width: 4, height: 4))
        }
        context.fill(board.placed(nearLegs, at: stance, scale: c), with: .color(hide.opacity(0.95)))
        var body = board.blob(center: .zero, points: [
            CGPoint(x: -36, y: -6), CGPoint(x: -24, y: -18), CGPoint(x: 8, y: -19), CGPoint(x: 26, y: -12),
            CGPoint(x: 32, y: 2), CGPoint(x: 28, y: 16), CGPoint(x: 0, y: 19), CGPoint(x: -28, y: 17), CGPoint(x: -38, y: 6)
        ])
        body.addPath(board.blob(center: .zero, points: [
            CGPoint(x: 24, y: -22), CGPoint(x: 44, y: -22), CGPoint(x: 54, y: -14), CGPoint(x: 54, y: 2),
            CGPoint(x: 46, y: 8), CGPoint(x: 28, y: 6)
        ]))
        // Ear.
        body.addPath(board.blob(center: .zero, points: [
            CGPoint(x: 30, y: -22), CGPoint(x: 34, y: -30), CGPoint(x: 40, y: -22)
        ]))
        let placedBody = board.placed(body, at: stance, scale: c)
        context.fill(placedBody, with: .color(hide.opacity(0.95)))
        var coat = context
        coat.clip(to: placedBody)
        // Lighter back and muzzle, darker underside.
        coat.fill(
            board.placed(board.blob(center: .zero, points: [
                CGPoint(x: -26, y: -20), CGPoint(x: 10, y: -23), CGPoint(x: 26, y: -14), CGPoint(x: 10, y: -8), CGPoint(x: -24, y: -8)
            ]), at: stance, scale: c),
            with: .color(hideLight.opacity(0.75))
        )
        coat.fill(
            board.placed(Path(ellipseIn: CGRect(x: 42, y: -14, width: 16, height: 18)), at: stance, scale: c),
            with: .color(hideLight.opacity(0.6))
        )
        coat.fill(
            board.placed(board.blob(center: .zero, points: [
                CGPoint(x: -34, y: 8), CGPoint(x: 0, y: 6), CGPoint(x: 30, y: 8), CGPoint(x: 30, y: 22), CGPoint(x: -34, y: 22)
            ]), at: stance, scale: c),
            with: .color(hideDark.opacity(0.5))
        )
        let capyEye = CGPoint(x: stance.x + 40 * s * c, y: stance.y - 13 * s * c)
        context.fill(board.circle(at: capyEye, radius: 2 * c), with: .color(plumage))
        context.fill(board.circle(at: CGPoint(x: capyEye.x - 0.7 * s * c, y: capyEye.y - 0.7 * s * c), radius: 0.7 * c), with: .color(.white.opacity(0.7)))
        context.fill(board.circle(at: CGPoint(x: stance.x + 52 * s * c, y: stance.y - 9 * s * c), radius: 1.3 * c), with: .color(plumage.opacity(0.85)))

        // MARK: Frog

        // Sitting on the large lily pad, facing left.
        let f: CGFloat = 1.25
        let pad = p(320, 736)
        var frogLegs = Path()
        frogLegs.addEllipse(in: CGRect(x: -16, y: -1, width: 12, height: 7))
        frogLegs.addEllipse(in: CGRect(x: 4, y: -1, width: 12, height: 7))
        context.fill(board.placed(frogLegs, at: pad, scale: f), with: .color(frogGreen.opacity(0.95)))
        let frogBody = board.placed(board.blob(center: .zero, points: [
            CGPoint(x: -11, y: -4), CGPoint(x: -4, y: -9), CGPoint(x: 6, y: -8), CGPoint(x: 11, y: -2),
            CGPoint(x: 9, y: 5), CGPoint(x: -9, y: 5)
        ]), at: pad, scale: f)
        context.fill(frogBody, with: .color(frogGreen.opacity(0.95)))
        var frogSkin = context
        frogSkin.clip(to: frogBody)
        frogSkin.fill(
            board.placed(Path(ellipseIn: CGRect(x: -10, y: 0, width: 18, height: 8)), at: pad, scale: f),
            with: .color(frogLight.opacity(0.8))
        )
        for x in [-6.0, 2.0] as [CGFloat] {
            let eyeCenter = CGPoint(x: pad.x + x * s * f, y: pad.y - 9 * s * f)
            context.fill(board.circle(at: eyeCenter, radius: 3 * f), with: .color(frogGreen.opacity(0.95)))
            context.fill(board.circle(at: eyeCenter, radius: 1.5 * f), with: .color(plumage))
            context.fill(board.circle(at: CGPoint(x: eyeCenter.x - 0.6 * s * f, y: eyeCenter.y - 0.6 * s * f), radius: 0.5 * f), with: .color(.white.opacity(0.8)))
        }

        // MARK: Butterflies

        // Two wings a side, the upper larger, on a short dark body.
        var upperWings = Path()
        upperWings.addEllipse(in: CGRect(x: -15, y: -10, width: 14, height: 10))
        upperWings.addEllipse(in: CGRect(x: 1, y: -10, width: 14, height: 10))
        var lowerWings = Path()
        lowerWings.addEllipse(in: CGRect(x: -10, y: -1, width: 9, height: 8))
        lowerWings.addEllipse(in: CGRect(x: 1, y: -1, width: 9, height: 8))
        var bodyLine = Path()
        bodyLine.move(to: CGPoint(x: 0, y: -9))
        bodyLine.addLine(to: CGPoint(x: 0, y: 7))
        bodyLine.move(to: CGPoint(x: 0, y: -9))
        bodyLine.addLine(to: CGPoint(x: -4, y: -14))
        bodyLine.move(to: CGPoint(x: 0, y: -9))
        bodyLine.addLine(to: CGPoint(x: 4, y: -14))
        let flights: [(x: CGFloat, y: CGFloat, rotation: Double, size: CGFloat, pink: Bool)] = [
            (172, 232, -0.5, 1.0, false), (268, 298, 0.4, 0.85, true), (150, 470, 0.9, 1.1, false),
            (306, 548, -0.7, 0.9, true), (212, 662, 0.25, 1.0, false)
        ]
        for flight in flights {
            let at = p(flight.x, flight.y)
            let tint = flight.pink ? pink : violet
            let shade = flight.pink ? violet : pink
            context.fill(
                board.placed(lowerWings, at: at, rotation: flight.rotation, scale: flight.size),
                with: .color(shade.opacity(0.85))
            )
            context.fill(
                board.placed(upperWings, at: at, rotation: flight.rotation, scale: flight.size),
                with: .color(tint.opacity(0.92))
            )
            context.stroke(
                board.placed(bodyLine, at: at, rotation: flight.rotation, scale: flight.size),
                with: .color(plumage.opacity(0.9)),
                style: StrokeStyle(lineWidth: max(0.5, 1.4 * s * flight.size), lineCap: .round)
            )
            var spots = Path()
            spots.addEllipse(in: CGRect(x: -10, y: -7.5, width: 3, height: 3))
            spots.addEllipse(in: CGRect(x: 7, y: -7.5, width: 3, height: 3))
            context.fill(
                board.placed(spots, at: at, rotation: flight.rotation, scale: flight.size),
                with: .color(cream.opacity(0.7))
            )
        }
    }
}
