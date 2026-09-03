import CoreGraphics
import XCTest
@testable import App

@MainActor
final class ChooserAppModelTests: XCTestCase {
    private let settlingDuration = TogetherTiming.defaultSettlingDuration

    func testVoiceOverCanRunTheRealChooserWithVirtualParticipants() {
        let scheduler = ManualChooserScheduler()
        let feedback = RecordingFeedbackCoordinator()
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .together),
            togetherCore: TogetherChooserCore(
                scheduler: scheduler,
                randomIndexGenerator: FixedRandomIndexGenerator(index: 2)
            ),
            feedback: feedback
        )

        XCTAssertTrue(
            model.chooseTogetherForAccessibility(
                participantCount: 4,
                in: CGSize(width: 320, height: 520)
            )
        )
        XCTAssertEqual(model.togetherSnapshot.participantTouchIDs.count, 4)
        XCTAssertEqual(model.togetherVisuals.count, 4)
        XCTAssertEqual(model.togetherSnapshot.phase, .settling)

        scheduler.advance(by: settlingDuration + ChoiceAnticipationTimeline.chooser.duration)

        XCTAssertEqual(
            model.togetherSnapshot.winner,
            model.togetherSnapshot.participantTouchIDs[2]
        )
        XCTAssertEqual(feedback.cues.filter { $0 == .chooserWinner }.count, 1)
    }

    func testAccessibleChooserRejectsInvalidCountsAndCriticalDrawState() {
        let scheduler = ManualChooserScheduler()
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .together),
            togetherCore: TogetherChooserCore(scheduler: scheduler),
            feedback: RecordingFeedbackCoordinator()
        )

        XCTAssertFalse(
            model.chooseTogetherForAccessibility(
                participantCount: 1,
                in: CGSize(width: 320, height: 520)
            )
        )
        XCTAssertTrue(
            model.chooseTogetherForAccessibility(
                participantCount: 2,
                in: CGSize(width: 320, height: 520)
            )
        )
        scheduler.advance(by: settlingDuration)
        XCTAssertEqual(model.togetherSnapshot.phase, .countdown)
        XCTAssertFalse(
            model.chooseTogetherForAccessibility(
                participantCount: 5,
                in: CGSize(width: 320, height: 520)
            )
        )
    }

    func testTogetherModeCanSwitchWhileOneFingerIsVisible() {
        let feedback = RecordingFeedbackCoordinator()
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .together),
            feedback: feedback
        )
        model.togetherTouchBegan(.init(id: 1, location: CGPoint(x: 80, y: 120)))

        XCTAssertEqual(model.togetherSnapshot.participantTouchIDs.count, 1)
        XCTAssertTrue(model.isModeChangeEnabled)

        model.requestModeChange(to: .tapIn)

        XCTAssertEqual(model.mode, .tapIn)
        XCTAssertTrue(model.togetherVisuals.isEmpty)
        XCTAssertEqual(feedback.stopCount, 1)
        XCTAssertEqual(feedback.cues.last, .modeChanged)
    }

    func testTogetherModeCanSwitchDuringSettlingButNotDuringTheActualDraw() {
        let scheduler = ManualChooserScheduler()
        let togetherCore = TogetherChooserCore(scheduler: scheduler)
        let feedback = RecordingFeedbackCoordinator()
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .together),
            togetherCore: togetherCore,
            feedback: feedback
        )
        model.togetherTouchBegan(.init(id: 1, location: CGPoint(x: 80, y: 120)))
        model.togetherTouchBegan(.init(id: 2, location: CGPoint(x: 220, y: 120)))

        XCTAssertEqual(model.togetherSnapshot.phase, .settling)
        XCTAssertTrue(model.isModeChangeEnabled)
        let settlingDurations = feedback.cues.compactMap { cue -> TimeInterval? in
            if case .settling(let duration) = cue { return duration }
            return nil
        }
        XCTAssertEqual(settlingDurations, [settlingDuration])

        scheduler.advance(by: settlingDuration)
        XCTAssertEqual(model.togetherSnapshot.phase, .countdown)
        XCTAssertFalse(model.isModeChangeEnabled)
        XCTAssertEqual(
            feedback.cues.filter { $0 == .togetherCountdown }.count,
            1
        )
        XCTAssertEqual(ChoiceAnticipationTimeline.chooser.duration, 2.75)

        model.requestModeChange(to: .pinball)
        XCTAssertEqual(model.mode, .together)
    }

    func testTogetherParticipantRemovalDuringCountdownDoesNotRestartHaptics() {
        let scheduler = ManualChooserScheduler()
        let feedback = RecordingFeedbackCoordinator()
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .together),
            togetherCore: TogetherChooserCore(
                scheduler: scheduler,
                randomIndexGenerator: FixedRandomIndexGenerator(index: 0)
            ),
            feedback: feedback
        )

        model.togetherTouchBegan(.init(id: 1, location: CGPoint(x: 60, y: 120)))
        model.togetherTouchBegan(.init(id: 2, location: CGPoint(x: 160, y: 120)))
        model.togetherTouchBegan(.init(id: 3, location: CGPoint(x: 260, y: 120)))
        scheduler.advance(by: settlingDuration)

        XCTAssertEqual(model.togetherSnapshot.phase, .countdown)
        XCTAssertEqual(feedback.togetherCountdownCount, 1)

        model.togetherTouchEnded(
            .init(id: 3, location: CGPoint(x: 260, y: 120)),
            cancelled: false
        )

        XCTAssertEqual(model.togetherSnapshot.phase, .countdown)
        XCTAssertEqual(feedback.togetherCountdownCount, 1)

        scheduler.advance(by: ChoiceAnticipationTimeline.chooser.duration)
        guard case .revealed = model.togetherSnapshot.phase else {
            return XCTFail("The original countdown deadline should still reveal a winner")
        }
        XCTAssertEqual(feedback.cues.filter { $0 == .chooserWinner }.count, 1)
    }

    func testLateChooserFingerCancelsActiveAnticipationBeforeRestartingSilentSettle() {
        let scheduler = ManualChooserScheduler()
        let feedback = RecordingFeedbackCoordinator()
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .together),
            togetherCore: TogetherChooserCore(scheduler: scheduler),
            feedback: feedback
        )

        model.togetherTouchBegan(.init(id: 1, location: CGPoint(x: 60, y: 120)))
        model.togetherTouchBegan(.init(id: 2, location: CGPoint(x: 160, y: 120)))
        scheduler.advance(by: settlingDuration)

        XCTAssertEqual(model.togetherSnapshot.phase, .countdown)
        XCTAssertEqual(feedback.togetherCountdownCount, 1)
        let cancellationCountBeforeLateFinger = feedback.sequenceCancelCount

        model.togetherTouchBegan(.init(id: 3, location: CGPoint(x: 260, y: 120)))

        XCTAssertEqual(model.togetherSnapshot.phase, .settling)
        XCTAssertEqual(
            feedback.sequenceCancelCount,
            cancellationCountBeforeLateFinger + 1
        )
        XCTAssertNil(model.countdownStartedAt)

        scheduler.advance(by: settlingDuration)
        XCTAssertEqual(model.togetherSnapshot.phase, .countdown)
        XCTAssertEqual(feedback.togetherCountdownCount, 2)
    }

    func testTapInProvisionalTouchCanBeClearedBySwitchingModes() {
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .tapIn),
            feedback: RecordingFeedbackCoordinator()
        )
        model.tapInTouchBegan(.init(id: 7, location: CGPoint(x: 150, y: 220)))

        XCTAssertEqual(model.tapInPending.count, 1)
        XCTAssertTrue(model.isModeChangeEnabled)

        model.requestModeChange(to: .together)

        XCTAssertEqual(model.mode, .together)
        XCTAssertTrue(model.tapInPending.isEmpty)
    }

    func testTapInOnlyConfirmsACompletedEntryWithHaptics() {
        let feedback = RecordingFeedbackCoordinator()
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .tapIn),
            feedback: feedback
        )

        model.tapInTouchBegan(.init(id: 7, location: CGPoint(x: 90, y: 120)))
        model.tapInTouchEnded(.init(id: 7, location: CGPoint(x: 90, y: 120)), cancelled: true)
        XCTAssertFalse(feedback.cues.contains(.entryCommitted))

        model.tapInTouchBegan(.init(id: 8, location: CGPoint(x: 160, y: 240)))
        model.tapInTouchEnded(.init(id: 8, location: CGPoint(x: 160, y: 240)), cancelled: false)

        XCTAssertEqual(feedback.cues.filter { $0 == .entryCommitted }.count, 1)
        XCTAssertEqual(model.tapInSnapshot.entries.count, 1)
    }

    func testSettingsPreparationRejectsCountdownAndDiscardsOnlyProvisionalTapInTouches() {
        let scheduler = ManualChooserScheduler()
        let tapInCore = TapInChooserCore(scheduler: scheduler)
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .tapIn),
            tapInCore: tapInCore,
            feedback: RecordingFeedbackCoordinator()
        )

        XCTAssertTrue(model.addTapInEntryForAccessibility())
        model.tapInTouchBegan(.init(id: 9, location: CGPoint(x: 120, y: 180)))
        XCTAssertEqual(model.tapInPending.count, 1)

        XCTAssertTrue(model.prepareToPresentSettings())
        XCTAssertTrue(model.tapInPending.isEmpty)
        XCTAssertEqual(model.tapInSnapshot.entries.count, 1)

        XCTAssertTrue(model.addTapInEntryForAccessibility())
        model.pickTapIn()
        XCTAssertEqual(model.tapInSnapshot.phase, .countdown)
        XCTAssertFalse(model.prepareToPresentSettings())
    }

    func testTapInPickStartsItsImmediateCountdownPattern() {
        let feedback = RecordingFeedbackCoordinator()
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .tapIn),
            feedback: feedback
        )
        XCTAssertTrue(model.addTapInEntryForAccessibility())
        XCTAssertTrue(model.addTapInEntryForAccessibility())
        feedback.removeAllCues()

        model.pickTapIn()

        XCTAssertEqual(feedback.cues, [.tapInCountdown(duration: 1.0)])
    }

    func testTogetherResultCanSwitchDirectlyToPinball() {
        let scheduler = ManualChooserScheduler()
        let togetherCore = TogetherChooserCore(
            scheduler: scheduler,
            randomIndexGenerator: FixedRandomIndexGenerator(index: 0)
        )
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .together),
            togetherCore: togetherCore,
            feedback: RecordingFeedbackCoordinator()
        )

        model.togetherTouchBegan(.init(id: 1, location: CGPoint(x: 80, y: 120)))
        model.togetherTouchBegan(.init(id: 2, location: CGPoint(x: 220, y: 120)))
        scheduler.advance(
            by: settlingDuration + ChoiceAnticipationTimeline.chooser.duration
        )

        guard case .revealed = model.togetherSnapshot.phase else {
            return XCTFail("Expected a completed Chooser choice")
        }
        XCTAssertTrue(model.isModeChangeEnabled)

        model.requestModeChange(to: .pinball)

        XCTAssertEqual(model.mode, .pinball)
        XCTAssertNil(model.confirmation)
    }

    func testPinballResultSwitchesModesImmediatelyAndClearsSeats() async throws {
        let model = makePinballModel(feedback: RecordingFeedbackCoordinator())
        model.startPinball(reduceMotion: true)
        try await Task.sleep(for: .milliseconds(600))

        guard case .revealed = model.pinballPhase else {
            return XCTFail("Expected a completed Pinball choice")
        }
        XCTAssertTrue(model.isModeChangeEnabled)

        model.requestModeChange(to: .tapIn)

        XCTAssertEqual(model.mode, .tapIn)
        XCTAssertTrue(model.pinballSeats.isEmpty)
        XCTAssertNil(model.confirmation)
    }

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
        XCTAssertEqual(feedback.cues.filter { $0 == .pinballSettle }.count, 1)

        try await Task.sleep(for: .milliseconds(600))
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

    func testRenderedPinballCallbacksDriveCollisionAndRevealExactlyOnce() async throws {
        let feedback = RecordingFeedbackCoordinator()
        let model = makePinballModel(feedback: feedback)
        model.startPinball(reduceMotion: false)

        guard case .running(let run) = model.pinballPhase else {
            return XCTFail("Expected an active Pinball replay")
        }
        let event = try XCTUnwrap(
            ChooserAppModel.pinballCollisionFeedbackEvents(for: run).first {
                !$0.isFairnessDeflection
            }
        )
        feedback.removeAllCues()

        let renderedImpact = NativeAnalyticReplayImpact(
            vertexIndex: event.vertexIndex,
            progress: event.progress,
            speedFraction: 0.57,
            wallNormalImpulseFraction: 0.31,
            isCorner: event.isCorner
        )
        model.handlePinballRenderedImpact(
            runID: UUID(),
            impact: renderedImpact
        )
        model.handlePinballRenderedImpact(
            runID: run.id,
            impact: NativeAnalyticReplayImpact(
                vertexIndex: event.vertexIndex,
                progress: min(1, event.progress + 0.05),
                speedFraction: 0.57,
                isCorner: event.isCorner
            )
        )
        XCTAssertTrue(feedback.cues.isEmpty)

        model.handlePinballRenderedImpact(
            runID: run.id,
            impact: renderedImpact
        )
        model.handlePinballRenderedImpact(
            runID: run.id,
            impact: renderedImpact
        )
        XCTAssertEqual(
            feedback.cues,
            [
                .pinballCollision(
                    speedFraction: 0.57,
                    normalImpulseFraction: 0.31,
                    isCorner: event.isCorner
                )
            ]
        )

        model.handlePinballRenderedEndpointCompression(runID: UUID())
        XCTAssertEqual(feedback.cues.filter { $0 == .pinballSettle }.count, 0)
        model.handlePinballRenderedEndpointCompression(runID: run.id)
        model.handlePinballRenderedEndpointCompression(runID: run.id)
        XCTAssertEqual(feedback.cues.filter { $0 == .pinballSettle }.count, 1)

        model.handlePinballReplayFinished(runID: UUID())
        guard case .running(let unchangedRun) = model.pinballPhase else {
            return XCTFail("A stale scene must not complete the active replay")
        }
        XCTAssertEqual(unchangedRun.id, run.id)

        model.handlePinballReplayFinished(runID: run.id)
        model.handlePinballReplayFinished(runID: run.id)
        for _ in 0..<20 {
            if case .revealing = model.pinballPhase { break }
            await Task.yield()
        }
        guard case .revealing(let revealingRun, _, _) = model.pinballPhase else {
            return XCTFail("The rendered completion should begin the winner reveal")
        }
        XCTAssertEqual(revealingRun.id, run.id)
        XCTAssertEqual(feedback.cues.filter { $0 == .pinballSettle }.count, 1)

        try await Task.sleep(for: .milliseconds(600))
        guard case .revealed(let revealedRun) = model.pinballPhase else {
            return XCTFail("Expected the rendered run to finish revealing")
        }
        XCTAssertEqual(revealedRun.id, run.id)
        XCTAssertEqual(revealedRun.result.finalPoint, run.result.finalPoint)
        XCTAssertEqual(revealedRun.result.winningSeatID, run.result.winningSeatID)
        XCTAssertEqual(feedback.cues.filter { $0 == .pinballSettle }.count, 1)
    }

    func testRenderedFairBounceDrivesItsDistinctCueExactlyOnce() throws {
        let feedback = RecordingFeedbackCoordinator()
        let model = makePinballModel(feedback: feedback)
        model.startPinball(reduceMotion: false)

        guard case .running(let run) = model.pinballPhase else {
            return XCTFail("Expected an active Pinball replay")
        }
        let deflectorVertex = try XCTUnwrap(run.result.fairnessDeflectorVertexIndex)
        let event = try XCTUnwrap(
            ChooserAppModel.pinballCollisionFeedbackEvents(for: run).first {
                $0.vertexIndex == deflectorVertex
            }
        )
        XCTAssertTrue(event.isFairnessDeflection)
        feedback.removeAllCues()

        let untaggedImpact = NativeAnalyticReplayImpact(
            vertexIndex: event.vertexIndex,
            progress: event.progress,
            speedFraction: 0.68,
            wallNormalImpulseFraction: 0.74,
            isCorner: event.isCorner,
            isFairnessDeflection: false
        )
        model.handlePinballRenderedImpact(runID: run.id, impact: untaggedImpact)
        XCTAssertTrue(
            feedback.cues.isEmpty,
            "The scene and resolved run must agree on the authored deflector before feedback fires"
        )

        let fairImpact = NativeAnalyticReplayImpact(
            vertexIndex: event.vertexIndex,
            progress: event.progress,
            speedFraction: 0.68,
            wallNormalImpulseFraction: 0.74,
            isCorner: event.isCorner,
            isFairnessDeflection: true
        )
        model.handlePinballRenderedImpact(runID: UUID(), impact: fairImpact)
        model.handlePinballRenderedImpact(runID: run.id, impact: fairImpact)
        model.handlePinballRenderedImpact(runID: run.id, impact: fairImpact)

        XCTAssertEqual(feedback.cues, [
            .pinballFairBounce(
                speedFraction: 0.68,
                normalImpulseFraction: 0.74
            )
        ])
    }

    func testPinballRollingResistanceProfileStaysReadableAtSixtyFramesPerSecond() throws {
        let model = makePinballModel(feedback: RecordingFeedbackCoordinator())
        model.startPinball(reduceMotion: false)

        guard case .running(let run) = model.pinballPhase,
              let partition = model.pinballPartition() else {
            return XCTFail("Expected an active Pinball run")
        }

        XCTAssertEqual(run.curve.duration, 4.00, accuracy: 0.0001)
        XCTAssertEqual(run.curve.decelerationExponent, 5, accuracy: 0.0001)
        XCTAssertEqual(run.curve.terminalSpeedFraction, 0, accuracy: 0.0001)
        XCTAssertLessThan(run.curve.normalizedSpeed(at: 0), 0.42)
        XCTAssertGreaterThan(
            run.curve.normalizedSpeed(at: run.curve.duration * 0.80),
            0.14,
            "The longer high-inertia run must remain visibly alive before its smooth roll-off."
        )

        let perimeter = partition.bounds.width * 2 + partition.bounds.height * 2
        let distanceInPerimeters = run.result.trajectory.launch.distance / perimeter
        XCTAssertTrue(ChooserAppModel.pinballDistanceRangeInPerimeters.contains(distanceInPerimeters))

        let firstFrameTravel = try run.curve.distance(
            at: 1.0 / 60.0,
            totalDistance: run.result.trajectory.launch.distance
        )
        // The longer run preserves launch speed while leaving room to roll out.
        XCTAssertGreaterThan(firstFrameTravel, 15)
        XCTAssertLessThan(firstFrameTravel, 24)
    }

    func testFlickStrengthControlsFlightDurationAndEndpointStillOwnsWinner() throws {
        let weakModel = makePinballModel(feedback: RecordingFeedbackCoordinator())
        weakModel.startPinball(
            flickIntent: try PinballFlickIntent(
                releasePoint: CGPoint(x: 120, y: 180),
                direction: CGVector(dx: 1, dy: 0),
                speed: 400
            ),
            reduceMotion: false
        )
        guard case .running(let weakRun) = weakModel.pinballPhase,
              let weakPartition = weakModel.pinballPartition() else {
            return XCTFail("Expected a weak-flick run")
        }
        XCTAssertEqual(weakRun.curve.duration, 4.20, accuracy: 0.000_001)
        XCTAssertEqual(weakRun.normalizedStrength, 0, accuracy: 0.000_001)
        XCTAssertEqual(weakRun.launchEnergy, 0.62, accuracy: 0.000_001)
        XCTAssertEqual(
            weakRun.result.winningSeatID,
            weakPartition.seatIDOrNil(containing: weakRun.result.finalPoint)
        )

        let strongModel = makePinballModel(feedback: RecordingFeedbackCoordinator())
        strongModel.startPinball(
            flickIntent: try PinballFlickIntent(
                releasePoint: CGPoint(x: 120, y: 180),
                direction: CGVector(dx: 0, dy: -1),
                speed: 1_600
            ),
            reduceMotion: false
        )
        guard case .running(let strongRun) = strongModel.pinballPhase,
              let strongPartition = strongModel.pinballPartition() else {
            return XCTFail("Expected a strong-flick run")
        }
        XCTAssertEqual(strongRun.curve.duration, 3.80, accuracy: 0.000_001)
        XCTAssertEqual(strongRun.normalizedStrength, 1, accuracy: 0.000_001)
        XCTAssertEqual(strongRun.launchEnergy, 1, accuracy: 0.000_001)
        XCTAssertEqual(strongRun.curve.decelerationExponent, 5, accuracy: 0.000_001)
        XCTAssertEqual(strongRun.curve.terminalSpeedFraction, 0, accuracy: 0.000_001)
        XCTAssertEqual(
            strongRun.result.winningSeatID,
            strongPartition.seatIDOrNil(containing: strongRun.result.finalPoint)
        )
    }

    func testPinballPartitionKeepsThirtyPointBallAndShadowInsidePlayfield() {
        let model = makePinballModel(feedback: RecordingFeedbackCoordinator())
        guard let bounds = model.pinballPartition()?.bounds else {
            return XCTFail("Expected Pinball partition")
        }

        XCTAssertEqual(bounds.minX, NativePinballReplayMetrics.collisionInset, accuracy: 0.000_001)
        XCTAssertEqual(bounds.minY, NativePinballReplayMetrics.collisionInset, accuracy: 0.000_001)
        XCTAssertEqual(bounds.maxX, 390 - NativePinballReplayMetrics.collisionInset, accuracy: 0.000_001)
        XCTAssertEqual(bounds.maxY, 700 - NativePinballReplayMetrics.collisionInset, accuracy: 0.000_001)
    }

    func testCoreHapticsPrewarmsAtLaunchForegroundAndFirstChooserFinger() {
        let feedback = RecordingFeedbackCoordinator()
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .together),
            feedback: feedback
        )
        XCTAssertEqual(feedback.prepareCount, 1)

        model.handleSceneBecameActive()
        XCTAssertEqual(feedback.prepareCount, 2)

        model.togetherTouchBegan(.init(id: 1, location: CGPoint(x: 80, y: 120)))
        XCTAssertEqual(feedback.prepareCount, 3)
        model.togetherTouchBegan(.init(id: 2, location: CGPoint(x: 220, y: 120)))
        XCTAssertEqual(feedback.prepareCount, 3)
    }

    func testPinballConfigurationAndUndoUseTheirSemanticCues() {
        let feedback = RecordingFeedbackCoordinator()
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .pinball),
            feedback: feedback
        )
        model.updatePinballPlayfield(size: CGSize(width: 390, height: 700))

        model.configureAccessiblePinballSeats(count: 6)
        XCTAssertEqual(feedback.cues.last, .confirmation)

        feedback.removeAllCues()
        model.undoPinballSeat()
        XCTAssertEqual(feedback.cues, [.undo])
        XCTAssertEqual(model.pinballSeats.count, 5)
    }

    func testFeedbackCoordinatorCanOperateSilentlyWhenHardwareAndAudioAreUnavailable() {
        let coordinator = NativeFeedbackCoordinator(
            hapticsEnabled: false,
            audioPolicy: .never
        )

        coordinator.prepare()

        XCTAssertEqual(coordinator.play(.entryCommitted), .silent)
        XCTAssertEqual(coordinator.play(.choiceWinner), .silent)
        XCTAssertEqual(coordinator.play(.pinballSettle), .silent)
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
final class RecordingFeedbackCoordinator: NativeFeedbackCoordinating {
    let supportsCoreHaptics = false
    private(set) var cues: [NativeFeedbackCue] = []
    private(set) var prepareCount = 0
    private(set) var stopCount = 0
    private(set) var sequenceCancelCount = 0

    var togetherCountdownCount: Int {
        cues.reduce(into: 0) { count, cue in
            if case .togetherCountdown = cue { count += 1 }
        }
    }

    func prepare() {
        prepareCount += 1
    }

    @discardableResult
    func play(_ cue: NativeFeedbackCue) -> NativeFeedbackDelivery {
        cues.append(cue)
        return .silent
    }

    func cancelSequence() {
        sequenceCancelCount += 1
    }

    func stopAll() {
        stopCount += 1
    }

    func removeAllCues() {
        cues.removeAll()
    }
}

private extension PinballRadialPartition {
    func seatIDOrNil(containing point: CGPoint) -> Int? {
        try? seatID(containing: point)
    }
}
