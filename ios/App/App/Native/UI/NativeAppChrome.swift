import SwiftUI

/// The three visual languages supported by the compact mode control.
/// Product mode names remain configurable so the control can be reused by a host app.
public enum NativeModeIconArtwork: String, CaseIterable, Sendable {
    case orbit
    case numberedTokens
    case analyticTrail
}

public struct NativeModeOption: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let iconArtwork: NativeModeIconArtwork

    public init(id: String, name: String, iconArtwork: NativeModeIconArtwork) {
        self.id = id
        self.name = name
        self.iconArtwork = iconArtwork
    }
}

/// A fixed triplet makes the cycling behavior explicit without coupling the UI to an engine enum.
public struct NativeModeTriplet: Sendable {
    public let first: NativeModeOption
    public let second: NativeModeOption
    public let third: NativeModeOption

    public init(
        first: NativeModeOption,
        second: NativeModeOption,
        third: NativeModeOption
    ) {
        precondition(Set([first.id, second.id, third.id]).count == 3, "Mode IDs must be unique")
        self.first = first
        self.second = second
        self.third = third
    }

    public var all: [NativeModeOption] { [first, second, third] }

    public func option(id: NativeModeOption.ID) -> NativeModeOption {
        all.first(where: { $0.id == id }) ?? first
    }

    public func next(after id: NativeModeOption.ID) -> NativeModeOption {
        let options = all
        guard let index = options.firstIndex(where: { $0.id == id }) else { return first }
        return options[(index + 1) % options.count]
    }

    /// Useful defaults for prototypes. Production code can supply any names and IDs.
    public static let chooserDefaults = NativeModeTriplet(
        first: NativeModeOption(id: "together", name: "Together", iconArtwork: .orbit),
        second: NativeModeOption(id: "tap-in", name: "Tap In", iconArtwork: .numberedTokens),
        third: NativeModeOption(id: "pinball", name: "Pinball", iconArtwork: .analyticTrail)
    )
}

/// A lightweight top chrome that does not own navigation or application state.
public struct NativeAppChrome: View {
    @Binding private var selectedModeID: NativeModeOption.ID
    private let modes: NativeModeTriplet
    private let isModeChangeEnabled: Bool
    private let onModeChange: (NativeModeOption) -> Void
    private let onSetDefaultMode: (NativeModeOption) -> Void
    private let onOpenInformation: () -> Void

    public init(
        selectedModeID: Binding<NativeModeOption.ID>,
        modes: NativeModeTriplet = .chooserDefaults,
        isModeChangeEnabled: Bool = true,
        onModeChange: @escaping (NativeModeOption) -> Void = { _ in },
        onSetDefaultMode: @escaping (NativeModeOption) -> Void = { _ in },
        onOpenInformation: @escaping () -> Void
    ) {
        self._selectedModeID = selectedModeID
        self.modes = modes
        self.isModeChangeEnabled = isModeChangeEnabled
        self.onModeChange = onModeChange
        self.onSetDefaultMode = onSetDefaultMode
        self.onOpenInformation = onOpenInformation
    }

    public var body: some View {
        HStack(alignment: .top) {
            NativeModeCycleButton(
                selectedModeID: $selectedModeID,
                modes: modes,
                isEnabled: isModeChangeEnabled,
                onModeChange: onModeChange,
                onSetDefaultMode: onSetDefaultMode
            )

            Spacer(minLength: 16)

            Button(action: onOpenInformation) {
                Image(systemName: "questionmark")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(.white.opacity(0.82))
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Help and information")
            .accessibilityIdentifier("help-and-information")
        }
    }
}

/// A compact three-state control. Tap cycles; long press reports the current mode as a default.
public struct NativeModeCycleButton: View {
    @Binding private var selectedModeID: NativeModeOption.ID
    private let modes: NativeModeTriplet
    private let isEnabled: Bool
    private let onModeChange: (NativeModeOption) -> Void
    private let onSetDefaultMode: (NativeModeOption) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var isPressed = false

    public init(
        selectedModeID: Binding<NativeModeOption.ID>,
        modes: NativeModeTriplet = .chooserDefaults,
        isEnabled: Bool = true,
        onModeChange: @escaping (NativeModeOption) -> Void = { _ in },
        onSetDefaultMode: @escaping (NativeModeOption) -> Void = { _ in }
    ) {
        self._selectedModeID = selectedModeID
        self.modes = modes
        self.isEnabled = isEnabled
        self.onModeChange = onModeChange
        self.onSetDefaultMode = onSetDefaultMode
    }

    private var selectedMode: NativeModeOption { modes.option(id: selectedModeID) }
    private var nextMode: NativeModeOption { modes.next(after: selectedModeID) }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(selectedMode.iconArtwork == .numberedTokens ? Color.cyan.opacity(0.13) : Color.white.opacity(0.07))

            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(
                    selectedMode.iconArtwork == .numberedTokens ? Color.cyan.opacity(0.38) : Color.white.opacity(0.14),
                    lineWidth: 1
                )

            NativeModeIcon(artwork: selectedMode.iconArtwork)
                .id(selectedMode.id)
                .transition(
                    reduceMotion
                        ? .opacity
                        : .asymmetric(
                            insertion: .scale(scale: 0.68).combined(with: .opacity),
                            removal: .scale(scale: 0.68).combined(with: .opacity)
                        )
                )
        }
        .frame(width: 48, height: 44)
        .scaleEffect(isPressed && isEnabled ? 0.92 : 1)
        .rotationEffect(.degrees(isPressed && isEnabled && !reduceMotion ? -3 : 0))
        .opacity(isEnabled ? 1 : 0.48)
        .contentShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .animation(reduceMotion ? .linear(duration: 0.01) : .spring(duration: 0.28, bounce: 0.42), value: selectedModeID)
        .animation(.easeOut(duration: 0.12), value: isPressed)
        .gesture(modeGesture, including: isEnabled ? .all : .none)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(selectedMode.name) mode")
        .accessibilityValue("Active")
        .accessibilityHint("Activate to switch to \(nextMode.name). Long press to make \(selectedMode.name) the default.")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("mode-cycle")
        .accessibilityAction(.default, cycleMode)
        .accessibilityAction(named: Text("Make \(selectedMode.name) Default")) {
            guard isEnabled else { return }
            onSetDefaultMode(selectedMode)
        }
    }

    private var modeGesture: some Gesture {
        let tap = TapGesture()
        let longPress = LongPressGesture(minimumDuration: 0.55, maximumDistance: 24)

        return longPress
            .exclusively(before: tap)
            .updating($isPressed) { _, state, _ in state = true }
            .onEnded { result in
                guard isEnabled else { return }
                switch result {
                case .first:
                    onSetDefaultMode(selectedMode)
                case .second:
                    cycleMode()
                }
            }
    }

    private func cycleMode() {
        guard isEnabled else { return }
        let next = nextMode
        if reduceMotion {
            selectedModeID = next.id
        } else {
            withAnimation(.spring(duration: 0.28, bounce: 0.42)) {
                selectedModeID = next.id
            }
        }
        onModeChange(next)
    }
}

private struct NativeModeIcon: View {
    let artwork: NativeModeIconArtwork

    var body: some View {
        Canvas { context, size in
            switch artwork {
            case .orbit:
                drawOrbit(in: &context, size: size)
            case .numberedTokens:
                drawNumberedTokens(in: &context, size: size)
            case .analyticTrail:
                drawPinball(in: &context, size: size)
            }
        }
        .frame(width: 32, height: 32)
    }

    private func drawOrbit(in context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let orbitRect = CGRect(x: center.x - 10.6, y: center.y - 10.6, width: 21.2, height: 21.2)
        context.stroke(Path(ellipseIn: orbitRect), with: .color(.white.opacity(0.30)), lineWidth: 1.6)

        let dots = [
            CGPoint(x: center.x, y: center.y - 9.2),
            CGPoint(x: center.x - 8.1, y: center.y + 5.1),
            CGPoint(x: center.x + 8.1, y: center.y + 5.1)
        ]
        for (index, point) in dots.enumerated() {
            let color: Color = index == 0 ? .cyan : (index == 1 ? .pink : .mint)
            context.fill(Path(ellipseIn: CGRect(x: point.x - 3.4, y: point.y - 3.4, width: 6.8, height: 6.8)), with: .color(color))
        }

        var spark = Path()
        spark.move(to: CGPoint(x: center.x, y: center.y - 3.8))
        spark.addLine(to: CGPoint(x: center.x, y: center.y + 3.8))
        spark.move(to: CGPoint(x: center.x - 3.8, y: center.y))
        spark.addLine(to: CGPoint(x: center.x + 3.8, y: center.y))
        context.stroke(spark, with: .color(.white.opacity(0.86)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
    }

    private func drawNumberedTokens(in context: inout GraphicsContext, size: CGSize) {
        var trail = Path()
        trail.move(to: CGPoint(x: 5, y: size.height - 5))
        trail.addCurve(
            to: CGPoint(x: size.width - 4.5, y: 4.5),
            control1: CGPoint(x: 12, y: size.height - 11),
            control2: CGPoint(x: size.width - 12, y: 14)
        )
        context.stroke(trail, with: .color(.white.opacity(0.28)), style: StrokeStyle(lineWidth: 1.3, dash: [2.4, 2.8]))

        let tokens: [(CGPoint, String, Color)] = [
            (CGPoint(x: 7, y: 25), "1", .pink),
            (CGPoint(x: 16, y: 16), "2", .cyan),
            (CGPoint(x: 25, y: 7), "3", .mint)
        ]
        for (point, number, color) in tokens {
            context.fill(Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)), with: .color(color.opacity(0.9)))
            context.draw(
                Text(number).font(.system(size: 6.5, weight: .heavy, design: .rounded)).foregroundStyle(.black.opacity(0.78)),
                at: point
            )
        }
    }

    private func drawPinball(in context: inout GraphicsContext, size: CGSize) {
        var trail = Path()
        trail.move(to: CGPoint(x: 3.5, y: size.height * 0.72))
        trail.addCurve(
            to: CGPoint(x: size.width * 0.53, y: size.height * 0.34),
            control1: CGPoint(x: size.width * 0.22, y: size.height * 0.94),
            control2: CGPoint(x: size.width * 0.31, y: size.height * 0.23)
        )
        trail.addCurve(
            to: CGPoint(x: size.width - 4, y: size.height * 0.57),
            control1: CGPoint(x: size.width * 0.74, y: size.height * 0.12),
            control2: CGPoint(x: size.width * 0.79, y: size.height * 0.79)
        )
        context.stroke(trail, with: .color(.cyan.opacity(0.82)), style: StrokeStyle(lineWidth: 2.3, lineCap: .round))

        let finish = CGPoint(x: size.width - 4, y: size.height * 0.57)
        context.fill(Path(ellipseIn: CGRect(x: finish.x - 4, y: finish.y - 4, width: 8, height: 8)), with: .color(.pink))

        var spark = Path()
        spark.move(to: CGPoint(x: finish.x, y: finish.y - 7))
        spark.addLine(to: CGPoint(x: finish.x, y: finish.y + 7))
        spark.move(to: CGPoint(x: finish.x - 7, y: finish.y))
        spark.addLine(to: CGPoint(x: finish.x + 7, y: finish.y))
        context.stroke(spark, with: .color(.white.opacity(0.82)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
    }
}
