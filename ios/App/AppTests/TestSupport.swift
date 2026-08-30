import CoreGraphics
import Foundation
import XCTest
@testable import App

struct FixedRandomIndexGenerator: RandomIndexGenerating {
    let index: Int

    func randomIndex(upperBound: Int) throws -> Int {
        index
    }
}

@MainActor
final class MemoryLaunchDefaultModeStore: LaunchDefaultModePersisting {
    var storedMode: AppMode?
    private(set) var savedModes: [AppMode] = []

    init(storedMode: AppMode? = nil) {
        self.storedMode = storedMode
    }

    func loadLaunchDefaultMode() -> AppMode? {
        storedMode
    }

    func saveLaunchDefaultMode(_ mode: AppMode) {
        storedMode = mode
        savedModes.append(mode)
    }
}

/// Small deterministic source suitable for repeatable statistical tests.
/// SplitMix64 has strong distribution properties without adding a dependency.
struct SplitMix64RandomSource: PinballRandomSource {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func nextUInt64() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}

enum PinballTestFixtures {
    static let portraitBounds = CGRect(x: 0, y: 0, width: 300, height: 600)
    static let landscapeBounds = CGRect(x: -25, y: 10, width: 700, height: 320)

    static func radialTaps(count: Int, in bounds: CGRect) -> [PinballSeatTap] {
        (0..<count).map { index in
            let angle = -CGFloat.pi / 2 + 2 * CGFloat.pi * CGFloat(index) / CGFloat(count)
            return PinballSeatTap(
                seatID: index + 1,
                point: CGPoint(
                    x: bounds.midX + cos(angle) * bounds.width * 0.42,
                    y: bounds.midY + sin(angle) * bounds.height * 0.42
                )
            )
        }
    }

    static func assertCyclicOrder(
        _ actual: [Int],
        matches expected: [Int],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard actual.count == expected.count, !actual.isEmpty else {
            XCTFail("Seat order counts differ", file: file, line: line)
            return
        }
        guard let start = expected.firstIndex(of: actual[0]) else {
            XCTFail("Seat order contains an unexpected ID", file: file, line: line)
            return
        }
        let rotated = (0..<expected.count).map { expected[(start + $0) % expected.count] }
        XCTAssertEqual(actual, rotated, file: file, line: line)
    }
}
