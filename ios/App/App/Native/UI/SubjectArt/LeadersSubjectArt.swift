import SwiftUI

// Leaders: a duel on a hex board. A cluster of gold-inked hex cells sits in
// the lower half with the two start spaces inlaid solid; two facing groups of
// three standee figures stand on the cells, each a round head and a bust on a
// flat wooden base with a split outline, black on its outer side and white on
// the side facing the opponent, the way a two-sided standee is printed; a
// pennant is planted at each group's flank. The upper half is left to the
// screenprint field. The cluster is laid out from its hub by the short-edge
// scale, so the honeycomb stays regular on a wide board.

extension BoardSubjectArtRenderer {
    static func drawLeadersStandees(in context: inout GraphicsContext, on board: BoardSubjectCanvas) {
        let s = board.scale
        let gold = board.color("#B8902A")
        let wood = board.color("#8A6A20")
        let ink = board.color("#053842")
        let leftLeader = board.color("#08747C")
        let leftGuard = board.color("#43B2BA")
        let rightLeader = board.color("#C73366")
        let rightGuard = board.color("#053842")

        // MARK: Hex cells

        let radius: CGFloat = 26
        let columnStep = radius * 1.7320508
        let rowStep = radius * 1.5
        let hub = board.point(195, 640)
        func cell(_ column: CGFloat, _ row: CGFloat) -> CGPoint {
            CGPoint(x: hub.x + column * columnStep * s, y: hub.y + row * rowStep * s)
        }
        func hexagon(at center: CGPoint, radius r: CGFloat) -> Path {
            var path = Path()
            for index in 0..<6 {
                let angle = (Double(index) * 60 - 90) * Double.pi / 180
                let vertex = CGPoint(x: center.x + cos(angle) * r * s, y: center.y + sin(angle) * r * s)
                if index == 0 { path.move(to: vertex) } else { path.addLine(to: vertex) }
            }
            path.closeSubpath()
            return path
        }

        // Rows of five, six and five.
        var cells = Path()
        for column in -2...2 {
            cells.addPath(hexagon(at: cell(CGFloat(column), -1), radius: radius))
            cells.addPath(hexagon(at: cell(CGFloat(column), 1), radius: radius))
        }
        for column in 0..<6 {
            cells.addPath(hexagon(at: cell(CGFloat(column) - 2.5, 0), radius: radius))
        }
        // The start spaces, inlaid solid with an inner rule.
        for column in [CGFloat(-2.5), 2.5] {
            context.fill(hexagon(at: cell(column, 0), radius: radius), with: .color(gold.opacity(0.35)))
            context.stroke(
                hexagon(at: cell(column, 0), radius: radius - 7),
                with: .color(gold.opacity(0.7)),
                style: StrokeStyle(lineWidth: max(0.4, 0.8 * s), lineJoin: .round)
            )
        }
        context.stroke(cells, with: .color(gold.opacity(0.95)), style: StrokeStyle(lineWidth: max(0.5, 1.5 * s), lineJoin: .round))

        // MARK: Standees

        // Authored with the base's center at the origin and the figure rising
        // above it: a bust with rounded shoulders, a neck and a round head.
        func headPoint(_ degrees: Double) -> CGPoint {
            let radians = degrees * Double.pi / 180
            return CGPoint(x: cos(radians) * 7, y: -38 + sin(radians) * 7)
        }
        let figureScale: CGFloat = 1.3
        var leftEdge = Path()
        leftEdge.move(to: CGPoint(x: -7, y: -8))
        leftEdge.addLine(to: CGPoint(x: -12, y: -22))
        leftEdge.addQuadCurve(to: CGPoint(x: -4, y: -30), control: CGPoint(x: -12, y: -29))
        leftEdge.addLine(to: headPoint(120))
        for step in 1...8 {
            leftEdge.addLine(to: headPoint(120 + Double(step) * 18.75))
        }
        var rightEdge = Path()
        rightEdge.move(to: headPoint(270))
        for step in 1...8 {
            rightEdge.addLine(to: headPoint(270 + Double(step) * 18.75))
        }
        rightEdge.addLine(to: CGPoint(x: 4, y: -30))
        rightEdge.addQuadCurve(to: CGPoint(x: 12, y: -22), control: CGPoint(x: 12, y: -29))
        rightEdge.addLine(to: CGPoint(x: 7, y: -8))
        var silhouette = Path()
        silhouette.addPath(leftEdge)
        silhouette.addPath(rightEdge)
        silhouette.closeSubpath()
        let baseTop = Path(roundedRect: CGRect(x: -12, y: -8, width: 24, height: 5), cornerRadius: 2)
        let baseSide = Path(roundedRect: CGRect(x: -11, y: -4, width: 22, height: 5), cornerRadius: 1.5)
        let splitLine = StrokeStyle(lineWidth: max(0.5, 1.2 * s), lineCap: .round, lineJoin: .round)

        func drawStandee(at base: CGPoint, tint: Color, darkOnLeft: Bool) {
            func put(_ path: Path) -> Path { board.placed(path, at: base, scale: figureScale) }
            context.fill(board.ellipse(at: CGPoint(x: base.x, y: base.y + 1.5 * s), rx: 19, ry: 4.5), with: .color(ink.opacity(0.14)))
            context.fill(put(baseSide), with: .color(wood.opacity(0.95)))
            context.fill(put(baseTop), with: .color(gold.opacity(0.95)))
            context.stroke(put(baseTop), with: .color(ink.opacity(0.4)), lineWidth: max(0.3, 0.6 * s))
            context.fill(put(silhouette), with: .color(tint.opacity(0.95)))
            context.stroke(put(darkOnLeft ? leftEdge : rightEdge), with: .color(.black.opacity(0.85)), style: splitLine)
            context.stroke(put(darkOnLeft ? rightEdge : leftEdge), with: .color(.white.opacity(0.92)), style: splitLine)
        }

        // Back row first, so nearer figures stand in front.
        drawStandee(at: cell(-2, -1), tint: leftGuard, darkOnLeft: true)
        drawStandee(at: cell(2, -1), tint: rightGuard, darkOnLeft: false)
        drawStandee(at: cell(-2.5, 0), tint: leftLeader, darkOnLeft: true)
        drawStandee(at: cell(2.5, 0), tint: rightLeader, darkOnLeft: false)
        drawStandee(at: cell(-2, 1), tint: leftGuard, darkOnLeft: true)
        drawStandee(at: cell(2, 1), tint: rightGuard, darkOnLeft: false)

        // MARK: Pennants

        // Planted at each flank, flying toward the opponent.
        for (side, tint) in [(CGFloat(-1), leftLeader), (1, rightLeader)] {
            let foot = CGPoint(x: hub.x + side * 160 * s, y: hub.y + 30 * s)
            var pole = Path()
            pole.move(to: foot)
            pole.addLine(to: CGPoint(x: foot.x, y: foot.y - 76 * s))
            context.stroke(pole, with: .color(wood.opacity(0.95)), style: StrokeStyle(lineWidth: max(0.6, 1.8 * s), lineCap: .round))
            var flag = Path()
            flag.move(to: CGPoint(x: 0, y: -76))
            flag.addQuadCurve(to: CGPoint(x: -side * 28, y: -66), control: CGPoint(x: -side * 14, y: -75))
            flag.addQuadCurve(to: CGPoint(x: 0, y: -56), control: CGPoint(x: -side * 14, y: -58))
            flag.closeSubpath()
            let placedFlag = board.placed(flag, at: foot)
            context.fill(placedFlag, with: .color(tint.opacity(0.92)))
            context.stroke(placedFlag, with: .color(ink.opacity(0.6)), style: StrokeStyle(lineWidth: max(0.4, 0.8 * s), lineJoin: .round))
            context.fill(board.circle(at: CGPoint(x: foot.x, y: foot.y - 78 * s), radius: 2.2), with: .color(gold.opacity(0.95)))
        }
    }
}
