import XCTest
@testable import App

@MainActor
final class OnboardingProgressTests: XCTestCase {
    private let key = "onboarding"
    private let versionKey = "onboarding-version"

    private func makeDefaults() throws -> (UserDefaults, String) {
        let suiteName = "OnboardingProgressTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        return (defaults, suiteName)
    }

    private func makeStore(_ defaults: UserDefaults) -> UserDefaultsOnboardingProgressStore {
        UserDefaultsOnboardingProgressStore(
            defaults: defaults,
            key: key,
            versionKey: versionKey
        )
    }

    /// The launch-default store writes during its read, which is why a brand
    /// new install cannot be told apart from an upgraded one using that key.
    /// This store must never acquire the same defect.
    func testAFreshInstallReportsNothingSeenWithoutWritingAnyDefault() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = makeStore(defaults)

        XCTAssertTrue(store.loadSeenMoments().isEmpty)
        XCTAssertTrue(store.loadSeenMoments().isEmpty)

        XCTAssertNil(defaults.object(forKey: key))
        XCTAssertNil(defaults.object(forKey: versionKey))
    }

    func testSavingProgressWritesSortedTokensAndTheCurrentVersion() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = makeStore(defaults)

        store.saveSeenMoments([.welcome, .modeCard(.pinball)])

        XCTAssertEqual(defaults.stringArray(forKey: key), ["mode.pinball", "welcome"])
        XCTAssertEqual(
            defaults.integer(forKey: versionKey),
            UserDefaultsOnboardingProgressStore.currentOnboardingVersion
        )
    }

    func testStoredProgressSurvivesANewStoreInstance() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        makeStore(defaults).saveSeenMoments([.welcome, .modeCard(.tapIn)])

        XCTAssertEqual(
            makeStore(defaults).loadSeenMoments(),
            [.welcome, .modeCard(.tapIn)]
        )
    }

    func testAnOlderOnboardingVersionRetiresEveryStoredMoment() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(["welcome", "mode.together"], forKey: key)
        defaults.set(0, forKey: versionKey)

        XCTAssertTrue(makeStore(defaults).loadSeenMoments().isEmpty)
        // Still a pure read: the stale values are left exactly as they were.
        XCTAssertEqual(defaults.integer(forKey: versionKey), 0)
        XCTAssertEqual(defaults.stringArray(forKey: key), ["welcome", "mode.together"])
    }

    func testAFutureOnboardingVersionKeepsStoredProgress() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(["welcome"], forKey: key)
        defaults.set(
            UserDefaultsOnboardingProgressStore.currentOnboardingVersion + 1,
            forKey: versionKey
        )

        XCTAssertEqual(makeStore(defaults).loadSeenMoments(), [.welcome])
    }

    func testUnknownStoredTokensAreIgnored() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(["welcome", "mode.telepathy", "nonsense"], forKey: key)
        defaults.set(
            UserDefaultsOnboardingProgressStore.currentOnboardingVersion,
            forKey: versionKey
        )

        XCTAssertEqual(makeStore(defaults).loadSeenMoments(), [.welcome])
    }

    func testEveryMomentRoundTripsThroughItsPersistenceToken() {
        XCTAssertEqual(OnboardingMoment.all.count, 1 + AppMode.allCases.count)
        for moment in OnboardingMoment.all {
            XCTAssertEqual(
                OnboardingMoment(persistenceToken: moment.persistenceToken),
                moment
            )
        }
        XCTAssertEqual(OnboardingMoment.welcome.persistenceToken, "welcome")
        XCTAssertEqual(OnboardingMoment.modeCard(.together).persistenceToken, "mode.together")
        XCTAssertEqual(OnboardingMoment.modeCard(.tapIn).persistenceToken, "mode.tapIn")
        XCTAssertEqual(OnboardingMoment.modeCard(.pinball).persistenceToken, "mode.pinball")
    }

    func testEveryWelcomePageMatchesACopyDeckModeIdentifier() {
        let copy = NativeOfflineInformationCopy.chooser(version: "1.1")
        for page in NativeWelcomePage.allCases {
            let instructions = copy.modes.first { $0.id == page.rawValue }
            XCTAssertNotNil(instructions, "no copy for welcome page \(page.rawValue)")
            XCTAssertFalse(instructions?.welcomeLine.isEmpty ?? true)
        }
        for mode in AppMode.allCases {
            XCTAssertEqual(NativeWelcomePage(mode: mode).rawValue, {
                switch mode {
                case .together: "together"
                case .tapIn: "tap-in"
                case .pinball: "pinball"
                }
            }())
        }
    }
}
