import SwiftUI
import XCTest
@testable import App

final class BoardChromeMetricsTests: XCTestCase {

    private func resolve(
        _ horizontal: UserInterfaceSizeClass?,
        _ vertical: UserInterfaceSizeClass?
    ) -> BoardChromeMetrics {
        .resolve(horizontalSizeClass: horizontal, verticalSizeClass: vertical)
    }

    /// The default must be today's phone values, so any surface that is never
    /// injected — a preview, a test host, a sheet whose environment someone
    /// forgot — renders unchanged rather than as a tablet.
    func testTheDefaultIsThePhone() {
        XCTAssertEqual(EnvironmentValues().boardChromeMetrics, .phone)
        XCTAssertEqual(BoardChromeMetrics.phone.readableWidth, 620)
        XCTAssertEqual(BoardChromeMetrics.phone.introCardMaxWidth, 520)
        XCTAssertEqual(BoardChromeMetrics.phone.dockHeight, 108)
        XCTAssertNil(BoardChromeMetrics.phone.actionRowMaxWidth)
    }

    func testPhonesResolveToTodaysValues() {
        XCTAssertEqual(resolve(.compact, .regular), .phone)
        XCTAssertEqual(resolve(.compact, .compact), .landscapePhone)
        XCTAssertEqual(BoardChromeMetrics.landscapePhone.dockHeight, 104)
    }

    /// The reason `resolve` takes both axes. A Pro Max in landscape reports a
    /// **regular** horizontal size class, so keying off that axis alone would
    /// hand a phone with ~246pt of playfield a tablet dock and a capped action
    /// row — a regression on a shipping device, triggered by rotating it.
    func testAProMaxInLandscapeIsStillAPhone() {
        let proMaxLandscape = resolve(.regular, .compact)
        XCTAssertEqual(proMaxLandscape, .landscapePhone)
        XCTAssertEqual(proMaxLandscape.dockHeight, 104)
        XCTAssertNil(proMaxLandscape.actionRowMaxWidth)
    }

    func testIPadResolvesToTablet() {
        XCTAssertEqual(resolve(.regular, .regular), .tablet)
        XCTAssertEqual(BoardChromeMetrics.tablet.actionRowMaxWidth, 520)
        XCTAssertGreaterThan(
            BoardChromeMetrics.tablet.readableWidth,
            BoardChromeMetrics.phone.readableWidth
        )
    }

    /// A narrow iPad column is phone-shaped and must be treated as one.
    func testASlideOverColumnIsAPhone() {
        XCTAssertEqual(resolve(.compact, .regular), .phone)
    }

    /// Size classes are optional and are genuinely nil before the first layout.
    func testUnknownSizeClassesFallBackToThePhone() {
        XCTAssertEqual(resolve(nil, nil), .phone)
        XCTAssertEqual(resolve(.regular, nil), .phone)
        XCTAssertEqual(resolve(nil, .regular), .phone)
    }

    /// Pinball cancels a running round when its playfield changes by more than
    /// half a point, so a dock height must depend only on the size class — never
    /// on the phase, the seat count, or how a `ViewThatFits` resolved.
    func testDockHeightIsConstantForAGivenSizeClass() {
        for _ in 0..<3 {
            XCTAssertEqual(resolve(.compact, .regular).dockHeight, 108)
            XCTAssertEqual(resolve(.regular, .regular).dockHeight, 124)
        }
    }
}
