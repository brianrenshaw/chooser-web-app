import SwiftUI

// Surfaces for the Res Arcana, Everdell Emerland and Sagrada worlds. Each is an
// abstract procedural recipe: color relationships and materials are inspired by
// the games, while artwork, logos, characters, symbols and fonts are not used.
//
// Every recipe is authored against a 390 x 844 phone board and scaled by the
// short edge, so Settings miniatures, phones and iPads keep the same character.
// They composite in non-linear (sRGB) space, the space they were designed in;
// linear blending lifts translucent light over dark glass and leather to grey.

private func hexColor(_ hex: String) -> Color { ChooserColorTheme.color(hex: hex) }

// MARK: - Res Arcana: tooled grimoire

/// Blind tooling pressed into candlelit leather: a double border, a ticked
/// circle, a pentagon with five node circles and corner arcs. Each line is drawn
/// twice, a dark pass up-left and a faint warm pass down-right, so it reads as
/// a groove rather than as ink. No star is drawn.
struct GrimoireToolingView: View {
    let visualTheme: ChooserVisualTheme

    var body: some View {
        Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: true) { context, size in
            let recipe = visualTheme.surfaceRecipe
            let ember = recipe.atmosphere(at: 0)
            let highlight = recipe.atmosphere(at: 1)
            let groove = recipe.atmosphere(at: 2)
            let scale = max(0.2, min(size.width, size.height) / 390)

            // Ember bloom low in the middle, as if from a candle on the table.
            let emberCenter = CGPoint(x: size.width * 0.5, y: size.height * 0.64)
            let emberRadius = max(size.width, size.height) * 0.38
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .radialGradient(
                    Gradient(colors: [ember.color.opacity(ember.opacity), ember.color.opacity(0)]),
                    center: emberCenter,
                    startRadius: 0,
                    endRadius: emberRadius
                )
            )

            let tooling = Self.toolingPath(in: size, scale: scale)
            let dotted = Self.dottedRingPath(in: size, scale: scale)
            let offset = 0.7 * scale
            for (dx, color, opacity) in [
                (-offset, groove.color, groove.opacity),
                (offset, highlight.color, highlight.opacity)
            ] {
                var layer = context
                layer.translateBy(x: dx, y: dx)
                layer.stroke(
                    tooling,
                    with: .color(color.opacity(opacity)),
                    style: StrokeStyle(lineWidth: max(0.6, 1.2 * scale), lineCap: .round, lineJoin: .round)
                )
                layer.stroke(
                    dotted,
                    with: .color(color.opacity(opacity)),
                    style: StrokeStyle(
                        lineWidth: max(0.5, 0.8 * scale),
                        lineCap: .round,
                        dash: [0.1, 4 * scale]
                    )
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    static func diagramCenter(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.5, y: size.height * 0.51)
    }

    static func toolingPath(in size: CGSize, scale: CGFloat) -> Path {
        var path = Path()
        let center = diagramCenter(in: size)
        // Fit the diagram to the short edge so a landscape board keeps it whole.
        let outer = min(size.width, size.height) * 0.456

        // Double border, following the board's own corners.
        let outerInset = 14 * scale
        let innerInset = 21 * scale
        path.addRoundedRect(
            in: CGRect(origin: .zero, size: size).insetBy(dx: outerInset, dy: outerInset),
            cornerSize: CGSize(width: 34 * scale, height: 34 * scale)
        )
        path.addRoundedRect(
            in: CGRect(origin: .zero, size: size).insetBy(dx: innerInset, dy: innerInset),
            cornerSize: CGSize(width: 28 * scale, height: 28 * scale)
        )

        // Rings.
        for ratio in [1.0, 152.0 / 178.0, 58.0 / 178.0] {
            let radius = outer * ratio
            path.addEllipse(in: CGRect(
                x: center.x - radius, y: center.y - radius,
                width: radius * 2, height: radius * 2
            ))
        }

        // Dial ticks just inside the outer ring, longer every 30 degrees.
        let tickOuter = outer * (174.0 / 178.0)
        for index in 0..<60 {
            let angle = (Double(index) * 6 - 90) * .pi / 180
            let tickInner = outer * (index.isMultiple(of: 5) ? 164.0 / 178.0 : 168.0 / 178.0)
            path.move(to: CGPoint(
                x: center.x + tickInner * cos(angle),
                y: center.y + tickInner * sin(angle)
            ))
            path.addLine(to: CGPoint(
                x: center.x + tickOuter * cos(angle),
                y: center.y + tickOuter * sin(angle)
            ))
        }

        // Pentagon (the essence tray) with a node circle at each vertex.
        let pentagonRadius = outer * (150.0 / 178.0)
        let nodeRadius = outer * (11.0 / 178.0)
        let vertices = (0..<5).map { index -> CGPoint in
            let angle = (-90 + 72 * Double(index)) * .pi / 180
            return CGPoint(
                x: center.x + pentagonRadius * cos(angle),
                y: center.y + pentagonRadius * sin(angle)
            )
        }
        path.addLines(vertices + [vertices[0]])
        for vertex in vertices {
            path.addEllipse(in: CGRect(
                x: vertex.x - nodeRadius, y: vertex.y - nodeRadius,
                width: nodeRadius * 2, height: nodeRadius * 2
            ))
        }

        // Corner arcs inside the border.
        let reach = 46 * scale
        let edge = outerInset
        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            (CGPoint(x: edge, y: edge + 106 * scale), CGPoint(x: edge + reach, y: edge + 106 * scale), CGPoint(x: edge + reach, y: edge + 60 * scale)),
            (CGPoint(x: size.width - edge, y: edge + 106 * scale), CGPoint(x: size.width - edge - reach, y: edge + 106 * scale), CGPoint(x: size.width - edge - reach, y: edge + 60 * scale)),
            (CGPoint(x: edge, y: size.height - edge - 106 * scale), CGPoint(x: edge + reach, y: size.height - edge - 106 * scale), CGPoint(x: edge + reach, y: size.height - edge - 60 * scale)),
            (CGPoint(x: size.width - edge, y: size.height - edge - 106 * scale), CGPoint(x: size.width - edge - reach, y: size.height - edge - 106 * scale), CGPoint(x: size.width - edge - reach, y: size.height - edge - 60 * scale))
        ]
        for (start, control, end) in corners {
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)
        }
        return path
    }

    static func dottedRingPath(in size: CGSize, scale: CGFloat) -> Path {
        let center = diagramCenter(in: size)
        let radius = min(size.width, size.height) * 0.456 * (52.0 / 178.0)
        return Path(ellipseIn: CGRect(
            x: center.x - radius, y: center.y - radius,
            width: radius * 2, height: radius * 2
        ))
    }
}

// MARK: - Everdell Emerland: canopy and river valley

/// A turquoise river through a misty, sunlit valley, framed by dark canopy
/// leaves, hanging vines and split monstera leaves at the lower corners.
struct CanopyRiverValleyView: View {
    let visualTheme: ChooserVisualTheme

    private static let canopyShades = ["#0B3A33", "#114A3E", "#1A5E48", "#0E4238"].map(hexColor)
    private static let vineLeaf = hexColor("#2A7556")
    private static let vineStem = hexColor("#1F5A45")
    private static let lilyPad = hexColor("#3E9A5E")
    private static let monstera = [hexColor("#155C45"), hexColor("#0E4A3A")]
    private static let violetBloom = hexColor("#A877D8")

    var body: some View {
        Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: true) { context, size in
            let recipe = visualTheme.surfaceRecipe
            let canopy = recipe.atmosphere(at: 0)
            let river = recipe.atmosphere(at: 1)
            let light = recipe.atmosphere(at: 2)
            let orchid = recipe.atmosphere(at: 3)
            let scale = max(0.2, min(size.width, size.height) / 390)
            let sx = size.width / 390
            let sy = size.height / 844
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * sx, y: y * sy) }

            // River ribbon, brightening as it nears the viewer.
            var ribbon = Path()
            ribbon.move(to: point(214, 210))
            ribbon.addCurve(to: point(200, 560), control1: point(150, 340), control2: point(132, 450))
            ribbon.addCurve(to: point(240, 860), control1: point(268, 670), control2: point(252, 740))
            ribbon.addLine(to: point(372, 860))
            ribbon.addCurve(to: point(272, 560), control1: point(344, 740), control2: point(300, 640))
            ribbon.addCurve(to: point(250, 210), control1: point(226, 450), control2: point(226, 340))
            ribbon.closeSubpath()
            var hazy = context
            hazy.addFilter(.blur(radius: 1.6 * scale))
            hazy.fill(ribbon, with: .linearGradient(
                Gradient(colors: [
                    river.color.opacity(river.opacity * 0.35),
                    river.color.opacity(river.opacity * 1.2),
                    river.color.opacity(min(1, river.opacity * 1.7))
                ]),
                startPoint: point(0, 210),
                endPoint: point(0, 844)
            ))

            // Ripples.
            for (x, y, width) in [(196.0, 380.0, 20.0), (182, 452, 24), (214, 520, 22), (238, 610, 26), (262, 690, 28), (280, 770, 30)] {
                var ripple = Path()
                ripple.move(to: point(x, y))
                ripple.addQuadCurve(to: point(x + width, y), control: point(x + width / 2, y - 4))
                context.stroke(ripple, with: .color(.white.opacity(0.45)), lineWidth: max(0.6, 1.4 * scale))
            }

            // Lily pads.
            for (x, y, radius) in [(320.0, 742.0, 13.0), (282, 806, 10), (345, 800, 8)] {
                let r = radius * scale
                let c = point(x, y)
                context.fill(
                    Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r * 0.64, width: r * 2, height: r * 1.28)),
                    with: .color(Self.lilyPad.opacity(0.75))
                )
            }

            // Shafts of light from the upper left, softened.
            var shafts = context
            shafts.addFilter(.blur(radius: 18 * scale))
            for (points, strength) in [
                ([point(-40, -20), point(40, -40), point(300, 720), point(180, 760)], 1.0),
                ([point(70, -40), point(120, -40), point(380, 560), point(330, 600)], 0.7),
                ([point(-60, 60), point(-20, 20), point(160, 820), point(80, 840)], 0.6)
            ] {
                var shaft = Path()
                shaft.addLines(points)
                shaft.closeSubpath()
                shafts.fill(shaft, with: .linearGradient(
                    Gradient(colors: [light.color.opacity(light.opacity * strength), light.color.opacity(0)]),
                    startPoint: points[0],
                    endPoint: points[2]
                ))
            }

            // Dappled light.
            for (x, y, radius) in [(150.0, 300.0, 40.0), (258, 246, 28), (110, 520, 34)] {
                let c = point(x, y)
                let r = radius * scale
                context.fill(
                    Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                    with: .radialGradient(
                        Gradient(colors: [light.color.opacity(0.38), light.color.opacity(0)]),
                        center: c, startRadius: 0, endRadius: r
                    )
                )
            }

            // Canopy: seeded leaves along the top and down both sides.
            var generator = BoardTextureGenerator(seed: visualTheme.textureSeed)
            let leafLength = 64 * scale
            func leaf(at origin: CGPoint, angle: Double, length: CGFloat) -> Path {
                var path = Path()
                path.move(to: .zero)
                path.addCurve(
                    to: CGPoint(x: length, y: 0),
                    control1: CGPoint(x: length * 0.22, y: -length * 0.15),
                    control2: CGPoint(x: length * 0.62, y: -length * 0.17)
                )
                path.addCurve(
                    to: .zero,
                    control1: CGPoint(x: length * 0.62, y: length * 0.17),
                    control2: CGPoint(x: length * 0.22, y: length * 0.15)
                )
                return path.applying(
                    CGAffineTransform(rotationAngle: angle).concatenating(
                        CGAffineTransform(translationX: origin.x, y: origin.y)
                    )
                )
            }
            let canopyBase = canopy.opacity / 0.40
            for _ in 0..<46 {
                let x = generator.range(-30...(size.width + 30))
                let edgeDrop = abs(x - size.width / 2) / max(1, size.width / 2) * 40 * scale
                let y = generator.range(-30...(110 * scale)) + edgeDrop
                let angle = Double(generator.range(0...(2 * .pi)))
                let shade = Self.canopyShades[Int(generator.unit() * 4) % 4]
                context.fill(
                    leaf(at: CGPoint(x: x, y: y), angle: angle, length: leafLength * generator.range(0.9...1.9)),
                    with: .color(shade.opacity(canopyBase))
                )
            }
            for side in 0..<2 {
                for _ in 0..<14 {
                    let x = side == 0 ? generator.range(-25...18) * scale : size.width - generator.range(-25...18) * scale
                    let y = generator.range(90...420) * sy
                    let angle = Double(generator.range(-1.0...1.0)) + (side == 0 ? 0 : .pi)
                    let shade = Self.canopyShades[Int(generator.unit() * 4) % 4]
                    context.fill(
                        leaf(at: CGPoint(x: x, y: y), angle: angle, length: leafLength * generator.range(0.7...1.4)),
                        with: .color(shade.opacity(canopyBase))
                    )
                }
            }

            // Two hanging vines.
            for (x, length) in [(58.0 * sx, 240.0 * sy), (size.width - 46 * sx, 280.0 * sy)] {
                var vine = Path()
                vine.move(to: CGPoint(x: x, y: 0))
                var y: CGFloat = 0
                var swing: CGFloat = 1
                while y < length {
                    let next = y + 40 * sy
                    vine.addQuadCurve(
                        to: CGPoint(x: x + generator.range(-5...5) * scale, y: next),
                        control: CGPoint(x: x + swing * 10 * scale, y: y + 20 * sy)
                    )
                    swing *= -1
                    y = next
                }
                context.stroke(vine, with: .color(Self.vineStem.opacity(0.8)), lineWidth: max(0.8, 1.6 * scale))
                var leafY = 56 * sy
                var flip = 1.0
                while leafY < length {
                    context.fill(
                        leaf(at: CGPoint(x: x, y: leafY), angle: .pi / 2 - flip * 0.95, length: 20 * scale),
                        with: .color(Self.vineLeaf)
                    )
                    flip *= -1
                    leafY += 56 * sy
                }
            }

            // Split monstera leaves at the lower corners.
            Self.drawMonstera(
                in: &context,
                tip: CGPoint(x: 70 * sx, y: size.height - 74 * sy),
                rotation: 216 * .pi / 180,
                scale: 1.15 * scale,
                color: Self.monstera[0]
            )
            Self.drawMonstera(
                in: &context,
                tip: CGPoint(x: size.width - 18 * sx, y: size.height - 44 * sy),
                rotation: 150 * .pi / 180,
                scale: 0.8 * scale,
                color: Self.monstera[1]
            )

            // A few orchid and violet blooms caught in the leaves.
            for (x, y, r) in [(24.0, 704.0, 6.0), (33, 698, 5), (30, 710, 5)] {
                let c = CGPoint(x: x * sx, y: size.height - (844 - y) * scale)
                context.fill(
                    Path(ellipseIn: CGRect(x: c.x - r * scale, y: c.y - r * scale, width: r * 2 * scale, height: r * 2 * scale)),
                    with: .color(orchid.color)
                )
            }
            for (x, y, r) in [(372.0, 430.0, 4.5), (366, 440, 4), (374, 450, 3.5)] {
                let c = CGPoint(x: size.width - (390 - x) * scale, y: y * sy)
                context.fill(
                    Path(ellipseIn: CGRect(x: c.x - r * scale, y: c.y - r * scale, width: r * 2 * scale, height: r * 2 * scale)),
                    with: .color(Self.violetBloom)
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// A heart-shaped leaf with three slits per side and two small holes,
    /// cut out with `destinationOut` inside its own layer.
    private static func drawMonstera(
        in context: inout GraphicsContext,
        tip: CGPoint,
        rotation: Double,
        scale: CGFloat,
        color: Color
    ) {
        context.drawLayer { layer in
            layer.translateBy(x: tip.x, y: tip.y)
            layer.rotate(by: .radians(rotation))
            layer.scaleBy(x: scale, y: scale)
            var leaf = Path()
            leaf.move(to: .zero)
            leaf.addCurve(to: CGPoint(x: -78, y: -100), control1: CGPoint(x: -40, y: -10), control2: CGPoint(x: -80, y: -50))
            leaf.addCurve(to: CGPoint(x: 0, y: -150), control1: CGPoint(x: -76, y: -150), control2: CGPoint(x: -30, y: -175))
            leaf.addCurve(to: CGPoint(x: 78, y: -100), control1: CGPoint(x: 30, y: -175), control2: CGPoint(x: 76, y: -150))
            leaf.addCurve(to: .zero, control1: CGPoint(x: 80, y: -50), control2: CGPoint(x: 40, y: -10))
            leaf.closeSubpath()
            layer.fill(leaf, with: .color(color))

            layer.blendMode = .destinationOut
            var slits = Path()
            for (start, end) in [
                (CGPoint(x: -34, y: -40), CGPoint(x: -96, y: -62)),
                (CGPoint(x: -40, y: -82), CGPoint(x: -100, y: -110)),
                (CGPoint(x: -30, y: -122), CGPoint(x: -74, y: -160))
            ] {
                slits.move(to: start); slits.addLine(to: end)
                slits.move(to: CGPoint(x: -start.x, y: start.y)); slits.addLine(to: CGPoint(x: -end.x, y: end.y))
            }
            layer.stroke(slits, with: .color(.black), style: StrokeStyle(lineWidth: 7, lineCap: .round))
            layer.fill(Path(ellipseIn: CGRect(x: -21, y: -70, width: 8, height: 16)), with: .color(.black))
            layer.fill(Path(ellipseIn: CGRect(x: 13, y: -106, width: 8, height: 16)), with: .color(.black))
        }
    }
}

// MARK: - Sagrada: rose window

/// The opaque structure of the Sagrada board: dim leaded shards, a rose
/// window behind the play area and a stone frame. Drawn as part of the base
/// surface, so Reduce Transparency never fades the window away.
struct RoseWindowStructureView: View {
    let visualTheme: ChooserVisualTheme

    /// Dusk glass: deep and slightly desaturated, so lit pieces always win.
    static let panePalette = [
        "#1B2F6E", "#22407F", "#1B2F6E", "#2A2560", "#22407F", "#134A55",
        "#5E1426", "#3E1F66", "#6E4A0E", "#164A2E", "#4A1238", "#1E3A78"
    ].map(hexColor)
    private static let petals = ["#8E2230", "#24489A"].map(hexColor)
    private static let outerLights = ["#7A5A12", "#4A2A86", "#165E66", "#4A2A86"].map(hexColor)
    private static let oculus = ["#FFF6D8", "#F2C64A", "#B07A12"].map(hexColor)
    private static let stoneDark = hexColor("#6E716C")
    private static let mortar = hexColor("#4E504C")

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let roseRadius = min(size.width, size.height) * 0.40
            let tessellation = RoseWindowTessellationCache.tessellation(
                size: size,
                seed: visualTheme.textureSeed,
                center: center,
                clearRadius: roseRadius
            )
            Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: true) { context, _ in
                let lead = hexColor(visualTheme.dividerSecondaryHex ?? "#0D080A")
                let stone = hexColor(visualTheme.dividerHex)
                let scale = max(0.2, min(size.width, size.height) / 390)
                let leadWidth = max(0.8, 2.4 * scale)

                for cell in tessellation.cells {
                    var pane = Path()
                    pane.addLines(cell.vertices)
                    pane.closeSubpath()
                    context.fill(pane, with: .color(Self.panePalette[cell.paletteIndex % Self.panePalette.count]))
                    context.stroke(pane, with: .color(lead), style: StrokeStyle(lineWidth: leadWidth, lineJoin: .round))
                }

                // Stone ring, then the rose's two tiers of lights and the oculus.
                let stoneRing = Path(ellipseIn: CGRect(
                    x: center.x - roseRadius, y: center.y - roseRadius,
                    width: roseRadius * 2, height: roseRadius * 2
                ))
                context.fill(stoneRing, with: .linearGradient(
                    Gradient(colors: [stone, Self.stoneDark]),
                    startPoint: CGPoint(x: center.x - roseRadius, y: center.y - roseRadius),
                    endPoint: CGPoint(x: center.x + roseRadius, y: center.y + roseRadius)
                ))
                context.stroke(stoneRing, with: .color(lead), lineWidth: leadWidth)

                let outer = roseRadius * (146.0 / 156.0)
                let middle = roseRadius * (96.0 / 156.0)
                let inner = roseRadius * (34.0 / 156.0)
                for index in 0..<24 {
                    let wedge = Self.wedge(center: center, inner: middle, outer: outer, index: index, count: 24)
                    context.fill(wedge, with: .color(Self.outerLights[index % 4]))
                    context.stroke(wedge, with: .color(lead), style: StrokeStyle(lineWidth: leadWidth * 0.84, lineJoin: .round))
                }
                for index in 0..<12 {
                    let wedge = Self.wedge(center: center, inner: inner, outer: middle, index: index, count: 12)
                    context.fill(wedge, with: .color(Self.petals[index % 2]))
                    context.stroke(wedge, with: .color(lead), style: StrokeStyle(lineWidth: leadWidth * 0.84, lineJoin: .round))
                }
                let tracery = Path(ellipseIn: CGRect(
                    x: center.x - middle, y: center.y - middle,
                    width: middle * 2, height: middle * 2
                ))
                context.stroke(tracery, with: .color(stone.opacity(0.9)), lineWidth: max(1, 3 * scale))
                context.stroke(tracery, with: .color(lead.opacity(0.8)), lineWidth: max(0.5, 1 * scale))
                let oculus = Path(ellipseIn: CGRect(
                    x: center.x - inner, y: center.y - inner,
                    width: inner * 2, height: inner * 2
                ))
                context.fill(oculus, with: .radialGradient(
                    Gradient(colors: Self.oculus),
                    center: center, startRadius: 0, endRadius: inner
                ))
                context.stroke(oculus, with: .color(lead), lineWidth: leadWidth)

                // Stone frame with block joints, following the board's corners.
                let frameWidth = 14 * scale
                var frame = Path(CGRect(origin: .zero, size: size))
                frame.addRoundedRect(
                    in: CGRect(origin: .zero, size: size).insetBy(dx: frameWidth, dy: frameWidth),
                    cornerSize: CGSize(width: 30 * scale, height: 30 * scale)
                )
                context.fill(
                    frame,
                    with: .linearGradient(
                        Gradient(colors: [stone, Self.stoneDark]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: size.width, y: size.height)
                    ),
                    style: FillStyle(eoFill: true)
                )
                var joints = Path()
                var x = 90 * scale
                while x < size.width - frameWidth {
                    joints.move(to: CGPoint(x: x, y: 0)); joints.addLine(to: CGPoint(x: x, y: frameWidth))
                    joints.move(to: CGPoint(x: x - 30 * scale, y: size.height - frameWidth)); joints.addLine(to: CGPoint(x: x - 30 * scale, y: size.height))
                    x += 80 * scale
                }
                var y = 120 * scale
                while y < size.height - frameWidth {
                    joints.move(to: CGPoint(x: 0, y: y)); joints.addLine(to: CGPoint(x: frameWidth, y: y))
                    joints.move(to: CGPoint(x: size.width - frameWidth, y: y + 50 * scale)); joints.addLine(to: CGPoint(x: size.width, y: y + 50 * scale))
                    y += 110 * scale
                }
                context.stroke(joints, with: .color(Self.mortar), lineWidth: max(0.5, 1.2 * scale))
                var innerEdge = Path()
                innerEdge.addRoundedRect(
                    in: CGRect(origin: .zero, size: size).insetBy(dx: frameWidth, dy: frameWidth),
                    cornerSize: CGSize(width: 30 * scale, height: 30 * scale)
                )
                context.stroke(innerEdge, with: .color(lead), lineWidth: leadWidth * 0.84)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static func wedge(center: CGPoint, inner: CGFloat, outer: CGFloat, index: Int, count: Int) -> Path {
        let step = 2 * Double.pi / Double(count)
        let start = -Double.pi / 2 + Double(index) * step
        let end = start + step
        var path = Path()
        path.addArc(center: center, radius: outer, startAngle: .radians(start), endAngle: .radians(end), clockwise: false)
        path.addArc(center: center, radius: inner, startAngle: .radians(end), endAngle: .radians(start), clockwise: true)
        path.closeSubpath()
        return path
    }
}

/// The light falling through the window: a warm glow around the rose and a
/// diagonal fall-off from the upper left. Atmosphere, so it follows the
/// Reduce Transparency policy.
struct RoseWindowLightView: View {
    let visualTheme: ChooserVisualTheme

    var body: some View {
        Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: true) { context, size in
            let glow = visualTheme.surfaceRecipe.atmosphere(at: 0)
            let light = visualTheme.surfaceRecipe.atmosphere(at: 1)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let rect = Path(CGRect(origin: .zero, size: size))
            context.fill(rect, with: .radialGradient(
                Gradient(colors: [glow.color.opacity(glow.opacity), glow.color.opacity(0)]),
                center: center,
                startRadius: 0,
                endRadius: min(size.width, size.height) * 0.59
            ))
            context.fill(rect, with: .linearGradient(
                Gradient(stops: [
                    .init(color: light.color.opacity(light.opacity), location: 0),
                    .init(color: light.color.opacity(light.opacity * 0.18), location: 0.55),
                    .init(color: Color.black.opacity(0.18), location: 1)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: size.height)
            ))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Tessellation is the only costly part of these recipes, and its inputs only
/// change with board size, so it is computed once per size and seed.
@MainActor
enum RoseWindowTessellationCache {
    private static var entries: [String: LeadedGlassTessellation] = [:]

    static func tessellation(
        size: CGSize,
        seed: UInt64,
        center: CGPoint,
        clearRadius: CGFloat
    ) -> LeadedGlassTessellation {
        let key = "\(Int(size.width.rounded()))x\(Int(size.height.rounded()))-\(seed)"
        if let cached = entries[key] { return cached }
        let built = LeadedGlassTessellation(
            size: size,
            seed: seed,
            clearCenter: center,
            clearRadius: clearRadius,
            paletteCount: RoseWindowStructureView.panePalette.count
        )
        if entries.count > 24 { entries.removeAll() }
        entries[key] = built
        return built
    }
}

// MARK: - Shared

extension BoardSurfaceRecipe {
    /// An atmosphere color and its authored opacity; absent entries are clear.
    func atmosphere(at index: Int) -> (color: Color, opacity: Double) {
        guard atmosphereHexValues.indices.contains(index),
              atmosphereOpacities.indices.contains(index) else {
            return (.clear, 0)
        }
        return (ChooserColorTheme.color(hex: atmosphereHexValues[index]), atmosphereOpacities[index])
    }
}
