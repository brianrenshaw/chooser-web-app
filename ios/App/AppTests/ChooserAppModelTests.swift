import CoreGraphics
import XCTest
@testable import App

@MainActor
final class ChooserAppModelTests: XCTestCase {
    func testReduceMotionPinballSkipsFlightAndKeepsTheFairResolvedWinner() async throws {
        let feedback = RecordingFeedbackCoordinator()
        let model = makePinballModel(feedback: feedback)

        model.startPinball(reduceMotion: true)

        guard case .revealing(let run, let pulse, let isLit) = model.pinballPhase else {
            return XCTFail("Reduce Motion should reveal the resolved endpoint without replaying flight")
        }
        XCTAssertEqual(pulse, 1)
        XCTAssertTrue(isLit)
        XCTAssertTrue(1...6 ~= run.result.winningSeatID)
        XCTAssertEqual(run.result.winningSeatID, model.pinballPartition()?.seatIDOrNil(containing: run.result.finalPoint))
        XCTAssertTrue(feedback.cues.contains(.winner))

        try await Task.sleep(for: .milliseconds(700))
        guard case .revealed(let revealedRun) = model.pinballPhase else {
            return XCTFail("The steady Reduce Motion reveal should finish in the result state")
        }
        XCTAssertEqual(revealedRun.result.winningSeatID, run.result.winningSeatID)
        XCTAssertEqual(revealedRun.result.finalPoint, run.result.finalPoint)
    }

    func testBackgroundingCancelsPinballReplayButPreservesSeats() {
        let feedback = RecordingFeedbackCoordinator()
        let model = makePinballModel(feedback: feedback)

        model.startPinball(reduceMotion: false)
        guard case .running = model.pinballPhase else {
            return XCTFail("Expected an active Pinball replay")
        }

        model.handleSceneBecameInactive()

        XCTAssertEqual(model.pinballSeats.count, 6)
        XCTAssertEqual(model.pinballPhase, .collecting)
        XCTAssertGreaterThanOrEqual(feedback.stopCount, 1)
    }

    func testFeedbackCoordinatorCanOperateSilentlyWhenHardwareAndAudioAreUnavailable() {
        let coordinator = NativeFeedbackCoordinator(
            hapticsEnabled: false,
            audioPolicy: .never
        )

        coordinator.prepare()

        XCTAssertEqual(coordinator.play(.entryCommitted), .silent)
        XCTAssertEqual(coordinator.play(.winner), .silent)
        coordinator.stopAll()
    }

    private func makePinballModel(
        feedback: RecordingFeedbackCoordinator
    ) -> ChooserAppModel {
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .pinball),
            feedback: feedback
        )
        model.updatePinballPlayfield(size: CGSize(width: 390, height: 700))
        model.configureAccessiblePinballSeats(count: 6)
        XCTAssertTrue(model.pinballCanStart)
        return model
    }
}

@MainActor
private final class RecordingFeedbackCoordinator: NativeFeedbackCoordinating {
    let supportsCoreHaptics = false
    private(set) var cues: [NativeFeedbackCue] = []
    private(set) var prepareCount = 0
    private(set) var stopCount = 0

    func prepare() {
        prepareCount += 1
    }

    @discardableResult
    func play(_ cue: NativeFeedbackCue) -> NativeFeedbackDelivery {
        cues.append(cue)
        return .silent
    }

    func stopAll() {
        stopCount += 1
    }
}

private extension PinballRadialPartition {
    func seatIDOrNil(containing point: CGPoint) -> Int? {
        try? seatID(containing: point)
    }
}
