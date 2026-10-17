import SwiftUI

// Wingspan Original: a field-guide plate. A plump songbird perched in profile
// on a bough that reaches in from the right edge, a nest of three pastel eggs
// where the bough meets that edge, three small birds on the wing in the upper
// left, and two drifting feathers low on the left. Flat watercolor fills
// under a thin ink outline, the way a guide plate is inked.

extension BoardSubjectArtRenderer {
    static func drawFieldGuideBirds(in context: inout GraphicsContext, on board: BoardSubjectCanvas) {
        let p = board.point
        let s = board.scale
        let ink = board.color("#27363B")
        let plumage = board.color("#D5A62D")
        let breast = board.color("#D95C4E")
        let bark = board.color("#6E5A48")
        let leafGreen = board.color("#508467")
        let featherBlue = board.color("#7EAFCA")
        let featherPlum = board.color("#80658A")
        let outline = StrokeStyle(lineWidth: max(0.5, 1 * s), lineCap: .round, lineJoin: .round)
        let hairline = StrokeStyle(lineWidth: max(0.4, 0.7 * s), lineCap: .round, lineJoin: .round)

        // MARK: Bough

        // Enters from the right edge, dips under the perch, and thins to a twig.
        let perchOnBough = p(300, 606)
        let bough = board.taperedStroke(
            from: p(398, 593),
            segments: [
                (to: perchOnBough, control1: p(362, 591), control2: p(330, 606), width: 12),
                (to: p(214, 596), control1: p(272, 606), control2: p(244, 598), width: 8),
                (to: p(148, 570), control1: p(186, 594), control2: p(164, 583), width: 4)
            ]
        )
        var twig = Path()
        twig.move(to: p(254, 602))
        twig.addQuadCurve(to: p(236, 578), control: p(252, 586))
        context.stroke(twig, with: .color(bark.opacity(0.9)), style: StrokeStyle(lineWidth: max(0.6, 2.6 * s), lineCap: .round))
        // Outline first, then the fill over it, so only the outer edge shows.
        context.stroke(bough, with: .color(ink.opacity(0.65)), lineWidth: max(0.8, 2 * s))
        context.fill(bough, with: .color(bark.opacity(0.94)))
        // A light along the top of the bough.
        var barkLight = Path()
        barkLight.move(to: p(384, 590))
        barkLight.addCurve(to: p(302, 601), control1: p(352, 587), control2: p(326, 600))
        barkLight.move(to: p(280, 601))
        barkLight.addQuadCurve(to: p(220, 594), control: p(250, 600))
        context.stroke(barkLight, with: .color(.white.opacity(0.3)), style: StrokeStyle(lineWidth: max(0.5, 2 * s), lineCap: .round))

        // MARK: Leaves

        func leafShape(length: CGFloat, width: CGFloat) -> Path {
            var path = Path()
            path.move(to: .zero)
            path.addQuadCurve(to: CGPoint(x: length, y: 0), control: CGPoint(x: length * 0.45, y: -width))
            path.addQuadCurve(to: .zero, control: CGPoint(x: length * 0.55, y: width))
            path.closeSubpath()
            return path
        }
        let leaves: [(base: CGPoint, degrees: Double, length: CGFloat, width: CGFloat)] = [
            (p(342, 591), -64, 30, 9),
            (p(318, 609), 64, 30, 9),
            (p(262, 607), 128, 32, 10),
            (p(236, 579), -104, 30, 9),
            (p(194, 597), 148, 28, 8),
            (p(176, 588), -118, 24, 7),
            (p(148, 570), -162, 30, 9)
        ]
        for leaf in leaves {
            let rotation = leaf.degrees * Double.pi / 180
            let shape = board.placed(leafShape(length: leaf.length, width: leaf.width), at: leaf.base, rotation: rotation)
            context.fill(shape, with: .color(leafGreen.opacity(0.9)))
            context.stroke(shape, with: .color(ink.opacity(0.55)), style: hairline)
            var rib = Path()
            rib.move(to: .zero)
            rib.addLine(to: CGPoint(x: leaf.length * 0.82, y: 0))
            context.stroke(board.placed(rib, at: leaf.base, rotation: rotation), with: .color(ink.opacity(0.35)), style: hairline)
        }

        // MARK: Nest

        // Where the bough meets the edge: a cupped bowl of twigs holding three eggs.
        let nestCenter = p(364, 598)
        context.fill(board.ellipse(at: nestCenter, rx: 30, ry: 9), with: .color(bark.opacity(0.7)))
        let eggColors = [board.participant(2), board.participant(3), board.participant(4)]
        for (index, offset) in [CGPoint(x: -14, y: -8), CGPoint(x: 1, y: -11), CGPoint(x: 15, y: -7)].enumerated() {
            let center = CGPoint(x: nestCenter.x + offset.x * s, y: nestCenter.y + offset.y * s)
            let egg = board.ellipse(at: center, rx: 8, ry: 10)
            context.fill(egg, with: .color(eggColors[index].opacity(0.92)))
            context.fill(
                board.ellipse(at: CGPoint(x: center.x - 2.5 * s, y: center.y - 4 * s), rx: 2.4, ry: 3.2),
                with: .color(.white.opacity(0.45))
            )
            context.stroke(egg, with: .color(ink.opacity(0.65)), style: hairline)
        }
        var bowl = Path()
        bowl.move(to: CGPoint(x: -30, y: 0))
        bowl.addQuadCurve(to: CGPoint(x: 30, y: 0), control: CGPoint(x: 0, y: 18))
        bowl.addQuadCurve(to: CGPoint(x: -30, y: 0), control: CGPoint(x: 0, y: 46))
        bowl.closeSubpath()
        let placedBowl = board.placed(bowl, at: nestCenter)
        context.fill(placedBowl, with: .color(bark.opacity(0.94)))
        context.stroke(placedBowl, with: .color(ink.opacity(0.65)), style: hairline)
        var straw = Path()
        for (from, control, to) in [
            (CGPoint(x: -25, y: 5), CGPoint(x: -8, y: 18), CGPoint(x: 12, y: 13)),
            (CGPoint(x: -18, y: 12), CGPoint(x: 2, y: 23), CGPoint(x: 23, y: 8)),
            (CGPoint(x: -10, y: 19), CGPoint(x: 5, y: 26), CGPoint(x: 18, y: 15)),
            (CGPoint(x: -22, y: 8), CGPoint(x: -14, y: 20), CGPoint(x: 0, y: 22))
        ] {
            straw.move(to: from)
            straw.addQuadCurve(to: to, control: control)
        }
        context.stroke(board.placed(straw, at: nestCenter), with: .color(ink.opacity(0.4)), style: hairline)

        // MARK: Perched songbird

        // Authored around the body's center, facing left, and hung from the
        // bough by the short-edge scale so it keeps its footing on wide boards.
        let birdScale: CGFloat = 1.3
        let footing = p(270, 606)
        let perch = CGPoint(x: footing.x, y: footing.y - 50 * s)
        func onPerch(_ path: Path) -> Path { board.placed(path, at: perch, scale: birdScale) }

        // A short tail angled down behind the perch, dark with pale tips.
        var tail = Path()
        tail.move(to: CGPoint(x: 16, y: -4))
        tail.addLine(to: CGPoint(x: 52, y: 14))
        tail.addLine(to: CGPoint(x: 55, y: 26))
        tail.addLine(to: CGPoint(x: 42, y: 32))
        tail.addLine(to: CGPoint(x: 12, y: 12))
        tail.closeSubpath()
        let placedTail = onPerch(tail)
        context.fill(placedTail, with: .color(ink.opacity(0.78)))
        context.stroke(placedTail, with: .color(ink), style: outline)
        var tailFeathers = Path()
        tailFeathers.move(to: CGPoint(x: 24, y: 6))
        tailFeathers.addLine(to: CGPoint(x: 52, y: 20))
        tailFeathers.move(to: CGPoint(x: 20, y: 12))
        tailFeathers.addLine(to: CGPoint(x: 46, y: 28))
        context.stroke(onPerch(tailFeathers), with: .color(.white.opacity(0.32)), style: hairline)
        var tailTips = Path()
        tailTips.move(to: CGPoint(x: 51, y: 17))
        tailTips.addLine(to: CGPoint(x: 44, y: 30))
        context.stroke(onPerch(tailTips), with: .color(.white.opacity(0.5)), style: StrokeStyle(lineWidth: max(0.6, 2 * s), lineCap: .round))

        var legs = Path()
        legs.move(to: CGPoint(x: -4, y: 26))
        legs.addLine(to: CGPoint(x: -8, y: 37))
        legs.addLine(to: CGPoint(x: -15, y: 38))
        legs.move(to: CGPoint(x: -8, y: 37))
        legs.addLine(to: CGPoint(x: -2, y: 40))
        legs.move(to: CGPoint(x: 8, y: 26))
        legs.addLine(to: CGPoint(x: 5, y: 37))
        legs.addLine(to: CGPoint(x: -2, y: 38))
        legs.move(to: CGPoint(x: 5, y: 37))
        legs.addLine(to: CGPoint(x: 11, y: 40))
        context.stroke(onPerch(legs), with: .color(ink.opacity(0.9)), style: StrokeStyle(lineWidth: max(0.6, 1.3 * s), lineCap: .round, lineJoin: .round))

        let body = onPerch(BoardSubjectCanvas.smoothClosed([
            CGPoint(x: -34, y: -6), CGPoint(x: -28, y: -22), CGPoint(x: -10, y: -30),
            CGPoint(x: 14, y: -26), CGPoint(x: 30, y: -12), CGPoint(x: 34, y: 6),
            CGPoint(x: 24, y: 22), CGPoint(x: 2, y: 30), CGPoint(x: -22, y: 22),
            CGPoint(x: -36, y: 8)
        ]))
        context.fill(body, with: .color(plumage.opacity(0.95)))
        // Breast, wing and crown light stay inside the silhouette.
        var feathered = context
        feathered.clip(to: body)
        feathered.fill(
            onPerch(Path(ellipseIn: CGRect(x: -42, y: -6, width: 60, height: 44))),
            with: .color(breast.opacity(0.9))
        )
        var wing = Path()
        wing.move(to: CGPoint(x: -10, y: -18))
        wing.addQuadCurve(to: CGPoint(x: 34, y: 10), control: CGPoint(x: 22, y: -22))
        wing.addQuadCurve(to: CGPoint(x: -10, y: -18), control: CGPoint(x: 8, y: 6))
        wing.closeSubpath()
        let placedWing = onPerch(wing)
        feathered.fill(placedWing, with: .color(ink.opacity(0.74)))
        var wingBars = Path()
        wingBars.move(to: CGPoint(x: 2, y: -12))
        wingBars.addQuadCurve(to: CGPoint(x: 24, y: 2), control: CGPoint(x: 14, y: -10))
        wingBars.move(to: CGPoint(x: -2, y: -4))
        wingBars.addQuadCurve(to: CGPoint(x: 18, y: 6), control: CGPoint(x: 8, y: -2))
        feathered.stroke(onPerch(wingBars), with: .color(.white.opacity(0.42)), style: StrokeStyle(lineWidth: max(0.5, 1.5 * s), lineCap: .round))
        var crownLight = Path()
        crownLight.move(to: CGPoint(x: -26, y: -18))
        crownLight.addQuadCurve(to: CGPoint(x: 6, y: -24), control: CGPoint(x: -12, y: -28))
        feathered.stroke(onPerch(crownLight), with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: max(0.6, 2.2 * s), lineCap: .round))
        context.stroke(body, with: .color(ink), style: outline)

        var beak = Path()
        beak.move(to: CGPoint(x: -33, y: -11))
        beak.addLine(to: CGPoint(x: -49, y: -5))
        beak.addLine(to: CGPoint(x: -33, y: -1))
        beak.closeSubpath()
        let placedBeak = onPerch(beak)
        context.fill(placedBeak, with: .color(ink.opacity(0.9)))
        context.stroke(placedBeak, with: .color(ink), style: hairline)
        context.fill(onPerch(Path(ellipseIn: CGRect(x: -25, y: -17, width: 6, height: 6))), with: .color(ink))
        context.fill(onPerch(Path(ellipseIn: CGRect(x: -24.4, y: -16.4, width: 2, height: 2))), with: .color(.white.opacity(0.85)))

        // MARK: Birds on the wing

        var wingArcs = Path()
        for (center, size) in [(p(44, 98), CGFloat(1.5)), (p(96, 56), 1.2), (p(144, 102), 1.0)] {
            var bird = Path()
            bird.move(to: CGPoint(x: -17, y: 3))
            bird.addQuadCurve(to: .zero, control: CGPoint(x: -9, y: -11))
            bird.addQuadCurve(to: CGPoint(x: 17, y: 3), control: CGPoint(x: 9, y: -11))
            wingArcs.addPath(board.placed(bird, at: center, scale: size))
        }
        context.stroke(wingArcs, with: .color(ink.opacity(0.82)), style: StrokeStyle(lineWidth: max(0.7, 2.2 * s), lineCap: .round))

        // MARK: Drifting feathers

        // A bare quill, a plume wider above the shaft than below, barbs
        // leaning toward the tip, and a pale under-wash so the vane reads on
        // the blue.
        for (base, degrees, length, tint) in [
            (p(30, 764), -40.0, CGFloat(104), featherBlue),
            (p(106, 790), 18.0, 88, featherPlum)
        ] {
            let rotation = degrees * Double.pi / 180
            let root = CGPoint(x: length * 0.2, y: 0)
            let tip = CGPoint(x: length, y: 0)
            let upper1 = CGPoint(x: length * 0.4, y: -length * 0.3)
            let upper2 = CGPoint(x: length * 0.86, y: -length * 0.18)
            let lower1 = CGPoint(x: length * 0.86, y: length * 0.11)
            let lower2 = CGPoint(x: length * 0.42, y: length * 0.17)
            var vane = Path()
            vane.move(to: root)
            vane.addCurve(to: tip, control1: upper1, control2: upper2)
            vane.addCurve(to: root, control1: lower1, control2: lower2)
            vane.closeSubpath()
            let placedVane = board.placed(vane, at: base, rotation: rotation)
            context.fill(placedVane, with: .color(.white.opacity(0.55)))
            context.fill(placedVane, with: .color(tint.opacity(0.74)))
            context.stroke(placedVane, with: .color(ink.opacity(0.45)), style: hairline)
            var barbs = Path()
            for index in 1..<9 {
                let t = CGFloat(index) / 9.5
                let u = 1 - t
                // Points along each vane edge, reached from the quill.
                let top = CGPoint(
                    x: u * u * u * root.x + 3 * u * u * t * upper1.x + 3 * u * t * t * upper2.x + t * t * t * tip.x,
                    y: 3 * u * u * t * upper1.y + 3 * u * t * t * upper2.y
                )
                let bottom = CGPoint(
                    x: u * u * u * tip.x + 3 * u * u * t * lower1.x + 3 * u * t * t * lower2.x + t * t * t * root.x,
                    y: 3 * u * u * t * lower1.y + 3 * u * t * t * lower2.y
                )
                barbs.move(to: CGPoint(x: top.x - length * 0.07, y: 0))
                barbs.addLine(to: CGPoint(x: top.x, y: top.y * 0.88))
                barbs.move(to: CGPoint(x: bottom.x - length * 0.06, y: 0))
                barbs.addLine(to: CGPoint(x: bottom.x, y: bottom.y * 0.88))
            }
            context.stroke(board.placed(barbs, at: base, rotation: rotation), with: .color(ink.opacity(0.3)), style: hairline)
            var quill = Path()
            quill.move(to: .zero)
            quill.addLine(to: tip)
            context.stroke(board.placed(quill, at: base, rotation: rotation), with: .color(ink.opacity(0.75)), style: StrokeStyle(lineWidth: max(0.6, 1.4 * s), lineCap: .round))
            var shaftLight = Path()
            shaftLight.move(to: CGPoint(x: length * 0.24, y: -1.2))
            shaftLight.addLine(to: CGPoint(x: length * 0.9, y: -1.2))
            context.stroke(board.placed(shaftLight, at: base, rotation: rotation), with: .color(.white.opacity(0.5)), style: hairline)
        }
    }
}
