import XCTest
@testable import App

final class RandomIndexGeneratorTests: XCTestCase {
    func testSecureRandomIndexAlwaysStaysWithinRequestedBounds() throws {
        let generator = SecureRandomIndexGenerator()

        for upperBound in [1, 2, 3, 17, 257] {
            for _ in 0..<2_000 {
                let index = try generator.randomIndex(upperBound: upperBound)
                XCTAssertTrue((0..<upperBound).contains(index))
            }
        }
    }

    func testSecureRandomIndexRejectsNonpositiveBounds() {
        let generator = SecureRandomIndexGenerator()

        for upperBound in [0, -1, Int.min] {
            XCTAssertThrowsError(try generator.randomIndex(upperBound: upperBound)) { error in
                XCTAssertEqual(error as? RandomIndexGenerationError, .invalidUpperBound(upperBound))
            }
        }
    }
}
