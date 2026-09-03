import CoreGraphics
import UIKit
import XCTest
@testable import App

@MainActor
final class ThemeShuffleTests: XCTestCase {
    func testRandomThemeCandidatesExcludeCurrentThemeAndCoverEveryOtherTheme() {
        let original = ChooserColorTheme.wingspanOriginal
        let expectedCandidates = ChooserColorTheme.allCases.filter { $0 != original }
        var selectedThemes: [ChooserColorTheme] = []

        for index in expectedCandidates.indices {
            let generator = RecordingThemeIndexGenerator(index: index)
            let store = MemoryChooserColorThemeStore(storedTheme: original)
            let model = ChooserAppModel(
                modeStore: MemoryLaunchDefaultModeStore(storedMode: .together),
                colorThemeStore: store,
                colorThemeRandomIndexGenerator: generator,
                feedback: NativeNoopFeedbackCoordinator()
            )

            XCTAssertTrue(model.randomizeColorTheme())
            XCTAssertEqual(generator.upperBounds, [expectedCandidates.count])
            XCTAssertEqual(store.savedThemes, [expectedCandidates[index]])
            XCTAssertNotEqual(model.colorTheme, original)
            selectedThemes.append(model.colorTheme)
        }

        XCTAssertEqual(selectedThemes, expectedCandidates)
    }

    func testRandomThemePreservesModeCommittedGroupAndResultState() {
        let scheduler = ManualChooserScheduler()
        let store = MemoryChooserColorThemeStore(storedTheme: .wingspanOriginal)
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .tapIn),
            colorThemeStore: store,
            tapInCore: TapInChooserCore(
                scheduler: scheduler,
                randomIndexGenerator: FixedRandomIndexGenerator(index: 1)
            ),
            colorThemeRandomIndexGenerator: FixedRandomIndexGenerator(index: 2),
            feedback: NativeNoopFeedbackCoordinator()
        )
        XCTAssertTrue(model.addTapInEntryForAccessibility())
        XCTAssertTrue(model.addTapInEntryForAccessibility())
        XCTAssertTrue(model.addTapInEntryForAccessibility())
        model.pickTapIn()
        scheduler.advance(by: 1)

        let entries = model.tapInSnapshot.entries
        let winner = model.tapInSnapshot.winner
        XCTAssertNotNil(winner)
        XCTAssertTrue(model.randomizeColorTheme())

        XCTAssertEqual(model.mode, .tapIn)
        XCTAssertEqual(model.tapInSnapshot.entries, entries)
        XCTAssertEqual(model.tapInSnapshot.winner, winner)
        XCTAssertEqual(store.savedThemes, [model.colorTheme])
        XCTAssertNil(model.toastMessage)
    }

    func testPhysicalShuffleRestoresAndPreservesRevealedChooserResult() {
        let scheduler = ManualChooserScheduler()
        let store = MemoryChooserColorThemeStore(storedTheme: .wingspanOriginal)
        let feedback = RecordingFeedbackCoordinator()
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .together),
            colorThemeStore: store,
            togetherCore: TogetherChooserCore(
                scheduler: scheduler,
                randomIndexGenerator: FixedRandomIndexGenerator(index: 1)
            ),
            colorThemeRandomIndexGenerator: FixedRandomIndexGenerator(index: 0),
            feedback: feedback
        )
        model.togetherTouchBegan(.init(id: 1, location: CGPoint(x: 80, y: 180)))
        model.togetherTouchBegan(.init(id: 2, location: CGPoint(x: 260, y: 180)))
        scheduler.advance(
            by: TogetherTiming.defaultSettlingDuration +
                ChoiceAnticipationTimeline.chooser.duration
        )

        let revealedSnapshot = model.togetherSnapshot
        let revealedVisuals = model.togetherVisuals
        XCTAssertNotNil(revealedSnapshot.winner)
        let winnerCueCount = feedback.cues.filter { $0 == .chooserWinner }.count

        for id in 10...12 {
            model.togetherTouchBegan(
                .init(
                    id: UInt64(id),
                    location: CGPoint(x: CGFloat(40 * id), y: 280)
                )
            )
        }
        for id in 10...12 {
            model.togetherTouchEnded(
                .init(
                    id: UInt64(id),
                    location: CGPoint(x: CGFloat(40 * id), y: 280)
                ),
                cancelled: true
            )
        }

        XCTAssertEqual(model.togetherSnapshot.phase, .idle)
        XCTAssertTrue(model.randomizeColorThemeAfterPhysicalGesture())
        XCTAssertEqual(model.togetherSnapshot, revealedSnapshot)
        XCTAssertEqual(model.togetherVisuals, revealedVisuals)
        XCTAssertEqual(
            feedback.cues.filter { $0 == .chooserWinner }.count,
            winnerCueCount,
            "Restoring a displayed result must not replay winner feedback"
        )
        XCTAssertEqual(store.savedThemes, [model.colorTheme])
    }

    func testOrdinaryTouchAfterChooserResultDoesNotRestoreOldResult() {
        let scheduler = ManualChooserScheduler()
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .together),
            togetherCore: TogetherChooserCore(
                scheduler: scheduler,
                randomIndexGenerator: FixedRandomIndexGenerator(index: 0)
            ),
            colorThemeRandomIndexGenerator: FixedRandomIndexGenerator(index: 0),
            feedback: NativeNoopFeedbackCoordinator()
        )
        model.togetherTouchBegan(.init(id: 1, location: CGPoint(x: 80, y: 180)))
        model.togetherTouchBegan(.init(id: 2, location: CGPoint(x: 260, y: 180)))
        scheduler.advance(
            by: TogetherTiming.defaultSettlingDuration +
                ChoiceAnticipationTimeline.chooser.duration
        )
        XCTAssertNotNil(model.togetherSnapshot.winner)

        let ordinaryTouch = NativeTouchEvent(id: 10, location: CGPoint(x: 170, y: 260))
        model.togetherTouchBegan(ordinaryTouch)
        model.togetherTouchEnded(ordinaryTouch, cancelled: false)

        XCTAssertTrue(model.randomizeColorThemeAfterPhysicalGesture())
        XCTAssertEqual(model.togetherSnapshot.phase, .idle)
        XCTAssertNil(model.togetherSnapshot.winner)
    }

    func testNativeHowItWorksIncludesThemeShuffleShortcut() {
        let copy = NativeOfflineInformationCopy.chooser(version: "1.0 (18)")
        XCTAssertTrue(
            copy.helpSections
                .flatMap(\.paragraphs)
                .contains("Three-finger tap anywhere to shuffle the colors.")
        )
    }

    func testRandomThemeRejectsProvisionalCriticalInactiveAndConfirmationStates() {
        let provisionalTogether = makeModel(mode: .together)
        provisionalTogether.togetherTouchBegan(
            .init(id: 1, location: CGPoint(x: 80, y: 120))
        )
        XCTAssertFalse(provisionalTogether.canRandomizeColorTheme)
        XCTAssertFalse(provisionalTogether.randomizeColorTheme())

        let provisionalTapIn = makeModel(mode: .tapIn)
        provisionalTapIn.tapInTouchBegan(
            .init(id: 1, location: CGPoint(x: 80, y: 120))
        )
        XCTAssertFalse(provisionalTapIn.canRandomizeColorTheme)
        provisionalTapIn.tapInTouchEnded(
            .init(id: 1, location: CGPoint(x: 80, y: 120)),
            cancelled: true
        )
        XCTAssertTrue(provisionalTapIn.canRandomizeColorTheme)

        let tapInCountdown = makeModel(mode: .tapIn)
        XCTAssertTrue(tapInCountdown.addTapInEntryForAccessibility())
        XCTAssertTrue(tapInCountdown.addTapInEntryForAccessibility())
        tapInCountdown.pickTapIn()
        XCTAssertFalse(tapInCountdown.canRandomizeColorTheme)

        let confirmation = makeModel(mode: .tapIn)
        XCTAssertTrue(confirmation.addTapInEntryForAccessibility())
        confirmation.requestClearTapIn()
        XCTAssertNotNil(confirmation.confirmation)
        XCTAssertFalse(confirmation.canRandomizeColorTheme)

        let inactive = makeModel(mode: .together)
        inactive.handleSceneBecameInactive()
        XCTAssertFalse(inactive.canRandomizeColorTheme)
        inactive.handleSceneBecameActive()
        XCTAssertTrue(inactive.canRandomizeColorTheme)
    }

    func testRandomThemeRejectsInvalidGeneratorOutputWithoutMutation() {
        let store = MemoryChooserColorThemeStore(storedTheme: .leaders)
        let model = ChooserAppModel(
            colorThemeStore: store,
            colorThemeRandomIndexGenerator: FixedRandomIndexGenerator(index: 99),
            feedback: NativeNoopFeedbackCoordinator()
        )

        XCTAssertFalse(model.randomizeColorTheme())
        XCTAssertEqual(model.colorTheme, .leaders)
        XCTAssertTrue(store.savedThemes.isEmpty)
    }

    func testWindowCoordinatorInstallsExactlyOneConfiguredDirectTouchRecognizer() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let coordinator = NativeThreeFingerThemeShuffleCoordinator()
        coordinator.update(isEnabled: true, voiceOverRunning: false, onRecognized: {})

        coordinator.install(on: window)
        coordinator.install(on: window)

        let recognizer = coordinator.gestureRecognizer
        XCTAssertTrue(coordinator.installedWindow === window)
        XCTAssertEqual(window.gestureRecognizers?.filter { $0 === recognizer }.count, 1)
        XCTAssertEqual(recognizer.numberOfTapsRequired, 1)
        XCTAssertEqual(recognizer.numberOfTouchesRequired, 3)
        XCTAssertEqual(
            recognizer.allowedTouchTypes,
            [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        )
        XCTAssertTrue(recognizer.cancelsTouchesInView)
        XCTAssertFalse(recognizer.delaysTouchesBegan)
        XCTAssertTrue(recognizer.delaysTouchesEnded)

        coordinator.uninstall()
        XCTAssertNil(coordinator.installedWindow)
        XCTAssertFalse(window.gestureRecognizers?.contains { $0 === recognizer } ?? false)
    }

    func testWindowCoordinatorDisablesPhysicalGestureForVoiceOver() {
        let coordinator = NativeThreeFingerThemeShuffleCoordinator()
        coordinator.update(isEnabled: true, voiceOverRunning: true, onRecognized: {})
        XCTAssertFalse(coordinator.gestureRecognizer.isEnabled)

        coordinator.update(isEnabled: true, voiceOverRunning: false, onRecognized: {})
        XCTAssertTrue(coordinator.gestureRecognizer.isEnabled)

        coordinator.update(isEnabled: false, voiceOverRunning: false, onRecognized: {})
        XCTAssertFalse(coordinator.gestureRecognizer.isEnabled)
    }

    private func makeModel(mode: AppMode) -> ChooserAppModel {
        ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: mode),
            colorThemeStore: MemoryChooserColorThemeStore(
                storedTheme: .wingspanOriginal
            ),
            colorThemeRandomIndexGenerator: FixedRandomIndexGenerator(index: 0),
            feedback: NativeNoopFeedbackCoordinator()
        )
    }
}

private final class RecordingThemeIndexGenerator: RandomIndexGenerating {
    let index: Int
    private(set) var upperBounds: [Int] = []

    init(index: Int) {
        self.index = index
    }

    func randomIndex(upperBound: Int) throws -> Int {
        upperBounds.append(upperBound)
        return index
    }
}
