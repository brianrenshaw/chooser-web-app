import CoreGraphics
import XCTest
@testable import App

@MainActor
final class ChooserAppModelOnboardingTests: XCTestCase {
    private func makeModel(
        mode: AppMode = .together,
        seen: Set<OnboardingMoment> = [],
        onboardingStore: MemoryOnboardingProgressStore? = nil,
        tapInCore: TapInChooserCore = TapInChooserCore(),
        feedback: RecordingFeedbackCoordinator = RecordingFeedbackCoordinator()
    ) -> (ChooserAppModel, MemoryOnboardingProgressStore, RecordingFeedbackCoordinator) {
        // Anyone who has seen the welcome has, in a 1.1 world, also met this
        // release's note — it is presented immediately after the welcome and
        // before any mode card. Seeding it keeps these tests about the thing
        // they are actually testing instead of re-asserting the note's
        // precedence eleven times over. `ChooserAppModelWhatsNewTests` owns
        // that precedence.
        var seen = seen
        if seen.contains(.welcome) {
            seen.insert(.whatsNew(release: OnboardingMoment.currentWhatsNewRelease))
        }
        let store = onboardingStore ?? MemoryOnboardingProgressStore(storedMoments: seen)
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: mode),
            onboardingStore: store,
            tapInCore: tapInCore,
            feedback: feedback
        )
        return (model, store, feedback)
    }

    // MARK: - First launch

    func testFirstLaunchPresentsTheWelcomeBeforeAnyModeCard() {
        let (model, store, _) = makeModel()

        model.startOnboardingIfNeeded()

        XCTAssertEqual(model.presentedOnboarding, .welcome)
        // Presenting is not progress; nothing is written until it is retired.
        XCTAssertTrue(store.savedMomentSets.isEmpty)
    }

    func testCompletingTheWelcomeAlsoRetiresTheCardForTheModeOnScreen() {
        let (model, store, _) = makeModel()
        model.startOnboardingIfNeeded()

        model.completeOnboarding()

        XCTAssertNil(model.presentedOnboarding)
        // Finishing the welcome also retires this release's note, so a first
        // time user is not handed "what's new" about a version they started on.
        XCTAssertEqual(
            store.storedMoments,
            [.welcome, .modeCard(.together), .whatsNew(release: OnboardingMoment.currentWhatsNewRelease)]
        )
        // One user action is exactly one write.
        XCTAssertEqual(
            store.savedMomentSets,
            [[.welcome, .modeCard(.together), .whatsNew(release: OnboardingMoment.currentWhatsNewRelease)]]
        )
    }

    func testSkippingTheWelcomeWritesTheSameProgressAsFinishingIt() {
        let (finished, finishedStore, _) = makeModel()
        finished.startOnboardingIfNeeded()
        finished.completeOnboarding()

        let (skipped, skippedStore, _) = makeModel()
        skipped.startOnboardingIfNeeded()
        skipped.skipOnboarding()

        XCTAssertEqual(finishedStore.storedMoments, skippedStore.storedMoments)
        XCTAssertEqual(finishedStore.savedMomentSets.count, skippedStore.savedMomentSets.count)
        XCTAssertNil(skipped.presentedOnboarding)
    }

    func testWelcomeCompletionPlaysTheConfirmationCue() {
        let feedback = RecordingFeedbackCoordinator()
        let (model, _, _) = makeModel(feedback: feedback)
        model.startOnboardingIfNeeded()
        feedback.removeAllCues()

        model.completeOnboarding()

        XCTAssertEqual(feedback.cues, [.confirmation])
    }

    // MARK: - Per-mode cards

    func testOpeningASecondModeShowsItsCardExactlyOnce() {
        let (model, store, _) = makeModel(seen: [.welcome, .modeCard(.together)])

        model.requestModeChange(to: .tapIn)
        XCTAssertEqual(model.presentedOnboarding, .modeCard(.tapIn))

        model.completeOnboarding()
        XCTAssertEqual(
            store.storedMoments,
            [
                .welcome,
                .modeCard(.together),
                .modeCard(.tapIn),
                .whatsNew(release: OnboardingMoment.currentWhatsNewRelease)
            ]
        )

        model.requestModeChange(to: .pinball)
        model.completeOnboarding()
        model.requestModeChange(to: .tapIn)
        XCTAssertNil(model.presentedOnboarding)
    }

    func testTheLaunchModeStillGetsItsCardWhenTheWelcomeWasAlreadySeen() {
        // The shape an upgrading 1.0 user lands in after finishing the welcome
        // on a launch default other than Chooser.
        let (model, _, _) = makeModel(mode: .pinball, seen: [.welcome])

        model.startOnboardingIfNeeded()

        XCTAssertEqual(model.presentedOnboarding, .modeCard(.pinball))
    }

    func testAFullySeenOnboardingNeverPresentsOrWritesAgain() {
        let (model, store, _) = makeModel(seen: Set(OnboardingMoment.allIncludingCurrentWhatsNew))

        model.startOnboardingIfNeeded()
        XCTAssertNil(model.presentedOnboarding)

        model.requestModeChange(to: .tapIn)
        XCTAssertNil(model.presentedOnboarding)

        model.requestModeChange(to: .pinball)
        XCTAssertNil(model.presentedOnboarding)

        XCTAssertTrue(store.savedMomentSets.isEmpty)
    }

    func testABoardTouchDismissesAVisibleModeCard() {
        let (model, store, _) = makeModel(mode: .tapIn, seen: [.welcome])
        model.startOnboardingIfNeeded()
        XCTAssertEqual(model.presentedOnboarding, .modeCard(.tapIn))

        model.tapInTouchBegan(.init(id: 4, location: CGPoint(x: 100, y: 140)))

        XCTAssertNil(model.presentedOnboarding)
        XCTAssertEqual(
            store.storedMoments,
            [.welcome, .modeCard(.tapIn), .whatsNew(release: OnboardingMoment.currentWhatsNewRelease)]
        )
    }

    // MARK: - Deep links

    func testAShortcutModeChangeDuringTheWelcomeRetiresTheDeliveredMode() {
        let (model, store, _) = makeModel()
        model.startOnboardingIfNeeded()

        // The App Shortcut lands while the welcome is up.
        model.requestModeChange(to: .pinball)

        XCTAssertEqual(model.presentedOnboarding, .welcome, "the welcome must not be replaced")
        XCTAssertEqual(model.mode, .pinball, "the shortcut must still be honoured")

        model.completeOnboarding()
        XCTAssertEqual(
            store.storedMoments,
            [.welcome, .modeCard(.pinball), .whatsNew(release: OnboardingMoment.currentWhatsNewRelease)]
        )

        // Chooser was never actually shown, so it still earns its card.
        model.requestModeChange(to: .together)
        XCTAssertEqual(model.presentedOnboarding, .modeCard(.together))
    }

    func testAModeArrivingBeforeTheFirstAppearanceStillShowsTheWelcomeFirst() {
        let (model, _, _) = makeModel()

        // The other cold-launch ordering: .onOpenURL wins the race with .task.
        model.requestModeChange(to: .tapIn)
        XCTAssertEqual(model.presentedOnboarding, .welcome)

        model.startOnboardingIfNeeded()
        XCTAssertEqual(model.presentedOnboarding, .welcome)
        XCTAssertEqual(model.mode, .tapIn)
    }

    func testOnboardingBlocksSettingsButNeverAShortcutModeChange() {
        let (model, _, _) = makeModel()
        model.startOnboardingIfNeeded()

        XCTAssertFalse(model.isSettingsEnabled)
        XCTAssertFalse(model.prepareToPresentSettings())

        // Gating this would silently swallow App Shortcut deep links.
        XCTAssertTrue(model.isModeChangeEnabled)
        model.requestModeChange(to: .pinball)
        XCTAssertEqual(model.mode, .pinball)
    }

    // MARK: - Lifecycle and guards

    func testBackgroundingKeepsTheWelcomeOnScreen() {
        let (model, store, _) = makeModel()
        model.startOnboardingIfNeeded()

        model.handleSceneBecameInactive()

        XCTAssertEqual(model.presentedOnboarding, .welcome)
        XCTAssertTrue(store.savedMomentSets.isEmpty)
    }

    func testACriticalInteractionNeverLetsOnboardingCoverTheDraw() {
        let scheduler = ManualChooserScheduler()
        let (model, store, _) = makeModel(
            mode: .tapIn,
            seen: [.welcome],
            tapInCore: TapInChooserCore(scheduler: scheduler)
        )
        // Show and retire the Tap In card first, so the only thing that could
        // still present during the countdown is a card this test must block.
        model.startOnboardingIfNeeded()
        XCTAssertEqual(model.presentedOnboarding, .modeCard(.tapIn))
        model.completeOnboarding()

        XCTAssertTrue(model.addTapInEntryForAccessibility())
        XCTAssertTrue(model.addTapInEntryForAccessibility())
        model.pickTapIn()
        XCTAssertEqual(model.tapInSnapshot.phase, .countdown)
        XCTAssertTrue(model.isCriticalInteractionActive)

        // A replay arriving mid-draw must be refused, not queued.
        model.requestWelcomeReplay()
        model.presentWelcomeReplayIfRequested()
        model.startOnboardingIfNeeded()

        XCTAssertNil(model.presentedOnboarding)
        XCTAssertEqual(store.savedMomentSets.count, 1, "only the card completion above")
    }

    // MARK: - Replay

    func testReplayingTheWelcomeFromSettingsWritesNothingAndRestoresNoModeCards() {
        let (model, store, _) = makeModel(seen: Set(OnboardingMoment.allIncludingCurrentWhatsNew))

        model.requestWelcomeReplay()
        model.presentWelcomeReplayIfRequested()
        XCTAssertEqual(model.presentedOnboarding, .welcome)

        model.completeOnboarding()

        XCTAssertNil(model.presentedOnboarding)
        XCTAssertTrue(store.savedMomentSets.isEmpty, "a replay must be free of side effects")

        // The per-mode cards stay retired.
        model.requestModeChange(to: .tapIn)
        XCTAssertNil(model.presentedOnboarding)
    }

    func testAReplayRequestIsConsumedExactlyOnce() {
        let (model, _, _) = makeModel(seen: Set(OnboardingMoment.allIncludingCurrentWhatsNew))

        model.requestWelcomeReplay()
        model.presentWelcomeReplayIfRequested()
        model.completeOnboarding()

        model.presentWelcomeReplayIfRequested()
        XCTAssertNil(model.presentedOnboarding)
    }

    func testAReplayIsRefusedWhileAnotherIntroductionIsShowing() {
        let (model, _, _) = makeModel()
        model.startOnboardingIfNeeded()

        model.requestWelcomeReplay()
        model.presentWelcomeReplayIfRequested()

        XCTAssertEqual(model.presentedOnboarding, .welcome)
    }

    func testThePresentedModeIntroPageTracksTheShowingCard() {
        let (model, _, _) = makeModel(mode: .pinball, seen: [.welcome])
        model.startOnboardingIfNeeded()

        XCTAssertEqual(model.presentedModeIntroPage, .pinball)

        model.completeOnboarding()
        XCTAssertNil(model.presentedModeIntroPage)
    }

    func testTheWelcomeIsNotReportedAsAModeIntroPage() {
        let (model, _, _) = makeModel()
        model.startOnboardingIfNeeded()

        XCTAssertEqual(model.presentedOnboarding, .welcome)
        XCTAssertNil(model.presentedModeIntroPage)
    }
}

/// The release note is for people who already know the app.
///
/// The distinction it depends on — upgrade versus fresh install — is only
/// available because `loadSeenMoments` is a pure read. The launch-default-mode
/// store writes during its own read to perform a migration, which is precisely
/// why that key cannot tell the two apart.
@MainActor
final class ChooserAppModelWhatsNewTests: XCTestCase {

    private var currentWhatsNew: OnboardingMoment {
        .whatsNew(release: OnboardingMoment.currentWhatsNewRelease)
    }

    private func makeModel(
        seen: Set<OnboardingMoment>
    ) -> (ChooserAppModel, MemoryOnboardingProgressStore, RecordingFeedbackCoordinator) {
        let store = MemoryOnboardingProgressStore(storedMoments: seen)
        let feedback = RecordingFeedbackCoordinator()
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .together),
            onboardingStore: store,
            feedback: feedback
        )
        return (model, store, feedback)
    }

    func testAFreshInstallSeesTheWelcomeAndNeverTheReleaseNote() {
        let (model, store, _) = makeModel(seen: [])
        model.startOnboardingIfNeeded()
        XCTAssertEqual(model.presentedOnboarding, .welcome)

        model.completeOnboarding()
        // Finishing the welcome retires this release's note in the same write:
        // someone meeting the app on 1.1 has nothing to catch up on.
        XCTAssertTrue(store.storedMoments.contains(currentWhatsNew))

        model.startOnboardingIfNeeded()
        XCTAssertNil(model.presentedOnboarding)
    }

    func testAnUpgraderSeesTheReleaseNoteOnce() {
        let (model, store, _) = makeModel(seen: Set(OnboardingMoment.all))
        model.startOnboardingIfNeeded()
        XCTAssertEqual(model.presentedOnboarding, currentWhatsNew)

        model.completeOnboarding()
        XCTAssertNil(model.presentedOnboarding)
        XCTAssertTrue(store.storedMoments.contains(currentWhatsNew))

        model.startOnboardingIfNeeded()
        XCTAssertNil(model.presentedOnboarding, "the note must not return")
    }

    func testTheWelcomeStillOutranksTheReleaseNote() {
        let (model, _, _) = makeModel(seen: [currentWhatsNew])
        model.startOnboardingIfNeeded()
        XCTAssertEqual(model.presentedOnboarding, .welcome)
    }

    func testAFutureReleaseNoteIsADifferentMoment() {
        let (model, _, _) = makeModel(
            seen: Set(OnboardingMoment.all).union([.whatsNew(release: "1.0")])
        )
        model.startOnboardingIfNeeded()
        XCTAssertEqual(
            model.presentedOnboarding,
            currentWhatsNew,
            "a note stored for an older release must not satisfy this one"
        )
    }

    func testTheReleaseTokenRoundTrips() {
        let moment = OnboardingMoment.whatsNew(release: "1.1")
        XCTAssertEqual(moment.persistenceToken, "whatsNew.1.1")
        XCTAssertEqual(OnboardingMoment(persistenceToken: "whatsNew.1.1"), moment)
        XCTAssertNil(OnboardingMoment(persistenceToken: "whatsNew."))
    }

    /// `all` means "has seen the introduction". A release note is not part of
    /// an introduction, and folding it in would silently change what every test
    /// seeding `all` is asserting about.
    func testAllExcludesTheReleaseNote() {
        XCTAssertFalse(OnboardingMoment.all.contains(currentWhatsNew))
        XCTAssertTrue(OnboardingMoment.allIncludingCurrentWhatsNew.contains(currentWhatsNew))
    }
}
