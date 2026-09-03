import SwiftUI

/// The one-time introduction shown the first time a mode is opened.
///
/// This does not weaken the product's text-free board, and it is worth saying
/// why, because the release checklist verifies that property:
///
/// 1. It adds **zero new prose** to the app. Both strings already ship in
///    `NativeOfflineInformationCopy` and already appear on How It Works. The
///    dismiss control is an icon, so no "Got it" verbiage is introduced.
/// 2. It is a panel, not board paint — opaque `informationPanelColor`, a 1pt
///    separator stroke, a drop shadow. It cannot be mistaken for a game piece.
/// 3. It is one-time and self-removing, so the board's steady state is
///    unchanged from the shipped release.
/// 4. It never blocks play. The stage stays fully live underneath, and the
///    first touch anywhere on the board dismisses it.
struct NativeModeIntroCard: View {
    let page: NativeWelcomePage
    let instructions: NativeModeInstructions
    let colorTheme: ChooserColorTheme
    let onDismiss: () -> Void

    @Environment(\.chooserVisualTheme) private var visualTheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
        .frame(maxWidth: 520)
        .nativeBoardPanel(cornerRadius: 22)
        .shadow(
            color: .black.opacity(0.18 * (colorSchemeContrast == .increased ? 1.18 : 1)),
            radius: 8,
            y: 4
        )
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityFocused($isFocused)
        .accessibilityIdentifier("mode-intro-card-\(page.rawValue)")
        .onAppear { isFocused = true }
    }

    /// 52pt, not 44: `BoardRingView` reserves `renderingOverflow` around the
    /// circle for its authored contact shadow, so a 28pt piece needs 52pt of
    /// frame. Clipping it back to 44 would remove the shadow that makes the
    /// piece read as physical.
    private var badge: some View {
        NativeWelcomeArtwork(page: page, theme: colorTheme, density: .compact)
            .frame(width: 52, height: 52)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(instructions.title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text(instructions.summary)
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(visualTheme.informationPanelInkColor.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dismissButton: some View {
        ChooserIconActionButton("Dismiss", systemImage: "xmark", action: onDismiss)
            .accessibilityIdentifier("mode-intro-dismiss")
    }
}

#Preview("Mode intro card") {
    let theme = ChooserColorTheme.everdell
    let copy = NativeOfflineInformationCopy.chooser(version: "1.1")
    return ZStack {
        BoardSurfaceView(theme: theme).ignoresSafeArea()
        VStack(spacing: 10) {
            ForEach(NativeWelcomePage.allCases) { page in
                if let instructions = copy.modes.first(where: { $0.id == page.rawValue }) {
                    NativeModeIntroCard(
                        page: page,
                        instructions: instructions,
                        colorTheme: theme,
                        onDismiss: {}
                    )
                }
            }
        }
        .padding()
    }
    .environment(\.chooserVisualTheme, theme.visualTheme)
    .environment(\.chooserColorTheme, theme)
}
