@preconcurrency import AVFoundation
@preconcurrency import CoreHaptics
import OSLog
import UIKit

public enum NativeFeedbackCue: Equatable, Sendable {
    case modeChanged
    case entryCommitted
    case settling(duration: TimeInterval)
    case togetherCountdown
    case tapInCountdown(duration: TimeInterval)
    case chooserWinner
    case choiceWinner
    case pinballSettle
    case undo
    case clearCommitted
    case confirmation
    case pinballLaunch(strength: Double)
    case pinballCollision(
        speedFraction: Double,
        normalImpulseFraction: Double,
        isCorner: Bool
    )
    case pinballFairBounce(
        speedFraction: Double,
        normalImpulseFraction: Double
    )
    case warning
}

enum NativeHapticEventKind: Equatable, Sendable {
    case transient
    case continuous
}

struct NativeHapticEventSpec: Equatable, Sendable {
    let kind: NativeHapticEventKind
    let intensity: Float
    let sharpness: Float
    let relativeTime: TimeInterval
    let duration: TimeInterval
}

enum NativeHapticDynamicParameterKind: Equatable, Sendable {
    case intensityControl
}

struct NativeHapticParameterCurveControlPointSpec: Equatable, Sendable {
    let relativeTime: TimeInterval
    let value: Float
}

struct NativeHapticParameterCurveSpec: Equatable, Sendable {
    let parameter: NativeHapticDynamicParameterKind
    let relativeTime: TimeInterval
    let controlPoints: [NativeHapticParameterCurveControlPointSpec]
}

enum NativeUIKitSequenceImpact: Equatable, Sendable {
    case soft
    case light
    case medium
    case rigid
    case heavy
}

struct NativeUIKitSequencePulse: Equatable, Sendable {
    let impact: NativeUIKitSequenceImpact
    let intensity: CGFloat
    let relativeTime: TimeInterval
}

public enum NativeFeedbackDelivery: Equatable, Sendable {
    case coreHaptics
    case coreHapticsAndAudio
    case uiKit
    case uiKitAndAudio
    case audio
    case silent
}

public enum NativeAudioFallbackPolicy: Sendable {
    case never
    case whenCoreHapticsUnavailable
    case always
}

/// Whether this process can safely start an AVAudioEngine for synthesized fallback cues.
/// CoreSimulator's audio service can abort inside AURemoteIO instead of surfacing a Swift
/// error, so the simulator deliberately uses the tactile/silent delivery paths only.
enum NativeAudioEngineCapability: Equatable, Sendable {
    case available
    case unavailable

    static var currentProcess: NativeAudioEngineCapability {
#if targetEnvironment(simulator)
        .unavailable
#else
        .available
#endif
    }

    var permitsStartup: Bool { self == .available }
}

@MainActor
public protocol NativeFeedbackCoordinating: AnyObject {
    var supportsCoreHaptics: Bool { get }
    func prepare()

    @discardableResult
    func play(_ cue: NativeFeedbackCue) -> NativeFeedbackDelivery

    func cancelSequence()
    func stopAll()
}

/// Coordinates feedback without owning game state. Core Haptics is preferred, UIKit is the
/// tactile fallback, and a synthesized AVFoundation tone can cover hardware without haptics.
@MainActor
public final class NativeFeedbackCoordinator: NativeFeedbackCoordinating {
    static let entryCommittedCoalescingWindow: TimeInterval = 0.050

    public let supportsCoreHaptics: Bool
    public var hapticsEnabled: Bool
    public var audioPolicy: NativeAudioFallbackPolicy
    public var onDelivery: ((NativeFeedbackCue, NativeFeedbackDelivery) -> Void)?
    var onUIKitSequencePulse: ((NativeUIKitSequencePulse) -> Void)?
    var coreHapticPlaybackOverride: ((NativeFeedbackCue) throws -> Void)?

    private var hapticEngine: CHHapticEngine?
    private var sequencePlayer: CHHapticPatternPlayer?
    private var fallbackSequenceTask: Task<Void, Never>?
    private var sequenceGeneration: UInt64 = 0
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let softImpactGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let rigidImpactGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private let audioEngine = AVAudioEngine()
    private let audioPlayer = AVAudioPlayerNode()
    private let audioEngineCapability: NativeAudioEngineCapability
    private let monotonicTime: () -> TimeInterval
    private var lastEntryCommittedTime: TimeInterval?
    private var audioIsConfigured = false
    private let audioSampleRate = 44_100.0

#if DEBUG
    private static let diagnosticLog = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "com.foliohtml.whos-first",
        category: .pointsOfInterest
    )
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.foliohtml.whos-first",
        category: "NativeFeedback"
    )
#endif

    public init(
        hapticsEnabled: Bool = true,
        audioPolicy: NativeAudioFallbackPolicy = .whenCoreHapticsUnavailable,
        onDelivery: ((NativeFeedbackCue, NativeFeedbackDelivery) -> Void)? = nil,
        monotonicTime: @escaping () -> TimeInterval = {
            ProcessInfo.processInfo.systemUptime
        }
    ) {
        self.supportsCoreHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        self.hapticsEnabled = hapticsEnabled
        self.audioPolicy = audioPolicy
        self.onDelivery = onDelivery
        self.audioEngineCapability = .currentProcess
        self.monotonicTime = monotonicTime
    }

    /// Deterministic capability seam for simulator verification of the real
    /// UIKit and Core-Haptics-error fallback branches.
    init(
        testSupportsCoreHaptics: Bool,
        testAudioEngineCapability: NativeAudioEngineCapability = .unavailable,
        hapticsEnabled: Bool = true,
        audioPolicy: NativeAudioFallbackPolicy = .never,
        onDelivery: ((NativeFeedbackCue, NativeFeedbackDelivery) -> Void)? = nil,
        monotonicTime: @escaping () -> TimeInterval = {
            ProcessInfo.processInfo.systemUptime
        }
    ) {
        self.supportsCoreHaptics = testSupportsCoreHaptics
        self.hapticsEnabled = hapticsEnabled
        self.audioPolicy = audioPolicy
        self.onDelivery = onDelivery
        self.audioEngineCapability = testAudioEngineCapability
        self.monotonicTime = monotonicTime
    }

    public func prepare() {
        selectionGenerator.prepare()
        softImpactGenerator.prepare()
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        rigidImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        notificationGenerator.prepare()

        if hapticsEnabled && supportsCoreHaptics {
            do {
                try prepareCoreHaptics()
            } catch {
                invalidateCoreHaptics(after: error, context: "prepare")
            }
        }

        if audioEngineCapability.permitsStartup &&
            (audioPolicy == .always || (!supportsCoreHaptics && audioPolicy == .whenCoreHapticsUnavailable)) {
            try? prepareAudio()
        }
    }

    @discardableResult
    public func play(_ cue: NativeFeedbackCue) -> NativeFeedbackDelivery {
        if cue == .entryCommitted, shouldCoalesceEntryCommitted() {
            logDelivery(cue, delivery: .silent)
            onDelivery?(cue, .silent)
            return .silent
        }

        var tactileDelivery: NativeFeedbackDelivery = .silent

        if hapticsEnabled && !cue.hapticEventSpecs.isEmpty {
            if supportsCoreHaptics {
                do {
                    if let coreHapticPlaybackOverride {
                        try coreHapticPlaybackOverride(cue)
                    } else {
                        try playCoreHaptic(cue)
                    }
                    tactileDelivery = .coreHaptics
                } catch {
                    if cue.isSequence {
                        cancelSequence()
                    }
                    invalidateCoreHaptics(after: error, context: "play")
                    tactileDelivery = playUIKitFallback(cue) ? .uiKit : .silent
                }
            } else {
                tactileDelivery = playUIKitFallback(cue) ? .uiKit : .silent
            }
        }

        let shouldPlayAudio: Bool
        switch audioPolicy {
        case .never:
            shouldPlayAudio = false
        case .whenCoreHapticsUnavailable:
            shouldPlayAudio = !supportsCoreHaptics
        case .always:
            shouldPlayAudio = true
        }

        let audioPlayed = cue.permitsAudioFallback &&
            shouldPlayAudio &&
            audioEngineCapability.permitsStartup &&
            playAudioFallback(cue)
        let delivery = combinedDelivery(tactile: tactileDelivery, audioPlayed: audioPlayed)
        logDelivery(cue, delivery: delivery)
        onDelivery?(cue, delivery)
        return delivery
    }

    private func shouldCoalesceEntryCommitted() -> Bool {
        let now = monotonicTime()
        guard now.isFinite else { return false }
        guard let previous = lastEntryCommittedTime else {
            lastEntryCommittedTime = now
            return false
        }
        let elapsed = now - previous
        guard elapsed >= 0 && elapsed < Self.entryCommittedCoalescingWindow else {
            lastEntryCommittedTime = now
            return false
        }
        return true
    }

    public func stopAll() {
        cancelSequence()
        audioPlayer.stop()
        if let hapticEngine {
            hapticEngine.stop { [weak self] error in
                guard let error else { return }
                Task { @MainActor [weak self] in
                    self?.logCoreHapticsError(error, context: "stop")
                }
            }
        }
    }

    public func cancelSequence() {
        try? sequencePlayer?.stop(atTime: CHHapticTimeImmediate)
        clearSequenceState()
    }

    private func prepareCoreHaptics() throws {
        if hapticEngine == nil {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = true
            engine.playsHapticsOnly = true
            engine.stoppedHandler = { [weak self] reason in
                Task { @MainActor [weak self] in
                    self?.clearSequenceState()
                    self?.logEngineStopped(reason)
                }
            }
            engine.resetHandler = { [weak self, weak engine] in
                Task { @MainActor [weak self, weak engine] in
                    guard let self else { return }
                    self.clearSequenceState()
                    self.logEngineReset()
                    guard let engine else {
                        self.hapticEngine = nil
                        return
                    }
                    do {
                        try engine.start()
                        self.logEnginePrepared(context: "reset")
                    } catch {
                        self.invalidateCoreHaptics(after: error, context: "reset")
                    }
                }
            }
            hapticEngine = engine
        }
        guard let hapticEngine else { throw NativeFeedbackError.engineUnavailable }
        do {
            try hapticEngine.start()
            logEnginePrepared(context: "start")
        } catch {
            self.hapticEngine = nil
            throw error
        }
    }

    private func playCoreHaptic(_ cue: NativeFeedbackCue) throws {
        try prepareCoreHaptics()
        guard let hapticEngine else { throw NativeFeedbackError.engineUnavailable }

        let pattern = try hapticPattern(for: cue)
        let player = try hapticEngine.makePlayer(with: pattern)
        if cue.isSequence {
            cancelSequence()
            do {
                try player.start(atTime: CHHapticTimeImmediate)
                sequencePlayer = player
            } catch {
                clearSequenceState()
                throw error
            }
        } else {
            try player.start(atTime: CHHapticTimeImmediate)
        }
    }

    private func hapticPattern(for cue: NativeFeedbackCue) throws -> CHHapticPattern {
        let events = hapticEvents(for: cue)
        guard !events.isEmpty else { throw NativeFeedbackError.emptyPattern }
        return try CHHapticPattern(
            events: events,
            parameterCurves: hapticParameterCurves(for: cue)
        )
    }

    private func hapticEvents(for cue: NativeFeedbackCue) -> [CHHapticEvent] {
        cue.hapticEventSpecs.map { spec in
            switch spec.kind {
            case .transient:
                transient(
                    intensity: spec.intensity,
                    sharpness: spec.sharpness,
                    at: spec.relativeTime
                )
            case .continuous:
                continuous(
                    intensity: spec.intensity,
                    sharpness: spec.sharpness,
                    duration: spec.duration,
                    at: spec.relativeTime
                )
            }
        }
    }

    private func hapticParameterCurves(for cue: NativeFeedbackCue) -> [CHHapticParameterCurve] {
        cue.hapticParameterCurveSpecs.map { spec in
            let controlPoints = spec.controlPoints.map {
                CHHapticParameterCurve.ControlPoint(
                    relativeTime: $0.relativeTime,
                    value: $0.value
                )
            }

            switch spec.parameter {
            case .intensityControl:
                return CHHapticParameterCurve(
                    parameterID: .hapticIntensityControl,
                    controlPoints: controlPoints,
                    relativeTime: spec.relativeTime
                )
            }
        }
    }

    private func clearSequenceState() {
        sequenceGeneration &+= 1
        sequencePlayer = nil
        fallbackSequenceTask?.cancel()
        fallbackSequenceTask = nil
    }

    private func invalidateCoreHaptics(after error: Error, context: String) {
        clearSequenceState()
        hapticEngine = nil
        logCoreHapticsError(error, context: context)
    }

    private func transient(intensity: Float, sharpness: Float, at time: TimeInterval) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: time
        )
    }

    private func continuous(
        intensity: Float,
        sharpness: Float,
        duration: TimeInterval,
        at time: TimeInterval
    ) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: time,
            duration: duration
        )
    }

    private func playUIKitFallback(_ cue: NativeFeedbackCue) -> Bool {
        if let pulses = cue.uiKitSequencePulses {
            startUIKitFallbackSequence(pulses)
            return true
        }
        if let pulse = cue.uiKitImmediatePulse {
            playUIKitSequencePulse(pulse)
            return true
        }

        switch cue {
        case .modeChanged:
            selectionGenerator.selectionChanged()
            selectionGenerator.prepare()
        case .entryCommitted:
            softImpactGenerator.impactOccurred(intensity: 0.55)
            softImpactGenerator.prepare()
        case .settling, .togetherCountdown, .tapInCountdown:
            return false
        case .chooserWinner, .choiceWinner, .pinballSettle:
            return false
        case .undo:
            softImpactGenerator.impactOccurred(intensity: 0.45)
            softImpactGenerator.prepare()
        case .clearCommitted:
            mediumImpactGenerator.impactOccurred(intensity: 0.55)
            mediumImpactGenerator.prepare()
        case .confirmation:
            selectionGenerator.selectionChanged()
            selectionGenerator.prepare()
        case .pinballLaunch(let strength):
            let clamped = min(1, max(0, strength))
            rigidImpactGenerator.impactOccurred(intensity: 0.46 + 0.40 * clamped)
            rigidImpactGenerator.prepare()
        case .pinballCollision:
            guard let event = cue.hapticEventSpecs.first else { return false }
            rigidImpactGenerator.impactOccurred(intensity: CGFloat(event.intensity))
            rigidImpactGenerator.prepare()
        case .pinballFairBounce:
            return false
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
            notificationGenerator.prepare()
        }
        return true
    }

    private func startUIKitFallbackSequence(_ pulses: [NativeUIKitSequencePulse]) {
        cancelSequence()
        let generation = sequenceGeneration
        var pendingPulses = pulses
        var initialElapsed: TimeInterval = 0
        if let first = pendingPulses.first, first.relativeTime <= 0 {
            playUIKitSequencePulse(first)
            pendingPulses.removeFirst()
            initialElapsed = first.relativeTime
        }
        guard !pendingPulses.isEmpty else { return }

        let scheduledPulses = pendingPulses
        let scheduledInitialElapsed = initialElapsed
        fallbackSequenceTask = Task { @MainActor [weak self] in
            var elapsed = scheduledInitialElapsed
            for pulse in scheduledPulses {
                let delay = max(0, pulse.relativeTime - elapsed)
                if delay > 0 {
                    do {
                        try await Task.sleep(for: .seconds(delay))
                    } catch {
                        return
                    }
                }
                guard !Task.isCancelled,
                      let self,
                      self.sequenceGeneration == generation else { return }
                self.playUIKitSequencePulse(pulse)
                elapsed = pulse.relativeTime
            }

            guard let self, self.sequenceGeneration == generation else { return }
            self.fallbackSequenceTask = nil
        }
    }

    private func playUIKitSequencePulse(_ pulse: NativeUIKitSequencePulse) {
        onUIKitSequencePulse?(pulse)
        switch pulse.impact {
        case .soft:
            softImpactGenerator.impactOccurred(intensity: pulse.intensity)
            softImpactGenerator.prepare()
        case .light:
            lightImpactGenerator.impactOccurred(intensity: pulse.intensity)
            lightImpactGenerator.prepare()
        case .medium:
            mediumImpactGenerator.impactOccurred(intensity: pulse.intensity)
            mediumImpactGenerator.prepare()
        case .rigid:
            rigidImpactGenerator.impactOccurred(intensity: pulse.intensity)
            rigidImpactGenerator.prepare()
        case .heavy:
            heavyImpactGenerator.impactOccurred(intensity: pulse.intensity)
            heavyImpactGenerator.prepare()
        }
    }

    private func prepareAudio() throws {
        guard audioEngineCapability.permitsStartup else {
            throw NativeFeedbackError.audioEngineUnavailable
        }
        guard !audioIsConfigured else {
            if !audioEngine.isRunning { try audioEngine.start() }
            return
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: audioSampleRate, channels: 1) else {
            throw NativeFeedbackError.audioFormatUnavailable
        }
        audioEngine.attach(audioPlayer)
        audioEngine.connect(audioPlayer, to: audioEngine.mainMixerNode, format: format)
        audioEngine.prepare()
        try audioEngine.start()
        audioIsConfigured = true
    }

    private func playAudioFallback(_ cue: NativeFeedbackCue) -> Bool {
        let tone = audioTone(for: cue)
        guard !tone.frequencies.isEmpty else { return false }

        do {
            try prepareAudio()
            guard let buffer = makeAudioBuffer(
                    frequencies: tone.frequencies,
                    duration: tone.duration,
                    volume: tone.volume
                  ) else { return false }

            audioPlayer.stop()
            audioPlayer.scheduleBuffer(buffer, at: nil, options: .interrupts)
            audioPlayer.play()
            return true
        } catch {
            return false
        }
    }

    private func audioTone(for cue: NativeFeedbackCue) -> (frequencies: [Double], duration: TimeInterval, volume: Float) {
        switch cue {
        case .modeChanged:
            return ([260], 0.035, 0.12)
        case .entryCommitted:
            return ([110], 0.045, 0.16)
        case .settling, .togetherCountdown, .tapInCountdown:
            return ([], 0, 0)
        case .chooserWinner, .choiceWinner:
            return ([], 0, 0)
        case .pinballSettle:
            return ([128, 96], 0.11, 0.14)
        case .undo:
            return ([170, 120], 0.10, 0.10)
        case .clearCommitted:
            return ([92], 0.14, 0.12)
        case .confirmation:
            return ([260, 330], 0.10, 0.10)
        case .pinballLaunch(let strength):
            let clamped = min(1, max(0, strength))
            return ([145 + 55 * clamped], 0.08, Float(0.10 + 0.06 * clamped))
        case .pinballCollision(let speedFraction, let normalImpulseFraction, let isCorner):
            let speed = min(1, max(0, speedFraction))
            let normalImpulse = min(1, max(0, normalImpulseFraction))
            let energy = speed * (0.20 + 0.80 * normalImpulse)
            let frequency = 105 + energy * 95 + (isCorner ? 20 : 0)
            return ([frequency], 0.035, Float(0.08 + energy * 0.10))
        case .pinballFairBounce:
            return ([], 0, 0)
        case .warning:
            return ([180, 240], 0.16, 0.16)
        }
    }

    private func makeAudioBuffer(
        frequencies: [Double],
        duration: TimeInterval,
        volume: Float
    ) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: audioSampleRate, channels: 1) else { return nil }
        let frameCount = AVAudioFrameCount(max(1, Int(audioSampleRate * duration)))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else { return nil }

        buffer.frameLength = frameCount
        let attackDuration = min(0.008, duration * 0.18)
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / audioSampleRate
            let attack = attackDuration > 0 ? min(1, time / attackDuration) : 1
            let release = pow(max(0, 1 - time / duration), 2.4)
            let combined = frequencies.reduce(0.0) { partial, frequency in
                partial + sin(2 * Double.pi * frequency * time)
            } / Double(max(1, frequencies.count))
            samples[frame] = Float(combined) * volume * Float(attack * release)
        }
        return buffer
    }

    private func combinedDelivery(
        tactile: NativeFeedbackDelivery,
        audioPlayed: Bool
    ) -> NativeFeedbackDelivery {
        guard audioPlayed else { return tactile }
        switch tactile {
        case .coreHaptics:
            return .coreHapticsAndAudio
        case .uiKit:
            return .uiKitAndAudio
        case .silent:
            return .audio
        default:
            return tactile
        }
    }

    private func logDelivery(_ cue: NativeFeedbackCue, delivery: NativeFeedbackDelivery) {
#if DEBUG
        os_signpost(.event, log: Self.diagnosticLog, name: "Feedback Delivery")
        Self.logger.debug(
            "cue=\(String(describing: cue), privacy: .public) delivery=\(String(describing: delivery), privacy: .public)"
        )
#endif
    }

    private func logEnginePrepared(context: String) {
#if DEBUG
        os_signpost(.event, log: Self.diagnosticLog, name: "Haptic Engine Prepared")
        Self.logger.debug("Core Haptics ready context=\(context, privacy: .public)")
#endif
    }

    private func logEngineStopped(_ reason: CHHapticEngine.StoppedReason) {
#if DEBUG
        os_signpost(.event, log: Self.diagnosticLog, name: "Haptic Engine Stopped")
        Self.logger.debug("Core Haptics stopped reason=\(String(describing: reason), privacy: .public)")
#endif
    }

    private func logEngineReset() {
#if DEBUG
        os_signpost(.event, log: Self.diagnosticLog, name: "Haptic Engine Reset")
        Self.logger.debug("Core Haptics reset")
#endif
    }

    private func logCoreHapticsError(_ error: Error, context: String) {
#if DEBUG
        os_signpost(.event, log: Self.diagnosticLog, name: "Haptic Engine Error")
        Self.logger.error(
            "Core Haptics error context=\(context, privacy: .public) error=\(String(describing: error), privacy: .public)"
        )
#endif
    }
}

@MainActor
public final class NativeNoopFeedbackCoordinator: NativeFeedbackCoordinating {
    public let supportsCoreHaptics = false
    public init() {}
    public func prepare() {}

    @discardableResult
    public func play(_ cue: NativeFeedbackCue) -> NativeFeedbackDelivery { .silent }

    public func cancelSequence() {}
    public func stopAll() {}
}

private extension ChoiceAnticipationFallbackWeight {
    var nativeImpact: NativeUIKitSequenceImpact {
        switch self {
        case .medium: .medium
        case .heavy: .heavy
        }
    }
}

extension NativeFeedbackCue {
    var hapticEventSpecs: [NativeHapticEventSpec] {
        switch self {
        case .modeChanged:
            return [Self.transientSpec(intensity: 0.18, sharpness: 0.55, at: 0)]
        case .entryCommitted:
            return [
                Self.transientSpec(intensity: 0.42, sharpness: 0.24, at: 0),
                NativeHapticEventSpec(
                    kind: .continuous,
                    intensity: 1.0,
                    sharpness: 0.06,
                    relativeTime: 0.008,
                    duration: 0.11
                )
            ]
        case .settling:
            return []
        case .togetherCountdown:
            return ChoiceAnticipationTimeline.chooser.beats.map { beat in
                Self.transientSpec(
                    intensity: beat.intensity,
                    sharpness: beat.sharpness,
                    at: beat.time
                )
            }
        case .tapInCountdown:
            return Self.tapInAnticipationSpecs
        case .chooserWinner:
            return Self.choiceWinnerEventSpecs(
                offset: ChoiceAnticipationTimeline.chooser.winnerContactTime
            )
        case .choiceWinner:
            return Self.choiceWinnerEventSpecs(offset: 0)
        case .pinballSettle:
            return [
                Self.transientSpec(intensity: 0.84, sharpness: 0.20, at: 0),
                NativeHapticEventSpec(
                    kind: .continuous,
                    intensity: 1.0,
                    sharpness: 0.055,
                    relativeTime: 0.008,
                    duration: 0.21
                )
            ]
        case .undo:
            return [
                Self.transientSpec(intensity: 0.28, sharpness: 0.42, at: 0),
                Self.transientSpec(intensity: 0.16, sharpness: 0.22, at: 0.075)
            ]
        case .clearCommitted:
            return [
                Self.transientSpec(intensity: 0.40, sharpness: 0.30, at: 0),
                Self.transientSpec(intensity: 0.23, sharpness: 0.18, at: 0.10)
            ]
        case .confirmation:
            return [
                Self.transientSpec(intensity: 0.34, sharpness: 0.40, at: 0),
                Self.transientSpec(intensity: 0.20, sharpness: 0.22, at: 0.10)
            ]
        case .pinballLaunch(let strength):
            let clamped = Float(min(1, max(0, strength)))
            return [
                Self.transientSpec(
                    intensity: 0.36 + 0.30 * clamped,
                    sharpness: 0.48 + 0.30 * clamped,
                    at: 0
                ),
                Self.transientSpec(
                    intensity: 0.12 + 0.12 * clamped,
                    sharpness: 0.18 + 0.15 * clamped,
                    at: 0.055
                )
            ]
        case .pinballCollision(let speedFraction, let normalImpulseFraction, let isCorner):
            let speed = Float(min(1, max(0, speedFraction)))
            let normalImpulse = Float(min(1, max(0, normalImpulseFraction)))
            let effectiveEnergy = speed * (0.20 + 0.80 * normalImpulse)
            let cornerIntensity: Float = isCorner ? 0.055 : 0
            let cornerSharpness: Float = isCorner ? 0.04 : 0
            let intensity = min(
                0.78,
                0.12
                    + 0.60 * Float(pow(Double(effectiveEnergy), 0.75))
                    + cornerIntensity
            )
            let sharpness = min(
                0.86,
                0.24
                    + 0.46 * normalImpulse * Float(sqrt(Double(speed)))
                    + 0.10 * speed
                    + cornerSharpness
            )
            return [Self.transientSpec(intensity: intensity, sharpness: sharpness, at: 0)]
        case .pinballFairBounce(let speedFraction, let normalImpulseFraction):
            let energy = Self.fairBounceEnergy(
                speedFraction: speedFraction,
                normalImpulseFraction: normalImpulseFraction
            )
            return [
                Self.transientSpec(
                    intensity: 0.60 + 0.18 * energy,
                    sharpness: 0.38 + 0.18 * energy,
                    at: 0
                ),
                NativeHapticEventSpec(
                    kind: .continuous,
                    intensity: 1,
                    sharpness: 0.07,
                    relativeTime: 0.004,
                    duration: 0.075
                )
            ]
        case .warning:
            return [
                Self.transientSpec(intensity: 0.42, sharpness: 0.38, at: 0),
                Self.transientSpec(intensity: 0.28, sharpness: 0.28, at: 0.11)
            ]
        }
    }

    var hapticParameterCurveSpecs: [NativeHapticParameterCurveSpec] {
        switch self {
        case .entryCommitted:
            return [
                NativeHapticParameterCurveSpec(
                    parameter: .intensityControl,
                    relativeTime: 0.008,
                    controlPoints: [
                        .init(relativeTime: 0, value: 0.38),
                        .init(relativeTime: 0.040, value: 0.22),
                        .init(relativeTime: 0.110, value: 0.05)
                    ]
                )
            ]
        case .chooserWinner:
            let winner = ChoiceAnticipationTimeline.chooser.winnerHaptic
            return [
                NativeHapticParameterCurveSpec(
                    parameter: .intensityControl,
                    relativeTime: ChoiceAnticipationTimeline.chooser.winnerContactTime
                        + winner.bodyStartTime,
                    controlPoints: winner.intensityCurve.map {
                        .init(relativeTime: $0.relativeTime, value: $0.intensity)
                    }
                )
            ]
        case .choiceWinner:
            let winner = ChoiceAnticipationTimeline.chooser.winnerHaptic
            return [
                NativeHapticParameterCurveSpec(
                    parameter: .intensityControl,
                    relativeTime: winner.bodyStartTime,
                    controlPoints: winner.intensityCurve.map {
                        .init(relativeTime: $0.relativeTime, value: $0.intensity)
                    }
                )
            ]
        case .pinballSettle:
            return [
                NativeHapticParameterCurveSpec(
                    parameter: .intensityControl,
                    relativeTime: 0.008,
                    controlPoints: [
                        .init(relativeTime: 0, value: 0.70),
                        .init(relativeTime: 0.035, value: 0.82),
                        .init(relativeTime: 0.105, value: 0.47),
                        .init(relativeTime: 0.170, value: 0.18),
                        .init(relativeTime: 0.210, value: 0.03)
                    ]
                )
            ]
        case .pinballFairBounce(let speedFraction, let normalImpulseFraction):
            let energy = Self.fairBounceEnergy(
                speedFraction: speedFraction,
                normalImpulseFraction: normalImpulseFraction
            )
            return [
                NativeHapticParameterCurveSpec(
                    parameter: .intensityControl,
                    relativeTime: 0.004,
                    controlPoints: [
                        .init(relativeTime: 0, value: 0.40 + 0.12 * energy),
                        .init(relativeTime: 0.024, value: 0.25 + 0.07 * energy),
                        .init(relativeTime: 0.075, value: 0.04)
                    ]
                )
            ]
        default:
            return []
        }
    }

    var uiKitSequencePulses: [NativeUIKitSequencePulse]? {
        switch self {
        case .entryCommitted:
            return Self.entryCommittedUIKitPulses
        case .togetherCountdown:
            return ChoiceAnticipationTimeline.chooser.beats.map { beat in
                NativeUIKitSequencePulse(
                    impact: beat.fallbackWeight.nativeImpact,
                    intensity: beat.fallbackIntensity,
                    relativeTime: beat.time
                )
            }
        case .tapInCountdown:
            return Self.tapInAnticipationUIKitPulses
        case .chooserWinner:
            return Self.choiceWinnerUIKitPulses(
                offset: ChoiceAnticipationTimeline.chooser.winnerContactTime
            )
        case .choiceWinner:
            return Self.choiceWinnerUIKitPulses(offset: 0)
        default:
            return nil
        }
    }

    var uiKitImmediatePulse: NativeUIKitSequencePulse? {
        switch self {
        case .pinballSettle:
            return .init(impact: .heavy, intensity: 0.92, relativeTime: 0)
        case .pinballFairBounce(let speedFraction, let normalImpulseFraction):
            let energy = CGFloat(Self.fairBounceEnergy(
                speedFraction: speedFraction,
                normalImpulseFraction: normalImpulseFraction
            ))
            return .init(
                impact: .rigid,
                intensity: 0.66 + 0.16 * energy,
                relativeTime: 0
            )
        default:
            return nil
        }
    }

    var isSequence: Bool {
        switch self {
        case .entryCommitted, .togetherCountdown, .tapInCountdown, .chooserWinner, .choiceWinner:
            return true
        default:
            return false
        }
    }

    private static let tapInAnticipationSpecs: [NativeHapticEventSpec] = [
        transientSpec(intensity: 0.46, sharpness: 0.26, at: 0.06),
        transientSpec(intensity: 0.62, sharpness: 0.30, at: 0.40),
        transientSpec(intensity: 0.78, sharpness: 0.34, at: 0.69),
        transientSpec(intensity: 0.92, sharpness: 0.38, at: 0.89)
    ]

    private static let tapInAnticipationUIKitPulses: [NativeUIKitSequencePulse] = [
        .init(impact: .medium, intensity: 0.60, relativeTime: 0.06),
        .init(impact: .medium, intensity: 0.76, relativeTime: 0.40),
        .init(impact: .heavy, intensity: 0.90, relativeTime: 0.69),
        .init(impact: .heavy, intensity: 1.0, relativeTime: 0.89)
    ]

    private static func choiceWinnerEventSpecs(
        offset: TimeInterval
    ) -> [NativeHapticEventSpec] {
        let winner = ChoiceAnticipationTimeline.chooser.winnerHaptic
        return [
            transientSpec(
                intensity: winner.attackIntensity,
                sharpness: winner.attackSharpness,
                at: offset + winner.attackTime
            ),
            NativeHapticEventSpec(
                kind: .continuous,
                intensity: 1.0,
                sharpness: winner.bodySharpness,
                relativeTime: offset + winner.bodyStartTime,
                duration: winner.bodyDuration
            )
        ]
    }

    private static let entryCommittedUIKitPulses: [NativeUIKitSequencePulse] = [
        .init(impact: .medium, intensity: 0.52, relativeTime: 0),
        .init(impact: .soft, intensity: 0.24, relativeTime: 0.070)
    ]

    private static func choiceWinnerUIKitPulses(
        offset: TimeInterval
    ) -> [NativeUIKitSequencePulse] {
        [
            .init(impact: .heavy, intensity: 1.0, relativeTime: offset),
            .init(impact: .heavy, intensity: 0.78, relativeTime: offset + 0.100),
            .init(impact: .medium, intensity: 0.52, relativeTime: offset + 0.320),
            .init(impact: .soft, intensity: 0.28, relativeTime: offset + 0.580),
            .init(impact: .soft, intensity: 0.16, relativeTime: offset + 0.740)
        ]
    }

    var permitsAudioFallback: Bool {
        switch self {
        case .settling,
             .togetherCountdown,
             .tapInCountdown,
             .chooserWinner,
             .choiceWinner,
             .pinballFairBounce:
            return false
        default:
            return true
        }
    }

    private static func fairBounceEnergy(
        speedFraction: Double,
        normalImpulseFraction: Double
    ) -> Float {
        let speed = Float(min(1, max(0, speedFraction)))
        let normalImpulse = Float(min(1, max(0, normalImpulseFraction)))
        return speed * (0.35 + 0.65 * normalImpulse)
    }

    private static func transientSpec(
        intensity: Float,
        sharpness: Float,
        at relativeTime: TimeInterval
    ) -> NativeHapticEventSpec {
        NativeHapticEventSpec(
            kind: .transient,
            intensity: intensity,
            sharpness: sharpness,
            relativeTime: relativeTime,
            duration: 0
        )
    }
}

private enum NativeFeedbackError: Error {
    case engineUnavailable
    case emptyPattern
    case audioEngineUnavailable
    case audioFormatUnavailable
}
