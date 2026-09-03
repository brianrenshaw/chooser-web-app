import XCTest

final class WhosFirstLaunchUITests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    @MainActor
    func testBuild12SavedLaunchDefaultMigratesToChooser() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-chooser.launch-default-mode", "pinball",
            "-chooser.launch-default-mode.migration-version", "0",
            // This file builds its own argument list rather than using
            // WhosFirstUITests' helper, so it needs its own onboarding
            // suppression or the first-run cover hides the toolbar below.
            "-chooser.onboarding.version", "1",
            "-chooser.onboarding", "(welcome, mode.together, mode.tapIn, mode.pinball)"
        ]
        app.launch()

        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Chooser mode"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["together-stage"].exists)
        XCTAssertFalse(app.buttons["Tap In mode"].exists)
        XCTAssertFalse(app.buttons["Pinball mode"].exists)
    }
}
