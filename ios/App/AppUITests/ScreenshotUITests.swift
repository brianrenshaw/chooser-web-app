import XCTest

/// Captures the App Store screenshot set from the running app.
///
/// These are **real device captures**, not the CSS posters the 1.0 set was
/// built from: every pixel is the app rendering itself on the simulator at
/// native resolution. That matters most for iPad, where the point of the
/// release is the layout — a mock would show a layout nobody ships.
///
/// Skipped unless explicitly asked for, because it is slow and produces files
/// rather than assertions. Run it with:
///
///     xcodebuild test -scheme App \
///       -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
///       -only-testing:AppUITests/ScreenshotUITests \
///       TEST_RUNNER_CAPTURE_SCREENSHOTS=1
///
/// `TEST_RUNNER_`-prefixed settings are injected into the runner's environment,
/// which is how the gate below sees it. Files land in the runner's Documents
/// directory; `scripts/capture-screenshots.sh` collects them.
final class ScreenshotUITests: XCTestCase {

    private var outputDirectory: URL!

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["CAPTURE_SCREENSHOTS"] == "1",
            "Set TEST_RUNNER_CAPTURE_SCREENSHOTS=1 to capture the screenshot set."
        )
        continueAfterFailure = false
        outputDirectory = try XCTUnwrap(
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        ).appendingPathComponent("screenshots", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - The set

    @MainActor
    func testCaptureChooser() throws {
        let app = launch(defaultMode: "together", chooserParticipants: 4)
        XCTAssertTrue(
            app.descendants(matching: .any)["together-stage"].waitForExistence(timeout: 8)
        )
        // Mid-anticipation, deliberately. The reveal dims the losers to near
        // nothing, so a capture taken after it shows a single ring on an empty
        // board — true to the app, and useless as a picture of the mode.
        settle(seconds: 2)
        try capture(app, named: "01-chooser")
    }

    @MainActor
    func testCaptureTapIn() throws {
        let app = launch(defaultMode: "tapIn")
        let stage = app.descendants(matching: .any)["tap-in-stage"]
        XCTAssertTrue(stage.waitForExistence(timeout: 8))
        for offset in tapInOffsets {
            stage.coordinate(withNormalizedOffset: offset).tap()
        }
        settle(seconds: 1)
        try capture(app, named: "02-tap-in")
    }

    @MainActor
    func testCapturePinballSeatsFlightAndResult() throws {
        let app = launch(defaultMode: "pinball")
        let stage = app.descendants(matching: .any)["pinball-stage"]
        XCTAssertTrue(stage.waitForExistence(timeout: 8))

        for offset in pinballSeatOffsets {
            stage.coordinate(withNormalizedOffset: offset).tap()
        }
        settle(seconds: 1)
        try capture(app, named: "03-pinball-seats")

        // A real flick: press, drag, release. The ball appears under the finger
        // once the gesture commits, exactly as in play.
        // Velocity matters: a flick must clear `minimumFlickSpeed`, and
        // XCUITest's default drag is far too slow to register as one. The
        // coordinates stay near the middle because Pinball's board is
        // letterboxed on iPad — the stage is wider than the playfield, so an
        // offset near the edge would land outside the board entirely.
        let start = stage.coordinate(withNormalizedOffset: CGVector(dx: 0.46, dy: 0.56))
        let finish = stage.coordinate(withNormalizedOffset: CGVector(dx: 0.60, dy: 0.40))
        start.press(
            forDuration: 0.05,
            thenDragTo: finish,
            withVelocity: .fast,
            thenHoldForDuration: 0
        )

        // Mid-flight. The flight is several seconds, so a short settle lands
        // inside it rather than after it.
        settle(seconds: 1)
        try capture(app, named: "04-pinball-flight")

        settle(seconds: 8)
        try capture(app, named: "05-pinball-result")
    }

    @MainActor
    func testCaptureVisualWorlds() throws {
        let app = launch(defaultMode: "pinball")
        let stage = app.descendants(matching: .any)["pinball-stage"]
        XCTAssertTrue(stage.waitForExistence(timeout: 8))
        for offset in pinballSeatOffsets {
            stage.coordinate(withNormalizedOffset: offset).tap()
        }
        settle(seconds: 1)

        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        settle(seconds: 1)
        try capture(app, named: "06-visual-worlds")
    }

    // MARK: - Support

    private let tapInOffsets: [CGVector] = [
        CGVector(dx: 0.22, dy: 0.20), CGVector(dx: 0.50, dy: 0.20), CGVector(dx: 0.78, dy: 0.20),
        CGVector(dx: 0.22, dy: 0.40), CGVector(dx: 0.50, dy: 0.40), CGVector(dx: 0.78, dy: 0.40),
        CGVector(dx: 0.22, dy: 0.60), CGVector(dx: 0.50, dy: 0.60), CGVector(dx: 0.78, dy: 0.60),
        CGVector(dx: 0.22, dy: 0.80), CGVector(dx: 0.50, dy: 0.80), CGVector(dx: 0.78, dy: 0.80)
    ]

    private let pinballSeatOffsets: [CGVector] = [
        CGVector(dx: 0.22, dy: 0.18), CGVector(dx: 0.78, dy: 0.18),
        CGVector(dx: 0.85, dy: 0.50), CGVector(dx: 0.78, dy: 0.82),
        CGVector(dx: 0.22, dy: 0.82), CGVector(dx: 0.15, dy: 0.50)
    ]

    @MainActor
    private func launch(
        defaultMode: String,
        chooserParticipants: Int? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-chooser.launch-default-mode.migration-version", "2",
            "-chooser.launch-default-mode", defaultMode,
            "-chooser.color-theme", "wingspan-original",
            "-chooser.onboarding.version", "1",
            "-chooser.onboarding",
            "(welcome, mode.together, mode.tapIn, mode.pinball, whatsNew.1.1)"
        ]
        if let chooserParticipants {
            arguments += [
                "-\(chooserParticipantsKey)", String(chooserParticipants)
            ]
        }
        app.launchArguments = arguments
        app.launch()
        return app
    }

    /// Must match `ChooserScreenshotSeed.participantCountKey`; this target
    /// cannot import the app module to read it.
    private let chooserParticipantsKey = "chooser.demo.chooser-participants"

    /// A plain wait. Screenshot states are animation-timed rather than
    /// element-gated — "the ball is mid-flight" is not an element that exists —
    /// so an expectation would be dishonest about what is being waited for.
    private func settle(seconds: TimeInterval) {
        let idle = XCTestExpectation(description: "settle")
        idle.isInverted = true
        wait(for: [idle], timeout: seconds)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, named name: String) throws {
        let screenshot = XCUIScreen.main.screenshot()
        let url = outputDirectory.appendingPathComponent("\(name).png")
        try screenshot.pngRepresentation.write(to: url)

        // Also attach it, so a failed run still shows what was on screen.
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
