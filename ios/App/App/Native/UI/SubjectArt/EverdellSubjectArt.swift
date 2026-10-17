import SwiftUI

// Everdell: the great tree, abstracted. A massive trunk rises from the bottom
// edge over splayed roots and forks into limbs that climb both sides of the
// board and branch again into a dense canopy across the top, which opens in
// the middle so the honey light pours through. Four lanterns hang from twigs
// on the branches, a cottage with a lit window sits on the roots and a pair
// of mushrooms grows beside them.

extension BoardSubjectArtRenderer {
    static func drawEverTree(in context: inout GraphicsContext, on board: BoardSubjectCanvas) {
        let p = board.point
        let s = board.scale
        let wood = board.color("#3A2412")
        let woodDark = board.color("#2A1A10")
        let leafDark = board.color("#6B3A1E")
        let leafMid = board.color("#C98A3A")
        let lantern = board.color("#E8B85A")
        let cream = board.color("#F3EBC9")
        let berry = board.color("#963F50")

        /// A tapering limb: a closed outline around a cubic centerline from
        /// `a` to `b`, `width` wide at the base and `tip` wide at the end, so
        /// joins and tips stay clean with no stroke caps. Every limb is wound
        /// the same way, so they union under the nonzero fill rule.
        func limb(from a: CGPoint, to b: CGPoint, control1 c1: CGPoint, control2 c2: CGPoint, width: CGFloat, tip: CGFloat) -> Path {
            var left: [CGPoint] = []
            var right: [CGPoint] = []
            let samples = 14
            for index in 0...samples {
                let t = CGFloat(index) / CGFloat(samples)
                let mt = 1 - t
                let b0 = mt * mt * mt
                let b1 = 3 * mt * mt * t
                let b2 = 3 * mt * t * t
                let b3 = t * t * t
                let x = b0 * a.x + b1 * c1.x + b2 * c2.x + b3 * b.x
                let y = b0 * a.y + b1 * c1.y + b2 * c2.y + b3 * b.y
                let d0 = 3 * mt * mt
                let d1 = 6 * mt * t
                let d2 = 3 * t * t
                let dx = d0 * (c1.x - a.x) + d1 * (c2.x - c1.x) + d2 * (b.x - c2.x)
                let dy = d0 * (c1.y - a.y) + d1 * (c2.y - c1.y) + d2 * (b.y - c2.y)
                let length = max(0.001, (dx * dx + dy * dy).squareRoot())
                let half = (width + (tip - width) * t) * s / 2
                let nx = -dy / length * half
                let ny = dx / length * half
                left.append(CGPoint(x: x + nx, y: y + ny))
                right.append(CGPoint(x: x - nx, y: y - ny))
            }
            var path = Path()
            path.move(to: left[0])
            for point in left.dropFirst() { path.addLine(to: point) }
            for point in right.reversed() { path.addLine(to: point) }
            path.closeSubpath()
            return path
        }

        // MARK: Canopy

        // Leaf masses across the top edge and down both sides, unioned into
        // one dark silhouette with a gap over the middle; the top-center mass
        // sits mostly above the board so the opening starts near the edge.
        var leaves = board.generator(salt: 0x4556_4552_5452)
        func leafMass(_ center: CGPoint, _ radius: CGFloat) -> Path {
            var points: [CGPoint] = []
            for index in 0..<8 {
                let angle = Double(index) / 8 * 2 * Double.pi
                let reach = radius * leaves.range(0.84...1.1)
                points.append(CGPoint(x: cos(angle) * reach, y: sin(angle) * reach))
            }
            return board.blob(center: center, points: points)
        }
        var darkCanopy = Path()
        for (x, y, radius) in [
            (30, 30, 92), (110, -12, 86), (195, -62, 92), (285, -8, 86), (365, 36, 92),
            (-18, 136, 76), (408, 150, 78), (95, 95, 60), (298, 100, 60),
            (44, 128, 56), (350, 136, 58), (-2, 236, 54), (394, 246, 56)
        ] as [(CGFloat, CGFloat, CGFloat)] {
            darkCanopy.addPath(leafMass(p(x, y), radius))
        }
        context.fill(darkCanopy, with: .color(leafDark.opacity(0.78)))

        // MARK: Trunk, limbs and roots

        var timber = Path()
        timber.addPath(limb(from: p(195, 880), to: p(195, 556), control1: p(188, 760), control2: p(200, 640), width: 136, tip: 66))
        // Roots splaying from the base.
        timber.addPath(limb(from: p(165, 804), to: p(24, 868), control1: p(132, 818), control2: p(70, 840), width: 36, tip: 4))
        timber.addPath(limb(from: p(225, 804), to: p(366, 868), control1: p(258, 818), control2: p(320, 840), width: 36, tip: 4))
        timber.addPath(limb(from: p(180, 838), to: p(100, 882), control1: p(156, 852), control2: p(126, 868), width: 22, tip: 3))
        timber.addPath(limb(from: p(210, 838), to: p(290, 882), control1: p(234, 852), control2: p(264, 868), width: 22, tip: 3))
        // Two main limbs from the fork, each branching again into the canopy,
        // the second branches tapering to points that vanish in the leaves.
        timber.addPath(limb(from: p(195, 590), to: p(72, 335), control1: p(150, 545), control2: p(70, 445), width: 62, tip: 32))
        timber.addPath(limb(from: p(195, 590), to: p(324, 350), control1: p(244, 548), control2: p(332, 455), width: 62, tip: 32))
        timber.addPath(limb(from: p(74, 340), to: p(18, 128), control1: p(52, 292), control2: p(16, 206), width: 32, tip: 2))
        timber.addPath(limb(from: p(74, 340), to: p(128, 106), control1: p(80, 282), control2: p(106, 190), width: 28, tip: 2))
        timber.addPath(limb(from: p(322, 355), to: p(378, 146), control1: p(348, 304), control2: p(380, 222), width: 32, tip: 2))
        timber.addPath(limb(from: p(322, 355), to: p(266, 118), control1: p(320, 294), control2: p(290, 206), width: 28, tip: 2))
        // Twigs reaching inward, one for each lantern.
        let twigTips = [p(88, 236), p(168, 240), p(240, 252), p(310, 250)]
        timber.addPath(limb(from: p(38, 248), to: twigTips[0], control1: p(54, 240), control2: p(72, 234), width: 9, tip: 2))
        timber.addPath(limb(from: p(100, 213), to: twigTips[1], control1: p(124, 216), control2: p(150, 232), width: 9, tip: 2))
        timber.addPath(limb(from: p(297, 227), to: twigTips[2], control1: p(276, 234), control2: p(256, 246), width: 9, tip: 2))
        timber.addPath(limb(from: p(360, 263), to: twigTips[3], control1: p(344, 254), control2: p(326, 250), width: 9, tip: 2))

        // Outline, then the wood over it so the joins between parts vanish.
        context.stroke(timber, with: .color(woodDark.opacity(0.7)), style: StrokeStyle(lineWidth: max(0.8, 2 * s), lineJoin: .round))
        context.fill(timber, with: .color(wood.opacity(0.95)))

        // Bark lines up the trunk and along the limbs, and the honey light
        // catching the wood nearest the glow, both clipped to the timber.
        var clipped = context
        clipped.clip(to: timber)
        var bark = Path()
        for (x0, x1, bend) in [(150.0, 176.0, 6.0), (168.0, 188.0, -5.0), (196.0, 198.0, 5.0), (218.0, 220.0, -6.0), (240.0, 242.0, 4.0)] as [(CGFloat, CGFloat, CGFloat)] {
            bark.move(to: p(x0, 870))
            bark.addCurve(to: p(x1, 596), control1: p(x0 + bend, 770), control2: p(x1 - bend, 680))
        }
        bark.move(to: p(178, 578))
        bark.addCurve(to: p(84, 380), control1: p(150, 530), control2: p(96, 450))
        bark.move(to: p(212, 578))
        bark.addCurve(to: p(310, 392), control1: p(240, 530), control2: p(298, 455))
        clipped.stroke(bark, with: .color(woodDark.opacity(0.55)), lineWidth: max(0.5, 1.6 * s))
        clipped.fill(Path(board.bounds), with: .radialGradient(
            Gradient(colors: [leafMid.opacity(0.38), leafMid.opacity(0)]),
            center: p(195, 330),
            startRadius: 0,
            endRadius: 330 * s
        ))

        // Lit leaf clusters over the dark canopy and the branch tips.
        var litCanopy = Path()
        for (x, y, radius) in [
            (68, 56, 52), (150, 16, 46), (248, 10, 48), (330, 64, 54), (14, 176, 42),
            (386, 196, 44), (108, 132, 36), (288, 138, 38), (12, 262, 30), (384, 272, 32)
        ] as [(CGFloat, CGFloat, CGFloat)] {
            litCanopy.addPath(leafMass(p(x, y), radius))
        }
        context.fill(litCanopy, with: .color(leafMid.opacity(0.58)))

        // MARK: Lanterns

        let lanternCenters = [p(88, 276), p(168, 296), p(240, 284), p(310, 300)]
        var strings = Path()
        var bodies = Path()
        var frames = Path()
        var ribs = Path()
        var glows = Path()
        for (tip, center) in zip(twigTips, lanternCenters) {
            strings.move(to: tip)
            strings.addLine(to: CGPoint(x: center.x, y: center.y - 17 * s))
            bodies.addPath(board.placed(
                Path(roundedRect: CGRect(x: -6.5, y: -9, width: 13, height: 18), cornerRadius: 4.5),
                at: center
            ))
            var frame = Path()
            frame.move(to: CGPoint(x: -6, y: -9))
            frame.addLine(to: CGPoint(x: -4.5, y: -13.5))
            frame.addLine(to: CGPoint(x: 4.5, y: -13.5))
            frame.addLine(to: CGPoint(x: 6, y: -9))
            frame.closeSubpath()
            frame.addRect(CGRect(x: -4, y: 9, width: 8, height: 2.8))
            frame.addEllipse(in: CGRect(x: -2.4, y: -18.5, width: 4.8, height: 4.8))
            frames.addPath(board.placed(frame, at: center))
            var rib = Path()
            rib.move(to: CGPoint(x: -2.2, y: -8)); rib.addLine(to: CGPoint(x: -2.2, y: 8))
            rib.move(to: CGPoint(x: 2.2, y: -8)); rib.addLine(to: CGPoint(x: 2.2, y: 8))
            ribs.addPath(board.placed(rib, at: center))
            glows.addPath(board.circle(at: center, radius: 19))
        }

        // MARK: Cottage in the roots

        let cottage = p(120, 806)
        let windowCenter = CGPoint(x: cottage.x + 7 * s, y: cottage.y - 13 * s)
        glows.addPath(board.circle(at: windowCenter, radius: 11))

        // One soft pass lights every lantern and the window together.
        var glow = context
        glow.addFilter(.blur(radius: max(3, 7 * s)))
        glow.fill(glows, with: .color(lantern.opacity(0.5)))

        context.stroke(strings, with: .color(woodDark.opacity(0.85)), lineWidth: max(0.5, 1 * s))
        context.fill(bodies, with: .color(lantern.opacity(0.95)))
        context.stroke(ribs, with: .color(woodDark.opacity(0.4)), lineWidth: max(0.4, 0.8 * s))
        context.stroke(bodies, with: .color(woodDark.opacity(0.9)), lineWidth: max(0.5, 1.2 * s))
        context.fill(frames, with: .color(woodDark.opacity(0.92)))

        context.fill(
            board.placed(Path(roundedRect: CGRect(x: -17, y: -24, width: 34, height: 25), cornerRadius: 2), at: cottage),
            with: .color(woodDark.opacity(0.95))
        )
        context.fill(board.placed(Path(CGRect(x: 9, y: -44, width: 5, height: 12)), at: cottage), with: .color(woodDark.opacity(0.95)))
        var roof = Path()
        roof.move(to: CGPoint(x: -22, y: -22))
        roof.addQuadCurve(to: CGPoint(x: 0, y: -46), control: CGPoint(x: -14, y: -44))
        roof.addQuadCurve(to: CGPoint(x: 22, y: -22), control: CGPoint(x: 14, y: -44))
        roof.addQuadCurve(to: CGPoint(x: -22, y: -22), control: CGPoint(x: 0, y: -18))
        roof.closeSubpath()
        let placedRoof = board.placed(roof, at: cottage)
        context.fill(placedRoof, with: .color(leafDark.opacity(0.95)))
        context.stroke(placedRoof, with: .color(woodDark.opacity(0.9)), lineWidth: max(0.5, 1 * s))
        var door = Path()
        door.move(to: CGPoint(x: -12, y: 0))
        door.addLine(to: CGPoint(x: -12, y: -11))
        door.addQuadCurve(to: CGPoint(x: -2, y: -11), control: CGPoint(x: -7, y: -21))
        door.addLine(to: CGPoint(x: -2, y: 0))
        door.closeSubpath()
        let placedDoor = board.placed(door, at: cottage)
        context.fill(placedDoor, with: .color(wood.opacity(0.95)))
        context.stroke(placedDoor, with: .color(leafMid.opacity(0.6)), lineWidth: max(0.4, 0.9 * s))
        let window = board.circle(at: windowCenter, radius: 3.6)
        context.fill(window, with: .color(lantern.opacity(0.97)))
        var panes = Path()
        panes.move(to: CGPoint(x: windowCenter.x - 3.6 * s, y: windowCenter.y))
        panes.addLine(to: CGPoint(x: windowCenter.x + 3.6 * s, y: windowCenter.y))
        panes.move(to: CGPoint(x: windowCenter.x, y: windowCenter.y - 3.6 * s))
        panes.addLine(to: CGPoint(x: windowCenter.x, y: windowCenter.y + 3.6 * s))
        context.stroke(panes, with: .color(woodDark.opacity(0.8)), lineWidth: max(0.4, 0.8 * s))
        context.stroke(window, with: .color(woodDark.opacity(0.9)), lineWidth: max(0.4, 0.9 * s))

        // MARK: Mushrooms

        for (position, size) in [(p(284, 822), 1.0), (p(302, 830), 0.68)] as [(CGPoint, CGFloat)] {
            let stem = Path(roundedRect: CGRect(x: -3, y: -1, width: 6, height: 10), cornerRadius: 2)
            context.fill(board.placed(stem, at: position, scale: size), with: .color(cream.opacity(0.85)))
            var cap = Path()
            cap.move(to: CGPoint(x: -10, y: 0))
            cap.addQuadCurve(to: CGPoint(x: 10, y: 0), control: CGPoint(x: 0, y: -17))
            cap.addQuadCurve(to: CGPoint(x: -10, y: 0), control: CGPoint(x: 0, y: 3))
            cap.closeSubpath()
            context.fill(board.placed(cap, at: position, scale: size), with: .color(berry.opacity(0.92)))
            var spots = Path()
            spots.addEllipse(in: CGRect(x: -5.6, y: -7.6, width: 3.2, height: 3.2))
            spots.addEllipse(in: CGRect(x: 1.7, y: -10.3, width: 2.6, height: 2.6))
            spots.addEllipse(in: CGRect(x: 3.9, y: -4.1, width: 2.2, height: 2.2))
            context.fill(board.placed(spots, at: position, scale: size), with: .color(cream.opacity(0.85)))
        }
    }
}
