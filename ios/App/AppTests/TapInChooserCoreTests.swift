import XCTest
@testable import App

@MainActor
final class TapInChooserCoreTests: XCTestCase {
    func testEntriesAreSequentialAndUndoReusesOnlyTheRemovedNumber() throws {
        let core = TapInChooserCore(scheduler: ManualChooserScheduler())
        let first = try core.addEntry()
        let second = try core.addEntry()
        let removed = try core.undo()
        let replacement = try core.addEntry()

        XCTAssertEqual(first, TapInEntry(id: 1, number: 1))
        XCTAssertEqual(second, removed)
        XCTAssertEqual(replacement.number, 2)
        XCTAssertNotEqual(replacement.id, removed.id, "Committed entry identity must not be reused")
        XCTAssertEqual(core.snapshot.entries, [first, replacement])
    }

    func testFiftiethEntryIsAcceptedAndFiftyFirstIsRejected() throws {
        let core = TapInChooserCore(scheduler: ManualChooserScheduler())

        for expectedNumber in 1...TapInChooserCore.maximumPlayerCount {
            XCTAssertEqual(try core.addEntry().number, expectedNumber)
        }
        XCTAssertEqual(core.snapshot.entries.count, 50)
        XCTAssertThrowsError(try core.addEntry()) { error in
            XCTAssertEqual(error as? TapInActionError, .maximumPlayersReached(50))
        }
        XCTAssertEqual(core.snapshot.entries.count, 50)
    }

    func testPickRequiresAtLeastTwoEntries() throws {
        let core = TapInChooserCore(scheduler: ManualChooserScheduler())
        XCTAssertThrowsError(try core.pick()) { error in
            XCTAssertEqual(error as? TapInActionError, .minimumPlayersRequired(2))
        }
        _ = try core.addEntry()
        XCTAssertThrowsError(try core.pick()) { error in
            XCTAssertEqual(error as? TapInActionError, .minimumPlayersRequired(2))
        }
    }

    func testDrawUsesFrozenEntryArrayAndPickAgainAllowsRepeatWinner() throws {
        let scheduler = ManualChooserScheduler()
        let core = TapInChooserCore(
            scheduler: scheduler,
            randomIndexGenerator: FixedRandomIndexGenerator(index: 1)
        )
        _ = try core.addEntry()
        let expectedWinner = try core.addEntry()
        _ = try core.addEntry()

        try core.pick()
        XCTAssertEqual(core.phase, .countdown)
        XCTAssertEqual(core.snapshot.drawSnapshot, core.snapshot.entries)
        XCTAssertThrowsError(try core.addEntry()) { error in
            XCTAssertEqual(error as? TapInActionError, .invalidPhase)
        }
        scheduler.advance(by: 1)
        XCTAssertEqual(core.phase, .revealed(winner: expectedWinner))

        try core.pickAgain()
        scheduler.advance(by: 1)
        XCTAssertEqual(core.phase, .revealed(winner: expectedWinner))
        XCTAssertEqual(core.snapshot.entries.count, 3)
    }

    func testClearRemovesPoolAndRestartsNumberingAndIdentity() throws {
        let core = TapInChooserCore(scheduler: ManualChooserScheduler())
        _ = try core.addEntry()
        _ = try core.addEntry()

        try core.clear()
        XCTAssertEqual(core.phase, .collecting)
        XCTAssertEqual(core.snapshot.entries, [])
        XCTAssertEqual(core.snapshot.drawSnapshot, [])
        XCTAssertEqual(try core.addEntry(), TapInEntry(id: 1, number: 1))
    }

    func testNewGroupFromResultClearsPoolAndRestartsNumbering() throws {
        let scheduler = ManualChooserScheduler()
        let core = TapInChooserCore(
            scheduler: scheduler,
            randomIndexGenerator: FixedRandomIndexGenerator(index: 0)
        )
        _ = try core.addEntry()
        _ = try core.addEntry()
        try core.pick()
        scheduler.advance(by: 1)
        guard case .revealed = core.phase else {
            return XCTFail("Expected a result before starting a new group")
        }

        core.newGroup()
        XCTAssertEqual(core.phase, .collecting)
        XCTAssertEqual(core.snapshot.entries, [])
        XCTAssertEqual(try core.addEntry(), TapInEntry(id: 1, number: 1))
    }

    func testLifecycleCancellationPreservesCommittedPoolAndCancelsDraw() throws {
        let scheduler = ManualChooserScheduler()
        let core = TapInChooserCore(scheduler: scheduler)
        let entries = [try core.addEntry(), try core.addEntry(), try core.addEntry()]
        try core.pick()

        core.cancelForLifecycle()
        scheduler.advance(by: 10)

        XCTAssertEqual(core.phase, .collecting)
        XCTAssertEqual(core.snapshot.entries, entries)
        XCTAssertEqual(core.snapshot.drawSnapshot, [])
    }

    func testCollectingOnlyActionsRejectCountdownAndResultPhases() throws {
        let scheduler = ManualChooserScheduler()
        let core = TapInChooserCore(
            scheduler: scheduler,
            randomIndexGenerator: FixedRandomIndexGenerator(index: 0)
        )
        _ = try core.addEntry()
        _ = try core.addEntry()
        try core.pick()

        XCTAssertThrowsError(try core.undo())
        XCTAssertThrowsError(try core.clear())
        XCTAssertThrowsError(try core.pick())
        scheduler.advance(by: 1)
        XCTAssertThrowsError(try core.undo())
        XCTAssertThrowsError(try core.clear())
    }
}
