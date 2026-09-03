import Foundation
import XCTest
@testable import App

@MainActor
final class AppModeCoreTests: XCTestCase {
    func testLegacyTogetherValueIsPresentedAsChooser() {
        XCTAssertEqual(AppMode.together.rawValue, "together")
        XCTAssertEqual(AppMode.together.accessibilityName, "Chooser")
    }

    func testEveryModeRoundTripsThroughItsShortcutDeepLink() {
        for mode in AppMode.allCases {
            XCTAssertEqual(AppMode(deepLinkURL: mode.deepLinkURL), mode)
        }
    }

    func testShortcutDeepLinksRejectForeignAndUnknownURLs() throws {
        XCTAssertNil(AppMode(deepLinkURL: try XCTUnwrap(URL(string: "https://example.com/mode/chooser"))))
        XCTAssertNil(AppMode(deepLinkURL: try XCTUnwrap(URL(string: "whosfirst://other/chooser"))))
        XCTAssertNil(AppMode(deepLinkURL: try XCTUnwrap(URL(string: "whosfirst://mode/unknown"))))
    }

    func testPersistedModeBecomesCurrentAndLaunchDefault() {
        let store = MemoryLaunchDefaultModeStore(storedMode: .pinball)
        let core = AppModeCore(store: store)

        XCTAssertEqual(core.currentMode, .pinball)
        XCTAssertEqual(core.launchDefaultMode, .pinball)
        XCTAssertEqual(store.savedModes, [])
    }

    func testFreshInstallUsesChooserFallback() {
        let core = AppModeCore(store: MemoryLaunchDefaultModeStore(storedMode: nil))

        XCTAssertEqual(core.currentMode, .together)
        XCTAssertEqual(core.launchDefaultMode, .together)
    }

    func testSessionModeCanChangeWithoutChangingLaunchDefault() {
        let store = MemoryLaunchDefaultModeStore(storedMode: .together)
        let core = AppModeCore(store: store)

        core.select(.tapIn, persistAsLaunchDefault: false)

        XCTAssertEqual(core.currentMode, .tapIn)
        XCTAssertEqual(core.launchDefaultMode, .together)
        XCTAssertEqual(store.storedMode, .together)
        XCTAssertEqual(store.savedModes, [])
    }

    func testExplicitDefaultChangePersistsOnlyDefault() {
        let store = MemoryLaunchDefaultModeStore(storedMode: .together)
        let core = AppModeCore(store: store)
        core.select(.pinball, persistAsLaunchDefault: false)

        core.setLaunchDefault(.pinball)

        XCTAssertEqual(core.currentMode, .pinball)
        XCTAssertEqual(core.launchDefaultMode, .pinball)
        XCTAssertEqual(store.savedModes, [.pinball])
    }

    func testOlderSavedDefaultMigratesOnceToChooserThenAllowsANewExplicitDefault() throws {
        let suiteName = "AppModeCoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(AppMode.pinball.rawValue, forKey: "launch-mode")
        let store = UserDefaultsLaunchDefaultModeStore(
            defaults: defaults,
            key: "launch-mode",
            migrationKey: "launch-mode-migration"
        )

        XCTAssertEqual(store.loadLaunchDefaultMode(), .together)
        XCTAssertEqual(defaults.string(forKey: "launch-mode"), AppMode.together.rawValue)
        XCTAssertEqual(
            defaults.integer(forKey: "launch-mode-migration"),
            UserDefaultsLaunchDefaultModeStore.currentMigrationVersion
        )

        store.saveLaunchDefaultMode(.tapIn)
        XCTAssertEqual(store.loadLaunchDefaultMode(), .tapIn)
    }

    func testCompletedLaunchDefaultMigrationPreservesAUsersLaterSelection() throws {
        let suiteName = "AppModeCoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(AppMode.pinball.rawValue, forKey: "launch-mode")
        defaults.set(
            UserDefaultsLaunchDefaultModeStore.currentMigrationVersion,
            forKey: "launch-mode-migration"
        )
        let store = UserDefaultsLaunchDefaultModeStore(
            defaults: defaults,
            key: "launch-mode",
            migrationKey: "launch-mode-migration"
        )

        XCTAssertEqual(store.loadLaunchDefaultMode(), .pinball)
    }

    func testInvalidMigratedPreferenceFallsBackToChooser() throws {
        let suiteName = "AppModeCoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set("not-a-mode", forKey: "launch-mode")
        defaults.set(
            UserDefaultsLaunchDefaultModeStore.currentMigrationVersion,
            forKey: "launch-mode-migration"
        )
        let store = UserDefaultsLaunchDefaultModeStore(
            defaults: defaults,
            key: "launch-mode",
            migrationKey: "launch-mode-migration"
        )

        XCTAssertNil(store.loadLaunchDefaultMode())
        let invalidPreferenceCore = AppModeCore(store: store)
        XCTAssertEqual(invalidPreferenceCore.currentMode, .together)
        XCTAssertEqual(invalidPreferenceCore.launchDefaultMode, .together)
    }

    func testModeEventsAnnounceOnlySessionModeChanges() {
        let store = MemoryLaunchDefaultModeStore(storedMode: .together)
        var events: [AppModeCoreEvent] = []
        let core = AppModeCore(store: store) { events.append($0) }

        core.select(.tapIn, persistAsLaunchDefault: false)
        core.setLaunchDefault(.tapIn)

        XCTAssertTrue(events.contains(.accessibilityAnnouncement(.init("Tap In mode."))))
        XCTAssertEqual(
            events.filter {
                if case .accessibilityAnnouncement = $0 { return true }
                return false
            }.count,
            1
        )
    }
}
