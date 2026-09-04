import CoreGraphics
import XCTest
@testable import App

/// The predicate this replaces was `verticalSizeClass == .compact`, which no
/// iPad ever reports — so every iPad, at every size, got the narrow phone
/// layout. These cases are the ones that predicate got wrong.
final class NativeWelcomeLayoutTests: XCTestCase {

    private func isWide(_ width: CGFloat, _ height: CGFloat, accessibility: Bool = false) -> Bool {
        NativeWelcomeLayout.usesWideLayout(
            pageSize: CGSize(width: width, height: height),
            isAccessibilitySize: accessibility
        )
    }

    // MARK: - What must not change

    func testPhonesInPortraitStayStacked() {
        XCTAssertFalse(isWide(320, 568))
        XCTAssertFalse(isWide(393, 852))
        XCTAssertFalse(isWide(430, 932))
    }

    func testPhonesInLandscapeGoSideBySide() {
        XCTAssertFalse(isWide(568, 320), "an SE is too narrow for two columns")
        XCTAssertTrue(isWide(844, 390))
        XCTAssertTrue(isWide(932, 430))
    }

    // MARK: - What the old predicate got wrong

    func testIPadInLandscapeGoesSideBySide() {
        XCTAssertTrue(isWide(1180, 820), "11-inch landscape used to be stacked")
        XCTAssertTrue(isWide(1366, 1024), "13-inch landscape used to be stacked")
    }

    /// The aspect guard, and the reason it exists. A 1024pt portrait page
    /// clears the 620pt width bar comfortably, but two columns on a tall page
    /// is not what side-by-side is for.
    func testIPadInPortraitStaysStacked() {
        XCTAssertFalse(isWide(820, 1180))
        XCTAssertFalse(isWide(1024, 1366))
    }

    func testANearlySquarePageStaysStacked() {
        XCTAssertFalse(isWide(1000, 950), "1.05 aspect is not short-and-wide")
        XCTAssertTrue(isWide(1000, 880), "1.14 aspect is")
    }

    // MARK: - Guards

    func testAccessibilityTextSizesAlwaysStack() {
        XCTAssertFalse(isWide(1366, 1024, accessibility: true))
        XCTAssertFalse(isWide(932, 430, accessibility: true))
    }

    /// A page can be measured at zero during the first layout pass.
    func testDegenerateSizesStack() {
        XCTAssertFalse(isWide(0, 0))
        XCTAssertFalse(isWide(1366, 0))
        XCTAssertFalse(isWide(.infinity, 500))
    }
}
