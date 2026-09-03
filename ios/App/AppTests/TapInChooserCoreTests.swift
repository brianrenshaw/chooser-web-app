import CoreGraphics
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

    func testDismissResultPreservesEntriesAndReturnsToCollecting() throws {
        let scheduler = ManualChooserScheduler()
        let core = TapInChooserCore(
            scheduler: scheduler,
            randomIndexGenerator: FixedRandomIndexGenerator(index: 1)
        )
        let first = try core.addEntry()
        let second = try core.addEntry()
        try core.pick()
        scheduler.advance(by: 1)

        XCTAssertEqual(core.phase, .revealed(winner: second))
        try core.dismissResult()

        XCTAssertEqual(core.phase, .collecting)
        XCTAssertEqual(core.snapshot.entries, [first, second])
        XCTAssertTrue(core.snapshot.drawSnapshot.isEmpty)
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

final class ChooserVisualGeometryTests: XCTestCase {
    func testTapInPreferredDiameterUsesTheLargerCalmRingSystem() {
        XCTAssertEqual(TapInGridLayout.preferredRingDiameter(for: 0), 156)
        XCTAssertEqual(TapInGridLayout.preferredRingDiameter(for: 5), 156)
        XCTAssertEqual(TapInGridLayout.preferredRingDiameter(for: 6), 142)
        XCTAssertEqual(TapInGridLayout.preferredRingDiameter(for: 10), 110)
        XCTAssertEqual(TapInGridLayout.preferredRingDiameter(for: 20), 78)
        XCTAssertEqual(TapInGridLayout.preferredRingDiameter(for: 50), 49)
    }

    func testEveryEdgeAndCornerContainsTheCompleteRenderedFootprint() {
        let cases: [(size: CGSize, diameter: CGFloat, emphasis: NativeNeonEmphasis, externalScale: CGFloat)] = [
            (CGSize(width: 430, height: 700), 156, .resting, 1.05),
            (CGSize(width: 430, height: 700), 172, .winner, 1),
            (CGSize(width: 850, height: 260), 164, .winner, 1),
            (CGSize(width: 850, height: 260), 48, .resting, 1.05)
        ]

        for testCase in cases {
            let size = testCase.size
            let rawPoints = [
                CGPoint(x: 0, y: 0),
                CGPoint(x: size.width, y: 0),
                CGPoint(x: 0, y: size.height),
                CGPoint(x: size.width, y: size.height),
                CGPoint(x: size.width / 2, y: size.height / 2)
            ]
            let radius = NativeNeonVisualMetrics.footprintRadius(
                diameter: testCase.diameter,
                emphasis: testCase.emphasis,
                externalScale: testCase.externalScale
            )
            for rawPoint in rawPoints {
                let displayed = NativeNeonVisualMetrics.clampedCenter(
                    rawPoint,
                    in: size,
                    diameter: testCase.diameter,
                    emphasis: testCase.emphasis,
                    externalScale: testCase.externalScale
                )
                XCTAssertGreaterThanOrEqual(displayed.x - radius, -0.001)
                XCTAssertGreaterThanOrEqual(displayed.y - radius, -0.001)
                XCTAssertLessThanOrEqual(displayed.x + radius, size.width + 0.001)
                XCTAssertLessThanOrEqual(displayed.y + radius, size.height + 0.001)
            }
        }
    }

    func testTapInGridFitsFullFootprintsAtRepresentativeCountsAndOrientations() {
        let sizes = [
            CGSize(width: 430, height: 650),
            CGSize(width: 850, height: 260)
        ]

        for size in sizes {
            for count in [1, 5, 6, 10, 20, 30, 50] {
                let layout = TapInGridLayout.make(count: count, in: size)
                XCTAssertEqual(layout.positions.count, count)
                let radius = NativeNeonVisualMetrics.footprintRadius(
                    diameter: layout.diameter,
                    emphasis: .resting,
                    externalScale: 1.05
                )

                for position in layout.positions {
                    XCTAssertGreaterThanOrEqual(position.x - radius, -0.01)
                    XCTAssertGreaterThanOrEqual(position.y - radius, -0.01)
                    XCTAssertLessThanOrEqual(position.x + radius, size.width + 0.01)
                    XCTAssertLessThanOrEqual(position.y + radius, size.height + 0.01)
                }

                // The black cores never collide. Broad blurred light may overlap
                // by design so large groups stay legible instead of collapsing
                // into tiny tokens.
                for firstIndex in layout.positions.indices {
                    for secondIndex in layout.positions.indices where secondIndex > firstIndex {
                        let first = layout.positions[firstIndex]
                        let second = layout.positions[secondIndex]
                        XCTAssertGreaterThanOrEqual(
                            hypot(first.x - second.x, first.y - second.y),
                            layout.diameter - 0.1
                        )
                    }
                }

                if count == 50 {
                    XCTAssertGreaterThanOrEqual(layout.diameter, 36)
                }
            }
        }
    }
}
