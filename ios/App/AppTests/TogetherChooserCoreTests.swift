import XCTest
@testable import App

@MainActor
final class TogetherChooserCoreTests: XCTestCase {
    private let settlingDuration = TogetherTiming.defaultSettlingDuration
    private let first = TogetherTouchIdentity(rawValue: 101)
    private let second = TogetherTouchIdentity(rawValue: 202)
    private let third = TogetherTouchIdentity(rawValue: 303)

    func testTwoTouchesSettleCountDownAndRevealExactlyOneStoredIdentity() {
        let scheduler = ManualChooserScheduler()
        let core = TogetherChooserCore(
            scheduler: scheduler,
            randomIndexGenerator: FixedRandomIndexGenerator(index: 1)
        )

        XCTAssertTrue(core.touchBegan(first))
        XCTAssertEqual(core.phase, .idle)
        XCTAssertTrue(core.touchBegan(second))
        XCTAssertEqual(core.phase, .settling)

        scheduler.advance(by: settlingDuration - 0.001)
        XCTAssertEqual(core.phase, .settling)
        scheduler.advance(by: 0.002)
        XCTAssertEqual(core.phase, .countdown)
        scheduler.advance(by: ChoiceAnticipationTimeline.chooser.duration)

        XCTAssertEqual(core.phase, .revealed(winner: second))
        XCTAssertEqual(core.snapshot.winner, second)
        XCTAssertEqual(core.snapshot.participantTouchIDs, [first, second])
    }

    func testDuplicateTouchIdentityNeverCreatesAnotherParticipant() {
        let core = TogetherChooserCore(scheduler: ManualChooserScheduler())

        XCTAssertTrue(core.touchBegan(first))
        XCTAssertFalse(core.touchBegan(first))
        XCTAssertEqual(core.snapshot.participantTouchIDs, [first])
        XCTAssertFalse(core.touchEnded(TogetherTouchIdentity(rawValue: 999)))
    }

    func testLateAdditionRestartsFullSettlingWindow() {
        let scheduler = ManualChooserScheduler()
        let core = TogetherChooserCore(scheduler: scheduler)
        core.touchBegan(first)
        core.touchBegan(second)
        scheduler.advance(by: settlingDuration * 0.6)

        core.touchBegan(third)
        scheduler.advance(by: settlingDuration * 0.4)
        XCTAssertEqual(core.phase, .settling, "The canceled first timer must not start countdown")
        scheduler.advance(by: settlingDuration * 0.6 - 0.001)
        XCTAssertEqual(core.phase, .settling)
        scheduler.advance(by: 0.002)
        XCTAssertEqual(core.phase, .countdown)
    }

    func testRemovalWhileSettlingRestartsForRemainingPair() {
        let scheduler = ManualChooserScheduler()
        let core = TogetherChooserCore(scheduler: scheduler)
        core.touchBegan(first)
        core.touchBegan(second)
        core.touchBegan(third)
        scheduler.advance(by: settlingDuration * 0.6)

        XCTAssertTrue(core.touchEnded(third))
        scheduler.advance(by: settlingDuration * 0.4)
        XCTAssertEqual(core.phase, .settling)
        scheduler.advance(by: settlingDuration * 0.6)
        XCTAssertEqual(core.phase, .countdown)
        XCTAssertEqual(core.snapshot.participantTouchIDs, [first, second])
    }

    func testRemovalDuringCountdownSamplesOnlyRemainingIdentities() {
        let scheduler = ManualChooserScheduler()
        let core = TogetherChooserCore(
            scheduler: scheduler,
            randomIndexGenerator: FixedRandomIndexGenerator(index: 1)
        )
        core.touchBegan(first)
        core.touchBegan(second)
        core.touchBegan(third)
        scheduler.advance(by: settlingDuration)
        XCTAssertEqual(core.phase, .countdown)

        core.touchEnded(second)
        XCTAssertEqual(core.snapshot.participantTouchIDs, [first, third])
        XCTAssertEqual(core.phase, .countdown)
        scheduler.advance(by: ChoiceAnticipationTimeline.chooser.duration)
        XCTAssertEqual(core.phase, .revealed(winner: third))
    }

    func testDroppingBelowTwoCancelsPendingChoice() {
        let scheduler = ManualChooserScheduler()
        let core = TogetherChooserCore(scheduler: scheduler)
        core.touchBegan(first)
        core.touchBegan(second)
        scheduler.advance(by: settlingDuration)
        XCTAssertEqual(core.phase, .countdown)

        core.touchCancelled(second)
        XCTAssertEqual(core.phase, .idle)
        scheduler.advance(by: 10)
        XCTAssertEqual(core.phase, .idle)
        XCTAssertEqual(core.snapshot.participantTouchIDs, [first])
    }

    func testRevealedRoundHoldsIdentityUntilNewTouchStartsFreshRound() {
        let scheduler = ManualChooserScheduler()
        let core = TogetherChooserCore(
            scheduler: scheduler,
            randomIndexGenerator: FixedRandomIndexGenerator(index: 0)
        )
        core.touchBegan(first)
        core.touchBegan(second)
        scheduler.advance(
            by: settlingDuration + ChoiceAnticipationTimeline.chooser.duration
        )
        XCTAssertEqual(core.phase, .revealed(winner: first))

        XCTAssertTrue(core.touchEnded(first))
        XCTAssertEqual(core.snapshot.participantTouchIDs, [first, second])
        XCTAssertTrue(core.touchBegan(third))
        XCTAssertEqual(core.phase, .idle)
        XCTAssertEqual(core.snapshot.participantTouchIDs, [third])
    }

    func testLifecycleCancellationDiscardsTouchesAndPendingTimers() {
        let scheduler = ManualChooserScheduler()
        var events: [TogetherChooserEvent] = []
        let core = TogetherChooserCore(scheduler: scheduler) { events.append($0) }
        core.touchBegan(first)
        core.touchBegan(second)
        scheduler.advance(by: 0.5)

        core.cancelForLifecycle()
        scheduler.advance(by: 10)

        XCTAssertEqual(core.phase, .idle)
        XCTAssertEqual(core.snapshot.participantTouchIDs, [])
        XCTAssertTrue(
            events.contains(
                .accessibilityAnnouncement(.init("Choice canceled. Place fingers again when ready."))
            )
        )
    }
}
