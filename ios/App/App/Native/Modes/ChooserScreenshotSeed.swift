#if DEBUG
import CoreGraphics
import Foundation

/// Puts Chooser into a real chosen state for a screenshot run. **DEBUG only** —
/// this file compiles out of every Release build, so nothing here ships.
///
/// Chooser's genuine state needs several fingers held on the glass at once for
/// the full stability window, and XCUITest has no API that synthesises
/// simultaneous sustained touches. Rather than photograph a mock, this drives
/// `chooseTogetherForAccessibility` — the *shipping* path behind the "Choose
/// from N people" VoiceOver action. The rings, the layout and the reveal are
/// therefore the real thing, produced by code a real user can reach; only the
/// finger input is synthesised.
///
/// Reading `UserDefaults` rather than parsing arguments is deliberate: the
/// `-key value` launch-argument form already lands there, which is how every
/// other UI-test seed in this project works.
enum ChooserScreenshotSeed {
    static let participantCountKey = "chooser.demo.chooser-participants"

    @MainActor
    static func seedIfRequested(model: ChooserAppModel, playfieldSize: CGSize) {
        let requested = UserDefaults.standard.integer(forKey: participantCountKey)
        guard (2...5).contains(requested) else { return }
        // Wait for a laid-out board. `onAppear` can fire while the geometry is
        // still degenerate, and the synthesised ring positions are clamped into
        // whatever size they are given — seeding early stacks every ring in a
        // corner, which is exactly what the first capture attempt produced.
        guard playfieldSize.width > 320, playfieldSize.height > 320 else { return }
        // Once per launch. A second call would clear the rings and redraw them,
        // which on a rotation or a re-appear would look like a spontaneous
        // reroll mid-capture.
        guard !hasSeeded else { return }
        hasSeeded = true
        _ = model.chooseTogetherForAccessibility(
            participantCount: requested,
            in: playfieldSize
        )
    }

    @MainActor private static var hasSeeded = false
}
#endif
