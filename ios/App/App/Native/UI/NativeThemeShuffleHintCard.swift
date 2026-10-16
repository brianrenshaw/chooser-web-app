import SwiftUI

/// The one-time tip that a three-finger tap shuffles the visual world.
///
/// It follows the `NativeModeIntroCard` contract: an opaque panel rather than
/// board paint, an icon-only dismiss, and it never blocks play. It appears only
/// over a settled result, after a handful of finished choices, so the person
/// can try the gesture straight away. Trying it, touching the board, or the
/// close button retires it for good.
///
/// The sighted copy reuses the How It Works line. VoiceOver reserves
/// three-finger gestures, so that variant points at the existing "Shuffle
/// colors" action instead.
struct NativeThemeShuffleHintCard: View {
    let colorTheme: ChooserColorTheme
    let onDismiss: () -> Void

    static let title = "Colors"
    static let gestureLine = "Three-finger tap anywhere to shuffle the colors."
    static let voiceOverLine = "Use the Shuffle colors action to change the colors."

    @Environment(\.chooserVisualTheme) private var visualTheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.boardChromeMetrics) private var chrome
    @AccessibilityFocusState private var isFocused: Bool

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    badge
                    text
                    HStack {
                        Spacer(minLength: 0)
                        dismissButton
                    }
                }
            } else {
                HStack(spacing: 14) {
                    badge
                    text
                    Spacer(minLength: 8)
                    dismissButton
                }
            }
        }
        .padding(14)
        .frame(maxWidth: chrome.introCardMaxWidth)
        .nativeBoardPanel(cornerRadius: 22)
        .shadow(
            color: .black.opacity(0.18 * (colorSchemeContrast == .increased ? 1.18 : 1)),
            radius: 8,
            y: 4
        )
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityFocused($isFocused)
        .accessibilityIdentifier("theme-shuffle-hint-card")
        .onAppear { isFocused = true }
    }

    /// Three fingertips in the current world's first three player colors, each
    /// with a faint touch ring, so the gesture reads before the words do.
    private var badge: some View {
        ZStack {
            fingertip(index: 0, offset: CGSize(width: 0, height: -11))
            fingertip(index: 1, offset: CGSize(width: -12, height: 8))
            fingertip(index: 2, offset: CGSize(width: 12, height: 8))
        }
        .frame(width: 52, height: 52)
        .accessibilityHidden(true)
    }

    private func fingertip(index: Int, offset: CGSize) -> some View {
        let color = colorTheme.participantColor(at: index)
        return ZStack {
            Circle()
                .strokeBorder(color.opacity(0.42), lineWidth: 1.5)
                .frame(width: 22, height: 22)
            Circle()
                .fill(color)
                .overlay {
                    Circle().strokeBorder(colorTheme.participantKeylineColor(at: index), lineWidth: 1)
                }
                .frame(width: 13, height: 13)
        }
        .offset(offset)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(Self.title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text(voiceOverEnabled ? Self.voiceOverLine : Self.gestureLine)
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(visualTheme.informationPanelInkColor.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dismissButton: some View {
        ChooserIconActionButton("Dismiss", systemImage: "xmark", action: onDismiss)
            .accessibilityIdentifier("theme-shuffle-hint-dismiss")
    }
}

#Preview("Theme shuffle hint") {
    let theme = ChooserColorTheme.everdell
    return ZStack {
        BoardSurfaceView(theme: theme).ignoresSafeArea()
        NativeThemeShuffleHintCard(colorTheme: theme, onDismiss: {})
            .padding()
    }
    .environment(\.chooserVisualTheme, theme.visualTheme)
    .boardChromeMetrics()
}
