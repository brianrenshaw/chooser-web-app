import AppIntents
import SwiftUI

@main
@MainActor
struct WhosFirstApp: App {
    @State private var model = ChooserAppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ChooserRootView(model: model)
                .preferredColorScheme(model.colorTheme.preferredColorScheme)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                model.handleSceneBecameActive()
            case .inactive, .background:
                model.handleSceneBecameInactive()
            @unknown default:
                break
            }
        }
    }
}

/// Makes the three physical chooser experiences available directly from
/// Shortcuts, Siri suggestions, and Spotlight without persisting a preference.
struct WhosFirstAppShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor { .teal }

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenChooserShortcutIntent(),
            phrases: [
                "Open Chooser in \(.applicationName)",
                "Choose together with \(.applicationName)"
            ],
            shortTitle: "Open Chooser",
            systemImageName: "hand.raised.fill"
        )

        AppShortcut(
            intent: OpenTapInShortcutIntent(),
            phrases: [
                "Open Tap In in \(.applicationName)",
                "Tap in with \(.applicationName)"
            ],
            shortTitle: "Open Tap In",
            systemImageName: "number.circle.fill"
        )

        AppShortcut(
            intent: OpenPinballShortcutIntent(),
            phrases: [
                "Open Pinball in \(.applicationName)",
                "Launch Pinball in \(.applicationName)"
            ],
            shortTitle: "Open Pinball",
            systemImageName: "circle.circle"
        )
    }
}

struct OpenChooserShortcutIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Chooser"
    static let description = IntentDescription("Open Who's First? in Chooser mode.")

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(AppMode.together.deepLinkURL))
    }
}

struct OpenTapInShortcutIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Tap In"
    static let description = IntentDescription("Open Who's First? in Tap In mode.")

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(AppMode.tapIn.deepLinkURL))
    }
}

struct OpenPinballShortcutIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Pinball"
    static let description = IntentDescription("Open Who's First? in Pinball mode.")

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(AppMode.pinball.deepLinkURL))
    }
}
