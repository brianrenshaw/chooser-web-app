import SwiftUI

public struct NativeInfoSection: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let paragraphs: [String]

    public init(id: String, title: String, paragraphs: [String]) {
        self.id = id
        self.title = title
        self.paragraphs = paragraphs
    }
}

public struct NativeModeInstructions: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    /// One short action line for the first-run welcome carousel, which has no
    /// room for `steps`. It is deliberately required rather than defaulted: a
    /// new mode must supply it here, so the welcome and How It Works can never
    /// drift out of sync.
    public let welcomeLine: String
    public let steps: [String]

    public init(
        id: String,
        title: String,
        summary: String,
        welcomeLine: String,
        steps: [String]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.welcomeLine = welcomeLine
        self.steps = steps
    }
}

public struct NativeOfflineInformationCopy: Sendable {
    public let appName: String
    public let version: String
    public let tagline: String
    public let modes: [NativeModeInstructions]
    public let helpSections: [NativeInfoSection]
    public let privacySections: [NativeInfoSection]
    public let privacySummary: String
    public let supportText: String

    public init(
        appName: String,
        version: String,
        tagline: String,
        modes: [NativeModeInstructions],
        helpSections: [NativeInfoSection],
        privacySections: [NativeInfoSection],
        privacySummary: String,
        supportText: String
    ) {
        self.appName = appName
        self.version = version
        self.tagline = tagline
        self.modes = modes
        self.helpSections = helpSections
        self.privacySections = privacySections
        self.privacySummary = privacySummary
        self.supportText = supportText
    }

    public static func chooser(version: String) -> NativeOfflineInformationCopy {
        NativeOfflineInformationCopy(
            appName: "Who's First?",
            version: version,
            tagline: "One fair choice, made together.",
            modes: [
                NativeModeInstructions(
                    id: "together",
                    title: "Chooser",
                    summary: "Everyone places one finger on the screen at once.",
                    welcomeLine: "Hold still. The remaining ring is the choice.",
                    steps: [
                        "Each person places one finger on the screen.",
                        "Hold still while the rings build anticipation.",
                        "The remaining ring is the choice."
                    ]
                ),
                NativeModeInstructions(
                    id: "tap-in",
                    title: "Tap In",
                    summary: "Each person joins one tap at a time.",
                    welcomeLine: "When everyone is in, choose Pick.",
                    steps: [
                        "Each player taps the screen once.",
                        "When everyone is in, choose Pick.",
                        "The remaining number is the choice."
                    ]
                ),
                NativeModeInstructions(
                    id: "pinball",
                    title: "Pinball",
                    summary: "Everyone taps nearest their seat around a flat device.",
                    welcomeLine: "Flick across the playfield. Where the ball stops is the choice.",
                    steps: [
                        "Add two to twelve seats around the playfield.",
                        "Flick across the playfield. Once the gesture becomes a flick, the ball appears under your finger and follows the exact release point and direction.",
                        "If ordinary bounces already reach the fairly selected seat, the path stays natural. Otherwise exactly one contact — a wall, or a seat ring the ball kicks off — visibly flexes once to redirect it, so every seat keeps exactly the same chance.",
                        "The equal-area region where the visible ball stops is the choice."
                    ]
                )
            ],
            helpSections: [
                NativeInfoSection(
                    id: "feedback",
                    title: "Haptics and sound",
                    paragraphs: [
                        "On hardware that supports it, native haptics carry the Chooser and Tap In anticipation and winner, and Pinball's one fair flex has its own distinct tactile cue. Where there is no Taptic Engine — iPad included — the same moments are carried visually. The winner remains silent; brief on-device sound is used only as an eligible fallback when Core Haptics is unavailable. System settings can reduce or disable feedback."
                    ]
                ),
                NativeInfoSection(
                    id: "retry",
                    title: "Try again",
                    paragraphs: [
                        "Chooser needs at least two simultaneous touches. In Tap In, finish the current tap and add at least two numbered entries before picking. Pinball needs at least two seats before a flick.",
                        "Tapped twice in Tap In? Undo removes the newest entry."
                    ]
                ),
                NativeInfoSection(
                    id: "colors",
                    title: "Colors",
                    paragraphs: [
                        "Three-finger tap anywhere to shuffle the colors."
                    ]
                )
            ],
            privacySections: [
                NativeInfoSection(
                    id: "processing",
                    title: "Temporary on-device processing",
                    paragraphs: [
                        "Finger locations, numbered entries, and Pinball seat positions are processed only in memory so the app can draw the experience and choose a winner.",
                        "Numbers are not identities. The app does not ask for names, accounts, or contact information."
                    ]
                ),
                NativeInfoSection(
                    id: "retention",
                    title: "No collection or retention",
                    paragraphs: [
                        "Interaction data is not persisted or transmitted. Closing or reloading the app clears it.",
                        "Only your chosen launch mode and color theme are saved on this device.",
                        "There are no ads, analytics, tracking identifiers, or third-party network services."
                    ]
                )
            ],
            privacySummary: "No accounts, ads, analytics, or tracking. Every choice happens on this device.",
            supportText: "Support and the public privacy policy remain available at brianrenshaw.app/chooser."
        )
    }
}

public enum NativeOfflineInformationDestination: Hashable, Sendable {
    case about
    case help
    case privacy
}

/// A ready-to-present, fully offline navigation flow. The host owns presentation and dismissal.
public struct NativeOfflineInformationFlow: View {
    private let copy: NativeOfflineInformationCopy
    private let selectedColorTheme: ChooserColorTheme
    private let colorThemes: [ChooserColorTheme]
    private let onSelectColorTheme: (ChooserColorTheme) -> Void
    private let onShuffleColorTheme: () -> Bool
    private let onDismiss: () -> Void
    private let onSupport: () -> Void
    private let onShowWelcome: () -> Void

    @State private var path: [NativeOfflineInformationDestination] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        copy: NativeOfflineInformationCopy,
        selectedColorTheme: ChooserColorTheme,
        colorThemes: [ChooserColorTheme] = ChooserColorTheme.allCases,
        onSelectColorTheme: @escaping (ChooserColorTheme) -> Void,
        onShuffleColorTheme: @escaping () -> Bool = { false },
        onDismiss: @escaping () -> Void,
        onSupport: @escaping () -> Void = {},
        onShowWelcome: @escaping () -> Void = {}
    ) {
        self.copy = copy
        self.selectedColorTheme = selectedColorTheme
        self.colorThemes = colorThemes
        self.onSelectColorTheme = onSelectColorTheme
        self.onShuffleColorTheme = onShuffleColorTheme
        self.onDismiss = onDismiss
        self.onSupport = onSupport
        self.onShowWelcome = onShowWelcome
    }

    public var body: some View {
        NavigationStack(path: $path) {
            NativeSettingsScreen(
                copy: copy,
                selectedColorTheme: selectedColorTheme,
                colorThemes: colorThemes,
                onSelectColorTheme: onSelectColorTheme,
                onShuffleColorTheme: onShuffleColorTheme,
                onSupport: onSupport,
                onShowWelcome: onShowWelcome,
                onDismiss: onDismiss
            )
            .navigationDestination(for: NativeOfflineInformationDestination.self) { destination in
                switch destination {
                case .about:
                    NativeAboutScreen(
                        copy: copy,
                        onShuffleColorTheme: onShuffleColorTheme
                    )
                case .help:
                    NativeHelpScreen(
                        copy: copy,
                        onShuffleColorTheme: onShuffleColorTheme,
                        onSupport: onSupport
                    )
                case .privacy:
                    NativePrivacyScreen(
                        copy: copy,
                        onShuffleColorTheme: onShuffleColorTheme
                    )
                }
            }
        }
        .tint(selectedColorTheme.interactiveTextColor)
        .environment(\.chooserAccentColor, selectedColorTheme.accentColor)
        .environment(\.chooserColorTheme, selectedColorTheme)
        .environment(\.chooserVisualTheme, selectedColorTheme.visualTheme)
        .environment(\.colorScheme, selectedColorTheme.preferredColorScheme)
        .animation(reduceMotion ? nil : .smooth(duration: 0.24), value: selectedColorTheme)
    }
}

public struct NativeSettingsScreen: View {
    private let copy: NativeOfflineInformationCopy
    private let selectedColorTheme: ChooserColorTheme
    private let colorThemes: [ChooserColorTheme]
    private let onSelectColorTheme: (ChooserColorTheme) -> Void
    private let onShuffleColorTheme: () -> Bool
    private let onSupport: () -> Void
    private let onShowWelcome: () -> Void
    private let onDismiss: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        copy: NativeOfflineInformationCopy,
        selectedColorTheme: ChooserColorTheme,
        colorThemes: [ChooserColorTheme],
        onSelectColorTheme: @escaping (ChooserColorTheme) -> Void,
        onShuffleColorTheme: @escaping () -> Bool = { false },
        onSupport: @escaping () -> Void,
        onShowWelcome: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void
    ) {
        self.copy = copy
        self.selectedColorTheme = selectedColorTheme
        self.colorThemes = colorThemes
        self.onSelectColorTheme = onSelectColorTheme
        self.onShuffleColorTheme = onShuffleColorTheme
        self.onSupport = onSupport
        self.onShowWelcome = onShowWelcome
        self.onDismiss = onDismiss
    }

    public var body: some View {
        Form {
            Section {
                LazyVGrid(
                    columns: colorThemeColumns,
                    spacing: 10
                ) {
                    ForEach(colorThemes) { theme in
                        NativeColorThemeOption(
                            theme: theme,
                            isSelected: theme == selectedColorTheme,
                            action: { onSelectColorTheme(theme) },
                            onShuffleColorTheme: onShuffleColorTheme
                        )
                    }
                }
                .padding(.vertical, 4)
                .listRowInsets(
                    EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0)
                )
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("color-theme-picker")
            } header: {
                Text("Colors")
                    .foregroundStyle(selectedColorTheme.informationPanelInkColor)
            } footer: {
                Text("Unofficial color inspiration; no affiliation with the named games or their publishers. Artwork, logos, and game assets are not used.")
                    .foregroundStyle(selectedColorTheme.informationPanelInkColor)
                    .padding(8)
                    .background(
                        selectedColorTheme.informationPanelColor,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
            }

            Section {
                NavigationLink(value: NativeOfflineInformationDestination.about) {
                    Label("About Who's First?", systemImage: "info.circle")
                        .foregroundStyle(selectedColorTheme.interactiveTextColor)
                }
                .accessibilityIdentifier("settings-about")

                // A Button, not a NavigationLink: the carousel is presented at
                // the root, not pushed into this stack. `hand.wave` is placed
                // here rather than after How It Works so it never sits directly
                // above Privacy's `hand.raised`.
                Button(action: onShowWelcome) {
                    Label("Show Welcome Again", systemImage: "hand.wave")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(selectedColorTheme.interactiveTextColor)
                }
                .accessibilityIdentifier("settings-show-welcome")

                NavigationLink(value: NativeOfflineInformationDestination.help) {
                    Label("How It Works", systemImage: "list.number")
                        .foregroundStyle(selectedColorTheme.interactiveTextColor)
                }
                .accessibilityIdentifier("settings-help")

                NavigationLink(value: NativeOfflineInformationDestination.privacy) {
                    Label("Privacy", systemImage: "hand.raised")
                        .foregroundStyle(selectedColorTheme.interactiveTextColor)
                }
                .accessibilityIdentifier("settings-privacy")

                Button(action: onSupport) {
                    Label("Contact Support", systemImage: "envelope")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(selectedColorTheme.interactiveTextColor)
                }
                .accessibilityIdentifier("settings-support")
            } header: {
                Text("Information")
                    .foregroundStyle(selectedColorTheme.informationPanelInkColor)
            } footer: {
                Text("Version \(copy.version)")
                    .monospacedDigit()
                    .foregroundStyle(selectedColorTheme.informationPanelInkColor)
                    .padding(8)
                    .background(
                        selectedColorTheme.informationPanelColor,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .accessibilityIdentifier("settings-version")
            }
            .listRowBackground(selectedColorTheme.informationPanelColor)
            .listSectionSeparatorTint(selectedColorTheme.separatorColor)
        }
        .scrollContentBackground(.hidden)
        .background(BoardSurfaceView(theme: selectedColorTheme).ignoresSafeArea())
        .foregroundStyle(selectedColorTheme.informationPanelInkColor)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .accessibilityIdentifier("settings-screen")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done", action: onDismiss)
                    .fontWeight(.semibold)
            }
        }
    }

    private var colorThemeColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }

        // Keep full world names readable in the compact-width landscape sheet.
        // The extra scrolling is preferable to squeezing five tiny cards into
        // the readable column and truncating the selected theme.
        return [GridItem(.adaptive(minimum: 156), spacing: 10)]
    }
}

private struct NativeColorThemeOption: View {
    let theme: ChooserColorTheme
    let isSelected: Bool
    let action: () -> Void
    let onShuffleColorTheme: () -> Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                NativeThemeBoardPreview(theme: theme)
                    .frame(height: 62)
                .accessibilityHidden(true)

                HStack(spacing: 6) {
                    Text(theme.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2, reservesSpace: true)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 2)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(theme.onChromeInkColor)
                            .accessibilityHidden(true)
                    }
                }
                .foregroundStyle(theme.onChromeInkColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 6)
                .background(
                    theme.chromeTintColor.opacity(0.92),
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )
            }
            .padding(12)
            .frame(
                maxWidth: .infinity,
                minHeight: dynamicTypeSize.isAccessibilitySize ? 136 : 120,
                alignment: .leading
            )
            .background {
                BoardSurfaceView(theme: theme)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(theme.actionAccentColor.opacity(0.12))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? theme.actionAccentColor.opacity(0.95) : theme.separatorColor,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
            .shadow(color: .black.opacity(isSelected ? 0.20 : 0.10), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.name) color theme")
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAction(named: Text("Shuffle colors")) {
            _ = onShuffleColorTheme()
        }
        .accessibilityIdentifier("theme-option-\(theme.id)")
    }
}

private struct NativeThemeBoardPreview: View {
    let theme: ChooserColorTheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BoardSurfaceView(theme: theme)

                BoardRingView(
                    diameter: 39,
                    lineWidth: 10,
                    style: .participant(theme: theme, index: 0),
                    emphasis: .resting
                )
                    .position(x: geometry.size.width * 0.23, y: geometry.size.height * 0.50)

                ForEach(0..<2, id: \.self) { index in
                    NumberedChitView(
                        number: index + 1,
                        diameter: 25,
                        style: .participant(theme: theme, index: index + 1),
                        emphasis: .resting
                    )
                        .position(
                            x: geometry.size.width * (index == 0 ? 0.50 : 0.67),
                            y: geometry.size.height * (index == 0 ? 0.37 : 0.66)
                        )
                }

                Capsule()
                    .fill(theme.actionAccentColor)
                    .frame(width: 25, height: 9)
                    .position(x: geometry.size.width * 0.84, y: geometry.size.height * 0.25)

                PhysicalPinballBallView(theme: theme, diameter: 17)
                    .position(x: geometry.size.width * 0.84, y: geometry.size.height * 0.68)
            }
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(theme.separatorColor, lineWidth: 1)
            }
        }
    }

}

public struct NativeAboutScreen: View {
    private let copy: NativeOfflineInformationCopy
    private let onShuffleColorTheme: () -> Bool

    @Environment(\.chooserColorTheme) private var colorTheme

    public init(
        copy: NativeOfflineInformationCopy,
        onShuffleColorTheme: @escaping () -> Bool = { false }
    ) {
        self.copy = copy
        self.onShuffleColorTheme = onShuffleColorTheme
    }

    public var body: some View {
        NativeInformationBackground {
            ScrollView {
                identity
                    .frame(maxWidth: 520, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 28)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 14) {
            BoardRingView(
                diameter: 64,
                lineWidth: 18,
                style: .participant(theme: colorTheme, index: 0),
                emphasis: .resting
            )
                .accessibilityHidden(true)

            Text(copy.appName)
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
                .accessibilityAction(named: Text("Shuffle colors")) {
                    _ = onShuffleColorTheme()
                }

            Text(copy.tagline)
                .font(.title3)
                .foregroundStyle(colorTheme.informationPanelInkColor)

            Text("Version \(copy.version)")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(colorTheme.informationPanelInkColor)

            Text(copy.privacySummary)
                .font(.callout)
                .foregroundStyle(colorTheme.informationPanelInkColor)
                .padding(.top, 8)

            Divider()
                .overlay(colorTheme.separatorColor)
                .padding(.vertical, 4)

            Text("Private, offline, and made for one quick choice together.")
                .font(.footnote)
                .foregroundStyle(colorTheme.informationPanelInkColor)
        }
        .padding(20)
        .background(
            colorTheme.informationPanelColor,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(colorTheme.separatorColor, lineWidth: 1)
        }
    }
}

public struct NativeHelpScreen: View {
    private let copy: NativeOfflineInformationCopy
    private let onShuffleColorTheme: () -> Bool
    private let onSupport: () -> Void
    @Environment(\.chooserVisualTheme) private var visualTheme

    public init(
        copy: NativeOfflineInformationCopy,
        onShuffleColorTheme: @escaping () -> Bool = { false },
        onSupport: @escaping () -> Void = {}
    ) {
        self.copy = copy
        self.onShuffleColorTheme = onShuffleColorTheme
        self.onSupport = onSupport
    }

    public var body: some View {
        NativeInformationBackground {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    Text("How It Works")
                        .font(.largeTitle.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .foregroundStyle(visualTheme.informationPanelInkColor)
                        .background(
                            visualTheme.informationPanelColor,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityAction(named: Text("Shuffle colors")) {
                            _ = onShuffleColorTheme()
                        }

                    ForEach(copy.modes) { mode in
                        NativeModeInstructionCard(mode: mode)
                    }

                    ForEach(copy.helpSections) { section in
                        NativeInfoSectionCard(section: section)
                    }

                    Button(action: onSupport) {
                        Label("Contact support", systemImage: "envelope")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(visualTheme.actionAccentColor)
                    .foregroundStyle(visualTheme.accentForegroundColor)

                    if let supportURL = URL(string: "https://brianrenshaw.app/chooser/support/") {
                        Link(destination: supportURL) {
                            Label("Public support page", systemImage: "safari")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(visualTheme.actionAccentColor)
                        .foregroundStyle(visualTheme.accentForegroundColor)
                    }

                    Text(copy.supportText)
                        .font(.footnote)
                        .foregroundStyle(visualTheme.informationPanelInkColor)
                        .padding(12)
                        .background(
                            visualTheme.informationPanelColor,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                }
                .frame(maxWidth: 760, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("How It Works")
        .navigationBarTitleDisplayMode(.inline)
    }
}

public struct NativePrivacyScreen: View {
    private let copy: NativeOfflineInformationCopy
    private let onShuffleColorTheme: () -> Bool
    @Environment(\.chooserVisualTheme) private var visualTheme

    public init(
        copy: NativeOfflineInformationCopy,
        onShuffleColorTheme: @escaping () -> Bool = { false }
    ) {
        self.copy = copy
        self.onShuffleColorTheme = onShuffleColorTheme
    }

    public var body: some View {
        NativeInformationBackground {
            ScrollView {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 24) {
                        privacySummary
                            .frame(minWidth: 240, maxWidth: 340, alignment: .leading)
                        privacySections
                            .frame(minWidth: 360, maxWidth: 620, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        privacySummary
                        privacySections
                    }
                }
                .frame(maxWidth: 980, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var privacySummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(visualTheme.interactiveTextColor)
                .accessibilityHidden(true)

            Text("Private by design")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
                .accessibilityAction(named: Text("Shuffle colors")) {
                    _ = onShuffleColorTheme()
                }

            Text(copy.privacySummary)
                .font(.title3)
                .foregroundStyle(visualTheme.informationPanelInkColor)
        }
        .padding(18)
        .background(
            visualTheme.informationPanelColor,
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(visualTheme.separatorColor, lineWidth: 1)
        }
    }

    private var privacySections: some View {
        LazyVStack(alignment: .leading, spacing: 18) {
            ForEach(copy.privacySections) { section in
                NativeInfoSectionCard(section: section)
            }

            if let privacyURL = URL(string: "https://brianrenshaw.app/chooser/privacy/") {
                Link(destination: privacyURL) {
                    Label("View public privacy policy", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(visualTheme.actionAccentColor)
                .foregroundStyle(visualTheme.accentForegroundColor)
            }
        }
    }
}

private struct NativeModeInstructionCard: View {
    let mode: NativeModeInstructions
    @Environment(\.chooserVisualTheme) private var visualTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(mode.title)
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            Text(mode.summary)
                .foregroundStyle(visualTheme.informationPanelInkColor)

            ForEach(Array(mode.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(index + 1, format: .number)
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(visualTheme.accentForegroundColor)
                        .frame(width: 24, height: 24)
                        .background(visualTheme.accentColor, in: Circle())
                        .accessibilityHidden(true)

                    Text(step)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Step \(index + 1): \(step)")
            }
        }
        .padding(18)
        .foregroundStyle(visualTheme.informationPanelInkColor)
        .background(visualTheme.informationPanelColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(visualTheme.separatorColor, lineWidth: 1)
        }
    }
}

private struct NativeInfoSectionCard: View {
    let section: NativeInfoSection
    @Environment(\.chooserVisualTheme) private var visualTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.title)
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)

            ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .foregroundStyle(visualTheme.informationPanelInkColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .foregroundStyle(visualTheme.informationPanelInkColor)
        .background(visualTheme.informationPanelColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(visualTheme.separatorColor, lineWidth: 1)
        }
    }
}

private struct NativeInformationBackground<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @Environment(\.chooserColorTheme) private var colorTheme

    var body: some View {
        ZStack {
            BoardSurfaceView(theme: colorTheme)
                .ignoresSafeArea()
            content()
        }
        .foregroundStyle(colorTheme.informationPanelInkColor)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
