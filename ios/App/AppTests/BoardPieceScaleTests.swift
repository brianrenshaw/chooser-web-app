import CoreGraphics
import XCTest
@testable import App

/// Every shipping iPhone playfield, in both orientations, at the sizes the
/// board actually receives after the dock and safe areas are taken out.
private let phonePlayfields: [CGSize] = [
    CGSize(width: 320, height: 454),   // SE, portrait
    CGSize(width: 375, height: 553),
    CGSize(width: 390, height: 596),
    CGSize(width: 393, height: 676),
    CGSize(width: 402, height: 704),
    CGSize(width: 430, height: 748),   // Pro Max, portrait
    CGSize(width: 568, height: 206),   // SE, landscape
    CGSize(width: 667, height: 219),
    CGSize(width: 844, height: 242),
    CGSize(width: 874, height: 246),   // Pro Max, landscape
    CGSize(width: 932, height: 258)
]

private let iPadPlayfields: [CGSize] = [
    CGSize(width: 820, height: 1000),   // 11-inch portrait
    CGSize(width: 1024, height: 700),   // 11-inch landscape
    CGSize(width: 1024, height: 1266),  // 13-inch portrait
    CGSize(width: 1366, height: 900)    // 13-inch landscape
]

final class BoardPieceScaleTests: XCTestCase {

    // MARK: - The regression fence

    /// The whole promise of the iPad pass is that no iPhone renders differently
    /// *because of scaling*. That reduces to one claim, so assert it directly
    /// rather than re-asserting every downstream size.
    func testBoardScaleIsExactlyOneOnEveryShippingPhonePlayfield() {
        for size in phonePlayfields {
            XCTAssertEqual(
                BoardPieceVisualMetrics.boardScale(for: size),
                1,
                "\(size) is a phone and must resolve to scale 1"
            )
        }
    }

    /// A narrow iPad column is phone-shaped, so it should play like a phone.
    /// This falls out of the 440 reference rather than needing a device check,
    /// which is exactly why it is worth pinning.
    func testASlideOverColumnIsTreatedAsAPhone() {
        XCTAssertEqual(
            BoardPieceVisualMetrics.boardScale(for: CGSize(width: 320, height: 1180)),
            1
        )
    }

    func testBoardScaleGrowsButStaysBounded() {
        var previous = BoardPieceVisualMetrics.boardScale(for: CGSize(width: 440, height: 440))
        XCTAssertEqual(previous, 1)
        for shortEdge in stride(from: CGFloat(460), through: 1400, by: 20) {
            let scale = BoardPieceVisualMetrics.boardScale(
                for: CGSize(width: shortEdge, height: shortEdge * 1.3)
            )
            XCTAssertGreaterThanOrEqual(scale, previous, "scale must be monotonic")
            XCTAssertLessThanOrEqual(scale, 1.9, "scale is capped")
            previous = scale
        }
    }

    // MARK: - Chooser

    /// `clampedCenter` degrades to "every ring at the exact centre of the board"
    /// once a footprint cannot fit, which stacks the rings on top of each other
    /// and destroys the mode. `fittedDiameter` exists to make that unreachable,
    /// so assert the inequality it is supposed to guarantee.
    func testChooserRingsAlwaysFitTheirOwnRevealFootprint() {
        for size in phonePlayfields + iPadPlayfields {
            let diameter = ChooserRingSizing.diameter(in: size)
            let radius = BoardPieceVisualMetrics.footprintRadius(
                diameter: diameter,
                emphasis: .winner,
                externalScale: ChooserRingSizing.externalScale,
                scale: BoardPieceVisualMetrics.boardScale(for: size)
            ) + ChooserRingSizing.margin
            XCTAssertLessThanOrEqual(
                radius,
                min(size.width, size.height) / 2 + 0.001,
                "a winning ring on \(size) would be clipped or collapse the clamp"
            )
        }
    }

    /// Portrait phones are the common case and must be bit-identical to 1.0.
    /// The SE sits at 158 because 320 * 0.45 falls under the lower clamp — that
    /// is the shipping value, not a regression.
    func testChooserRingDiameterIsUnchangedOnPortraitPhones() {
        XCTAssertEqual(ChooserRingSizing.diameter(in: CGSize(width: 393, height: 676)), 176)
        XCTAssertEqual(ChooserRingSizing.diameter(in: CGSize(width: 430, height: 748)), 176)
        XCTAssertEqual(ChooserRingSizing.diameter(in: CGSize(width: 402, height: 704)), 176)
        XCTAssertEqual(ChooserRingSizing.diameter(in: CGSize(width: 320, height: 454)), 158)
        XCTAssertEqual(ChooserRingSizing.diameter(in: CGSize(width: 375, height: 553)), 168.75)
    }

    /// Landscape phones deliberately changed. The old `shortEdge - 40` tail was
    /// a hand-derived "fit the winner overflow on the short edge", but it
    /// counted only the 20pt overflow and forgot the 1.06 winner scale, the
    /// rebound scale and the landing translation — so it returned a diameter
    /// whose complete footprint did not fit, and the lifted winner shadow was
    /// trimmed by the stage clip. This is that same intent, computed correctly.
    func testChooserRingsShrinkOnShortLandscapePhonesSoTheWinnerIsNotClipped() {
        let landscape = CGSize(width: 667, height: 219)
        let diameter = ChooserRingSizing.diameter(in: landscape)
        XCTAssertLessThan(diameter, 144, "the old tail returned an unfittable 144")
        XCTAssertGreaterThan(diameter, 110, "but it must stay a substantial piece")
    }

    /// Compared against an orientation-matched phone, because the landscape
    /// anchors are smaller than the portrait ones and pooling the two would let
    /// a landscape regression hide behind the portrait headroom.
    func testChooserRingsGrowOnIPad() {
        let portraitPhone = ChooserRingSizing.diameter(in: CGSize(width: 393, height: 676))
        let landscapePhone = ChooserRingSizing.diameter(in: CGSize(width: 874, height: 246))
        for size in iPadPlayfields {
            let phone = size.width > size.height ? landscapePhone : portraitPhone
            XCTAssertGreaterThan(
                ChooserRingSizing.diameter(in: size),
                phone * 1.3,
                "\(size) should draw a meaningfully larger ring than a phone"
            )
        }
    }

    // MARK: - Tap In

    /// The reveal must never be an anticlimax.
    func testTapInWinnerNeverShrinksOnReveal() {
        for size in phonePlayfields + iPadPlayfields {
            let scale = BoardPieceVisualMetrics.boardScale(for: size)
            for count in 2...50 {
                let layout = TapInGridLayout.make(count: count, in: size, scale: scale)
                let winner = TapInGridLayout.winnerDiameter(
                    gridDiameter: layout.diameter,
                    in: size,
                    scale: scale
                )
                XCTAssertGreaterThanOrEqual(
                    winner,
                    layout.diameter,
                    "\(count) entries on \(size): winner \(winner) < grid \(layout.diameter)"
                )
            }
        }
    }

    /// Where the guard actually binds — and it is not the iPad.
    ///
    /// Scaling the cap alongside the grid already removes the large-board case:
    /// the grid is capped at `156 * s` and the winner at `172 * s`, so on a big
    /// board the winner is comfortably larger by construction. The guard earns
    /// its place on a *short* board, where the cap collapses to
    /// `shortEdge - 56` and drops below a grid diameter that the width still
    /// allows. iPhone SE in landscape is that board, so this is a shipping 1.0
    /// bug rather than an iPad concern: two entries there reveal a winner
    /// smaller than the chit it grew out of.
    func testTheWinnerGuardIsLoadBearingOnAShortBoard() {
        let board = CGSize(width: 568, height: 206)
        let scale = BoardPieceVisualMetrics.boardScale(for: board)
        XCTAssertEqual(scale, 1, "the SE is a phone")
        let layout = TapInGridLayout.make(count: 2, in: board, scale: scale)
        let unguardedCap = min(
            172 * scale,
            max(104 * scale, min(board.width, board.height) - 56 * scale)
        )
        XCTAssertGreaterThan(
            layout.diameter,
            unguardedCap,
            "if the cap already exceeded the grid diameter this test proves nothing"
        )
        XCTAssertEqual(
            TapInGridLayout.winnerDiameter(
                gridDiameter: layout.diameter,
                in: board,
                scale: scale
            ),
            layout.diameter,
            "the guard must hold the winner at the grid diameter, not below it"
        )
    }

    func testTapInGridIsUnchangedOnPhones() {
        for size in phonePlayfields {
            for count in [2, 5, 12, 30, 50] {
                XCTAssertEqual(
                    TapInGridLayout.make(count: count, in: size).diameter,
                    TapInGridLayout.make(count: count, in: size, scale: 1).diameter,
                    "\(count) on \(size)"
                )
            }
        }
    }

    func testTapInPreferredDiameterScalesLinearly() {
        for count in [2, 6, 10, 20, 50] {
            XCTAssertEqual(
                TapInGridLayout.preferredRingDiameter(for: count, scale: 1),
                TapInGridLayout.preferredRingDiameter(for: count),
                "scale 1 must be the shipping value"
            )
        }
        // Rounding lives inside the expression, so compare against the scaled
        // expression rather than asserting an exact multiple of the phone value.
        XCTAssertEqual(TapInGridLayout.preferredRingDiameter(for: 5, scale: 1.5), 234)
        XCTAssertEqual(
            TapInGridLayout.preferredRingDiameter(for: 20, scale: 1.5),
            (156 * 1.5 * (5.0 / 20.0).squareRoot()).rounded()
        )
    }

    /// A scale below 1 must never shrink a piece — every length in the system
    /// takes `max(1, scale)` precisely so a bad caller cannot make the board
    /// smaller than a phone's.
    func testScalesBelowOneAreClampedRatherThanShrinking() {
        XCTAssertEqual(TapInGridLayout.preferredRingDiameter(for: 5, scale: 0.5), 156)
        XCTAssertEqual(BoardPieceVisualMetrics.bandWidth(for: 176, scale: 0.5),
                       BoardPieceVisualMetrics.bandWidth(for: 176))
        XCTAssertEqual(
            TapInGridLayout.winnerDiameter(gridDiameter: 100, in: CGSize(width: 400, height: 700), scale: 0.5),
            TapInGridLayout.winnerDiameter(gridDiameter: 100, in: CGSize(width: 400, height: 700))
        )
    }
}
