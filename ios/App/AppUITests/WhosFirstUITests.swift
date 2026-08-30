import XCTest

final class WhosFirstUITests: XCTestCase {
    @MainActor
    private func launchApp() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        return app
    }

    @MainActor
    func testModeControlCyclesThroughAllThreeModes() {
        let app = launchApp()
        let order = ["Together mode", "Tap In mode", "Pinball mode"]
        guard let currentIndex = order.firstIndex(where: { modeElement(in: app, labeled: $0).exists }) else {
            return XCTFail("No accessible current-mode control was discoverable")
        }

        let current = modeElement(in: app, labeled: order[currentIndex])
        XCTAssertTrue(current.isHittable)
        current.tap()

        let secondLabel = order[(currentIndex + 1) % order.count]
        XCTAssertTrue(modeElement(in: app, labeled: secondLabel).waitForExistence(timeout: 2))
        modeElement(in: app, labeled: secondLabel).tap()

        let thirdLabel = order[(currentIndex + 2) % order.count]
        XCTAssertTrue(modeElement(in: app, labeled: thirdLabel).waitForExistence(timeout: 2))
        modeElement(in: app, labeled: thirdLabel).tap()

        XCTAssertTrue(modeElement(in: app, labeled: order[currentIndex]).waitForExistence(timeout: 2))
    }

    @MainActor
    func testOfflineInformationOpensAndDismisses() {
        let app = launchApp()
        let help = accessibleElement(
            in: app,
            identifier: "help-and-information",
            fallbackLabel: "Help and information"
        )
        XCTAssertTrue(help.waitForExistence(timeout: 3))
        XCTAssertTrue(help.isHittable)
        help.tap()

        let aboutNavigationBar = app.navigationBars["About"]
        let appName = app.staticTexts["Who's First?"]
        XCTAssertTrue(
            aboutNavigationBar.waitForExistence(timeout: 2) || appName.waitForExistence(timeout: 2),
            "The native offline information flow did not appear"
        )

        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 2))
        done.tap()
        XCTAssertTrue(help.waitForExistence(timeout: 2))
    }

    @MainActor
    func testCurrentModeRemainsUsableAfterRotation() {
        let app = launchApp()
        defer { XCUIDevice.shared.orientation = .portrait }
        let modeLabels = ["Together mode", "Tap In mode", "Pinball mode"]
        guard let currentLabel = modeLabels.first(where: { modeElement(in: app, labeled: $0).exists }) else {
            return XCTFail("No accessible current-mode control was discoverable")
        }

        XCUIDevice.shared.orientation = .landscapeLeft

        let rotatedControl = modeElement(in: app, labeled: currentLabel)
        XCTAssertTrue(rotatedControl.waitForExistence(timeout: 3))
        XCTAssertTrue(rotatedControl.isHittable)
        XCTAssertTrue(app.windows.firstMatch.exists)
    }

    @MainActor
    func testLongPressSavesDefaultWithoutCycling() {
        let app = launchApp()
        let labels = ["Together mode", "Tap In mode", "Pinball mode"]
        guard let currentLabel = labels.first(where: { modeElement(in: app, labeled: $0).exists }) else {
            return XCTFail("No accessible current-mode control was discoverable")
        }

        let control = modeElement(in: app, labeled: currentLabel)
        XCTAssertTrue(control.isHittable)
        control.press(forDuration: 0.7)

        XCTAssertTrue(
            modeElement(in: app, labeled: currentLabel).waitForExistence(timeout: 2),
            "A completed long press must not also cycle to the next mode"
        )

        app.terminate()
        app.launch()
        XCTAssertTrue(
            modeElement(in: app, labeled: currentLabel).waitForExistence(timeout: 3),
            "The long-pressed mode should become the next launch default"
        )
    }

    @MainActor
    private func modeElement(in app: XCUIApplication, labeled label: String) -> XCUIElement {
        accessibleElement(in: app, identifier: "mode-cycle", fallbackLabel: label)
    }

    /// Prefer stable identifiers as they are added by the production shell,
    /// while retaining a label fallback for SwiftUI accessibility elements.
    @MainActor
    private func accessibleElement(
        in app: XCUIApplication,
        identifier: String,
        fallbackLabel: String
    ) -> XCUIElement {
        let identified = app.descendants(matching: .any)[identifier]
        if identified.exists {
            return identified
        }

        let button = app.buttons[fallbackLabel]
        if button.exists {
            return button
        }
        return app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", fallbackLabel))
            .firstMatch
    }
}
