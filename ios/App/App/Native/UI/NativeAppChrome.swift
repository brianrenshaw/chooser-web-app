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

/// A fixed triplet keeps the menu independent from the chooser engine enum.
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

    /// Useful defaults for prototypes. Production code can supply any names and IDs.
    public static let chooserDefaults = NativeModeTriplet(
        first: NativeModeOption(id: "together", name: "Chooser", iconArtwork: .orbit),
        second: NativeModeOption(id: "tap-in", name: "Tap In", iconArtwork: .numberedTokens),
        third: NativeModeOption(id: "pinball", name: "Pinball", iconArtwork: .analyticTrail)
    )
}

/// A lightweight top chrome that does not own navigation or application state.
public struct NativeAppChrome: View {
    private let selectedModeID: NativeModeOption.ID
    private let modes: NativeModeTriplet
    private let isModeChangeEnabled: Bool
    private let isSettingsEnabled: Bool
    private let onModeChange: (NativeModeOption) -> Void
    private let onSetDefaultMode: (NativeModeOption) -> Void
    private let onOpenSettings: () -> Void
    @Environment(\.chooserVisualTheme) private var visualTheme

    public init(
        selectedModeID: NativeModeOption.ID,
        modes: NativeModeTriplet = .chooserDefaults,
        isModeChangeEnabled: Bool = true,
        isSettingsEnabled: Bool = true,
        onModeChange: @escaping (NativeModeOption) -> Void = { _ in },
        onSetDefaultMode: @escaping (NativeModeOption) -> Void = { _ in },
        onOpenSettings: @escaping () -> Void
    ) {
        self.selectedModeID = selectedModeID
        self.modes = modes
        self.isModeChangeEnabled = isModeChangeEnabled
        self.isSettingsEnabled = isSettingsEnabled
        self.onModeChange = onModeChange
        self.onSetDefaultMode = onSetDefaultMode
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        HStack(alignment: .top) {
            NativeModeMenu(
                selectedModeID: selectedModeID,
                modes: modes,
                isEnabled: isModeChangeEnabled,
                onModeChange: onModeChange,
                onSetDefaultMode: onSetDefaultMode
            )

            Spacer(minLength: 16)

            NativeSettingsButton(
                isEnabled: isSettingsEnabled,
                action: onOpenSettings
            )
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .tint(
            visualTheme.chromeTintColor.opacity(
                visualTheme.chromeControlBackingOpacity
            )
        )
    }
}

/// The semantic Settings action. A navigation toolbar supplies its Liquid
/// Glass treatment automatically; standalone hosts can apply `.buttonStyle(.glass)`.
public struct NativeSettingsButton: View {
    private let isEnabled: Bool
    private let action: () -> Void
    @Environment(\.chooserVisualTheme) private var visualTheme

    public init(isEnabled: Bool = true, action: @escaping () -> Void) {
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape")
                .font(.system(size: 16, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .frame(width: 44, height: 44)
                .foregroundStyle(visualTheme.primaryInkColor)
        }
        .accessibilityLabel("Settings")
        .accessibilityHint(
            isEnabled
                ? "Opens appearance and app information"
                : "Unavailable while a choice is in progress"
        )
        .accessibilityIdentifier("settings-button")
        .controlSize(.large)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.38)
        .animation(.easeInOut(duration: 0.15), value: isEnabled)
    }
}

/// A fixed-size mode marble that keeps the main screen quiet while making all
/// three modes directly available in a native menu.
public struct NativeModeMenu: View {
    private let selectedModeID: NativeModeOption.ID
    private let modes: NativeModeTriplet
    private let isEnabled: Bool
    private let onModeChange: (NativeModeOption) -> Void
    private let onSetDefaultMode: (NativeModeOption) -> Void
    @Environment(\.chooserColorTheme) private var colorTheme

    public init(
        selectedModeID: NativeModeOption.ID,
        modes: NativeModeTriplet = .chooserDefaults,
        isEnabled: Bool = true,
        onModeChange: @escaping (NativeModeOption) -> Void = { _ in },
        onSetDefaultMode: @escaping (NativeModeOption) -> Void = { _ in }
    ) {
        self.selectedModeID = selectedModeID
        self.modes = modes
        self.isEnabled = isEnabled
        self.onModeChange = onModeChange
        self.onSetDefaultMode = onSetDefaultMode
    }

    private var selectedMode: NativeModeOption { modes.option(id: selectedModeID) }
    public var body: some View {
        Menu {
            Section("Choose a mode") {
                ForEach(modes.all) { option in
                    Button {
                        guard option.id != selectedModeID else { return }
                        onModeChange(option)
                    } label: {
                        Label {
                            Text(option.name)
                        } icon: {
                            Image(
                                systemName: option.id == selectedModeID
                                    ? "checkmark"
                                    : option.iconArtwork.menuSystemImage
                            )
                        }
                    }
                    .disabled(option.id == selectedModeID)
                    .accessibilityIdentifier("mode-option-\(option.id)")
                }
            }

            Divider()

            Button {
                onSetDefaultMode(selectedMode)
            } label: {
                Label("Make \(selectedMode.name) Default", systemImage: "star")
            }
            .accessibilityIdentifier("make-current-mode-default")
        } label: {
            NativeModeMarble(artwork: selectedMode.iconArtwork, theme: colorTheme)
        }
        .menuOrder(.fixed)
        .buttonStyle(.plain)
        .controlSize(.large)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .disabled(!isEnabled)
        .accessibilityLabel("\(selectedMode.name) mode")
        .accessibilityValue("Current")
        .accessibilityHint("Opens the mode menu")
        .accessibilityIdentifier("mode-menu")
    }

}

private struct NativeModeMarble: View {
    let artwork: NativeModeIconArtwork
    let theme: ChooserColorTheme

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        ZStack {
            NativeModeIcon(artwork: artwork, theme: theme)
                .frame(width: 25, height: 25)
                .id(artwork)
                .transition(.blurReplace)
        }
        .frame(width: 44, height: 44)
        .contentShape(Circle())
        .opacity(isEnabled ? 1 : 0.38)
        .animation(.smooth(duration: 0.22), value: artwork)
    }
}

private extension NativeModeIconArtwork {
    var menuSystemImage: String {
        switch self {
        case .orbit: "hand.raised.fill"
        case .numberedTokens: "number.circle.fill"
        case .analyticTrail: "sparkles"
        }
    }
}

private struct NativeModeIcon: View {
    let artwork: NativeModeIconArtwork
    let theme: ChooserColorTheme

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
        let dots = [
            CGPoint(x: center.x, y: center.y - 7.2),
            CGPoint(x: center.x - 6.5, y: center.y + 4.7),
            CGPoint(x: center.x + 6.5, y: center.y + 4.7)
        ]
        for (index, point) in dots.enumerated() {
            let color = theme.participantColor(at: index)
            let circle = Path(
                ellipseIn: CGRect(x: point.x - 3.75, y: point.y - 3.75, width: 7.5, height: 7.5)
            )
            context.fill(
                circle,
                with: .color(color)
            )
            context.stroke(
                circle,
                with: .color(theme.onChromeInkColor.opacity(0.72)),
                lineWidth: 1.15
            )
        }
    }

    private func drawNumberedTokens(in context: inout GraphicsContext, size: CGSize) {
        var trail = Path()
        trail.move(to: CGPoint(x: 5, y: size.height - 5))
        trail.addCurve(
            to: CGPoint(x: size.width - 4.5, y: 4.5),
            control1: CGPoint(x: 12, y: size.height - 11),
            control2: CGPoint(x: size.width - 12, y: 14)
        )
        context.stroke(
            trail,
            with: .color(theme.secondaryInkColor.opacity(0.55)),
            style: StrokeStyle(lineWidth: 1.3, dash: [2.4, 2.8])
        )

        let tokens: [(CGPoint, String, Int)] = [
            (CGPoint(x: 7, y: 25), "1", 0),
            (CGPoint(x: 16, y: 16), "2", 1),
            (CGPoint(x: 25, y: 7), "3", 2)
        ]
        for (point, number, index) in tokens {
            let color = theme.participantColor(at: index)
            let circle = Path(
                ellipseIn: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)
            )
            context.fill(circle, with: .color(color.opacity(0.94)))
            context.stroke(
                circle,
                with: .color(theme.onChromeInkColor.opacity(0.66)),
                lineWidth: 1
            )
            context.draw(
                Text(number)
                    .font(.system(size: 6.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.participantNumeralColor(at: index)),
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
        context.stroke(
            trail,
            with: .color(theme.onChromeInkColor.opacity(0.58)),
            style: StrokeStyle(lineWidth: 4.1, lineCap: .round)
        )
        context.stroke(
            trail,
            with: .color(theme.pinballTailColor.opacity(0.88)),
            style: StrokeStyle(lineWidth: 2.3, lineCap: .round)
        )

        let finish = CGPoint(x: size.width - 4, y: size.height * 0.57)
        let ball = Path(
            ellipseIn: CGRect(x: finish.x - 4, y: finish.y - 4, width: 8, height: 8)
        )
        context.fill(
            ball,
            with: .color(theme.pinballColor)
        )
        context.stroke(
            ball,
            with: .color(theme.onChromeInkColor.opacity(0.68)),
            lineWidth: 1.1
        )
    }
}
