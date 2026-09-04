import SwiftUI

/// A deterministic, non-illustrative texture shared by the live board,
/// miniature previews, rings, and chits. Its opacity is supplied by the theme.
public struct BoardFinishTextureView: View {
    public let finish: BoardPieceFinish
    public let seed: UInt64
    public let ink: Color
    public let opacity: Double

    public init(
        finish: BoardPieceFinish,
        seed: UInt64,
        ink: Color,
        opacity: Double
    ) {
        self.finish = finish
        self.seed = seed
        self.ink = ink
        self.opacity = opacity
    }

    public var body: some View {
        Canvas(opaque: false, colorMode: .linear, rendersAsynchronously: true) { context, size in
            var generator = BoardTextureGenerator(seed: seed)
            switch finish {
            case .watercolorEggshell:
                drawSoftFlecks(context: &context, size: size, generator: &generator, count: 54)
            case .peacockJewelEnamel:
                drawPeacockContours(context: &context, size: size, generator: &generator)
            case .featherJewelEnamel:
                drawCurvedFibers(context: &context, size: size, generator: &generator, count: 24)
            case .hammeredMetal:
                drawDimples(context: &context, size: size, generator: &generator, count: 78)
            case .frescoEnamel:
                drawFrescoFlecks(context: &context, size: size, generator: &generator, count: 68)
            case .pressedWoodPaper:
                drawPaperFibers(context: &context, size: size, generator: &generator)
            case .midnightEnamel:
                drawSparseSpeckle(context: &context, size: size, generator: &generator, count: 46)
            case .flatScreenprint:
                drawScreenprintDots(context: &context, size: size, generator: &generator)
            }
        }
        .foregroundStyle(ink)
        .opacity(min(0.12, max(0, opacity)))
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func drawSoftFlecks(
        context: inout GraphicsContext,
        size: CGSize,
        generator: inout BoardTextureGenerator,
        count: Int
    ) {
        for _ in 0..<count {
            let width = generator.range(5...19)
            let height = generator.range(2...8)
            let rect = CGRect(
                x: generator.range(-4...max(-3, size.width - width + 4)),
                y: generator.range(-4...max(-3, size.height - height + 4)),
                width: width,
                height: height
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(ink.opacity(Double(generator.range(0.28...0.72))))
            )
        }
    }

    private func drawPeacockContours(
        context: inout GraphicsContext,
        size: CGSize,
        generator: inout BoardTextureGenerator
    ) {
        let minimumDimension = max(1, min(size.width, size.height))
        let spacing = max(10, minimumDimension / 7)
        var y = -spacing * 0.35
        var row = 0
        while y < size.height + spacing {
            var x = row.isMultiple(of: 2) ? -spacing * 0.25 : spacing * 0.35
            while x < size.width + spacing {
                let radius = spacing * generator.range(0.34...0.48)
                let rect = CGRect(
                    x: x - radius,
                    y: y - radius * 0.72,
                    width: radius * 2,
                    height: radius * 1.44
                )
                context.stroke(
                    Path(ellipseIn: rect),
                    with: .color(ink.opacity(Double(generator.range(0.46...0.78)))),
                    lineWidth: 0.75
                )
                x += spacing
            }
            row += 1
            y += spacing * 0.72
        }
    }

    private func drawCurvedFibers(
        context: inout GraphicsContext,
        size: CGSize,
        generator: inout BoardTextureGenerator,
        count: Int
    ) {
        for _ in 0..<count {
            let start = CGPoint(x: generator.range(0...size.width), y: generator.range(0...size.height))
            let length = generator.range(10...32)
            var path = Path()
            path.move(to: start)
            path.addQuadCurve(
                to: CGPoint(x: start.x + length, y: start.y + generator.range(-5...5)),
                control: CGPoint(x: start.x + length * 0.48, y: start.y + generator.range(-7...7))
            )
            context.stroke(
                path,
                with: .color(ink.opacity(Double(generator.range(0.44...0.82)))),
                lineWidth: 0.75
            )
        }
    }

    private func drawDimples(
        context: inout GraphicsContext,
        size: CGSize,
        generator: inout BoardTextureGenerator,
        count: Int
    ) {
        for _ in 0..<count {
            let diameter = generator.range(1.2...3.8)
            let rect = CGRect(
                x: generator.range(0...max(0, size.width - diameter)),
                y: generator.range(0...max(0, size.height - diameter)),
                width: diameter,
                height: diameter
            )
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(ink.opacity(Double(generator.range(0.42...0.88)))),
                lineWidth: 0.7
            )
        }
    }

    private func drawFrescoFlecks(
        context: inout GraphicsContext,
        size: CGSize,
        generator: inout BoardTextureGenerator,
        count: Int
    ) {
        for _ in 0..<count {
            let start = CGPoint(x: generator.range(0...size.width), y: generator.range(0...size.height))
            var path = Path()
            path.move(to: start)
            path.addLine(to: CGPoint(x: start.x + generator.range(-4...4), y: start.y + generator.range(1...6)))
            context.stroke(
                path,
                with: .color(ink.opacity(Double(generator.range(0.35...0.76)))),
                lineWidth: 0.9
            )
        }
    }

    private func drawPaperFibers(
        context: inout GraphicsContext,
        size: CGSize,
        generator: inout BoardTextureGenerator
    ) {
        let spacing = max(6, size.height / 24)
        var y: CGFloat = spacing / 2
        while y < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y + generator.range(-1.5...1.5)))
            for step in 1...8 {
                path.addLine(to: CGPoint(
                    x: size.width * CGFloat(step) / 8,
                    y: y + generator.range(-2.2...2.2)
                ))
            }
            context.stroke(path, with: .color(ink.opacity(0.62)), lineWidth: 0.65)
            y += spacing
        }
    }

    private func drawSparseSpeckle(
        context: inout GraphicsContext,
        size: CGSize,
        generator: inout BoardTextureGenerator,
        count: Int
    ) {
        for _ in 0..<count {
            let diameter = generator.range(0.7...2.0)
            context.fill(
                Path(ellipseIn: CGRect(
                    x: generator.range(0...max(0, size.width - diameter)),
                    y: generator.range(0...max(0, size.height - diameter)),
                    width: diameter,
                    height: diameter
                )),
                with: .color(ink.opacity(Double(generator.range(0.40...0.92))))
            )
        }
    }

    private func drawScreenprintDots(
        context: inout GraphicsContext,
        size: CGSize,
        generator: inout BoardTextureGenerator
    ) {
        let spacing: CGFloat = 9
        var row = 0
        var y: CGFloat = 2
        while y < size.height {
            var x: CGFloat = row.isMultiple(of: 2) ? 2 : 6.5
            while x < size.width {
                let diameter = generator.range(0.8...1.5)
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)),
                    with: .color(ink.opacity(0.76))
                )
                x += spacing
            }
            row += 1
            y += spacing
        }
    }
}

/// Centralizes the visual response of custom board materials to system
/// accessibility appearance settings. Default values are deliberately neutral
/// so the authored Build 14 theme recipes remain pixel-for-pixel unchanged
/// unless the user enables an accessibility preference.
struct BoardAccessibilityAppearancePolicy: Equatable, Sendable {
    let reduceTransparency: Bool
    let increasedContrast: Bool
    let differentiateWithoutColor: Bool

    init(
        reduceTransparency: Bool = false,
        increasedContrast: Bool = false,
        differentiateWithoutColor: Bool = false
    ) {
        self.reduceTransparency = reduceTransparency
        self.increasedContrast = increasedContrast
        self.differentiateWithoutColor = differentiateWithoutColor
    }

    /// Broad translucent atmosphere is decorative, so simplify it while the
    /// opaque theme gradient remains intact.
    var surfaceAtmosphereOpacityMultiplier: Double {
        reduceTransparency ? 0.38 : 1
    }

    /// Fine texture is an important material cue under increased contrast,
    /// but it is restrained when transparent layering is reduced.
    var surfaceTextureOpacityMultiplier: Double {
        (reduceTransparency ? 0.78 : 1) * (increasedContrast ? 1.22 : 1)
    }

    var materialTextureOpacityMultiplier: Double {
        (reduceTransparency ? 0.72 : 1) * (increasedContrast ? 1.28 : 1)
    }

    var materialReliefOpacityMultiplier: CGFloat {
        (reduceTransparency ? 0.68 : 1) * (increasedContrast ? 1.16 : 1)
    }

    /// Structural edges carry ownership and piece boundaries, so they become
    /// wider and more decisive rather than changing participant hues.
    var edgeWidthMultiplier: CGFloat {
        increasedContrast ? 1.32 : 1
    }

    var edgeOpacityMultiplier: CGFloat {
        increasedContrast ? 1.24 : 1
    }

    var shadowOpacityMultiplier: Double {
        increasedContrast ? 1.18 : 1
    }

    var dimmedPieceOpacity: Double {
        increasedContrast ? 0.32 : 0.22
    }

    /// A segmented contour is a pattern/shape cue, independent of hue.
    var showsWinnerContour: Bool {
        differentiateWithoutColor
    }
}

/// Root-level material that can also be embedded in Settings miniatures.
public struct BoardSurfaceView: View {
    public let visualTheme: ChooserVisualTheme

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    public init(theme: ChooserColorTheme) { self.visualTheme = theme.visualTheme }
    public init(visualTheme: ChooserVisualTheme) { self.visualTheme = visualTheme }

    public var body: some View {
        let policy = accessibilityAppearancePolicy

        GeometryReader { geometry in
            ZStack {
                baseSurface(in: geometry.size)
                BoardSurfaceAtmosphereView(visualTheme: visualTheme)
                    .opacity(policy.surfaceAtmosphereOpacityMultiplier)
                BoardFinishTextureView(
                    finish: visualTheme.surfaceRecipe.texture.rendererFinish,
                    seed: visualTheme.textureSeed,
                    ink: visualTheme.primaryInkColor,
                    opacity: visualTheme.textureOpacity
                        * policy.surfaceTextureOpacityMultiplier
                )
            }
        }
        .accessibilityHidden(true)
    }

    private var accessibilityAppearancePolicy: BoardAccessibilityAppearancePolicy {
        BoardAccessibilityAppearancePolicy(
            reduceTransparency: reduceTransparency,
            increasedContrast: colorSchemeContrast == .increased,
            differentiateWithoutColor: differentiateWithoutColor
        )
    }

    @ViewBuilder
    private func baseSurface(in size: CGSize) -> some View {
        let gradient = Gradient(stops: visualTheme.surfaceRecipe.stops.map {
            Gradient.Stop(
                color: ChooserColorTheme.color(hex: $0.hex),
                location: $0.location
            )
        })

        switch visualTheme.surfaceRecipe.composition {
        case .goldenForestClearing:
            RadialGradient(
                gradient: gradient,
                center: UnitPoint(x: 0.50, y: 0.46),
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.72
            )
        case .parchmentMedallion, .warmFrescoMedallion:
            LinearGradient(
                gradient: gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .verticalWatercolorWash, .coralFeatherField, .brightLeafField,
             .midnightRedEdge, .layeredScreenprint:
            LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
        }
    }
}

private struct BoardSurfaceAtmosphereView: View {
    let visualTheme: ChooserVisualTheme

    var body: some View {
        GeometryReader { geometry in
            compositionLayers(in: geometry.size)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func compositionLayers(in size: CGSize) -> some View {
        switch visualTheme.surfaceRecipe.composition {
        case .verticalWatercolorWash:
            ZStack {
                softBloom(index: 0, center: UnitPoint(x: 0.24, y: 0.18), radius: max(size.width, size.height) * 0.52)
                softBloom(index: 1, center: UnitPoint(x: 0.82, y: 0.22), radius: max(size.width, size.height) * 0.30)
            }
        case .coralFeatherField:
            ZStack {
                softBloom(index: 0, center: UnitPoint(x: 0.76, y: 0.25), radius: max(size.width, size.height) * 0.48)
                softBloom(index: 1, center: UnitPoint(x: 0.18, y: 0.78), radius: max(size.width, size.height) * 0.34)
            }
        case .brightLeafField:
            ZStack {
                edgeVignette(index: 0, size: size, innerLocation: 0.46)
                AbstractSurfaceMarks(
                    primary: atmosphereColor(at: 0),
                    secondary: atmosphereColor(at: 1),
                    primaryOpacity: atmosphereOpacity(at: 0),
                    secondaryOpacity: atmosphereOpacity(at: 1),
                    style: .leaf
                )
            }
        case .parchmentMedallion:
            ZStack {
                softBloom(index: 0, center: .center, radius: max(size.width, size.height) * 0.54)
                softBloom(index: 1, center: UnitPoint(x: 0.60, y: 0.58), radius: max(size.width, size.height) * 0.38)
            }
        case .warmFrescoMedallion:
            ZStack {
                edgeVignette(index: 0, size: size, innerLocation: 0.48)
                softBloom(index: 1, center: UnitPoint(x: 0.50, y: 0.46), radius: max(size.width, size.height) * 0.42)
                softBloom(index: 2, center: UnitPoint(x: 0.50, y: 0.46), radius: max(size.width, size.height) * 0.26)
            }
        case .goldenForestClearing:
            AbstractSurfaceMarks(
                primary: atmosphereColor(at: 0),
                secondary: atmosphereColor(at: 1),
                primaryOpacity: atmosphereOpacity(at: 0),
                secondaryOpacity: atmosphereOpacity(at: 1),
                style: .riverPath
            )
        case .midnightRedEdge:
            ZStack {
                edgeVignette(index: 0, size: size, innerLocation: 0.42)
                Rectangle()
                    .strokeBorder(
                        atmosphereColor(at: 0).opacity(atmosphereOpacity(at: 0) * 0.92),
                        lineWidth: max(9, min(size.width, size.height) * 0.035)
                    )
                    .blur(radius: 5)
                softBloom(index: 1, center: .center, radius: max(size.width, size.height) * 0.30)
            }
        case .layeredScreenprint:
            AbstractSurfaceMarks(
                primary: atmosphereColor(at: 0),
                secondary: atmosphereColor(at: 1),
                primaryOpacity: atmosphereOpacity(at: 0),
                secondaryOpacity: atmosphereOpacity(at: 1),
                style: .screenprint
            )
        }
    }

    private func softBloom(index: Int, center: UnitPoint, radius: CGFloat) -> some View {
        RadialGradient(
            gradient: Gradient(stops: [
                Gradient.Stop(
                    color: atmosphereColor(at: index).opacity(atmosphereOpacity(at: index)),
                    location: 0
                ),
                Gradient.Stop(color: .clear, location: 1)
            ]),
            center: center,
            startRadius: 0,
            endRadius: max(1, radius)
        )
    }

    private func edgeVignette(index: Int, size: CGSize, innerLocation: Double) -> some View {
        RadialGradient(
            gradient: Gradient(stops: [
                Gradient.Stop(color: .clear, location: innerLocation),
                Gradient.Stop(
                    color: atmosphereColor(at: index).opacity(atmosphereOpacity(at: index)),
                    location: 1
                )
            ]),
            center: .center,
            startRadius: 0,
            endRadius: max(size.width, size.height) * 0.72
        )
    }

    private func atmosphereColor(at index: Int) -> Color {
        guard visualTheme.surfaceRecipe.atmosphereHexValues.indices.contains(index) else {
            return .clear
        }
        return ChooserColorTheme.color(hex: visualTheme.surfaceRecipe.atmosphereHexValues[index])
    }

    private func atmosphereOpacity(at index: Int) -> Double {
        guard visualTheme.surfaceRecipe.atmosphereOpacities.indices.contains(index) else { return 0 }
        return visualTheme.surfaceRecipe.atmosphereOpacities[index]
    }
}

private struct AbstractSurfaceMarks: View {
    enum Style { case leaf, riverPath, screenprint }

    let primary: Color
    let secondary: Color
    let primaryOpacity: Double
    let secondaryOpacity: Double
    let style: Style

    var body: some View {
        Canvas(opaque: false, colorMode: .linear, rendersAsynchronously: true) { context, size in
            switch style {
            case .leaf:
                for index in 0..<7 {
                    let y = size.height * (0.10 + CGFloat(index) * 0.135)
                    var path = Path()
                    path.move(to: CGPoint(x: -size.width * 0.08, y: y))
                    path.addCurve(
                        to: CGPoint(x: size.width * 1.08, y: y - size.height * 0.045),
                        control1: CGPoint(x: size.width * 0.25, y: y - size.height * 0.08),
                        control2: CGPoint(x: size.width * 0.72, y: y + size.height * 0.07)
                    )
                    context.stroke(path, with: .color(primary.opacity(primaryOpacity * 0.34)), lineWidth: 1.2)
                }
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: size.width * 0.70, y: size.height * 0.14,
                        width: size.width * 0.18, height: size.width * 0.18
                    )),
                    with: .color(secondary.opacity(secondaryOpacity))
                )
            case .riverPath:
                var path = Path()
                path.move(to: CGPoint(x: -size.width * 0.06, y: size.height * 0.72))
                path.addCurve(
                    to: CGPoint(x: size.width * 1.06, y: size.height * 0.31),
                    control1: CGPoint(x: size.width * 0.30, y: size.height * 0.52),
                    control2: CGPoint(x: size.width * 0.64, y: size.height * 0.55)
                )
                context.stroke(path, with: .color(primary.opacity(primaryOpacity)), lineWidth: max(4, size.width * 0.018))

                var river = Path()
                river.move(to: CGPoint(x: size.width * 0.72, y: size.height * 1.05))
                river.addCurve(
                    to: CGPoint(x: size.width * 0.42, y: -size.height * 0.05),
                    control1: CGPoint(x: size.width * 0.52, y: size.height * 0.70),
                    control2: CGPoint(x: size.width * 0.70, y: size.height * 0.28)
                )
                context.stroke(river, with: .color(secondary.opacity(secondaryOpacity)), lineWidth: max(3, size.width * 0.012))
            case .screenprint:
                for index in 0..<4 {
                    let inset = CGFloat(index) * size.width * 0.055
                    let rect = CGRect(
                        x: -size.width * 0.16 + inset,
                        y: size.height * (0.12 + CGFloat(index) * 0.17),
                        width: size.width * 0.78,
                        height: size.height * 0.30
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(primary.opacity(primaryOpacity)))
                }
                for index in 0..<3 {
                    var slash = Path()
                    let x = size.width * (0.62 + CGFloat(index) * 0.12)
                    slash.move(to: CGPoint(x: x, y: size.height * 0.18))
                    slash.addLine(to: CGPoint(x: x + size.width * 0.08, y: size.height * 0.31))
                    context.stroke(
                        slash,
                        with: .color(secondary.opacity(secondaryOpacity)),
                        style: StrokeStyle(lineWidth: max(2, size.width * 0.012), lineCap: .round)
                    )
                }
            }
        }
    }
}

@MainActor
public struct BoardPieceStyle {
    public let face: Color
    public let bevel: Color
    public let foreground: Color
    public let keyline: Color
    public let shade: Color
    public let textureInk: Color
    public let finish: BoardPieceFinish
    public let textureSeed: UInt64
    public let textureOpacity: Double

    // Compatibility names retained until every caller lands with Build 11.
    public var core: Color { face }
    public var glow: Color { bevel }

    public init(
        face: Color,
        bevel: Color,
        foreground: Color,
        keyline: Color,
        shade: Color,
        textureInk: Color,
        finish: BoardPieceFinish,
        textureSeed: UInt64,
        textureOpacity: Double
    ) {
        self.face = face
        self.bevel = bevel
        self.foreground = foreground
        self.keyline = keyline
        self.shade = shade
        self.textureInk = textureInk
        self.finish = finish
        self.textureSeed = textureSeed
        self.textureOpacity = textureOpacity
    }

    /// Compatibility initializer for small utility pieces outside the theme
    /// system. It remains solid and matte rather than inventing a glow.
    public init(
        core: Color,
        glow: Color? = nil,
        foreground: Color = ChooserColorTheme.warmIvoryColor,
        keyline: Color? = nil,
        shade: Color? = nil
    ) {
        let resolvedShade = shade ?? core.opacity(0.78)
        let resolvedEdge = keyline ?? core.opacity(0.86)
        self.init(
            face: core,
            bevel: glow ?? core,
            foreground: foreground,
            keyline: resolvedEdge,
            shade: resolvedShade,
            textureInk: resolvedShade,
            finish: .flatScreenprint,
            textureSeed: 0x57484F5346495253,
            textureOpacity: 0.055
        )
    }

    public static let cyan = participant(theme: .wingspanOriginal, index: 0)
    public static let pink = participant(theme: .wingspanNectar, index: 1)
    public static let mint = participant(theme: .everdell, index: 4)

    public static func hue(_ degrees: Double) -> BoardPieceStyle {
        let normalized = ((degrees.truncatingRemainder(dividingBy: 360)) + 360)
            .truncatingRemainder(dividingBy: 360)
        let face = Color(hue: normalized / 360, saturation: 0.58, brightness: 0.70)
        return BoardPieceStyle(core: face, glow: face, shade: face.opacity(0.78))
    }

    public static func participant(theme: ChooserColorTheme, index: Int) -> BoardPieceStyle {
        let visualTheme = theme.visualTheme
        let material = visualTheme.pieceFinish.presentation
        return BoardPieceStyle(
            face: visualTheme.participantColor(at: index),
            bevel: visualTheme.participantBevelColor(at: index),
            foreground: visualTheme.participantNumeralColor(at: index),
            keyline: visualTheme.participantKeylineColor(at: index),
            shade: visualTheme.participantShadeColor(at: index),
            textureInk: visualTheme.participantShadeColor(at: index),
            finish: visualTheme.pieceFinish,
            textureSeed: visualTheme.textureSeed &+ UInt64(truncatingIfNeeded: index &* 0x9E37),
            textureOpacity: min(0.09, visualTheme.textureOpacity * material.textureMultiplier)
        )
    }
}

public enum BoardPieceEmphasis: Sendable {
    case resting
    case pulsing(period: TimeInterval = 1.2)
    case winner
    case receded
    case dimmed
}

public enum BoardPieceVisualMetrics {
    /// Playfield short edge at and below which a board renders exactly as it
    /// always has. Chosen to sit above the largest iPhone playfield short edge
    /// in either orientation, so every phone — and a narrow iPad Slide Over
    /// column, which is phone-sized — resolves to scale 1 by construction
    /// rather than by a device check.
    public static let referenceShortEdge: CGFloat = 440

    /// How much larger board pieces draw on a canvas bigger than a phone's.
    ///
    /// Deliberately sublinear. A linear law on a 13-inch iPad would give a
    /// ~410pt Chooser ring, which is absurd for five fingers on one screen;
    /// the exponent keeps pieces substantial without letting them swallow the
    /// board.
    ///
    /// This is NOT the law Pinball uses. Pinball scales its lengths linearly
    /// because a uniform scale is a similarity transform of its reachability
    /// problem, which is what makes its fairness guarantee survive a change of
    /// board size for free. Damping that would forfeit the proof. The two laws
    /// answer different questions and must not be unified — see
    /// `PinballBoardMetrics`.
    public static func boardScale(for playfieldSize: CGSize) -> CGFloat {
        let shortEdge = min(playfieldSize.width, playfieldSize.height)
        guard shortEdge.isFinite, shortEdge > referenceShortEdge else { return 1 }
        return min(1.9, pow(shortEdge / referenceShortEdge, 0.62))
    }

    public static func bandWidth(for diameter: CGFloat, scale: CGFloat = 1) -> CGFloat {
        // The clamp bounds scale, not the ratio. Saturating at a fixed 22 is
        // what makes a large ring read as a thin hoop instead of a game piece.
        let s = max(1, scale)
        return min(22 * s, max(18 * s, diameter * 0.125))
    }

    public static func chitRimWidth(for diameter: CGFloat, scale: CGFloat = 1) -> CGFloat {
        let s = max(1, scale)
        return min(9 * s, max(7 * s, diameter * 0.075))
    }

    /// Keyline weight for a piece of a given diameter.
    ///
    /// Keyed off diameter rather than board scale so it is correct for any
    /// large piece regardless of which sizing path produced it. Square-rooted
    /// so an edge thickens without becoming a second band, and exactly 1 at the
    /// authored 176pt reference so no current render changes.
    public static func edgeWidthScale(for diameter: CGFloat) -> CGFloat {
        guard diameter.isFinite, diameter > 176 else { return 1 }
        return min(1.6, sqrt(diameter / 176))
    }

    /// The authored contact shadow for an emphasis, scaled with the board.
    ///
    /// A flat shadow under a 296pt piece reads as a sticker, which breaks the
    /// physical-game-piece language the whole visual system exists to sell.
    public static func shadowMetrics(
        for emphasis: BoardPieceEmphasis,
        scale: CGFloat = 1
    ) -> (radius: CGFloat, y: CGFloat) {
        let s = max(1, scale)
        switch emphasis {
        case .resting: return (5.5 * s, 3.5 * s)
        case .pulsing: return (7.5 * s, 4.5 * s)
        case .winner: return (11 * s, 7 * s)
        case .receded, .dimmed: return (4 * s, 2 * s)
        }
    }

    public static func ringTextureOpacity(from baseOpacity: Double) -> Double {
        min(0.12, max(0, baseOpacity) * 1.35)
    }

    public static func chitTextureOpacity(from baseOpacity: Double) -> Double {
        min(0.12, max(0, baseOpacity) * 1.18)
    }

    public static func maximumScale(for emphasis: BoardPieceEmphasis) -> CGFloat {
        switch emphasis {
        case .winner: 1.06
        case .resting, .pulsing, .receded, .dimmed: 1
        }
    }

    public static func renderingOverflow(
        for diameter: CGFloat,
        emphasis: BoardPieceEmphasis,
        scale: CGFloat = 1
    ) -> CGFloat {
        // Match the complete authored contact shadow, not merely the circle's
        // geometric edge. This footprint is consumed by every clipped mode
        // stage, so undercounting it would trim resting pieces at an edge and
        // the lifted 11pt-radius/7pt-offset winner shadow after reveal.
        //
        // The authored 12/20 anchors are kept and multiplied rather than
        // derived from the shadow: the slack differs between them (9 -> 12 but
        // 18 -> 20), so any formula that reproduces one misses the other. The
        // invariant that actually matters — overflow covers radius + offset —
        // is asserted in tests instead.
        (emphasis.isWinner ? 20 : 12) * max(1, scale)
    }

    public static func footprintRadius(
        diameter: CGFloat,
        emphasis: BoardPieceEmphasis,
        externalScale: CGFloat = 1,
        scale: CGFloat = 1
    ) -> CGFloat {
        let paddedRadius = diameter / 2 + renderingOverflow(
            for: diameter,
            emphasis: emphasis,
            scale: scale
        )
        return paddedRadius * maximumScale(for: emphasis) * max(1, externalScale)
    }

    /// The largest diameter whose full footprint still fits the stage.
    ///
    /// `clampedCenter` degrades to "every piece at the exact centre" once a
    /// footprint cannot fit, which stacks pieces on top of each other. That
    /// guard is correct as a last resort, so rather than weaken it, this makes
    /// the unfittable case unreachable — and replaces three separately tuned
    /// fudge tails that each solved this by hand.
    public static func fittedDiameter(
        _ preferred: CGFloat,
        in size: CGSize,
        emphasis: BoardPieceEmphasis = .winner,
        externalScale: CGFloat = 1,
        margin: CGFloat = 4,
        scale: CGFloat = 1
    ) -> CGFloat {
        guard size.width > 0, size.height > 0, preferred > 0 else { return preferred }
        let halfShortEdge = min(size.width, size.height) / 2
        let budget = halfShortEdge - max(0, margin)
        guard budget > 0 else { return preferred }

        // footprintRadius = (d/2 + overflow) * maximumScale * externalScale
        let overflow = renderingOverflow(for: preferred, emphasis: emphasis, scale: scale)
        let multiplier = maximumScale(for: emphasis) * max(1, externalScale)
        guard multiplier > 0 else { return preferred }
        let fitted = (budget / multiplier - overflow) * 2
        guard fitted.isFinite, fitted > 0 else { return preferred }
        return min(preferred, fitted)
    }

    public static func clampedCenter(
        _ proposed: CGPoint,
        in size: CGSize,
        diameter: CGFloat,
        emphasis: BoardPieceEmphasis = .resting,
        externalScale: CGFloat = 1,
        margin: CGFloat = 4,
        scale: CGFloat = 1
    ) -> CGPoint {
        guard size.width > 0, size.height > 0 else { return .zero }
        let radius = footprintRadius(
            diameter: diameter,
            emphasis: emphasis,
            externalScale: externalScale,
            scale: scale
        ) + max(0, margin)
        let xInset = min(radius, size.width / 2)
        let yInset = min(radius, size.height / 2)
        let x = proposed.x.isFinite ? proposed.x : size.width / 2
        let y = proposed.y.isFinite ? proposed.y : size.height / 2
        return CGPoint(
            x: min(max(x, xInset), size.width - xInset),
            y: min(max(y, yInset), size.height - yInset)
        )
    }
}

public struct BoardRingView<Center: View>: View {
    private let diameter: CGFloat
    private let lineWidth: CGFloat
    private let style: BoardPieceStyle
    private let fillsCenter: Bool
    private let emphasis: BoardPieceEmphasis
    private let emphasisAnimationDuration: TimeInterval?
    private let accessibilityLabel: String
    /// How much larger than a phone this board is drawing. Defaults to 1, so a
    /// caller that never learned about scaling renders exactly as it always did.
    private let boardScale: CGFloat
    private let center: Center

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    public init(
        diameter: CGFloat = 120,
        lineWidth: CGFloat = 4,
        style: BoardPieceStyle = .cyan,
        fillsCenter: Bool = false,
        emphasis: BoardPieceEmphasis = .resting,
        emphasisAnimationDuration: TimeInterval? = nil,
        accessibilityLabel: String = "Choice ring",
        boardScale: CGFloat = 1,
        @ViewBuilder center: () -> Center
    ) {
        self.diameter = diameter
        self.lineWidth = lineWidth
        self.style = style
        self.fillsCenter = fillsCenter
        self.emphasis = emphasis
        self.emphasisAnimationDuration = emphasisAnimationDuration
        self.accessibilityLabel = accessibilityLabel
        self.boardScale = boardScale
        self.center = center()
    }

    public init(
        diameter: CGFloat = 120,
        lineWidth: CGFloat = 4,
        palette: BoardPieceStyle,
        fillsCenter: Bool = false,
        emphasis: BoardPieceEmphasis = .resting,
        emphasisAnimationDuration: TimeInterval? = nil,
        accessibilityLabel: String = "Choice ring",
        boardScale: CGFloat = 1,
        @ViewBuilder center: () -> Center
    ) {
        self.init(
            diameter: diameter,
            lineWidth: lineWidth,
            style: palette,
            fillsCenter: fillsCenter,
            emphasis: emphasis,
            emphasisAnimationDuration: emphasisAnimationDuration,
            accessibilityLabel: accessibilityLabel,
            boardScale: boardScale,
            center: center
        )
    }

    public var body: some View {
        let presentation = presentation
        let policy = accessibilityAppearancePolicy
        let overflow = BoardPieceVisualMetrics.renderingOverflow(
            for: diameter,
            emphasis: emphasis,
            scale: boardScale
        )

        ZStack {
            if fillsCenter {
                opaqueChit(presentation: presentation)
            } else {
                hollowBand(presentation: presentation)
            }
            center.foregroundStyle(style.foreground)

            if policy.showsWinnerContour, emphasis.isWinner {
                winnerContour(policy: policy)
            }
        }
        .frame(width: diameter, height: diameter)
        .padding(overflow)
        .scaleEffect(presentation.scale)
        .opacity(presentation.opacity)
        .saturation(presentation.saturation)
        .animation(
            reduceMotion ? nil : .smooth(duration: resolvedEmphasisAnimationDuration),
            value: emphasisKey
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private func hollowBand(presentation: Presentation) -> some View {
        let bandWidth = min(diameter * 0.46, max(1, lineWidth))
        let material = style.finish.presentation
        let policy = accessibilityAppearancePolicy
        // Keylines thicken with the piece so a large ring keeps a decisive
        // edge instead of a hairline. Derived from one multiplier rather than
        // by editing the eight authored per-finish tuples.
        let edgeScale = BoardPieceVisualMetrics.edgeWidthScale(for: diameter)
        let outerEdgeWidth = material.outerEdgeWidth * policy.edgeWidthMultiplier * edgeScale
        let innerEdgeWidth = material.innerEdgeWidth * policy.edgeWidthMultiplier * edgeScale
        let innerOcclusionWidth = max(1.2, innerEdgeWidth * 1.35)
        let innerOcclusionInset = max(0, bandWidth - innerOcclusionWidth)

        return ZStack {
            // A tinted contact layer anchors the marker before the softer
            // cast shadow is applied to the completed material below.
            Circle()
                .strokeBorder(
                    style.shade.opacity(colorOpacity(
                        material.innerOcclusionOpacity * policy.edgeOpacityMultiplier * 0.42
                    )),
                    lineWidth: bandWidth
                )
                .offset(y: 1.1)
                .blur(radius: 0.75)

            Circle()
                .strokeBorder(style.face, lineWidth: bandWidth)

            Circle()
                .strokeBorder(reliefGradient(material: material), lineWidth: bandWidth)
                .opacity(colorOpacity(
                    material.reliefOpacity * policy.materialReliefOpacityMultiplier
                ))

            BoardFinishTextureView(
                finish: style.finish,
                seed: style.textureSeed,
                ink: style.textureInk,
                opacity: BoardPieceVisualMetrics.ringTextureOpacity(
                    from: style.textureOpacity
                ) * policy.materialTextureOpacityMultiplier
            )
            .mask(Circle().strokeBorder(lineWidth: bandWidth))

            // Both authored edges remain in the participant hue family. The
            // wider inner edge is occlusion from the hollow piece, not a hard
            // black outline painted around it.
            Circle()
                .strokeBorder(
                    style.keyline.opacity(colorOpacity(
                        material.edgeTintOpacity * policy.edgeOpacityMultiplier
                    )),
                    lineWidth: outerEdgeWidth
                )

            Circle()
                .inset(by: outerEdgeWidth)
                .strokeBorder(
                    style.bevel.opacity(colorOpacity(
                        material.bevelOpacity * policy.materialReliefOpacityMultiplier
                    )),
                    lineWidth: max(1, innerEdgeWidth * 0.72)
                )

            Circle()
                .inset(by: max(0, innerOcclusionInset - innerEdgeWidth * 0.85))
                .strokeBorder(
                    style.bevel.opacity(colorOpacity(
                        material.bevelOpacity * policy.materialReliefOpacityMultiplier * 0.34
                    )),
                    lineWidth: max(0.8, innerEdgeWidth * 0.55)
                )

            Circle()
                .inset(by: innerOcclusionInset)
                .strokeBorder(
                    style.shade.opacity(colorOpacity(
                        material.innerOcclusionOpacity * policy.edgeOpacityMultiplier
                    )),
                    lineWidth: innerOcclusionWidth
                )
        }
            .compositingGroup()
            .shadow(
                color: style.shade.opacity(
                    clampedOpacity(
                        presentation.shadowOpacity * 0.24 * material.shadowMultiplier
                    )
                ),
                radius: 1.4,
                x: 0,
                y: 1.3
            )
            .shadow(
                color: .black.opacity(presentation.shadowOpacity * material.shadowMultiplier),
                radius: presentation.shadowRadius,
                x: 0,
                y: presentation.shadowY
            )
    }

    private func opaqueChit(presentation: Presentation) -> some View {
        let policy = accessibilityAppearancePolicy
        let rimWidth = BoardPieceVisualMetrics.chitRimWidth(for: diameter, scale: boardScale)
            * (policy.increasedContrast ? 1.12 : 1)
        let material = style.finish.presentation
        let edgeScale = BoardPieceVisualMetrics.edgeWidthScale(for: diameter)
        let outerEdgeWidth = material.outerEdgeWidth * policy.edgeWidthMultiplier * edgeScale
        let innerEdgeWidth = material.innerEdgeWidth * policy.edgeWidthMultiplier * edgeScale
        return ZStack {
            Circle().fill(style.face)

            Circle()
                .fill(reliefGradient(material: material))
                .opacity(colorOpacity(
                    material.reliefOpacity * policy.materialReliefOpacityMultiplier * 0.82
                ))

            BoardFinishTextureView(
                finish: style.finish,
                seed: style.textureSeed,
                ink: style.textureInk,
                opacity: BoardPieceVisualMetrics.chitTextureOpacity(
                    from: style.textureOpacity
                ) * policy.materialTextureOpacityMultiplier
            )
            .clipShape(Circle())

            Circle()
                .strokeBorder(
                    style.shade.opacity(colorOpacity(0.94 * policy.edgeOpacityMultiplier)),
                    lineWidth: rimWidth
                )

            Circle()
                .inset(by: rimWidth)
                .strokeBorder(
                    style.bevel.opacity(colorOpacity(
                        material.bevelOpacity * policy.materialReliefOpacityMultiplier
                    )),
                    lineWidth: innerEdgeWidth
                )

            Circle()
                .strokeBorder(
                    style.keyline.opacity(colorOpacity(
                        material.edgeTintOpacity * policy.edgeOpacityMultiplier
                    )),
                    lineWidth: outerEdgeWidth
                )
        }
            .compositingGroup()
            .shadow(
                color: style.shade.opacity(
                    clampedOpacity(
                        presentation.shadowOpacity * 0.18 * material.shadowMultiplier
                    )
                ),
                radius: 1.1,
                x: 0,
                y: 1
            )
            .shadow(
                color: .black.opacity(
                    clampedOpacity(
                        presentation.shadowOpacity * 0.72 * material.shadowMultiplier
                    )
                ),
                radius: presentation.shadowRadius * 0.78,
                x: 0,
                y: presentation.shadowY * 0.74
            )
    }

    private func reliefGradient(
        material: BoardPieceMaterialPresentation
    ) -> AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: [
                Gradient.Stop(color: style.shade, location: 0),
                Gradient.Stop(color: style.face, location: 0.22),
                Gradient.Stop(color: style.bevel, location: 0.42),
                Gradient.Stop(color: style.face, location: 0.67),
                Gradient.Stop(color: style.shade, location: 1)
            ]),
            center: .center,
            startAngle: .degrees(material.reliefRotationDegrees),
            endAngle: .degrees(material.reliefRotationDegrees + 360)
        )
    }

    private func winnerContour(
        policy: BoardAccessibilityAppearancePolicy
    ) -> some View {
        let contourWidth = max(2.4, min(4, diameter * 0.019))
            * policy.edgeWidthMultiplier
        let dashLength = max(4, diameter * 0.042)

        return Circle()
            .inset(by: contourWidth * 0.72)
            .stroke(
                style.foreground.opacity(0.96),
                style: StrokeStyle(
                    lineWidth: contourWidth,
                    lineCap: .round,
                    dash: [dashLength, dashLength * 0.68]
                )
            )
            .accessibilityHidden(true)
    }

    private var presentation: Presentation {
        let policy = accessibilityAppearancePolicy
        let shadow = BoardPieceVisualMetrics.shadowMetrics(
            for: emphasis,
            scale: boardScale
        )
        switch emphasis {
        case .resting:
            return Presentation(
                scale: 1,
                opacity: 1,
                shadowOpacity: 0.22 * policy.shadowOpacityMultiplier,
                shadowRadius: shadow.radius,
                shadowY: shadow.y,
                saturation: 1
            )
        case .pulsing:
            return Presentation(
                scale: reduceMotion ? 1 : 0.965,
                opacity: 1,
                shadowOpacity: 0.28 * policy.shadowOpacityMultiplier,
                shadowRadius: shadow.radius,
                shadowY: shadow.y,
                saturation: 1
            )
        case .winner:
            return Presentation(
                scale: 1.06,
                opacity: 1,
                shadowOpacity: 0.38 * policy.shadowOpacityMultiplier,
                shadowRadius: shadow.radius,
                shadowY: shadow.y,
                saturation: 1
            )
        case .receded, .dimmed:
            return Presentation(
                scale: 1,
                opacity: policy.dimmedPieceOpacity,
                shadowOpacity: 0.12 * policy.shadowOpacityMultiplier,
                shadowRadius: shadow.radius,
                shadowY: shadow.y,
                saturation: 0.68
            )
        }
    }

    private var accessibilityAppearancePolicy: BoardAccessibilityAppearancePolicy {
        BoardAccessibilityAppearancePolicy(
            reduceTransparency: reduceTransparency,
            increasedContrast: colorSchemeContrast == .increased,
            differentiateWithoutColor: differentiateWithoutColor
        )
    }

    private func colorOpacity(_ value: CGFloat) -> Double {
        Double(min(1, max(0, value)))
    }

    private func clampedOpacity(_ value: Double) -> Double {
        min(1, max(0, value))
    }

    private var emphasisKey: String {
        switch emphasis {
        case .resting: "resting"
        case .pulsing: "tension"
        case .winner: "winner"
        case .receded: "receded"
        case .dimmed: "dimmed"
        }
    }

    private var resolvedEmphasisAnimationDuration: TimeInterval {
        emphasisAnimationDuration ?? (emphasis.isPulsing ? 0.92 : 0.26)
    }

    private struct Presentation {
        let scale: CGFloat
        let opacity: Double
        let shadowOpacity: Double
        let shadowRadius: CGFloat
        let shadowY: CGFloat
        let saturation: Double
    }
}

public extension BoardRingView where Center == EmptyView {
    init(
        diameter: CGFloat = 120,
        lineWidth: CGFloat = 4,
        style: BoardPieceStyle = .cyan,
        fillsCenter: Bool = false,
        emphasis: BoardPieceEmphasis = .resting,
        emphasisAnimationDuration: TimeInterval? = nil,
        accessibilityLabel: String = "Choice ring",
        boardScale: CGFloat = 1
    ) {
        self.init(
            diameter: diameter,
            lineWidth: lineWidth,
            style: style,
            fillsCenter: fillsCenter,
            emphasis: emphasis,
            emphasisAnimationDuration: emphasisAnimationDuration,
            accessibilityLabel: accessibilityLabel,
            boardScale: boardScale,
            center: { EmptyView() }
        )
    }

    init(
        diameter: CGFloat = 120,
        lineWidth: CGFloat = 4,
        palette: BoardPieceStyle,
        fillsCenter: Bool = false,
        emphasis: BoardPieceEmphasis = .resting,
        emphasisAnimationDuration: TimeInterval? = nil,
        accessibilityLabel: String = "Choice ring",
        boardScale: CGFloat = 1
    ) {
        self.init(
            diameter: diameter,
            lineWidth: lineWidth,
            style: palette,
            fillsCenter: fillsCenter,
            emphasis: emphasis,
            emphasisAnimationDuration: emphasisAnimationDuration,
            accessibilityLabel: accessibilityLabel,
            boardScale: boardScale,
            center: { EmptyView() }
        )
    }
}

/// SwiftUI counterpart of the SpriteKit Pinball ball. Both renderers consume
/// the same material presentation values, keeping Settings miniatures honest.
public struct PhysicalPinballBallView: View {
    public let theme: ChooserColorTheme
    public let diameter: CGFloat

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    public init(theme: ChooserColorTheme, diameter: CGFloat = NativePinballReplayMetrics.ballDiameter) {
        self.theme = theme
        self.diameter = diameter
    }

    public var body: some View {
        let material = theme.pinballMaterial.presentation
        let policy = accessibilityAppearancePolicy
        // Divides by the FIXED reference, never the live scaled diameter. If it
        // divided by the scaled value, both sides would grow together, lineScale
        // would stay 1, and a large ball would render with hairline strokes.
        // Artwork ratios use the reference; physics uses the live value.
        let lineScale = max(0.45, diameter / PinballBoardMetrics.referenceBallDiameter)

        ZStack {
            Circle()
                .fill(theme.pinballColor)
                .shadow(
                    color: .black.opacity(
                        min(1, 0.30 * policy.shadowOpacityMultiplier)
                    ),
                    radius: max(1.5, diameter * 0.10),
                    y: max(1, diameter * 0.08)
                )

            Circle()
                .fill(theme.pinballEdgeColor.opacity(colorOpacity(
                    material.shadeAlpha * policy.materialReliefOpacityMultiplier
                )))
                .scaleEffect(material.shadeRadius)
                .offset(x: diameter * 0.10, y: -diameter * 0.11)

            Circle()
                .strokeBorder(
                    theme.pinballEdgeColor.opacity(colorOpacity(
                        material.rimAlpha * policy.edgeOpacityMultiplier
                    )),
                    lineWidth: material.rimWidth * lineScale * policy.edgeWidthMultiplier
                )

            Circle()
                .strokeBorder(
                    theme.pinballEdgeColor.opacity(colorOpacity(
                        0.88 * policy.edgeOpacityMultiplier
                    )),
                    lineWidth: material.edgeWidth * lineScale * policy.edgeWidthMultiplier
                )

            if material.markRadius > 0 {
                Circle()
                    .fill(theme.pinballEdgeColor.opacity(colorOpacity(
                        material.markAlpha * policy.materialReliefOpacityMultiplier
                    )))
                    .frame(
                        width: diameter * material.markRadius,
                        height: diameter * material.markRadius
                    )
                    .offset(x: -diameter * 0.14, y: diameter * 0.135)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }

    private var accessibilityAppearancePolicy: BoardAccessibilityAppearancePolicy {
        BoardAccessibilityAppearancePolicy(
            reduceTransparency: reduceTransparency,
            increasedContrast: colorSchemeContrast == .increased
        )
    }

    private func colorOpacity(_ value: CGFloat) -> Double {
        Double(min(1, max(0, value)))
    }
}

public struct NumberedChitView: View {
    public let number: Int
    public let diameter: CGFloat
    public let style: BoardPieceStyle
    public let emphasis: BoardPieceEmphasis
    public let boardScale: CGFloat

    public var palette: BoardPieceStyle { style }

    public init(
        number: Int,
        diameter: CGFloat = 76,
        style: BoardPieceStyle = .cyan,
        emphasis: BoardPieceEmphasis = .resting,
        boardScale: CGFloat = 1
    ) {
        self.number = number
        self.diameter = diameter
        self.style = style
        self.emphasis = emphasis
        self.boardScale = boardScale
    }

    public init(
        number: Int,
        diameter: CGFloat = 76,
        palette: BoardPieceStyle,
        emphasis: BoardPieceEmphasis = .resting,
        boardScale: CGFloat = 1
    ) {
        self.init(
            number: number,
            diameter: diameter,
            style: palette,
            emphasis: emphasis,
            boardScale: boardScale
        )
    }

    public var body: some View {
        BoardRingView(
            diameter: diameter,
            lineWidth: BoardPieceVisualMetrics.chitRimWidth(for: diameter, scale: boardScale),
            style: style,
            fillsCenter: true,
            emphasis: emphasis,
            accessibilityLabel: emphasis.isWinner ? "Winning number \(number)" : "Number \(number)",
            boardScale: boardScale
        ) {
            Text(number, format: .number)
                .font(.system(size: diameter * 0.31, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(diameter * 0.15)
        }
    }
}

public extension BoardPieceEmphasis {
    var isWinner: Bool {
        if case .winner = self { return true }
        return false
    }

    var isPulsing: Bool {
        if case .pulsing = self { return true }
        return false
    }
}

// Source-compatible bridges. Rendering semantics are fully board-native.
public typealias NativeNeonPalette = BoardPieceStyle
public typealias NativeNeonEmphasis = BoardPieceEmphasis
public typealias NativeNeonVisualMetrics = BoardPieceVisualMetrics
public typealias NativeNeonRingView = BoardRingView
public typealias NativeNeonTokenView = NumberedChitView

private struct BoardTextureGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }

    mutating func unit() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat(Double(state >> 11) / Double(1 << 53))
    }

    mutating func range(_ range: ClosedRange<CGFloat>) -> CGFloat {
        range.lowerBound + unit() * (range.upperBound - range.lowerBound)
    }

}
