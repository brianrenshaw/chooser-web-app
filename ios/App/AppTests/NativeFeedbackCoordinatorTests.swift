import CoreGraphics
import XCTest
@testable import App

@MainActor
final class NativeFeedbackCoordinatorTests: XCTestCase {
    func testDisabledHapticsNeverDeliverGameplayThroughEitherBackend() {
        for supportsCoreHaptics in [false, true] {
            let coordinator = NativeFeedbackCoordinator(
                testSupportsCoreHaptics: supportsCoreHaptics,
                hapticsEnabled: false,
                audioPolicy: .never
            )
            coordinator.coreHapticPlaybackOverride = { _ in
                XCTFail("Disabled haptics must not start Core Haptics playback")
            }
            coordinator.onUIKitSequencePulse = { _ in
                XCTFail("Disabled haptics must not deliver UIKit fallback pulses")
            }
            for cue: NativeFeedbackCue in [
                .entryCommitted, .togetherCountdown, .tapInCountdown(duration: 1),
                .chooserWinner, .choiceWinner, .pinballLaunch(strength: 1),
                .pinballCollision(speedFraction: 1, normalImpulseFraction: 1, isCorner: true),
                .pinballFairBounce(speedFraction: 1, normalImpulseFraction: 1), .pinballSettle
            ] {
                XCTAssertEqual(coordinator.play(cue), .silent)
            }
        }
    }

    func testGameplayPatternsStayBoundedAndLeaveWinnerIntensityHeadroom() {
        let winnerIntensity = ChoiceAnticipationTimeline.chooser.winnerHaptic.attackIntensity
        var cues: [NativeFeedbackCue] = [
            .entryCommitted, .togetherCountdown, .tapInCountdown(duration: 1)
        ]
        for energy in [-1.0, 0, 0.25, 0.5, 1, 2] {
            cues += [
                .pinballLaunch(strength: energy),
                .pinballCollision(speedFraction: energy, normalImpulseFraction: energy, isCorner: true),
                .pinballFairBounce(speedFraction: energy, normalImpulseFraction: energy)
            ]
        }
        for cue in cues {
            for event in cue.hapticEventSpecs {
                XCTAssertTrue((0...1).contains(event.intensity))
                XCTAssertTrue((0...1).contains(event.sharpness))
                if event.kind == .transient {
                    XCTAssertLessThan(event.intensity, winnerIntensity)
                }
            }
            for curve in cue.hapticParameterCurveSpecs {
                XCTAssertTrue(curve.controlPoints.allSatisfy { (0...1).contains($0.value) })
            }
            for pulse in cue.uiKitSequencePulses ?? [] {
                XCTAssertTrue((0...1).contains(pulse.intensity))
            }
        }
    }

    func testTogetherSettlingWindowIsTactilelySilent() {
        let settling = NativeFeedbackCue.settling(duration: 1.5).hapticEventSpecs

        XCTAssertTrue(settling.isEmpty)
        XCTAssertNil(NativeFeedbackCue.settling(duration: 1.5).uiKitSequencePulses)
        XCTAssertFalse(NativeFeedbackCue.settling(duration: 1.5).isSequence)
        XCTAssertFalse(NativeFeedbackCue.settling(duration: 1.5).permitsAudioFallback)
    }

    func testSilentSettlingReturnsSilentDeliveryEvenWhenAudioPolicyIsAlways() {
        let coordinator = NativeFeedbackCoordinator(
            hapticsEnabled: true,
            audioPolicy: .always
        )

        XCTAssertEqual(coordinator.play(.settling(duration: 1.5)), .silent)
    }

    func testUnavailableAudioEngineCapabilityNeverStartsSynthesizedFallback() {
        let coordinator = NativeFeedbackCoordinator(
            testSupportsCoreHaptics: false,
            testAudioEngineCapability: .unavailable,
            audioPolicy: .always
        )

        coordinator.prepare()

        XCTAssertEqual(
            coordinator.play(.warning),
            .uiKit,
            "Tactile feedback remains available without attempting synthesized audio"
        )
    }

    func testSimulatorDisablesAudioEngineStartupAtTheProcessCapabilitySeam() {
#if targetEnvironment(simulator)
        XCTAssertEqual(NativeAudioEngineCapability.currentProcess, .unavailable)
        XCTAssertFalse(NativeAudioEngineCapability.currentProcess.permitsStartup)
#else
        XCTAssertEqual(NativeAudioEngineCapability.currentProcess, .available)
        XCTAssertTrue(NativeAudioEngineCapability.currentProcess.permitsStartup)
#endif
    }

    func testChooserAnticipationUsesTheSharedDecisionTimeline() throws {
        let timeline = ChoiceAnticipationTimeline.chooser
        let cue = NativeFeedbackCue.togetherCountdown
        let haptics = cue.hapticEventSpecs
        let fallback = try XCTUnwrap(cue.uiKitSequencePulses)

        assertTimes(haptics, equal: timeline.beats.map(\.time))
        XCTAssertEqual(
            haptics.map(\.kind),
            Array(repeating: .transient, count: timeline.beats.count)
        )
        XCTAssertEqual(haptics.map(\.intensity), timeline.beats.map(\.intensity))
        XCTAssertEqual(haptics.map(\.sharpness), timeline.beats.map(\.sharpness))

        XCTAssertEqual(
            fallback.map(\.impact),
            Array(repeating: .heavy, count: 6)
        )
        XCTAssertEqual(fallback.map(\.intensity), timeline.beats.map(\.fallbackIntensity))
        assertPulseTimes(fallback, equal: timeline.beats.map(\.time))
        XCTAssertFalse(cue.permitsAudioFallback)
    }

    func testChooserWinnerUsesTheSharedDecisiveLanding() throws {
        let timeline = ChoiceAnticipationTimeline.chooser
        let winner = timeline.winnerHaptic
        let contactTime = timeline.winnerContactTime
        let cue = NativeFeedbackCue.chooserWinner
        let events = cue.hapticEventSpecs
        let curves = cue.hapticParameterCurveSpecs
        let fallback = try XCTUnwrap(cue.uiKitSequencePulses)

        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0], .init(
            kind: .transient,
            intensity: winner.attackIntensity,
            sharpness: winner.attackSharpness,
            relativeTime: contactTime + winner.attackTime,
            duration: 0
        ))
        XCTAssertEqual(events[1], .init(
            kind: .continuous,
            intensity: 1.0,
            sharpness: winner.bodySharpness,
            relativeTime: contactTime + winner.bodyStartTime,
            duration: winner.bodyDuration
        ))

        let curve = try XCTUnwrap(curves.first)
        XCTAssertEqual(curves.count, 1)
        XCTAssertEqual(
            curve.relativeTime,
            contactTime + winner.bodyStartTime,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            curve.controlPoints,
            winner.intensityCurve.map {
                .init(relativeTime: $0.relativeTime, value: $0.intensity)
            }
        )
        XCTAssertEqual(
            fallback,
            [
                .init(impact: .heavy, intensity: 1.0, relativeTime: contactTime),
                .init(impact: .heavy, intensity: 1.0, relativeTime: contactTime + 0.140),
                .init(impact: .heavy, intensity: 0.95, relativeTime: contactTime + 0.340),
                .init(impact: .medium, intensity: 0.65, relativeTime: contactTime + 0.540)
            ]
        )
        XCTAssertNil(cue.uiKitImmediatePulse)
        XCTAssertTrue(cue.isSequence)
        XCTAssertFalse(cue.permitsAudioFallback)
    }

    func testTapInKeepsOneSecondAnticipationWithStrongerBeats() throws {
        let cue = NativeFeedbackCue.tapInCountdown(duration: 1.0)
        let haptics = cue.hapticEventSpecs
        let fallback = try XCTUnwrap(cue.uiKitSequencePulses)

        assertTimes(haptics, equal: [0.06, 0.40, 0.69, 0.89])
        XCTAssertEqual(haptics.map(\.intensity), [0.78, 0.86, 0.93, 0.98])
        XCTAssertEqual(haptics.map(\.sharpness), [0.65, 0.73, 0.81, 0.90])
        assertPulseTimes(fallback, equal: [0.06, 0.40, 0.69, 0.89])
    }

    func testTapInChoiceWinnerKeepsTheSameEnvelopeWithoutChooserContactOffset() throws {
        let cue = NativeFeedbackCue.choiceWinner
        let events = cue.hapticEventSpecs
        let curves = cue.hapticParameterCurveSpecs
        let fallback = try XCTUnwrap(cue.uiKitSequencePulses)
        let timeline = ChoiceAnticipationTimeline.chooser
        let shared = timeline.winnerHaptic

        XCTAssertEqual(events.count, 2)
        let chooserEvents = NativeFeedbackCue.chooserWinner.hapticEventSpecs
        XCTAssertEqual(chooserEvents.count, events.count)
        for (tapInEvent, chooserEvent) in zip(events, chooserEvents) {
            XCTAssertEqual(tapInEvent.kind, chooserEvent.kind)
            XCTAssertEqual(tapInEvent.intensity, chooserEvent.intensity)
            XCTAssertEqual(tapInEvent.sharpness, chooserEvent.sharpness)
            XCTAssertEqual(tapInEvent.duration, chooserEvent.duration)
            XCTAssertEqual(
                chooserEvent.relativeTime - tapInEvent.relativeTime,
                timeline.winnerContactTime,
                accuracy: 0.000_001
            )
        }

        let attack = try XCTUnwrap(events.first)
        XCTAssertEqual(attack.kind, .transient)
        XCTAssertEqual(attack.intensity, shared.attackIntensity, accuracy: 0.000_001)
        XCTAssertEqual(attack.sharpness, shared.attackSharpness, accuracy: 0.000_001)
        XCTAssertEqual(attack.relativeTime, shared.attackTime, accuracy: 0.000_001)

        let body = try XCTUnwrap(events.first { $0.kind == .continuous })
        XCTAssertEqual(body.kind, .continuous)
        XCTAssertEqual(body.intensity, 1.0, accuracy: 0.000_001)
        XCTAssertEqual(body.sharpness, shared.bodySharpness, accuracy: 0.000_001)
        XCTAssertEqual(body.relativeTime, shared.bodyStartTime, accuracy: 0.000_001)
        XCTAssertEqual(body.duration, shared.bodyDuration, accuracy: 0.000_001)
        XCTAssertEqual(events.filter { $0.kind == .transient }.count, 1)

        let curve = try XCTUnwrap(curves.first)
        XCTAssertEqual(curves.count, 1)
        XCTAssertEqual(curve.parameter, .intensityControl)
        XCTAssertEqual(curve.relativeTime, shared.bodyStartTime, accuracy: 0.000_001)
        XCTAssertEqual(
            curve.controlPoints,
            shared.intensityCurve.map {
                .init(relativeTime: $0.relativeTime, value: $0.intensity)
            }
        )

        XCTAssertEqual(
            fallback,
            [
                .init(impact: .heavy, intensity: 1.0, relativeTime: 0),
                .init(impact: .heavy, intensity: 1.0, relativeTime: 0.140),
                .init(impact: .heavy, intensity: 0.95, relativeTime: 0.340),
                .init(impact: .medium, intensity: 0.65, relativeTime: 0.540)
            ]
        )
        XCTAssertNil(cue.uiKitImmediatePulse)
        XCTAssertTrue(cue.isSequence)
        XCTAssertFalse(cue.permitsAudioFallback)
    }

    func testEntryCommitIsAFirmContactWithAShortBody() throws {
        let cue = NativeFeedbackCue.entryCommitted
        let events = cue.hapticEventSpecs
        let curve = try XCTUnwrap(cue.hapticParameterCurveSpecs.first)
        let fallback = try XCTUnwrap(cue.uiKitSequencePulses)

        XCTAssertEqual(events, [
            .init(
                kind: .transient,
                intensity: 0.85,
                sharpness: 0.75,
                relativeTime: 0,
                duration: 0
            ),
            .init(
                kind: .continuous,
                intensity: 1.0,
                sharpness: 0.45,
                relativeTime: 0.008,
                duration: 0.11
            )
        ])
        XCTAssertEqual(curve.relativeTime, 0.008, accuracy: 0.000_001)
        XCTAssertEqual(curve.controlPoints, [
            .init(relativeTime: 0, value: 0.85),
            .init(relativeTime: 0.040, value: 0.65),
            .init(relativeTime: 0.110, value: 0.05)
        ])
        XCTAssertEqual(fallback, [
            .init(impact: .heavy, intensity: 1.0, relativeTime: 0),
            .init(impact: .heavy, intensity: 0.65, relativeTime: 0.070)
        ])
        XCTAssertTrue(cue.isSequence)
    }

    func testEntryCommitCoalescesSimultaneousContactsForFiftyMilliseconds() {
        var now: TimeInterval = 100
        let coordinator = NativeFeedbackCoordinator(
            testSupportsCoreHaptics: false,
            audioPolicy: .never,
            monotonicTime: { now }
        )
        var pulses: [NativeUIKitSequencePulse] = []
        coordinator.onUIKitSequencePulse = { pulses.append($0) }

        XCTAssertEqual(coordinator.play(.entryCommitted), .uiKit)
        now += 0.020
        XCTAssertEqual(coordinator.play(.entryCommitted), .silent)
        now += 0.029
        XCTAssertEqual(coordinator.play(.entryCommitted), .silent)
        now += 0.002
        XCTAssertEqual(coordinator.play(.entryCommitted), .uiKit)

        XCTAssertEqual(
            pulses,
            [
                .init(impact: .heavy, intensity: 1.0, relativeTime: 0),
                .init(impact: .heavy, intensity: 1.0, relativeTime: 0)
            ],
            "Only the first physical contact in each 50ms cluster should reach the Taptic Engine"
        )
        coordinator.cancelSequence()
    }

    func testPinballWinnerSharesTheFirmSustainedRumbleAtItsOwnContact() throws {
        let cue = NativeFeedbackCue.pinballSettle
        XCTAssertEqual(cue.hapticEventSpecs, NativeFeedbackCue.choiceWinner.hapticEventSpecs)
        XCTAssertEqual(cue.hapticParameterCurveSpecs, NativeFeedbackCue.choiceWinner.hapticParameterCurveSpecs)
        XCTAssertEqual(cue.uiKitSequencePulses, NativeFeedbackCue.choiceWinner.uiKitSequencePulses)
        XCTAssertNil(cue.uiKitImmediatePulse)
        XCTAssertTrue(cue.isSequence)
        XCTAssertTrue(cue.permitsAudioFallback)
    }

    func testPinballLaunchCueTracksCommittedFlickStrength() throws {
        let weak = NativeFeedbackCue.pinballLaunch(strength: 0).hapticEventSpecs
        let strong = NativeFeedbackCue.pinballLaunch(strength: 1).hapticEventSpecs

        XCTAssertEqual(weak.count, 2)
        XCTAssertEqual(strong.count, 2)
        XCTAssertGreaterThan(strong[0].intensity, weak[0].intensity)
        XCTAssertGreaterThan(strong[0].sharpness, weak[0].sharpness)
        XCTAssertGreaterThan(strong[1].intensity, weak[1].intensity)
        XCTAssertGreaterThan(strong[1].sharpness, weak[1].sharpness)
        XCTAssertTrue((weak + strong).allSatisfy {
            (0...1).contains($0.intensity) && (0...1).contains($0.sharpness)
        })
    }

    func testWarningPatternRemainsBounded() {
        let warning = NativeFeedbackCue.warning.hapticEventSpecs

        XCTAssertEqual(warning.map(\.intensity), [0.42, 0.28])
        XCTAssertTrue(warning.allSatisfy {
            (0...1).contains($0.intensity) && (0...1).contains($0.sharpness)
        })
    }

    func testPinballCollisionProfileTracksSpeedAndCornerEnergy() throws {
        let stopped = try XCTUnwrap(
            NativeFeedbackCue.pinballCollision(
                speedFraction: 0,
                normalImpulseFraction: 1,
                isCorner: false
            ).hapticEventSpecs.first
        )
        let glancing = try XCTUnwrap(
            NativeFeedbackCue.pinballCollision(
                speedFraction: 1,
                normalImpulseFraction: 0.15,
                isCorner: false
            ).hapticEventSpecs.first
        )
        let moving = try XCTUnwrap(
            NativeFeedbackCue.pinballCollision(
                speedFraction: 1,
                normalImpulseFraction: 1,
                isCorner: false
            ).hapticEventSpecs.first
        )
        let corner = try XCTUnwrap(
            NativeFeedbackCue.pinballCollision(
                speedFraction: 1,
                normalImpulseFraction: 1,
                isCorner: true
            ).hapticEventSpecs.first
        )

        XCTAssertEqual(stopped.intensity, 0.38, accuracy: 0.000_001)
        XCTAssertEqual(stopped.sharpness, 0.50, accuracy: 0.000_001)
        XCTAssertGreaterThan(glancing.intensity, stopped.intensity)
        XCTAssertGreaterThan(glancing.sharpness, stopped.sharpness)
        XCTAssertGreaterThan(moving.intensity, glancing.intensity)
        XCTAssertGreaterThan(moving.sharpness, glancing.sharpness)
        XCTAssertGreaterThan(corner.intensity, moving.intensity)
        XCTAssertGreaterThan(corner.sharpness, moving.sharpness)
    }

    func testPinballFairBounceIsASpringyImpactBelowTheFinalSettle() throws {
        let weakCue = NativeFeedbackCue.pinballFairBounce(
            speedFraction: 0,
            normalImpulseFraction: 0
        )
        let strongCue = NativeFeedbackCue.pinballFairBounce(
            speedFraction: 1,
            normalImpulseFraction: 1
        )
        let weak = weakCue.hapticEventSpecs
        let strong = strongCue.hapticEventSpecs
        let settle = NativeFeedbackCue.pinballSettle.hapticEventSpecs

        XCTAssertEqual(weak, [
            .init(
                kind: .transient,
                intensity: 0.82,
                sharpness: 0.65,
                relativeTime: 0,
                duration: 0
            ),
            .init(
                kind: .continuous,
                intensity: 1,
                sharpness: 0.45,
                relativeTime: 0.004,
                duration: 0.075
            )
        ])
        XCTAssertEqual(strong[0].intensity, 0.98, accuracy: 0.000_001)
        XCTAssertEqual(strong[0].sharpness, 0.90, accuracy: 0.000_001)
        XCTAssertEqual(strong[1], weak[1])
        let curve = try XCTUnwrap(strongCue.hapticParameterCurveSpecs.first)
        XCTAssertEqual(strongCue.hapticParameterCurveSpecs.count, 1)
        XCTAssertEqual(curve.parameter, .intensityControl)
        XCTAssertEqual(curve.relativeTime, 0.004, accuracy: 0.000_001)
        XCTAssertEqual(curve.controlPoints.map(\.relativeTime), [0, 0.024, 0.075])
        for (point, expected): (NativeHapticParameterCurveControlPointSpec, Float) in zip(
            curve.controlPoints, [0.90, 0.65, 0.04]
        ) {
            XCTAssertEqual(point.value, expected, accuracy: 0.000_001)
        }

        XCTAssertLessThan(strong[0].intensity, settle[0].intensity)
        XCTAssertLessThan(sequenceEndTime(strong), sequenceEndTime(settle))
        let weakFallback = try XCTUnwrap(weakCue.uiKitImmediatePulse)
        let strongFallback = try XCTUnwrap(strongCue.uiKitImmediatePulse)
        XCTAssertEqual(weakFallback.impact, .rigid)
        XCTAssertEqual(weakFallback.intensity, 0.88, accuracy: 0.000_001)
        XCTAssertEqual(weakFallback.relativeTime, 0, accuracy: 0.000_001)
        XCTAssertEqual(strongFallback.impact, .rigid)
        XCTAssertEqual(strongFallback.intensity, 1.0, accuracy: 0.000_001)
        XCTAssertEqual(strongFallback.relativeTime, 0, accuracy: 0.000_001)
        XCTAssertFalse(strongCue.isSequence)
        XCTAssertFalse(strongCue.permitsAudioFallback)
    }

    func testPinballCollisionScheduleHasReadableSpacingAndWinnerQuietWindow() throws {
        let bounds = CGRect(x: 13, y: 13, width: 364, height: 674)
        let partition = try PinballRadialPartition(
            bounds: bounds,
            taps: PinballTestFixtures.radialTaps(count: 6, in: bounds)
        )
        let perimeter = bounds.width * 2 + bounds.height * 2
        let launch = try PinballLaunch(
            start: CGPoint(x: bounds.midX + 17, y: bounds.midY - 23),
            direction: CGVector(dx: 0.83, dy: 0.56),
            distance: perimeter * 2.5
        )
        let result = try PinballRoundResolver.resolve(launch: launch, partition: partition)
        let curve = try PinballMotionProfile(
            duration: ChooserAppModel.pinballFlightDuration
        )
        let run = NativePinballRun(result: result, curve: curve)

        let events = ChooserAppModel.pinballCollisionFeedbackEvents(for: run)

        XCTAssertFalse(events.isEmpty)
        XCTAssertGreaterThanOrEqual(
            events.first?.time ?? 0,
            ChooserAppModel.pinballCollisionMinimumSpacing
        )
        XCTAssertLessThanOrEqual(
            events.last?.time ?? .infinity,
            curve.duration - ChooserAppModel.pinballWinnerQuietWindow + 0.000_001
        )
        for pair in zip(events, events.dropFirst()) {
            XCTAssertGreaterThanOrEqual(
                pair.1.time - pair.0.time,
                ChooserAppModel.pinballCollisionMinimumSpacing - 0.000_001
            )
            XCTAssertLessThanOrEqual(pair.1.speedFraction, pair.0.speedFraction)
        }
        for event in events {
            XCTAssertEqual(
                event.speedFraction,
                run.launchEnergy * Double(curve.remainingSpeedFraction(at: event.time)),
                accuracy: 0.000_001
            )
        }
    }

    func testFairBounceBypassesThinningWithoutChangingOrdinaryCollisionRules() throws {
        let bounds = CGRect(x: 13, y: 13, width: 364, height: 674)
        let partition = try PinballRadialPartition(
            bounds: bounds,
            taps: PinballTestFixtures.radialTaps(count: 6, in: bounds)
        )
        let perimeter = bounds.width * 2 + bounds.height * 2
        let launch = try PinballLaunch(
            start: CGPoint(x: bounds.maxX - 0.01, y: bounds.midY),
            direction: CGVector(dx: 1, dy: 0.1),
            distance: perimeter * 2.5
        )
        let ordinaryResult = try PinballRoundResolver.resolve(
            launch: launch,
            partition: partition
        )
        let curve = try PinballMotionProfile(duration: ChooserAppModel.pinballFlightDuration)
        let ordinaryRun = NativePinballRun(result: ordinaryResult, curve: curve)
        let ordinaryEvents = ChooserAppModel.pinballCollisionFeedbackEvents(for: ordinaryRun)

        XCTAssertFalse(
            ordinaryEvents.contains { $0.vertexIndex == 1 },
            "A wall contact inside the launch quiet window remains visually present but tactilely thinned"
        )

        let fairResult = PinballRoundResult(
            trajectory: ordinaryResult.trajectory,
            winningRegion: ordinaryResult.winningRegion,
            fairnessDeflectorVertexIndex: 1
        )
        let fairRun = NativePinballRun(result: fairResult, curve: curve)
        let fairEvents = ChooserAppModel.pinballCollisionFeedbackEvents(for: fairRun)
        let fairEvent = try XCTUnwrap(fairEvents.first { $0.vertexIndex == 1 })

        XCTAssertTrue(fairEvent.isFairnessDeflection)
        XCTAssertLessThan(fairEvent.time, ChooserAppModel.pinballCollisionMinimumSpacing)
        if let nextOrdinary = fairEvents.first(where: {
            !$0.isFairnessDeflection && $0.time > fairEvent.time
        }) {
            XCTAssertGreaterThanOrEqual(
                nextOrdinary.time - fairEvent.time,
                ChooserAppModel.pinballCollisionMinimumSpacing - 0.000_001,
                "The authored bumper must reserve enough tactile space to remain legible"
            )
        }
        for pair in zip(
            fairEvents.filter { !$0.isFairnessDeflection },
            fairEvents.filter { !$0.isFairnessDeflection }.dropFirst()
        ) {
            XCTAssertGreaterThanOrEqual(
                pair.1.time - pair.0.time,
                ChooserAppModel.pinballCollisionMinimumSpacing - 0.000_001
            )
        }
    }

    func testUIKitFallbackDeliversTheRealSequenceAndCancellationStopsLaterPulses() async throws {
        let coordinator = NativeFeedbackCoordinator(
            testSupportsCoreHaptics: false,
            audioPolicy: .never
        )
        var delivered: [NativeUIKitSequencePulse] = []
        coordinator.onUIKitSequencePulse = { delivered.append($0) }

        XCTAssertEqual(
            coordinator.play(.togetherCountdown),
            .uiKit
        )
        try await Task.sleep(for: .milliseconds(300))
        let firstBeatTime = try XCTUnwrap(
            ChoiceAnticipationTimeline.chooser.beats.first?.time
        )
        XCTAssertEqual(delivered.map(\.relativeTime), [firstBeatTime])

        coordinator.cancelSequence()
        try await Task.sleep(for: .milliseconds(900))
        XCTAssertEqual(
            delivered.map(\.relativeTime),
            [firstBeatTime],
            "No scheduled fallback impacts may escape cancellation"
        )
    }

    func testUIKitWinnerFallbackApproximatesTheSustainedBodyAndCancelsCleanly() async throws {
        let coordinator = NativeFeedbackCoordinator(
            testSupportsCoreHaptics: false,
            audioPolicy: .never
        )
        var delivered: [NativeUIKitSequencePulse] = []
        coordinator.onUIKitSequencePulse = { delivered.append($0) }

        XCTAssertEqual(coordinator.play(.choiceWinner), .uiKit)
        try await Task.sleep(for: .milliseconds(220))
        XCTAssertEqual(
            delivered,
            [
                .init(impact: .heavy, intensity: 1.0, relativeTime: 0),
                .init(impact: .heavy, intensity: 1.0, relativeTime: 0.140)
            ]
        )

        coordinator.cancelSequence()
        try await Task.sleep(for: .milliseconds(900))
        XCTAssertEqual(delivered.count, 2, "The decaying fallback body must obey cancellation")
    }

    func testCoreHapticsPlaybackFailureUsesTheActualUIKitFallbackBranch() {
        enum InjectedFailure: Error { case unavailable }

        let coordinator = NativeFeedbackCoordinator(
            testSupportsCoreHaptics: true,
            audioPolicy: .never
        )
        var delivered: [NativeUIKitSequencePulse] = []
        coordinator.onUIKitSequencePulse = { delivered.append($0) }
        coordinator.coreHapticPlaybackOverride = { _ in
            throw InjectedFailure.unavailable
        }

        XCTAssertEqual(coordinator.play(.choiceWinner), .uiKit)
        XCTAssertEqual(
            delivered,
            [.init(impact: .heavy, intensity: 1.0, relativeTime: 0)]
        )
    }

    private func assertTimes(
        _ events: [NativeHapticEventSpec],
        equal expected: [TimeInterval],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(events.count, expected.count, file: file, line: line)
        for (event, expectedTime) in zip(events, expected) {
            XCTAssertEqual(
                event.relativeTime,
                expectedTime,
                accuracy: 0.000_001,
                file: file,
                line: line
            )
        }
    }

    private func assertPulseTimes(
        _ pulses: [NativeUIKitSequencePulse],
        equal expected: [TimeInterval],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(pulses.count, expected.count, file: file, line: line)
        for (pulse, expectedTime) in zip(pulses, expected) {
            XCTAssertEqual(
                pulse.relativeTime,
                expectedTime,
                accuracy: 0.000_001,
                file: file,
                line: line
            )
        }
    }

    private func sequenceEndTime(_ events: [NativeHapticEventSpec]) -> TimeInterval {
        events.map { $0.relativeTime + $0.duration }.max() ?? 0
    }
}
