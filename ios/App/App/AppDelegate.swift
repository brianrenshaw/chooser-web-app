import SwiftUI

@main
@MainActor
struct WhosFirstApp: App {
    @State private var model = ChooserAppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ChooserRootView(model: model)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                model.handleSceneBecameInactive()
            }
        }
    }
}
