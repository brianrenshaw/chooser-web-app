import SwiftUI

// Wingspan Americas: two hummingbirds hovering at trumpet blooms. Each bloom
// hangs from a stem that climbs in from a corner and opens toward its bird;
// each bird is a teardrop body with a needle beak, a gold throat, a forked
// tail and two translucent wing ellipses for the blur of hovering. One pair
// in the upper left over the light, one in the lower right in the shade,
// with grains of pollen drifting between beak and bloom. Each bloom is hung
// from its bird by the short-edge scale so the pair stays together on a
// wide board.

extension BoardSubjectArtRenderer {
    static func drawHummingbirdsAndBlooms(in context: inout GraphicsContext, on board: BoardSubjectCanvas) {
        let p = board.point
        let s = board.scale
        let shade = board.color("#0B2B21")
        let stem = board.color("#075D38")
        let stemLight = board.color("#5DB46E")
        let teal = board.color("#0A7880")
        let pink = board.color("#EF4770")
        let orange = board.color("#E85A3B")
        let gold = board.color("#F1D35A")
        let birdScale: CGFloat = 1.4
        let bloomScale: CGFloat = 1.3

        /// Places a path authored around its origin with +x as its facing
        /// direction; `flipped` mirrors it so it faces left before rotating.
        func place(_ path: Path, at position: CGPoint, degrees: Double, magnify: CGFloat, flipped: Bool = false) -> Path {
            path.applying(
                CGAffineTransform(scaleX: (flipped ? -1 : 1) * s * magnify, y: s * magnify)
                    .concatenating(CGAffineTransform(rotationAngle: degrees * Double.pi / 180))
                    .concatenating(CGAffineTransform(translationX: position.x, y: position.y))
            )
        }
        func rotatedEllipse(center: CGPoint, rx: CGFloat, ry: CGFloat, degrees: Double) -> Path {
            Path(ellipseIn: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2)).applying(
                CGAffineTransform(rotationAngle: degrees * Double.pi / 180)
                    .concatenating(CGAffineTransform(translationX: center.x, y: center.y))
            )
        }

        // MARK: Blooms

        // Authored with the trumpet's axis along +x: calyx, tube, five lobes
        // at the rim, a throat, and three stamens dusted with pollen.
        func drawBloom(base: CGPoint, degrees: Double, from corner: CGPoint, control: CGPoint, petal: Color, throat: Color, salt: UInt64) {
            func put(_ path: Path) -> Path { place(path, at: base, degrees: degrees, magnify: bloomScale) }
            var stalk = Path()
            stalk.move(to: corner)
            stalk.addQuadCurve(to: base, control: control)
            context.stroke(stalk, with: .color(stem.opacity(0.95)), style: StrokeStyle(lineWidth: max(0.8, 3.6 * s), lineCap: .round))
            context.stroke(stalk, with: .color(stemLight.opacity(0.45)), style: StrokeStyle(lineWidth: max(0.4, 1.2 * s), lineCap: .round))

            var calyx = Path()
            calyx.move(to: CGPoint(x: 6, y: -6))
            calyx.addQuadCurve(to: CGPoint(x: -10, y: 0), control: CGPoint(x: -6, y: -7))
            calyx.addQuadCurve(to: CGPoint(x: 6, y: 6), control: CGPoint(x: -6, y: 7))
            calyx.closeSubpath()
            context.fill(put(calyx), with: .color(stem.opacity(0.95)))

            var bell = Path()
            bell.move(to: CGPoint(x: -2, y: -4))
            bell.addQuadCurve(to: CGPoint(x: 30, y: -12), control: CGPoint(x: 16, y: -5))
            bell.addLine(to: CGPoint(x: 30, y: 12))
            bell.addQuadCurve(to: CGPoint(x: -2, y: 4), control: CGPoint(x: 16, y: 5))
            bell.closeSubpath()
            for angle in [-78.0, -39, 0, 39, 78] {
                let radians = angle * Double.pi / 180
                bell.addPath(rotatedEllipse(
                    center: CGPoint(x: 31 + 9 * cos(radians), y: 15 * sin(radians)),
                    rx: 10, ry: 6.5, degrees: angle
                ))
            }
            let placedBell = put(bell)
            context.stroke(placedBell, with: .color(shade.opacity(0.7)), lineWidth: max(0.6, 1.8 * s))
            context.fill(placedBell, with: .color(petal.opacity(0.94)))
            // The throat seen through the mouth, its shadow, and a light along the tube.
            context.fill(put(Path(ellipseIn: CGRect(x: 27, y: -10, width: 11, height: 20))), with: .color(throat.opacity(0.92)))
            context.fill(put(Path(ellipseIn: CGRect(x: 30, y: -5, width: 5, height: 10))), with: .color(shade.opacity(0.55)))
            var light = Path()
            light.move(to: CGPoint(x: 2, y: -3))
            light.addQuadCurve(to: CGPoint(x: 26, y: -9), control: CGPoint(x: 14, y: -4))
            context.stroke(put(light), with: .color(.white.opacity(0.3)), style: StrokeStyle(lineWidth: max(0.5, 1.8 * s), lineCap: .round))

            let antherEnds = [CGPoint(x: 52, y: -4), CGPoint(x: 55, y: 1), CGPoint(x: 51, y: 6)]
            var stamens = Path()
            for end in antherEnds {
                stamens.move(to: CGPoint(x: 33, y: 0))
                stamens.addQuadCurve(to: end, control: CGPoint(x: 44, y: end.y * 0.4))
            }
            context.stroke(put(stamens), with: .color(throat.opacity(0.9)), style: StrokeStyle(lineWidth: max(0.4, 1 * s), lineCap: .round))
            var anthers = Path()
            for end in antherEnds {
                anthers.addPath(Path(ellipseIn: CGRect(x: end.x - 1.8, y: end.y - 1.8, width: 3.6, height: 3.6)))
            }
            context.fill(put(anthers), with: .color(gold.opacity(0.95)))

            // Pollen drifting out of the mouth.
            var pollen = board.generator(salt: salt)
            var grains = Path()
            for _ in 0..<9 {
                let along = pollen.range(44...82)
                let across = pollen.range(-24...24)
                let r = pollen.range(0.8...1.6)
                grains.addPath(Path(ellipseIn: CGRect(x: along - r, y: across - r, width: r * 2, height: r * 2)))
            }
            context.fill(put(grains), with: .color(gold.opacity(0.8)))
        }

        // MARK: Hummingbirds

        // Authored facing right: wings, forked tail, needle beak, body,
        // throat, sheen and eye.
        func drawHummingbird(at position: CGPoint, degrees: Double, flipped: Bool, plumage: Color) {
            func put(_ path: Path) -> Path { place(path, at: position, degrees: degrees, magnify: birdScale, flipped: flipped) }
            var wings = Path()
            wings.addPath(rotatedEllipse(center: CGPoint(x: -9, y: -20), rx: 6, ry: 17, degrees: -28))
            wings.addPath(rotatedEllipse(center: CGPoint(x: 6, y: -19), rx: 6, ry: 17, degrees: 24))
            let placedWings = put(wings)
            context.fill(placedWings, with: .color(plumage.opacity(0.62)))
            context.fill(placedWings, with: .color(.white.opacity(0.1)))
            context.stroke(placedWings, with: .color(.white.opacity(0.4)), lineWidth: max(0.4, 0.9 * s))

            var tail = Path()
            tail.move(to: CGPoint(x: -16, y: -3))
            tail.addLine(to: CGPoint(x: -40, y: -10))
            tail.addLine(to: CGPoint(x: -22, y: 3))
            tail.closeSubpath()
            tail.move(to: CGPoint(x: -16, y: 1))
            tail.addLine(to: CGPoint(x: -40, y: 10))
            tail.addLine(to: CGPoint(x: -22, y: 5))
            tail.closeSubpath()
            let placedTail = put(tail)
            context.fill(placedTail, with: .color(plumage.opacity(0.9)))
            context.stroke(placedTail, with: .color(shade.opacity(0.7)), style: StrokeStyle(lineWidth: max(0.4, 0.8 * s), lineJoin: .round))

            var beak = Path()
            beak.move(to: CGPoint(x: 14, y: -4))
            beak.addLine(to: CGPoint(x: 46, y: -6))
            beak.addLine(to: CGPoint(x: 14, y: 0))
            beak.closeSubpath()
            context.fill(put(beak), with: .color(shade.opacity(0.92)))

            let body = put(BoardSubjectCanvas.smoothClosed([
                CGPoint(x: -22, y: 2), CGPoint(x: -12, y: -8), CGPoint(x: 4, y: -11),
                CGPoint(x: 16, y: -7), CGPoint(x: 19, y: 1), CGPoint(x: 11, y: 10),
                CGPoint(x: -6, y: 10)
            ]))
            context.fill(body, with: .color(plumage.opacity(0.95)))
            var feathered = context
            feathered.clip(to: body)
            feathered.fill(put(Path(ellipseIn: CGRect(x: 4, y: -1, width: 16, height: 11))), with: .color(gold.opacity(0.95)))
            var sheen = Path()
            sheen.move(to: CGPoint(x: -12, y: -5))
            sheen.addQuadCurve(to: CGPoint(x: 10, y: -7), control: CGPoint(x: 0, y: -10))
            feathered.stroke(put(sheen), with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: max(0.5, 2 * s), lineCap: .round))
            context.stroke(body, with: .color(shade.opacity(0.75)), lineWidth: max(0.4, 1 * s))
            context.fill(put(Path(ellipseIn: CGRect(x: 8, y: -7, width: 3.6, height: 3.6))), with: .color(shade.opacity(0.95)))
            context.fill(put(Path(ellipseIn: CGRect(x: 8.6, y: -6.6, width: 1.2, height: 1.2))), with: .color(.white.opacity(0.8)))
        }

        // MARK: The two pairs

        // Upper left: an orange trumpet climbing from the corner opens up and
        // to the right; a teal bird dips in from above.
        let upperBird = p(120, 250)
        drawBloom(
            base: CGPoint(x: upperBird.x - 66 * s, y: upperBird.y + 80 * s), degrees: -53,
            from: p(-6, 30), control: p(6, 240),
            petal: orange, throat: gold, salt: 0x4855_4D01
        )
        drawHummingbird(at: upperBird, degrees: -40, flipped: true, plumage: teal)

        // Lower right: a gold trumpet climbing from the corner opens up and
        // to the left; a pink bird dips in from above.
        let lowerBird = p(300, 560)
        drawBloom(
            base: CGPoint(x: lowerBird.x + 66 * s, y: lowerBird.y + 70 * s), degrees: -127,
            from: p(396, 830), control: p(392, 700),
            petal: gold, throat: orange, salt: 0x4855_4D02
        )
        drawHummingbird(at: lowerBird, degrees: 40, flipped: false, plumage: pink)
    }
}
