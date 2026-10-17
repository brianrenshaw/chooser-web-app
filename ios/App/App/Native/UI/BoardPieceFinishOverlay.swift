import SwiftUI

/// Extra material detail drawn over a ring or chit for finishes whose
/// character is more than a texture: a wax seal's poured rim and stamped ring,
/// stained glass's lead came, a coin's milled edge, an egg's speckle, resin's
/// inner glow, iridescence, enamel rings and a standee's split rim.
///
/// Purely decorative: it never changes a piece's frame, hit area or the hue
/// family keyline that the contrast tests measure.
struct BoardPieceFinishOverlay: View {
    let style: BoardPieceStyle
    let diameter: CGFloat
    /// The band width for a hollow ring, or nil for a filled chit.
    let bandWidth: CGFloat?
    let policy: BoardAccessibilityAppearancePolicy

    /// Stained-glass lead is a material, not a participant color.
    private static let lead = ChooserColorTheme.color(hex: "#0D080A")

    var body: some View {
        switch style.finish {
        case .waxSeal:
            waxSeal
        case .leadedGlass:
            leadedGlass
        case .paintedWood:
            satinSheen(opacity: 0.20)
        case .watercolorEggshell:
            // A wooden egg: a few soft specks and a gentle sheen.
            ZStack {
                SpeckleShape(seed: style.textureSeed, count: bandWidth == nil ? 9 : 14)
                    .fill(style.keyline.opacity(clamped(0.42 * Double(policy.materialReliefOpacityMultiplier))))
                    .mask(pieceMask)
                satinSheen(opacity: 0.24)
            }
        case .peacockJewelEnamel:
            // A lighter inner enamel ring, as on cloisonné.
            ZStack {
                innerRing(color: style.bevel, opacity: 0.55, chitInset: 0.12, width: 0.022)
                satinSheen(opacity: 0.30)
            }
        case .featherJewelEnamel:
            // Iridescence that shifts from mint to violet, like a
            // hummingbird's throat.
            ZStack {
                AngularGradient(
                    colors: [
                        Color(red: 0.50, green: 1.0, blue: 0.83).opacity(0.42),
                        .clear,
                        Color(red: 0.78, green: 0.49, blue: 1.0).opacity(0.32),
                        .clear,
                        Color(red: 0.50, green: 1.0, blue: 0.83).opacity(0.42)
                    ],
                    center: .center,
                    angle: .degrees(-30)
                )
                .opacity(Double(policy.materialReliefOpacityMultiplier))
                .mask(pieceMask)
                satinSheen(opacity: 0.30)
            }
        case .hammeredMetal:
            // A struck coin: a milled edge and an inner ring.
            ZStack {
                Circle()
                    .inset(by: max(1, diameter * 0.018))
                    .stroke(
                        style.shade.opacity(clamped(0.70 * Double(policy.edgeOpacityMultiplier))),
                        style: StrokeStyle(
                            lineWidth: max(1.4, diameter * 0.04),
                            dash: [max(1, diameter * 0.014), max(1, diameter * 0.018)]
                        )
                    )
                innerRing(color: style.bevel, opacity: 0.55, chitInset: 0.13, width: 0.02)
                satinSheen(opacity: 0.26)
            }
        case .frescoEnamel:
            satinSheen(opacity: 0.18)
        case .pressedWoodPaper:
            // Translucent amber resin: light gathers inside the piece.
            ZStack {
                RadialGradient(
                    colors: [Color.white.opacity(0.36), Color.white.opacity(0)],
                    center: UnitPoint(x: 0.40, y: 0.36),
                    startRadius: 0,
                    endRadius: diameter * 0.46
                )
                .opacity(Double(policy.materialReliefOpacityMultiplier))
                .mask(pieceMask)
                satinSheen(opacity: 0.34)
            }
        case .midnightEnamel:
            // A struck mana coin.
            ZStack {
                innerRing(color: style.bevel, opacity: 0.55, chitInset: 0.10, width: 0.02)
                satinSheen(opacity: 0.24)
            }
        case .flatScreenprint:
            // A black-and-white split rim, like a two-sided standee, and a
            // spot-gloss highlight.
            ZStack {
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(Color(white: 0.04).opacity(0.85), lineWidth: max(1.2, diameter * 0.022))
                    .padding(max(0.6, diameter * 0.011))
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(Color.white.opacity(0.9), lineWidth: max(1.2, diameter * 0.022))
                    .padding(max(0.6, diameter * 0.011))
                Ellipse()
                    .fill(Color.white.opacity(clamped(0.34 * Double(policy.materialReliefOpacityMultiplier))))
                    .frame(width: diameter * 0.30, height: diameter * 0.12)
                    .rotationEffect(.degrees(-30))
                    .offset(x: -diameter * 0.16, y: -diameter * (bandWidth == nil ? 0.22 : 0.37))
            }
        case .speckledEgg:
            // A dragon egg: dense dark specks and a soft sheen.
            ZStack {
                SpeckleShape(seed: style.textureSeed, count: bandWidth == nil ? 14 : 22)
                    .fill(style.keyline.opacity(clamped(0.55 * Double(policy.materialReliefOpacityMultiplier))))
                    .mask(pieceMask)
                satinSheen(opacity: 0.26)
            }
        case .lacqueredToken:
            // A lacquered wooden token: a sheen on top and the darker side
            // showing along the lower edge, a cylinder seen from slightly above.
            ZStack {
                Circle()
                    .trim(from: 0.06, to: 0.44)
                    .stroke(
                        style.shade.opacity(clamped(0.55 * Double(policy.materialReliefOpacityMultiplier))),
                        lineWidth: max(1.2, diameter * 0.03)
                    )
                    .padding(max(0.6, diameter * 0.012))
                satinSheen(opacity: 0.28)
            }
        case .bubbleBead:
            // A glass bubble: light gathers inside, a foam rim, a bright specular.
            ZStack {
                RadialGradient(
                    colors: [Color.white.opacity(0.40), Color.white.opacity(0)],
                    center: UnitPoint(x: 0.38, y: 0.32),
                    startRadius: 0,
                    endRadius: diameter * 0.48
                )
                .opacity(Double(policy.materialReliefOpacityMultiplier))
                .mask(pieceMask)
                Circle()
                    .strokeBorder(Color.white.opacity(0.75), lineWidth: max(0.8, diameter * 0.012))
                satinSheen(opacity: 0.42)
            }
        }
    }

    /// The area a piece actually occupies: the band of a ring, or the face of
    /// a chit.
    @ViewBuilder
    private var pieceMask: some View {
        if let bandWidth {
            Circle().strokeBorder(lineWidth: bandWidth)
        } else {
            Circle()
        }
    }

    /// A struck or enamelled ring: along the middle of a ring's band, or
    /// inset inside a chit's face.
    @ViewBuilder
    private func innerRing(color: Color, opacity: Double, chitInset: CGFloat, width: CGFloat) -> some View {
        let resolved = color.opacity(clamped(opacity * Double(policy.materialReliefOpacityMultiplier)))
        if let bandWidth {
            Circle()
                .inset(by: bandWidth / 2)
                .stroke(resolved, lineWidth: max(0.8, bandWidth * 0.10))
        } else {
            Circle()
                .inset(by: diameter * chitInset)
                .stroke(resolved, lineWidth: max(0.8, diameter * width))
        }
    }

    // MARK: Wax seal

    private var waxSeal: some View {
        let edgeScale = BoardPieceVisualMetrics.edgeWidthScale(for: diameter)
        return ZStack {
            // The poured rim: a slightly uneven outer edge in the wax's own color.
            PouredRimShape(seed: style.textureSeed, amplitude: max(0.6, diameter * 0.012))
                .stroke(style.face, lineWidth: max(1.4, diameter * 0.018))
            PouredRimShape(seed: style.textureSeed, amplitude: max(0.6, diameter * 0.012))
                .stroke(
                    style.keyline.opacity(clamped(0.55 * Double(policy.edgeOpacityMultiplier))),
                    lineWidth: max(0.7, 0.9 * edgeScale)
                )

            // The stamped impression: a pressed channel in the middle of a ring,
            // or a ring stamped inside a chit's face.
            if let bandWidth {
                Circle()
                    .inset(by: bandWidth / 2)
                    .stroke(
                        style.shade.opacity(clamped(0.55 * Double(policy.materialReliefOpacityMultiplier))),
                        lineWidth: max(0.8, bandWidth * 0.08)
                    )
            } else {
                Circle()
                    .inset(by: diameter * 0.17)
                    .stroke(
                        style.shade.opacity(clamped(0.62 * Double(policy.materialReliefOpacityMultiplier))),
                        lineWidth: max(0.8, diameter * 0.022)
                    )
            }

            satinSheen(opacity: 0.34)
        }
    }

    // MARK: Leaded glass

    private var leadedGlass: some View {
        let came = max(1.4, diameter * 0.03) * policy.edgeWidthMultiplier
        return ZStack {
            if let bandWidth {
                // Lead on both edges of the ring, with four short bars across it.
                Circle().strokeBorder(Self.lead.opacity(0.92), lineWidth: came)
                Circle()
                    .inset(by: max(0, bandWidth - came))
                    .strokeBorder(Self.lead.opacity(0.86), lineWidth: came)
                LeadBarsShape(bandWidth: bandWidth)
                    .stroke(Self.lead.opacity(0.9), style: StrokeStyle(lineWidth: came * 0.9, lineCap: .round))
                // Light passing through the middle of the glass.
                Circle()
                    .inset(by: bandWidth / 2)
                    .stroke(Color.white.opacity(0.30), lineWidth: max(1, bandWidth * 0.22))
                    .blur(radius: max(0.5, bandWidth * 0.12))
            } else {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.34), Color.white.opacity(0)],
                            center: UnitPoint(x: 0.40, y: 0.36),
                            startRadius: 0,
                            endRadius: diameter * 0.5
                        )
                    )
                Circle().strokeBorder(Self.lead.opacity(0.92), lineWidth: came * 1.2)
            }
            satinSheen(opacity: 0.40)
        }
    }

    // MARK: Shared

    /// A soft highlight arc up and to the left, where the light sits.
    private func satinSheen(opacity: Double) -> some View {
        Circle()
            .inset(by: diameter * 0.13)
            .trim(from: 0.58, to: 0.74)
            .stroke(
                Color.white.opacity(clamped(opacity * Double(policy.materialReliefOpacityMultiplier))),
                style: StrokeStyle(lineWidth: max(1, diameter * 0.03), lineCap: .round)
            )
            .blur(radius: max(0.3, diameter * 0.006))
    }

    private func clamped(_ value: Double) -> Double { min(1, max(0, value)) }
}

/// A circle whose radius wanders a little, like wax poured past the stamp.
/// Seeded, so each participant keeps the same rim.
private struct PouredRimShape: Shape {
    let seed: UInt64
    let amplitude: CGFloat

    func path(in rect: CGRect) -> Path {
        var generator = BoardTextureGenerator(seed: seed ^ 0x5741_5853)
        let count = 36
        let offsets = (0..<count).map { _ in generator.range(-1...1) }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - amplitude
        var points: [CGPoint] = []
        for index in 0..<count {
            // Average neighbours so the rim swells rather than jitters.
            let smoothed = (offsets[(index + count - 1) % count] + offsets[index] * 2 + offsets[(index + 1) % count]) / 4
            let angle = Double(index) / Double(count) * 2 * .pi
            let r = radius + smoothed * amplitude
            points.append(CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle)))
        }
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: CGPoint(x: (first.x + points[count - 1].x) / 2, y: (first.y + points[count - 1].y) / 2))
        for index in 0..<count {
            let current = points[index]
            let next = points[(index + 1) % count]
            path.addQuadCurve(
                to: CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2),
                control: current
            )
        }
        path.closeSubpath()
        return path
    }
}

/// Four short lead bars across a ring band, at the diagonals.
private struct LeadBarsShape: Shape {
    let bandWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = max(0, outer - bandWidth)
        var path = Path()
        for degrees in [45.0, 135.0, 225.0, 315.0] {
            let angle = degrees * .pi / 180
            path.move(to: CGPoint(x: center.x + inner * cos(angle), y: center.y + inner * sin(angle)))
            path.addLine(to: CGPoint(x: center.x + outer * cos(angle), y: center.y + outer * sin(angle)))
        }
        return path
    }
}

/// A seeded scatter of small specks, like the paint on a wooden egg.
private struct SpeckleShape: Shape {
    let seed: UInt64
    let count: Int

    func path(in rect: CGRect) -> Path {
        var generator = BoardTextureGenerator(seed: seed ^ 0x4547_4753)
        var path = Path()
        let size = min(rect.width, rect.height)
        for _ in 0..<count {
            let diameter = size * generator.range(0.018...0.04)
            path.addEllipse(in: CGRect(
                x: rect.minX + generator.range(0.12...0.88) * rect.width - diameter / 2,
                y: rect.minY + generator.range(0.12...0.88) * rect.height - diameter / 2,
                width: diameter,
                height: diameter * generator.range(0.7...1.0)
            ))
        }
        return path
    }
}
