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

/// The first-run introduction: one page per mode, presented as a drag-dismissible
/// sheet over `ChooserRootView`.
///
/// Presentation notes for anyone editing this:
/// - It is presented at a partial detent so the board stays visible above it and
///   it reads as a card rather than a takeover. Do not add `.statusBarHidden`
///   here; a sheet does not own the status bar.
/// - A sheet is a **separate environment tree**. The four `chooser*` values are
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
    @Environment(\.boardChromeMetrics) private var chrome

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
            .frame(maxWidth: chrome.readableWidth)
            .frame(maxWidth: .infinity)
            .safeAreaPadding(.horizontal)
        }
        // No identifier on this ZStack. SwiftUI propagates a container's
        // accessibility identifier down onto every descendant element that is
        // not behind an accessibility container boundary, so one here would
        // silently overwrite `welcome-skip`, `welcome-continue`, and the rest.
        // `welcome-pages` is the carousel's presence marker instead.
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

    /// Deliberately one short line, and deliberately without the Skip button.
    ///
    /// A sheet is height-constrained where the full screen was not, so a
    /// two-line header stacked above the pages is the first thing to clip at
    /// large Dynamic Type sizes. The tagline lives on the About screen, and
    /// dismissal now belongs at the bottom next to Continue where the thumb
    /// already is — the drag indicator covers the gesture affordance.
    private var header: some View {
        Text(copy.appName)
            .font(.system(.headline, design: .rounded, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .nativeBoardPanel(cornerRadius: 16)
            .padding(.top, 6)
            .layoutPriority(1)
            .accessibilityAddTraits(.isHeader)
            .accessibilityAction(named: Text("Shuffle colors")) {
                _ = onShuffleColorTheme()
            }
            .accessibilityIdentifier("welcome-title")
    }

    private var skipButton: some View {
        Button("Skip", action: onSkip)
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(colorTheme.interactiveTextColor)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityHint("Closes the introduction")
            .accessibilityIdentifier("welcome-skip")
            // Kept in the layout on the last page so the footer never changes
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

            skipButton
        }
        .padding(.horizontal, 22)
        .padding(.bottom, verticalSizeClass == .compact ? 10 : 22)
        // Same reasoning as the header: inside a height-constrained sheet the
        // paging ScrollView will happily take every available point and squeeze
        // the fixed chrome, which clips these labels at large Dynamic Type
        // sizes. The scrollable page area is what should give way.
        .layoutPriority(1)
    }

    // MARK: - Paging

    private var isLastPage: Bool {
        currentPage == NativeWelcomePage.allCases.last
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

// MARK: - Layout decision

enum NativeWelcomeLayout {
    /// Whether a welcome page puts its artwork beside the text rather than
    /// above it.
    ///
    /// Keyed off the page's real width and shape, never a size class. The
    /// predicate this replaces was `verticalSizeClass == .compact`, which is
    /// **never true on iPad** — so a 13-inch canvas got the narrow phone layout
    /// while an iPhone in landscape got the wide one. Size classes answer
    /// "what kind of device is this?"; the question here is "is this page short
    /// and wide enough for two columns?", which only the geometry can answer.
    ///
    /// The aspect guard is what keeps iPad **portrait** stacked. A 1024pt-wide
    /// portrait page clears the width bar easily, but side-by-side is for
    /// short-and-wide — which is what the original predicate was reaching for.
    static func usesWideLayout(pageSize: CGSize, isAccessibilitySize: Bool) -> Bool {
        guard !isAccessibilitySize else { return false }
        guard pageSize.width.isFinite, pageSize.height > 0 else { return false }
        return pageSize.width >= 620 && pageSize.width > pageSize.height * 1.1
    }
}

// MARK: - One page

struct NativeWelcomePageView: View {
    let page: NativeWelcomePage
    let instructions: NativeModeInstructions?
    let colorTheme: ChooserColorTheme
    let isCurrent: Bool
    @AccessibilityFocusState.Binding var focusedPage: NativeWelcomePage?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GeometryReader { geometry in
            let usesWideLayout = NativeWelcomeLayout.usesWideLayout(
                pageSize: geometry.size,
                isAccessibilitySize: dynamicTypeSize.isAccessibilitySize
            )
            let artworkHeight = illustrationHeight(
                in: geometry.size,
                usesWideLayout: usesWideLayout
            )

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

    /// The fractions keep the artwork from crowding out the text block; the
    /// caps stop it ballooning. On a phone the cap is what binds and these are
    /// the shipping numbers unchanged.
    ///
    /// The caps were tuned against a partial sheet detent that no longer
    /// applies, so on a page-sized sheet they were simply stale — an iPad met
    /// a 220pt illustration in 1000pt of height. Letting the cap itself rise
    /// with the page keeps the phone value fixed while giving a large sheet
    /// artwork proportionate to it.
    private func illustrationHeight(in size: CGSize, usesWideLayout: Bool) -> CGFloat {
        if dynamicTypeSize.isAccessibilitySize { return 76 }
        if usesWideLayout {
            return min(size.height * 0.66, max(190, size.height * 0.34))
        }
        return min(size.height * 0.40, max(220, size.height * 0.30))
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
