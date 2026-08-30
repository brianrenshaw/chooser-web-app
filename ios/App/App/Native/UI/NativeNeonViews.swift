import SwiftUI

@MainActor
public struct NativeNeonPalette {
    public let core: Color
    public let glow: Color
    public let foreground: Color

    public init(core: Color, glow: Color? = nil, foreground: Color = .white) {
        self.core = core
        self.glow = glow ?? core
        self.foreground = foreground
    }

    public static let cyan = NativeNeonPalette(core: .cyan)
    public static let pink = NativeNeonPalette(core: .pink)
    public static let mint = NativeNeonPalette(core: .mint)

    public static func hue(_ degrees: Double) -> NativeNeonPalette {
        let normalized = ((degrees.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
        let color = Color(hue: normalized / 360, saturation: 0.86, brightness: 1)
        return NativeNeonPalette(core: color)
    }
}

public enum NativeNeonEmphasis: Sendable {
    case resting
    case pulsing(period: TimeInterval = 1.2)
    case winner
    case dimmed
}

/// A reusable neon ring whose animation is a pure function of timeline time.
public struct NativeNeonRingView<Center: View>: View {
    private let diameter: CGFloat
    private let lineWidth: CGFloat
    private let palette: NativeNeonPalette
    private let emphasis: NativeNeonEmphasis
    private let accessibilityLabel: String
    private let center: Center

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        diameter: CGFloat = 120,
        lineWidth: CGFloat = 4,
        palette: NativeNeonPalette = .cyan,
        emphasis: NativeNeonEmphasis = .resting,
        accessibilityLabel: String = "Choice ring",
        @ViewBuilder center: () -> Center
    ) {
        self.diameter = diameter
        self.lineWidth = lineWidth
        self.palette = palette
        self.emphasis = emphasis
        self.accessibilityLabel = accessibilityLabel
        self.center = center()
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || !isPulsing)) { timeline in
            let presentation = presentation(at: timeline.date)

            ZStack {
                Circle()
                    .stroke(palette.glow.opacity(presentation.outerOpacity), lineWidth: lineWidth * 2.6)
                    .blur(radius: presentation.blurRadius)

                Circle()
                    .stroke(palette.core.opacity(presentation.opacity), lineWidth: lineWidth)
                    .shadow(color: palette.glow.opacity(presentation.shadowOpacity), radius: presentation.shadowRadius)

                center
                    .foregroundStyle(palette.foreground.opacity(presentation.opacity))
            }
            .frame(width: diameter, height: diameter)
            .scaleEffect(presentation.scale)
            .opacity(presentation.opacity)
            .drawingGroup()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var isPulsing: Bool {
        if case .pulsing = emphasis { return true }
        return false
    }

    private func presentation(at date: Date) -> Presentation {
        switch emphasis {
        case .resting:
            return Presentation(scale: 1, opacity: 1, outerOpacity: 0.30, shadowOpacity: 0.72, blurRadius: 8, shadowRadius: 16)
        case .pulsing(let period):
            guard !reduceMotion else {
                return Presentation(scale: 1, opacity: 1, outerOpacity: 0.34, shadowOpacity: 0.76, blurRadius: 9, shadowRadius: 18)
            }
            let safePeriod = max(0.15, period)
            let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: safePeriod) / safePeriod
            let wave = (sin(phase * .pi * 2 - .pi / 2) + 1) / 2
            return Presentation(
                scale: 1 + 0.07 * wave,
                opacity: 0.88 + 0.12 * wave,
                outerOpacity: 0.25 + 0.18 * wave,
                shadowOpacity: 0.58 + 0.32 * wave,
                blurRadius: 8 + 4 * wave,
                shadowRadius: 14 + 10 * wave
            )
        case .winner:
            return Presentation(scale: 1.16, opacity: 1, outerOpacity: 0.58, shadowOpacity: 1, blurRadius: 14, shadowRadius: 30)
        case .dimmed:
            return Presentation(scale: 0.96, opacity: 0.22, outerOpacity: 0.08, shadowOpacity: 0.12, blurRadius: 5, shadowRadius: 8)
        }
    }

    private struct Presentation {
        let scale: CGFloat
        let opacity: Double
        let outerOpacity: Double
        let shadowOpacity: Double
        let blurRadius: CGFloat
        let shadowRadius: CGFloat
    }
}

public extension NativeNeonRingView where Center == EmptyView {
    init(
        diameter: CGFloat = 120,
        lineWidth: CGFloat = 4,
        palette: NativeNeonPalette = .cyan,
        emphasis: NativeNeonEmphasis = .resting,
        accessibilityLabel: String = "Choice ring"
    ) {
        self.init(
            diameter: diameter,
            lineWidth: lineWidth,
            palette: palette,
            emphasis: emphasis,
            accessibilityLabel: accessibilityLabel,
            center: { EmptyView() }
        )
    }
}

/// A numbered token for sequential-entry modes.
public struct NativeNeonTokenView: View {
    public let number: Int
    public let diameter: CGFloat
    public let palette: NativeNeonPalette
    public let emphasis: NativeNeonEmphasis

    public init(
        number: Int,
        diameter: CGFloat = 76,
        palette: NativeNeonPalette = .cyan,
        emphasis: NativeNeonEmphasis = .resting
    ) {
        self.number = number
        self.diameter = diameter
        self.palette = palette
        self.emphasis = emphasis
    }

    public var body: some View {
        NativeNeonRingView(
            diameter: diameter,
            lineWidth: max(2.5, diameter * 0.045),
            palette: palette,
            emphasis: emphasis,
            accessibilityLabel: emphasis.isWinner ? "Winning number \(number)" : "Number \(number)"
        ) {
            Text(number, format: .number)
                .font(.system(size: diameter * 0.36, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(diameter * 0.12)
        }
    }
}

private extension NativeNeonEmphasis {
    var isWinner: Bool {
        if case .winner = self { return true }
        return false
    }
}
