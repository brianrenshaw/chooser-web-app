import SwiftUI

// Deeper surfaces for the original eight worlds, grounded in each game's box
// and components. Like `BoardWorldSurfaces.swift`, these are abstract
// procedural recipes authored on a 390 x 844 board and scaled by the short
// edge, composited in non-linear (sRGB) space.

// MARK: - Wingspan Original: wet-edged watercolor washes

/// Two loose washes whose pigment pools at a slightly darker edge, the way
/// watercolor dries on cold-press paper.
struct WetEdgeWashView: View {
    let visualTheme: ChooserVisualTheme

    var body: some View {
        Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: true) { context, size in
            let recipe = visualTheme.surfaceRecipe
            let scale = max(0.2, min(size.width, size.height) / 390)
            var generator = BoardTextureGenerator(seed: visualTheme.textureSeed ^ 0x5741_5348)
            let washes: [(index: Int, center: CGPoint, radius: CGSize)] = [
                (0, CGPoint(x: size.width * 0.23, y: size.height * 0.21), CGSize(width: 150 * scale, height: 120 * scale)),
                (1, CGPoint(x: size.width * 0.82, y: size.height * 0.73), CGSize(width: 170 * scale, height: 150 * scale))
            ]
            for wash in washes {
                let tint = recipe.atmosphere(at: wash.index)
                let path = Self.blob(center: wash.center, radius: wash.radius, generator: &generator)
                var soft = context
                soft.addFilter(.blur(radius: 6 * scale))
                soft.fill(path, with: .color(tint.color.opacity(tint.opacity)))
                // The wet edge: a thin, darker ring where the pigment dried.
                context.stroke(
                    path,
                    with: .color(tint.color.opacity(min(0.4, tint.opacity * 1.8))),
                    lineWidth: max(0.8, 2.4 * scale)
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static func blob(center: CGPoint, radius: CGSize, generator: inout BoardTextureGenerator) -> Path {
        let count = 14
        let points = (0..<count).map { index -> CGPoint in
            let angle = Double(index) / Double(count) * 2 * .pi
            let wobble = generator.range(0.80...1.12)
            return CGPoint(
                x: center.x + radius.width * wobble * cos(angle),
                y: center.y + radius.height * wobble * sin(angle)
            )
        }
        var path = Path()
        path.move(to: CGPoint(x: (points[0].x + points[count - 1].x) / 2, y: (points[0].y + points[count - 1].y) / 2))
        for index in 0..<count {
            let current = points[index]
            let next = points[(index + 1) % count]
            path.addQuadCurve(to: CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2), control: current)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Wingspan Asia: red lacquer with a peacock eye-spot

/// Tone-on-tone concentric eye-spots behind the play area and in two corners,
/// with a soft lacquer gloss from the upper left.
struct PeacockLacquerView: View {
    let visualTheme: ChooserVisualTheme

    var body: some View {
        Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: true) { context, size in
            let spot = visualTheme.surfaceRecipe.atmosphere(at: 0)
            let gloss = visualTheme.surfaceRecipe.atmosphere(at: 1)
            let scale = max(0.2, min(size.width, size.height) / 390)
            let lineWidth = max(0.8, 2 * scale)
            for (center, radius) in [
                (CGPoint(x: size.width * 0.5, y: size.height * 0.5), CGSize(width: 120 * scale, height: 150 * scale)),
                (CGPoint(x: size.width * 0.15, y: size.height * 0.14), CGSize(width: 70 * scale, height: 88 * scale)),
                (CGPoint(x: size.width * 0.87, y: size.height * 0.90), CGSize(width: 80 * scale, height: 100 * scale))
            ] {
                for (ratio, drop) in [(1.0, 0.0), (0.66, 0.04), (0.34, 0.08)] {
                    let rect = CGRect(
                        x: center.x - radius.width * ratio,
                        y: center.y - radius.height * ratio + radius.height * drop,
                        width: radius.width * ratio * 2,
                        height: radius.height * ratio * 2
                    )
                    context.stroke(Path(ellipseIn: rect), with: .color(spot.color.opacity(spot.opacity)), lineWidth: lineWidth)
                }
            }
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: gloss.color.opacity(gloss.opacity), location: 0),
                        .init(color: gloss.color.opacity(0), location: 0.45)
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Wingspan Americas: rainforest clearing

/// Dark leaf silhouettes reaching in from the corners of a lit clearing.
struct RainforestEdgeLeavesView: View {
    let visualTheme: ChooserVisualTheme

    var body: some View {
        Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: true) { context, size in
            let shade = visualTheme.surfaceRecipe.atmosphere(at: 0)
            let scale = max(0.2, min(size.width, size.height) / 390)
            func leaf(base: CGPoint, tip: CGPoint, width: CGFloat) -> Path {
                let dx = tip.x - base.x
                let dy = tip.y - base.y
                let length = max(1, hypot(dx, dy))
                let normal = CGPoint(x: -dy / length * width, y: dx / length * width)
                var path = Path()
                path.move(to: base)
                path.addQuadCurve(to: tip, control: CGPoint(x: base.x + dx * 0.5 + normal.x, y: base.y + dy * 0.5 + normal.y))
                path.addQuadCurve(to: base, control: CGPoint(x: base.x + dx * 0.5 - normal.x, y: base.y + dy * 0.5 - normal.y))
                return path
            }
            let w = size.width
            let h = size.height
            let s = scale
            let leaves: [(CGPoint, CGPoint, CGFloat)] = [
                (CGPoint(x: -20 * s, y: 0), CGPoint(x: 10 * s, y: 140 * s), 22 * s),
                (CGPoint(x: 30 * s, y: -10 * s), CGPoint(x: 90 * s, y: 120 * s), 20 * s),
                (CGPoint(x: -10 * s, y: 40 * s), CGPoint(x: 120 * s, y: 70 * s), 16 * s),
                (CGPoint(x: w + 20 * s, y: 30 * s), CGPoint(x: w - 30 * s, y: 170 * s), 22 * s),
                (CGPoint(x: w - 30 * s, y: -10 * s), CGPoint(x: w - 90 * s, y: 100 * s), 18 * s),
                (CGPoint(x: -20 * s, y: h), CGPoint(x: 20 * s, y: h - 144 * s), 22 * s),
                (CGPoint(x: 20 * s, y: h + 10 * s), CGPoint(x: 110 * s, y: h - 90 * s), 18 * s),
                (CGPoint(x: w + 20 * s, y: h), CGPoint(x: w - 20 * s, y: h - 144 * s), 22 * s),
                (CGPoint(x: w - 20 * s, y: h + 10 * s), CGPoint(x: w - 120 * s, y: h - 70 * s), 18 * s)
            ]
            for (base, tip, width) in leaves {
                context.fill(leaf(base: base, tip: tip, width: width), with: .color(shade.color.opacity(min(1, shade.opacity * 1.25))))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Nidavellir: slate and forge

/// A forge glow rising from below the slate.
struct SlateForgeGlowView: View {
    let visualTheme: ChooserVisualTheme

    var body: some View {
        Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: true) { context, size in
            let forge = visualTheme.surfaceRecipe.atmosphere(at: 0)
            let cool = visualTheme.surfaceRecipe.atmosphere(at: 1)
            let rect = Path(CGRect(origin: .zero, size: size))
            context.fill(rect, with: .radialGradient(
                Gradient(colors: [forge.color.opacity(forge.opacity), forge.color.opacity(0)]),
                center: CGPoint(x: size.width / 2, y: size.height),
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.6
            ))
            context.fill(rect, with: .radialGradient(
                Gradient(colors: [cool.color.opacity(cool.opacity), cool.color.opacity(0)]),
                center: CGPoint(x: size.width / 2, y: size.height * 0.36),
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.45
            ))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Concordia: the map board

/// The opaque structure of the Concordia board: a parchment frame around an
/// engraved sea, with soft province washes. Part of the base surface.
struct MediterraneanMapStructureView: View {
    let visualTheme: ChooserVisualTheme

    var body: some View {
        Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: true) { context, size in
            let recipe = visualTheme.surfaceRecipe
            let ochre = recipe.atmosphere(at: 0)
            let terracotta = recipe.atmosphere(at: 1)
            let wave = recipe.atmosphere(at: 2)
            let parchment = ChooserColorTheme.color(hex: visualTheme.secondaryDetailHex ?? "#E8DDC0")
            let route = ChooserColorTheme.color(hex: visualTheme.detailAccentHex)
            let scale = max(0.2, min(size.width, size.height) / 390)
            let sx = size.width / 390
            let sy = size.height / 844
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * sx, y: y * sy) }

            // Engraved waves across the sea.
            var waves = Path()
            let spacing = 14 * scale
            var y = spacing
            var row = 0
            while y < size.height {
                var x: CGFloat = row.isMultiple(of: 2) ? 0 : -20 * scale
                while x < size.width {
                    waves.move(to: CGPoint(x: x, y: y))
                    waves.addQuadCurve(to: CGPoint(x: x + 20 * scale, y: y), control: CGPoint(x: x + 10 * scale, y: y - 5 * scale))
                    x += 40 * scale
                }
                y += spacing
                row += 1
            }
            context.stroke(waves, with: .color(wave.color.opacity(wave.opacity)), lineWidth: max(0.5, 1 * scale))

            // Province washes, like coastlines seen from above.
            var province = Path()
            province.move(to: point(0, 300))
            province.addQuadCurve(to: point(200, 320), control: point(120, 260))
            province.addQuadCurve(to: point(390, 330), control: point(280, 380))
            province.addLine(to: point(390, 560))
            province.addQuadCurve(to: point(190, 540), control: point(260, 600))
            province.addQuadCurve(to: point(0, 520), control: point(110, 470))
            province.closeSubpath()
            context.fill(province, with: .color(ochre.color.opacity(ochre.opacity)))
            var south = Path()
            south.move(to: point(0, 640))
            south.addQuadCurve(to: point(200, 660), control: point(120, 600))
            south.addQuadCurve(to: point(390, 690), control: point(290, 720))
            south.addLine(to: point(390, 844))
            south.addLine(to: point(0, 844))
            south.closeSubpath()
            context.fill(south, with: .color(terracotta.color.opacity(terracotta.opacity)))

            // Parchment frame with a fine dashed rule, following the corners.
            let frameWidth = 16 * scale
            var frame = Path(CGRect(origin: .zero, size: size))
            let inner = CGRect(origin: .zero, size: size).insetBy(dx: frameWidth, dy: frameWidth)
            frame.addRoundedRect(in: inner, cornerSize: CGSize(width: 26 * scale, height: 26 * scale))
            context.fill(frame, with: .color(parchment), style: FillStyle(eoFill: true))
            context.stroke(
                Path(roundedRect: inner, cornerSize: CGSize(width: 26 * scale, height: 26 * scale)),
                with: .color(route.opacity(0.55)),
                lineWidth: max(0.6, 1.2 * scale)
            )
            context.stroke(
                Path(roundedRect: CGRect(origin: .zero, size: size).insetBy(dx: 6 * scale, dy: 6 * scale), cornerSize: CGSize(width: 32 * scale, height: 32 * scale)),
                with: .color(route.opacity(0.45)),
                style: StrokeStyle(lineWidth: max(0.5, 1 * scale), dash: [14 * scale, 4 * scale])
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Everdell: honey light and autumn leaves

/// A few autumn leaves drifting at the edges of the tree's honey light.
struct FallingLeavesView: View {
    let visualTheme: ChooserVisualTheme

    var body: some View {
        Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: true) { context, size in
            let recipe = visualTheme.surfaceRecipe
            let scale = max(0.2, min(size.width, size.height) / 390)
            let sx = size.width / 390
            let sy = size.height / 844
            let placements: [(x: CGFloat, y: CGFloat, angle: Double, tint: Int)] = [
                (52, 762, -0.3, 0), (342, 128, 0.6, 1), (312, 790, 0.2, 2),
                (72, 118, -0.8, 1), (30, 430, 1.1, 2), (366, 470, -1.2, 0)
            ]
            for placement in placements {
                let tint = recipe.atmosphere(at: placement.tint)
                var leaf = Path()
                let length = 22 * scale
                leaf.move(to: CGPoint(x: -length / 2, y: 0))
                leaf.addQuadCurve(to: CGPoint(x: length / 2, y: 0), control: CGPoint(x: 0, y: -length * 0.6))
                leaf.addQuadCurve(to: CGPoint(x: -length / 2, y: 0), control: CGPoint(x: 0, y: length * 0.45))
                let transform = CGAffineTransform(rotationAngle: placement.angle)
                    .concatenating(CGAffineTransform(translationX: placement.x * sx, y: placement.y * sy))
                context.fill(leaf.applying(transform), with: .color(tint.color.opacity(min(1, tint.opacity * 1.3))))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Lizard Wizard: amber and plum painting

/// Plum shadow at the edges and a warm painted bloom near the top, with no
/// red frame.
struct AmberPlumPaintingView: View {
    let visualTheme: ChooserVisualTheme

    var body: some View {
        Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: true) { context, size in
            let plum = visualTheme.surfaceRecipe.atmosphere(at: 0)
            let warm = visualTheme.surfaceRecipe.atmosphere(at: 1)
            let rect = Path(CGRect(origin: .zero, size: size))
            context.fill(rect, with: .radialGradient(
                Gradient(stops: [
                    .init(color: plum.color.opacity(0), location: 0.42),
                    .init(color: plum.color.opacity(plum.opacity), location: 1)
                ]),
                center: CGPoint(x: size.width * 0.46, y: size.height * 0.42),
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.72
            ))
            // Broad brush strokes, felt rather than seen.
            var strokes = context
            strokes.addFilter(.blur(radius: max(4, min(size.width, size.height) * 0.03)))
            for (y, tilt) in [(0.22, -0.06), (0.48, 0.04), (0.74, -0.03)] as [(CGFloat, CGFloat)] {
                var stroke = Path()
                stroke.move(to: CGPoint(x: -20, y: size.height * y))
                stroke.addQuadCurve(
                    to: CGPoint(x: size.width + 20, y: size.height * (y + tilt)),
                    control: CGPoint(x: size.width * 0.5, y: size.height * (y - 0.05))
                )
                strokes.stroke(stroke, with: .color(warm.color.opacity(warm.opacity)), lineWidth: min(size.width, size.height) * 0.12)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Leaders: gold-ink inlay

/// A thin gold-ink border inside the board's edge, like the inlay marking
/// the board's start spaces.
struct GoldInlayBorderView: View {
    let visualTheme: ChooserVisualTheme

    var body: some View {
        Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: true) { context, size in
            let gold = visualTheme.surfaceRecipe.atmosphere(at: 2)
            let ink = ChooserColorTheme.color(hex: visualTheme.surfaceInkHex)
            let scale = max(0.2, min(size.width, size.height) / 390)
            let outer = CGRect(origin: .zero, size: size).insetBy(dx: 16 * scale, dy: 16 * scale)
            let inner = CGRect(origin: .zero, size: size).insetBy(dx: 22 * scale, dy: 22 * scale)
            context.stroke(
                Path(roundedRect: outer, cornerSize: CGSize(width: 30 * scale, height: 30 * scale)),
                with: .linearGradient(
                    Gradient(colors: [gold.color, gold.color.opacity(0.7), gold.color]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: size.height)
                ),
                lineWidth: max(0.6, 1.2 * scale)
            )
            context.stroke(
                Path(roundedRect: inner, cornerSize: CGSize(width: 26 * scale, height: 26 * scale)),
                with: .color(ink.opacity(0.22)),
                lineWidth: max(0.5, 0.8 * scale)
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
