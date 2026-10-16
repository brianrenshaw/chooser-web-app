import CoreGraphics
import XCTest
@testable import App

final class LeadedGlassTessellationTests: XCTestCase {
    private let phone = CGSize(width: 390, height: 844)

    private func make(size: CGSize, seed: UInt64 = 0x53414752414441) -> LeadedGlassTessellation {
        LeadedGlassTessellation(
            size: size,
            seed: seed,
            clearCenter: CGPoint(x: size.width / 2, y: size.height / 2),
            clearRadius: min(size.width, size.height) * 0.40,
            paletteCount: 12
        )
    }

    func testTheSameSeedAndSizeAlwaysDrawTheSameShards() {
        XCTAssertEqual(make(size: phone), make(size: phone))
        XCTAssertNotEqual(make(size: phone), make(size: phone, seed: 7))
    }

    func testShardsAreRealPolygonsWithValidPaneColors() {
        let tessellation = make(size: phone)
        XCTAssertGreaterThan(tessellation.cells.count, 20)
        for cell in tessellation.cells {
            XCTAssertGreaterThanOrEqual(cell.vertices.count, 3)
            XCTAssertGreaterThan(LeadedGlassTessellation.area(of: cell.vertices), 1)
            XCTAssertTrue((0..<12).contains(cell.paletteIndex))
        }
    }

    func testShardsTileTheWholeBoardWithoutOverlap() {
        let tessellation = make(size: phone)
        // Clip every cell to the visible board; the pieces must add up to it.
        let board = [
            CGPoint(x: 0, y: 0), CGPoint(x: phone.width, y: 0),
            CGPoint(x: phone.width, y: phone.height), CGPoint(x: 0, y: phone.height)
        ]
        var covered: CGFloat = 0
        for cell in tessellation.cells {
            var polygon = cell.vertices
            for index in board.indices {
                let p = board[index]
                let q = board[(index + 1) % board.count]
                // Keep the board side of each edge (clip keeps a·x <= c).
                let a = CGPoint(x: q.y - p.y, y: -(q.x - p.x))
                polygon = LeadedGlassTessellation.clip(polygon, a: a, c: a.x * p.x + a.y * p.y)
            }
            covered += LeadedGlassTessellation.area(of: polygon)
        }
        XCTAssertEqual(covered, phone.width * phone.height, accuracy: phone.width * phone.height * 0.001)
    }

    func testShardSizeFollowsTheShortEdgeSoAnIPadIsNotAMosaic() {
        let pad = CGSize(width: 1032, height: 1376)
        let phoneCells = make(size: phone).cells.count
        let padCells = make(size: pad).cells.count
        // Same aspect class, so roughly the same number of shards.
        XCTAssertLessThan(abs(padCells - phoneCells), phoneCells / 2)
    }

    func testAnEmptyBoardHasNoShards() {
        XCTAssertTrue(make(size: .zero).cells.isEmpty)
    }
}
