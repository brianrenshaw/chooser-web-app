import CoreGraphics
import Foundation
import XCTest
@testable import App

/// Reachability across board **shapes**.
///
/// A uniform scale is a similarity transform of Pinball's whole reachability
/// problem, so it changes nothing — that is what
/// `testAUniformScaleChangesNoOutcome` pins. Reachability depends instead on a
/// dimensionless tuple, and the one member of that tuple which an iPad actually
/// moves is the **aspect ratio**. So the fairness re-test that iPad support owes
/// is along shape, not size, which inverts the obvious test plan.
///
/// Slide Over is the densest configuration the product ships and the one where
/// a hole is most likely: a 3.1 ratio column packs twelve seats into a corridor.
final class PinballAspectRatioFairnessTests: XCTestCase {

    private struct Board {
        let name: String
        let size: CGSize
        let isPhone: Bool

        init(name: String, size: CGSize, isPhone: Bool = false) {
            self.name = name
            self.size = size
            self.isPhone = isPhone
        }
    }

    // One board per distinct *shape*, not per device.
    //
    // Letterboxing sends every full-screen iPad board to the reference ratio,
    // so an 11-inch portrait, an 11-inch landscape and a 13-inch portrait all
    // become 1.79 boards differing only in scale — and scale is provably free.
    // Running all three costs a third of the suite's wall clock to re-test the
    // same dimensionless configuration three times, which is how this suite
    // grew heavy enough to be killed under load.
    private let boards = [
        Board(name: "iPad 13 portrait", size: CGSize(width: 1024, height: 1266)),
        Board(name: "Slide Over", size: CGSize(width: 320, height: 1000)),
        // Two phones, not the whole lineup: the Pro Max is the ceiling — the
        // worst board the app ships on either device family — and the reference
        // is the floor the fairness matrix is proven against. The boards in
        // between cost a minute of suite time and tell us nothing new.
        Board(name: "phone Pro Max", size: CGSize(width: 440, height: 752), isPhone: true),
        Board(name: "phone reference", size: CGSize(width: 390, height: 700), isPhone: true)
    ]

    /// Every region must be reachable from every flick, at every seat count, on
    /// every board shape. An unreachable region is not a cosmetic defect: the
    /// round fails, the player flicks again, and the re-draw resamples the
    /// winner — so a region that cannot be reached is a region that wins less
    /// often than 1/N over completed rounds.
    func testEveryRegionIsReachableAtEveryAspectRatio() throws {
        var rates = [String: Double]()
        var phoneCeiling = 0.0
        for board in boards {
            let failures = try unreachableCounts(on: board)
            let rate = Double(failures.total) / Double(max(failures.attempts, 1))
            rates[board.name] = rate
            if board.isPhone { phoneCeiling = max(phoneCeiling, rate) }
            print(String(format: "GRID %@ %d/%d %.3f%%", board.name, failures.total, failures.attempts, rate * 100))

            // An absolute backstop, so a uniform regression across every board
            // cannot pass by quietly raising the phone ceiling with it.
            XCTAssertLessThanOrEqual(
                rate,
                0.03,
                "\(board.name): \(failures.total)/\(failures.attempts) unreachable"
            )
        }

        // The claim that matters, and it is self-calibrating: no board the app
        // ships is a worse place to be a region than the worst iPhone already
        // is. Without letterboxing, iPad portrait sat at 8.2% against a phone
        // ceiling of 2.4%.
        for board in boards where !board.isPhone {
            XCTAssertLessThanOrEqual(
                rates[board.name] ?? 1,
                phoneCeiling,
                """
                \(board.name) is a worse board than the worst iPhone \
                (\(String(format: "%.2f%%", (rates[board.name] ?? 1) * 100)) \
                vs \(String(format: "%.2f%%", phoneCeiling * 100))).
                """
            )
        }
    }

    private struct Counts {
        var total = 0
        var attempts = 0
        var worstSeatCount = 0
    }

    private func unreachableCounts(on board: Board) throws -> Counts {
        let size = PinballPlayfieldLetterbox.playfieldSize(fitting: board.size)
        let metrics = PinballBoardMetrics(playfieldSize: size)
        let seatCounts = Array(2...12)

        // The resolver is pure, so the seat counts are independent. Serialised
        // this sweep is minutes; fanned out it is seconds.
        let lock = NSLock()
        var perSeatFailures = [Int: Int]()
        var attempts = 0

        DispatchQueue.concurrentPerform(iterations: seatCounts.count) { index in
            let seatCount = seatCounts[index]
            var localFailures = 0
            var localAttempts = 0

            do {
                let bounds = CGRect(origin: .zero, size: size)
                    .insetBy(dx: metrics.collisionInset, dy: metrics.collisionInset)
                let partition = try PinballRadialPartition(
                    bounds: bounds,
                    taps: PinballTestFixtures.radialTaps(count: seatCount, in: bounds)
                )
                guard let layout = PinballSeatTokenSizing.bumperAwareLayout(
                    for: partition,
                    in: size,
                    ballRadius: metrics.ballRadius
                ) else {
                    lock.lock()
                    perSeatFailures[seatCount] = Int.max
                    lock.unlock()
                    return
                }
                let bumpers = PinballBumperField(from: layout, ballRadius: metrics.ballRadius)

                let releasePoints = [
                    CGPoint(x: bounds.midX, y: bounds.midY),
                    CGPoint(
                        x: bounds.minX + bounds.width * 0.38,
                        y: bounds.minY + bounds.height * 0.44
                    )
                ]
                for releasePoint in releasePoints {
                    for angleStep in 0..<8 {
                        let angle = (CGFloat(angleStep) + 0.5) * 2 * .pi / 8
                        for speed: CGFloat in [600, 1_400] {
                            let intent = try PinballFlickIntent(
                                releasePoint: releasePoint,
                                direction: CGVector(dx: cos(angle), dy: sin(angle)),
                                speed: speed
                            )
                            for regionIndex in 0..<seatCount {
                                localAttempts += 1
                                var random = ForcedWinnerSource(
                                    winnerIndex: regionIndex,
                                    upperBound: seatCount,
                                    seed: UInt64(angleStep &* 31 &+ regionIndex &+ 7)
                                )
                                do {
                                    let result = try PinballSpecularFlickResolver.resolve(
                                        partition: partition,
                                        intent: intent,
                                        using: &random,
                                        maximumSegments: 10_000,
                                        bumpers: bumpers
                                    )
                                    if result.winningRegion.seat.seatID
                                        != partition.regions[regionIndex].seat.seatID {
                                        localFailures += 1
                                    }
                                } catch {
                                    localFailures += 1
                                }
                            }
                        }
                    }
                }
            } catch {
                localFailures = Int.max
            }

            lock.lock()
            perSeatFailures[seatCount] = localFailures
            attempts += localAttempts
            lock.unlock()
        }

        var counts = Counts()
        counts.attempts = attempts
        for (seatCount, failures) in perSeatFailures {
            counts.total += failures
            if failures > 0, perSeatFailures[counts.worstSeatCount] ?? 0 < failures {
                counts.worstSeatCount = seatCount
            }
        }
        return counts
    }

    /// The letterbox must be invisible on every iPhone. This is the promise
    /// that made the rule acceptable at all: capping every board at the
    /// reference ratio would have narrowed an SE by 20% to fix a problem the SE
    /// does not have.
    func testTheLetterboxLeavesEveryPhoneExactlyAsItWas() {
        let phones = [
            CGSize(width: 375, height: 539),
            CGSize(width: 375, height: 581),
            CGSize(width: 390, height: 700),
            CGSize(width: 393, height: 678),
            CGSize(width: 402, height: 704),
            CGSize(width: 440, height: 752),
            CGSize(width: 667, height: 347),
            CGSize(width: 874, height: 246),
            CGSize(width: 320, height: 454)
        ]
        for phone in phones {
            XCTAssertEqual(
                PinballPlayfieldLetterbox.playfieldSize(fitting: phone),
                phone,
                "\(phone) is a phone and must not be letterboxed"
            )
        }
    }

    /// A phone-shaped iPad column is already elongated past the reference and
    /// must be left alone — it measures cleanest of all the boards.
    func testANarrowColumnIsNeverLetterboxed() {
        let column = CGSize(width: 320, height: 1000)
        XCTAssertEqual(PinballPlayfieldLetterbox.playfieldSize(fitting: column), column)
    }

    /// Continuity is not cosmetic. A playfield that changes size cancels a
    /// running round, and on iPad a size change is one Stage Manager drag away,
    /// so a cliff in this function would end rounds mid-flight. This is the
    /// reason the rule has a floor clause rather than a device check.
    func testTheLetterboxIsContinuousAcrossEveryShortEdge() {
        let longEdge: CGFloat = 1000
        var previous = PinballPlayfieldLetterbox
            .playfieldSize(fitting: CGSize(width: 200, height: longEdge))
        for shortEdge in stride(from: CGFloat(201), through: 1000, by: 1) {
            let size = PinballPlayfieldLetterbox
                .playfieldSize(fitting: CGSize(width: shortEdge, height: longEdge))
            XCTAssertLessThanOrEqual(
                abs(size.width - previous.width),
                1.001,
                "a \(shortEdge)pt board jumps to \(size.width) from \(previous.width)"
            )
            previous = size
        }
    }

    func testTheLetterboxNeverGrowsOrInvertsABoard() {
        for width in stride(from: CGFloat(200), through: 1400, by: 37) {
            for height in stride(from: CGFloat(200), through: 1400, by: 41) {
                let proposed = CGSize(width: width, height: height)
                let result = PinballPlayfieldLetterbox.playfieldSize(fitting: proposed)
                XCTAssertLessThanOrEqual(result.width, proposed.width)
                XCTAssertLessThanOrEqual(result.height, proposed.height)
                XCTAssertGreaterThan(result.width, 0)
                XCTAssertGreaterThan(result.height, 0)
                XCTAssertEqual(
                    result.width > result.height,
                    proposed.width > proposed.height,
                    "\(proposed) changed orientation"
                )
            }
        }
    }

    func testDegenerateSizesPassThroughUnchanged() {
        for size in [
            CGSize(width: 0, height: 0),
            CGSize(width: -10, height: 100),
            CGSize(width: CGFloat.infinity, height: 100),
            CGSize(width: CGFloat.nan, height: 100)
        ] {
            let result = PinballPlayfieldLetterbox.playfieldSize(fitting: size)
            XCTAssertEqual(result.width.isNaN, size.width.isNaN)
            if !size.width.isNaN {
                XCTAssertEqual(result, size)
            }
        }
    }

    /// The shape of a board is a scale-invariant property, so the portrait /
    /// landscape branch in seat sizing must pick the same side at any size.
    /// If it did not, the similarity argument would not survive a resize and
    /// every conclusion above would be about a different problem.
    func testOrientationIsScaleInvariant() {
        for size in [
            CGSize(width: 390, height: 700),
            CGSize(width: 820, height: 1000),
            CGSize(width: 1180, height: 820),
            CGSize(width: 320, height: 1000)
        ] {
            let metrics = PinballBoardMetrics(playfieldSize: size)
            XCTAssertEqual(
                metrics.referenceSize.width > metrics.referenceSize.height,
                size.width > size.height,
                "\(size) changed orientation when reduced to reference scale"
            )
            XCTAssertEqual(
                metrics.referenceSize.width / metrics.referenceSize.height,
                size.width / size.height,
                accuracy: 1e-9,
                "\(size) changed aspect ratio when reduced to reference scale"
            )
        }
    }
}
