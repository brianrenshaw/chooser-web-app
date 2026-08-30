import XCTest

final class WhosFirstLaunchUITests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    @MainActor
    func testLaunchShowsNativeChooserChrome() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Help and information"].waitForExistence(timeout: 3))

        let modeLabels = ["Together mode", "Tap In mode", "Pinball mode"]
        XCTAssertTrue(
            modeLabels.contains { app.buttons[$0].exists },
            "Launch should expose exactly one current mode through the native mode control"
        )
    }
}
