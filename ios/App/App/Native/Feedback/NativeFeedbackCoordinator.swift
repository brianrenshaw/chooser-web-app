@preconcurrency import AVFoundation
@preconcurrency import CoreHaptics
import UIKit

public struct NativeCustomFeedback: Equatable, Sendable {
    public let intensity: Float
    public let sharpness: Float
    public let duration: TimeInterval
    public let audioFrequencies: [Double]

    public init(
        intensity: Float,
        sharpness: Float,
        duration: TimeInterval,
        audioFrequencies: [Double] = []
    ) {
        self.intensity = min(1, max(0, intensity))
        self.sharpness = min(1, max(0, sharpness))
        self.duration = max(0.01, duration)
        self.audioFrequencies = audioFrequencies.filter { $0 > 0 }
    }
}

public enum NativeFeedbackCue: Equatable, Sendable {
    case modeChanged
    case entryCommitted
    case countdown(progress: Double)
    case winner
    case warning
    case destructive
    case custom(NativeCustomFeedback)
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

@MainActor
public protocol NativeFeedbackCoordinating: AnyObject {
    var supportsCoreHaptics: Bool { get }
    func prepare()

    @discardableResult
    func play(_ cue: NativeFeedbackCue) -> NativeFeedbackDelivery

    func stopAll()
}

/// Coordinates feedback without owning game state. Core Haptics is preferred, UIKit is the
/// tactile fallback, and a synthesized AVFoundation tone can cover hardware without haptics.
@MainActor
public final class NativeFeedbackCoordinator: NativeFeedbackCoordinating {
    public let supportsCoreHaptics: Bool
    public var hapticsEnabled: Bool
    public var audioPolicy: NativeAudioFallbackPolicy
    public var onDelivery: ((NativeFeedbackCue, NativeFeedbackDelivery) -> Void)?

    private var hapticEngine: CHHapticEngine?
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let rigidImpactGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private let audioEngine = AVAudioEngine()
    private let audioPlayer = AVAudioPlayerNode()
    private var audioIsConfigured = false
    private let audioSampleRate = 44_100.0

    public init(
        hapticsEnabled: Bool = true,
        audioPolicy: NativeAudioFallbackPolicy = .whenCoreHapticsUnavailable,
        onDelivery: ((NativeFeedbackCue, NativeFeedbackDelivery) -> Void)? = nil
    ) {
        self.supportsCoreHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        self.hapticsEnabled = hapticsEnabled
        self.audioPolicy = audioPolicy
        self.onDelivery = onDelivery
    }

    public func prepare() {
        selectionGenerator.prepare()
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        rigidImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        notificationGenerator.prepare()

        if hapticsEnabled && supportsCoreHaptics {
            do {
                try prepareCoreHaptics()
            } catch {
                hapticEngine = nil
            }
        }

        if audioPolicy == .always || (!supportsCoreHaptics && audioPolicy == .whenCoreHapticsUnavailable) {
            try? prepareAudio()
        }
    }

    @discardableResult
    public func play(_ cue: NativeFeedbackCue) -> NativeFeedbackDelivery {
        var tactileDelivery: NativeFeedbackDelivery = .silent

        if hapticsEnabled {
            if supportsCoreHaptics {
                do {
                    try playCoreHaptic(cue)
                    tactileDelivery = .coreHaptics
                } catch {
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
            shouldPlayAudio = !supportsCoreHaptics || tactileDelivery == .silent
        case .always:
            shouldPlayAudio = true
        }

        let audioPlayed = shouldPlayAudio && playAudioFallback(cue)
        let delivery = combinedDelivery(tactile: tactileDelivery, audioPlayed: audioPlayed)
        onDelivery?(cue, delivery)
        return delivery
    }

    public func stopAll() {
        audioPlayer.stop()
        if let hapticEngine {
            hapticEngine.stop(completionHandler: nil)
        }
    }

    private func prepareCoreHaptics() throws {
        if hapticEngine == nil {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = true
            engine.resetHandler = { [weak engine] in
                try? engine?.start()
            }
            hapticEngine = engine
        }
        try hapticEngine?.start()
    }

    private func playCoreHaptic(_ cue: NativeFeedbackCue) throws {
        try prepareCoreHaptics()
        guard let hapticEngine else { throw NativeFeedbackError.engineUnavailable }

        let events = hapticEvents(for: cue)
        guard !events.isEmpty else { throw NativeFeedbackError.emptyPattern }
        let pattern = try CHHapticPattern(events: events, parameters: [])
        let player = try hapticEngine.makePlayer(with: pattern)
        try player.start(atTime: CHHapticTimeImmediate)
    }

    private func hapticEvents(for cue: NativeFeedbackCue) -> [CHHapticEvent] {
        switch cue {
        case .modeChanged:
            return [transient(intensity: 0.34, sharpness: 0.72, at: 0)]
        case .entryCommitted:
            return [transient(intensity: 0.42, sharpness: 0.64, at: 0)]
        case .countdown(let progress):
            let progress = Float(min(1, max(0, progress)))
            return [transient(intensity: 0.42 + progress * 0.52, sharpness: 0.48 + progress * 0.42, at: 0)]
        case .winner:
            return [
                transient(intensity: 1, sharpness: 0.82, at: 0),
                transient(intensity: 1, sharpness: 0.90, at: 0.08),
                transient(intensity: 1, sharpness: 1, at: 0.17),
                continuous(intensity: 0.72, sharpness: 0.38, duration: 0.30, at: 0.24)
            ]
        case .warning:
            return [
                transient(intensity: 0.72, sharpness: 0.34, at: 0),
                transient(intensity: 0.72, sharpness: 0.34, at: 0.12)
            ]
        case .destructive:
            return [
                transient(intensity: 0.92, sharpness: 0.22, at: 0),
                continuous(intensity: 0.52, sharpness: 0.18, duration: 0.18, at: 0.07)
            ]
        case .custom(let custom):
            if custom.duration <= 0.06 {
                return [transient(intensity: custom.intensity, sharpness: custom.sharpness, at: 0)]
            }
            return [continuous(
                intensity: custom.intensity,
                sharpness: custom.sharpness,
                duration: custom.duration,
                at: 0
            )]
        }
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
        switch cue {
        case .modeChanged:
            selectionGenerator.selectionChanged()
            selectionGenerator.prepare()
        case .entryCommitted:
            lightImpactGenerator.impactOccurred(intensity: 0.72)
            lightImpactGenerator.prepare()
        case .countdown(let progress):
            let normalized = min(1, max(0, progress))
            if normalized < 0.45 {
                mediumImpactGenerator.impactOccurred(intensity: 0.55 + normalized * 0.4)
                mediumImpactGenerator.prepare()
            } else {
                rigidImpactGenerator.impactOccurred(intensity: 0.62 + normalized * 0.38)
                rigidImpactGenerator.prepare()
            }
        case .winner:
            heavyImpactGenerator.impactOccurred(intensity: 1)
            notificationGenerator.notificationOccurred(.success)
            heavyImpactGenerator.prepare()
            notificationGenerator.prepare()
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
            notificationGenerator.prepare()
        case .destructive:
            notificationGenerator.notificationOccurred(.error)
            notificationGenerator.prepare()
        case .custom(let custom):
            mediumImpactGenerator.impactOccurred(intensity: CGFloat(custom.intensity))
            mediumImpactGenerator.prepare()
        }
        return true
    }

    private func prepareAudio() throws {
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
        do {
            try prepareAudio()
            let tone = audioTone(for: cue)
            guard !tone.frequencies.isEmpty,
                  let buffer = makeAudioBuffer(
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
        case .countdown(let progress):
            let normalized = min(1, max(0, progress))
            return ([130 + normalized * 260], 0.045 + normalized * 0.025, Float(0.13 + normalized * 0.18))
        case .winner:
            return ([220, 440, 660], 0.34, 0.22)
        case .warning:
            return ([180, 240], 0.16, 0.16)
        case .destructive:
            return ([76], 0.22, 0.20)
        case .custom(let custom):
            return (custom.audioFrequencies, custom.duration, min(0.32, max(0.05, custom.intensity * 0.32)))
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
}

@MainActor
public final class NativeNoopFeedbackCoordinator: NativeFeedbackCoordinating {
    public let supportsCoreHaptics = false
    public init() {}
    public func prepare() {}

    @discardableResult
    public func play(_ cue: NativeFeedbackCue) -> NativeFeedbackDelivery { .silent }

    public func stopAll() {}
}

private enum NativeFeedbackError: Error {
    case engineUnavailable
    case emptyPattern
    case audioFormatUnavailable
}
