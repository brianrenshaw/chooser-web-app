import Foundation
import XCTest
@testable import App

@MainActor
final class AppModeCoreTests: XCTestCase {
    func testPersistedModeBecomesCurrentAndLaunchDefault() {
        let store = MemoryLaunchDefaultModeStore(storedMode: .pinball)
        let core = AppModeCore(store: store)

        XCTAssertEqual(core.currentMode, .pinball)
        XCTAssertEqual(core.launchDefaultMode, .pinball)
        XCTAssertEqual(store.savedModes, [])
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

    func testLongPressStyleDefaultChangePersistsOnlyDefault() {
        let store = MemoryLaunchDefaultModeStore(storedMode: .together)
        let core = AppModeCore(store: store)
        core.select(.pinball, persistAsLaunchDefault: false)

        core.setLaunchDefault(.pinball)

        XCTAssertEqual(core.currentMode, .pinball)
        XCTAssertEqual(core.launchDefaultMode, .pinball)
        XCTAssertEqual(store.savedModes, [.pinball])
    }

    func testFallbackAndUserDefaultsRoundTrip() throws {
        let suiteName = "AppModeCoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsLaunchDefaultModeStore(defaults: defaults, key: "launch-mode")
        XCTAssertNil(store.loadLaunchDefaultMode())

        store.saveLaunchDefaultMode(.tapIn)
        XCTAssertEqual(store.loadLaunchDefaultMode(), .tapIn)

        defaults.set("not-a-mode", forKey: "launch-mode")
        XCTAssertNil(store.loadLaunchDefaultMode())
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
