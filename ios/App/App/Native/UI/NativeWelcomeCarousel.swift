import SwiftUI

/// One page of the first-run welcome.
///
/// `rawValue` deliberately equals the copy-deck's mode id, so a page can find
/// its `NativeModeInstructions` with no lookup table. Three id spaces already
/// exist in this app — `AppMode.tapIn.rawValue` is `"tapIn"` while its deep
/// link path is `"tap-in"` — and this enum pins the welcome to the copy-deck
/// one.
public enum NativeWelcomePage: String, CaseIterable, Identifiable, Sendable {
    case chooser = "together"
    case tapIn = "tap-in"
    case pinball = "pinball"

    public var id: String { rawValue }

    public init(mode: AppMode) {
        switch mode {
        case .together: self = .chooser
        case .tapIn: self = .tapIn
        case .pinball: self = .pinball
        }
    }

    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

/// The first-run introduction: one page per mode, presented as a full screen
/// cover over `ChooserRootView`.
///
/// Presentation notes for anyone editing this:
/// - A cover is a **separate environment tree**. The four `chooser*` values are
///   re-injected here, exactly as `NativeOfflineInformationFlow` does for the
///   settings sheet. Removing them silently falls back to default theming.
/// - The three-finger shuffle gesture lives on the root's `.background` and
///   cannot reach a separate presentation, so the VoiceOver "Shuffle colors"
///   action on the header is the only shuffle affordance here.
public struct NativeWelcomeCarousel: View {
    private let copy: NativeOfflineInformationCopy
    private let colorTheme: ChooserColorTheme
    private let onFinish: () -> Void
    private let onSkip: () -> Void
    private let onShuffleColorTheme: () -> Bool

    @State private var scrolledPage: NativeWelcomePage? = .chooser
    @State private var currentPage: NativeWelcomePage = .chooser
    @AccessibilityFocusState private var focusedPage: NativeWelcomePage?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    public init(
        copy: NativeOfflineInformationCopy,
        colorTheme: ChooserColorTheme,
        onFinish: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onShuffleColorTheme: @escaping () -> Bool = { false }
    ) {
        self.copy = copy
        self.colorTheme = colorTheme
        self.onFinish = onFinish
        self.onSkip = onSkip
        self.onShuffleColorTheme = onShuffleColorTheme
    }

    public var body: some View {
        ZStack {
            BoardSurfaceView(theme: colorTheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                pages
                footer
            }
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .safeAreaPadding(.horizontal)
        }
        // No identifier on this ZStack. SwiftUI propagates a container's
        // accessibility identifier down onto every descendant element that is
        // not behind an accessibility container boundary, so one here would
        // silently overwrite `welcome-skip`, `welcome-continue`, and the rest.
        // `welcome-pages` is the carousel's presence marker instead.
        .statusBarHidden(true)
        .tint(colorTheme.interactiveTextColor)
        .environment(\.chooserAccentColor, colorTheme.accentColor)
        .environment(\.chooserColorTheme, colorTheme)
        .environment(\.chooserVisualTheme, colorTheme.visualTheme)
        .environment(\.colorScheme, colorTheme.preferredColorScheme)
        .onChange(of: scrolledPage) { _, page in
            // `.scrollPosition(id:)` transiently writes nil during layout, so
            // downstream UI reads the non-optional mirror instead.
            guard let page, page != currentPage else { return }
            currentPage = page
        }
        .onChange(of: currentPage) { _, page in
            announcePageChange(to: page)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(copy.appName)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text(copy.tagline)
                    .font(.system(.footnote, design: .rounded, weight: .regular))
                    .foregroundStyle(colorTheme.informationPanelInkColor.opacity(0.86))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityAction(named: Text("Shuffle colors")) {
                _ = onShuffleColorTheme()
            }
            // On the combined text element only. Putting this on the enclosing
            // HStack would overwrite the Skip button's own identifier.
            .accessibilityIdentifier("welcome-title")

            skipButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .nativeBoardPanel(cornerRadius: 16)
        .padding(.top, 10)
    }

    private var skipButton: some View {
        Button("Skip", action: onSkip)
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(colorTheme.interactiveTextColor)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityHint("Closes the introduction")
            .accessibilityIdentifier("welcome-skip")
            // Kept in the layout on the last page so the header never changes
            // height mid-carousel.
            .opacity(isLastPage ? 0 : 1)
            .allowsHitTesting(!isLastPage)
            .accessibilityHidden(isLastPage)
    }

    // MARK: - Pages

    private var pages: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(NativeWelcomePage.allCases) { page in
                    NativeWelcomePageView(
                        page: page,
                        instructions: instructions(for: page),
                        colorTheme: colorTheme,
                        usesWideLayout: usesWideLayout,
                        isCurrent: page == currentPage,
                        focusedPage: $focusedPage
                    )
                    .containerRelativeFrame(.horizontal)
                    .id(page)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $scrolledPage)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Welcome")
        .accessibilityValue("Page \(currentPage.index + 1) of \(NativeWelcomePage.allCases.count)")
        .accessibilityAction(named: Text("Next page")) { advance(by: 1) }
        .accessibilityAction(named: Text("Previous page")) { advance(by: -1) }
        .accessibilityIdentifier("welcome-pages")
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 12) {
            NativeWelcomePageIndicator(
                currentPage: currentPage,
                onSelect: { move(to: $0) }
            )

            ChooserActionButton(
                isLastPage ? "Get Started" : "Continue",
                systemImage: isLastPage ? "checkmark" : "arrow.right",
                accessibilityLabel: isLastPage ? "Get started" : "Continue to the next page",
                isPrimary: true
            ) {
                if isLastPage {
                    onFinish()
                } else {
                    advance(by: 1)
                }
            }
            .frame(maxWidth: 420)
            .animation(
                reduceMotion ? .linear(duration: 0.01) : .smooth(duration: 0.20),
                value: isLastPage
            )
            .accessibilityIdentifier("welcome-continue")
        }
        .padding(.horizontal, 22)
        .padding(.bottom, verticalSizeClass == .compact ? 10 : 22)
    }

    // MARK: - Paging

    private var isLastPage: Bool {
        currentPage == NativeWelcomePage.allCases.last
    }

    private var usesWideLayout: Bool {
        verticalSizeClass == .compact && !dynamicTypeSize.isAccessibilitySize
    }

    private func instructions(for page: NativeWelcomePage) -> NativeModeInstructions? {
        copy.modes.first { $0.id == page.rawValue }
    }

    private func advance(by offset: Int) {
        let pages = NativeWelcomePage.allCases
        let target = currentPage.index + offset
        guard pages.indices.contains(target) else { return }
        move(to: pages[target])
    }

    private func move(to page: NativeWelcomePage) {
        guard page != currentPage else { return }
        // The interactive swipe is direct manipulation and is left alone;
        // only programmatic movement is gated on Reduce Motion.
        withAnimation(reduceMotion ? .linear(duration: 0.01) : .smooth(duration: 0.28)) {
            scrolledPage = page
        }
        currentPage = page
    }

    private func announcePageChange(to page: NativeWelcomePage) {
        focusedPage = page
        guard let instructions = instructions(for: page) else { return }
        // Focus restoration is occasionally refused, so the announcement is the
        // safety net. Both together mean a page change is never silent.
        AccessibilityNotification.Announcement(
            "\(instructions.title). Page \(page.index + 1) of \(NativeWelcomePage.allCases.count)."
        ).post()
    }
}

// MARK: - One page

struct NativeWelcomePageView: View {
    let page: NativeWelcomePage
    let instructions: NativeModeInstructions?
    let colorTheme: ChooserColorTheme
    let usesWideLayout: Bool
    let isCurrent: Bool
    @AccessibilityFocusState.Binding var focusedPage: NativeWelcomePage?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GeometryReader { geometry in
            let artworkHeight = illustrationHeight(in: geometry.size)

            ScrollView {
                Group {
                    if usesWideLayout {
                        HStack(alignment: .center, spacing: 28) {
                            artwork.frame(height: artworkHeight)
                            textBlock
                        }
                    } else {
                        VStack(spacing: 20) {
                            artwork.frame(height: artworkHeight)
                            textBlock
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 16)
                .frame(minHeight: geometry.size.height, alignment: .center)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        // Off-screen pages must leave the accessibility tree, or VoiceOver
        // reads page two while page one is on screen.
        .accessibilityHidden(!isCurrent)
        .accessibilityIdentifier("welcome-page-\(page.rawValue)")
    }

    private var artwork: some View {
        NativeWelcomeArtwork(page: page, theme: colorTheme, density: .full)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var textBlock: some View {
        if let instructions {
            VStack(alignment: .leading, spacing: 10) {
                Text(instructions.title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($focusedPage, equals: page)

                Text(instructions.summary)
                    .font(.system(.title3, design: .rounded, weight: .semibold))

                Text(instructions.welcomeLine)
                    .font(.system(.body, design: .rounded, weight: .regular))
                    .foregroundStyle(colorTheme.informationPanelInkColor.opacity(0.86))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(18)
            .nativeBoardPanel(cornerRadius: 24)
        }
    }

    private func illustrationHeight(in size: CGSize) -> CGFloat {
        if dynamicTypeSize.isAccessibilitySize { return 88 }
        if usesWideLayout { return min(size.height * 0.72, 220) }
        return min(size.height * 0.46, 300)
    }
}

// MARK: - Page dots

/// Page dots that differentiate by **size and ring, never by hue**.
///
/// Two consequences, both deliberate — do not "improve" this by tinting the
/// current dot with the accent color:
/// - `primaryInkColor` is the ink role solved against the board *surface*; the
///   accent is not, so an accent dot can fail contrast on some worlds.
/// - Because the cue is shape-based, Differentiate Without Color needs no
///   branch here at all.
struct NativeWelcomePageIndicator: View {
    let currentPage: NativeWelcomePage
    let onSelect: (NativeWelcomePage) -> Void

    @Environment(\.chooserVisualTheme) private var visualTheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var baseDot: CGFloat { dynamicTypeSize.isAccessibilitySize ? 11 : 8 }
    private var spacing: CGFloat { dynamicTypeSize.isAccessibilitySize ? 14 : 10 }
    private var inactiveOpacity: Double { colorSchemeContrast == .increased ? 0.42 : 0.26 }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(NativeWelcomePage.allCases) { page in
                let isCurrent = page == currentPage
                let size = isCurrent ? baseDot * 1.35 : baseDot
                Circle()
                    .fill(visualTheme.primaryInkColor.opacity(isCurrent ? 1 : inactiveOpacity))
                    .frame(width: size, height: size)
                    .overlay {
                        if isCurrent {
                            Circle()
                                .stroke(
                                    visualTheme.primaryInkColor.opacity(0.55),
                                    lineWidth: 1.5 * (colorSchemeContrast == .increased ? 1.32 : 1)
                                )
                                .scaleEffect(1.9)
                        }
                    }
            }
        }
        // Three 8pt dots is roughly 44x8, which fails the 44pt minimum target
        // check in `performAccessibilityAudit()` without this explicit frame.
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page")
        .accessibilityValue("\(currentPage.index + 1) of \(NativeWelcomePage.allCases.count)")
        .accessibilityAdjustableAction { direction in
            let pages = NativeWelcomePage.allCases
            switch direction {
            case .increment:
                let next = currentPage.index + 1
                if pages.indices.contains(next) { onSelect(pages[next]) }
            case .decrement:
                let previous = currentPage.index - 1
                if pages.indices.contains(previous) { onSelect(pages[previous]) }
            @unknown default:
                break
            }
        }
        .accessibilityIdentifier("welcome-page-indicator")
    }
}

#Preview("Welcome carousel") {
    NativeWelcomeCarousel(
        copy: .chooser(version: "1.1"),
        colorTheme: .wingspanOriginal,
        onFinish: {},
        onSkip: {}
    )
}
