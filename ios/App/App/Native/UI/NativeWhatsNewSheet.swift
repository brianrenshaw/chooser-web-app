import SwiftUI

/// One release's note, shown once, to people who already know the app.
///
/// It is deliberately **not** a second welcome carousel. Someone opening 1.1
/// has used the app before; they need to know what moved, not what the app is.
/// So: one page, no paging, no artwork, and it never appears for a fresh
/// install — `presentOnboardingIfNeeded` gates it behind having seen the
/// welcome, and finishing the welcome retires this release's note in the same
/// write.
struct NativeWhatsNewCopy: Sendable {
    let release: String
    let title: String
    let lead: String
    let items: [(symbol: String, title: String, detail: String)]

    static let current = NativeWhatsNewCopy(
        release: OnboardingMoment.currentWhatsNewRelease,
        title: "What's new",
        lead: "Who's First? now plays on iPad, and Pinball got fairer.",
        items: [
            (
                "ipad.and.iphone",
                "Made for iPad",
                "Rings, chits, seats and the ball all scale with the screen, so the board fills the table instead of floating in the middle of it."
            ),
            (
                "circle.hexagongrid.fill",
                "Seat rings light up",
                "In Pinball, a seat ring now lights the moment the ball strikes it, so you can follow the path by feel and eye together."
            ),
            (
                "equal.circle.fill",
                "Every seat reachable",
                "A gentle flick used to leave some seats out of reach, which quietly cost them turns. Now the ball can kick off a seat ring as well as a wall, so every seat keeps exactly the same chance."
            )
        ]
    )
}

struct NativeWhatsNewSheet: View {
    let copy: NativeWhatsNewCopy
    let colorTheme: ChooserColorTheme
    let onDismiss: () -> Void

    @Environment(\.boardChromeMetrics) private var chrome
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var isTitleFocused: Bool

    var body: some View {
        ZStack {
            BoardSurfaceView(theme: colorTheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        ForEach(Array(copy.items.enumerated()), id: \.offset) { _, item in
                            row(symbol: item.symbol, title: item.title, detail: item.detail)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.top, 28)
                    .padding(.bottom, 16)
                }
                .scrollBounceBehavior(.basedOnSize)

                ChooserActionButton(
                    "Continue",
                    systemImage: "arrow.right",
                    accessibilityLabel: "Continue to the board",
                    isPrimary: true,
                    action: onDismiss
                )
                .frame(maxWidth: 420)
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
                .accessibilityIdentifier("whats-new-continue")
            }
            .frame(maxWidth: chrome.readableWidth)
            .frame(maxWidth: .infinity)
            .safeAreaPadding(.horizontal)
        }
        .accessibilityIdentifier("whats-new")
        .onAppear { isTitleFocused = true }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Version \(copy.release)")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(colorTheme.informationPanelInkColor.opacity(0.72))

            Text(copy.title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($isTitleFocused)

            Text(copy.lead)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(colorTheme.informationPanelInkColor.opacity(0.86))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func row(symbol: String, title: String, detail: String) -> some View {
        let content = VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .bold))
            Text(detail)
                .font(.system(.body, design: .rounded, weight: .regular))
                .foregroundStyle(colorTheme.informationPanelInkColor.opacity(0.86))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)

        Group {
            // At accessibility text sizes a fixed-width icon column steals room
            // the words need, so the badge moves above the text instead.
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    badge(symbol)
                    content
                }
            } else {
                HStack(alignment: .top, spacing: 14) {
                    badge(symbol)
                    content
                }
            }
        }
        .padding(16)
        .nativeBoardPanel(cornerRadius: 22)
        .accessibilityElement(children: .combine)
    }

    private func badge(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(colorTheme.accentColor)
            .frame(width: 44, height: 44)
            .background(colorTheme.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
            .accessibilityHidden(true)
    }
}
