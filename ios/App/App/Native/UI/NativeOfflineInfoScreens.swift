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
    public let steps: [String]

    public init(id: String, title: String, summary: String, steps: [String]) {
        self.id = id
        self.title = title
        self.summary = summary
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
                    title: "Together",
                    summary: "Everyone touches the device at the same time.",
                    steps: [
                        "Place two or more fingers on the screen.",
                        "Hold still while the rings count down.",
                        "The glowing ring goes first."
                    ]
                ),
                NativeModeInstructions(
                    id: "tap-in",
                    title: "Tap In",
                    summary: "Each person joins one tap at a time.",
                    steps: [
                        "Each player taps the screen once.",
                        "When everyone is in, choose Pick.",
                        "The glowing number goes first."
                    ]
                ),
                NativeModeInstructions(
                    id: "pinball",
                    title: "Pinball",
                    summary: "Everyone taps nearest their seat around a flat iPhone.",
                    steps: [
                        "Add two to twelve seats around the playfield.",
                        "Choose Start and watch the glow slow down.",
                        "The region where it actually stops goes first."
                    ]
                )
            ],
            helpSections: [
                NativeInfoSection(
                    id: "feedback",
                    title: "Haptics and sound",
                    paragraphs: [
                        "Native haptics and an on-device audio fallback make the countdown and result easier to feel. System settings can reduce or disable that feedback."
                    ]
                ),
                NativeInfoSection(
                    id: "retry",
                    title: "Try again",
                    paragraphs: [
                        "Together needs at least two simultaneous touches. In Tap In, finish the current tap and add at least two numbered entries before picking. Pinball needs at least two seats.",
                        "Tapped twice in Tap In? Undo removes the newest entry."
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
                        "There are no ads, analytics, tracking identifiers, or third-party network services."
                    ]
                )
            ],
            privacySummary: "No accounts, ads, analytics, or tracking. Every choice happens on this device.",
            supportText: "Support and the public privacy policy remain available at brianrenshaw.github.io/chooser-web-app."
        )
    }
}

public enum NativeOfflineInformationDestination: Hashable, Sendable {
    case help
    case privacy
}

/// A ready-to-present, fully offline navigation flow. The host owns presentation and dismissal.
public struct NativeOfflineInformationFlow: View {
    private let copy: NativeOfflineInformationCopy
    private let onDismiss: () -> Void
    private let onSupport: () -> Void

    @State private var path: [NativeOfflineInformationDestination] = []

    public init(
        copy: NativeOfflineInformationCopy,
        onDismiss: @escaping () -> Void,
        onSupport: @escaping () -> Void = {}
    ) {
        self.copy = copy
        self.onDismiss = onDismiss
        self.onSupport = onSupport
    }

    public var body: some View {
        NavigationStack(path: $path) {
            NativeAboutScreen(
                copy: copy,
                onOpenHelp: { path.append(.help) },
                onOpenPrivacy: { path.append(.privacy) },
                onDismiss: onDismiss
            )
            .navigationDestination(for: NativeOfflineInformationDestination.self) { destination in
                switch destination {
                case .help:
                    NativeHelpScreen(copy: copy, onSupport: onSupport)
                case .privacy:
                    NativePrivacyScreen(copy: copy)
                }
            }
        }
        .tint(.cyan)
    }
}

public struct NativeAboutScreen: View {
    private let copy: NativeOfflineInformationCopy
    private let onOpenHelp: () -> Void
    private let onOpenPrivacy: () -> Void
    private let onDismiss: () -> Void

    public init(
        copy: NativeOfflineInformationCopy,
        onOpenHelp: @escaping () -> Void,
        onOpenPrivacy: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.copy = copy
        self.onOpenHelp = onOpenHelp
        self.onOpenPrivacy = onOpenPrivacy
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NativeInformationBackground {
            ScrollView {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 24) {
                        identity
                            .frame(minWidth: 240, maxWidth: 340, alignment: .leading)
                        modeCards
                            .frame(minWidth: 360, maxWidth: 620, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 24) {
                        identity
                        modeCards
                    }
                }
                .frame(maxWidth: 980, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done", action: onDismiss)
                    .fontWeight(.semibold)
            }
        }
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 12) {
            NativeNeonRingView(diameter: 72, lineWidth: 3, palette: .cyan, emphasis: .resting)
                .accessibilityHidden(true)

            Text(copy.appName)
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)

            Text(copy.tagline)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Version \(copy.version)")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.tertiary)

            Text(copy.privacySummary)
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.top, 6)
        }
    }

    private var modeCards: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(copy.modes) { mode in
                NativeModeInstructionCard(mode: mode)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { informationButtons }
                VStack(spacing: 12) { informationButtons }
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var informationButtons: some View {
        Button(action: onOpenHelp) {
            Label("Help", systemImage: "questionmark.circle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)

        Button(action: onOpenPrivacy) {
            Label("Privacy", systemImage: "hand.raised")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
    }
}

public struct NativeHelpScreen: View {
    private let copy: NativeOfflineInformationCopy
    private let onSupport: () -> Void

    public init(copy: NativeOfflineInformationCopy, onSupport: @escaping () -> Void = {}) {
        self.copy = copy
        self.onSupport = onSupport
    }

    public var body: some View {
        NativeInformationBackground {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    Text("Help")
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)

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

                    if let supportURL = URL(string: "https://brianrenshaw.github.io/chooser-web-app/support.html") {
                        Link(destination: supportURL) {
                            Label("Public support page", systemImage: "safari")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                    }

                    Text(copy.supportText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: 760, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}

public struct NativePrivacyScreen: View {
    private let copy: NativeOfflineInformationCopy

    public init(copy: NativeOfflineInformationCopy) {
        self.copy = copy
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
                .foregroundStyle(.cyan)
                .accessibilityHidden(true)

            Text("Private by design")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)

            Text(copy.privacySummary)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var privacySections: some View {
        LazyVStack(alignment: .leading, spacing: 18) {
            ForEach(copy.privacySections) { section in
                NativeInfoSectionCard(section: section)
            }

            if let privacyURL = URL(string: "https://brianrenshaw.github.io/chooser-web-app/privacy.html") {
                Link(destination: privacyURL) {
                    Label("View public privacy policy", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }
        }
    }
}

private struct NativeModeInstructionCard: View {
    let mode: NativeModeInstructions

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(mode.title)
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            Text(mode.summary)
                .foregroundStyle(.secondary)

            ForEach(Array(mode.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(index + 1, format: .number)
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.black)
                        .frame(width: 24, height: 24)
                        .background(.cyan, in: Circle())
                        .accessibilityHidden(true)

                    Text(step)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Step \(index + 1): \(step)")
            }
        }
        .padding(18)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct NativeInfoSectionCard: View {
    let section: NativeInfoSection

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.title)
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)

            ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct NativeInformationBackground<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            content()
        }
        .foregroundStyle(.white)
    }
}
