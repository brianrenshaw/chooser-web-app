import CoreGraphics
import Foundation

public enum ChoiceAnticipationFallbackWeight: Equatable, Sendable {
    case medium
    case heavy
}

public struct ChoiceAnticipationBeat: Equatable, Sendable {
    public let time: TimeInterval
    public let intensity: Float
    public let sharpness: Float
    public let fallbackWeight: ChoiceAnticipationFallbackWeight
    public let fallbackIntensity: CGFloat
    public let compressionScale: CGFloat
    public let reboundScale: CGFloat
    public let translation: CGFloat
    public let rotationDegrees: Double

    public init(
        time: TimeInterval,
        intensity: Float,
        sharpness: Float,
        fallbackWeight: ChoiceAnticipationFallbackWeight,
        fallbackIntensity: CGFloat,
        compressionScale: CGFloat,
        reboundScale: CGFloat,
        translation: CGFloat,
        rotationDegrees: Double
    ) {
        self.time = time
        self.intensity = intensity
        self.sharpness = sharpness
        self.fallbackWeight = fallbackWeight
        self.fallbackIntensity = fallbackIntensity
        self.compressionScale = compressionScale
        self.reboundScale = reboundScale
        self.translation = translation
        self.rotationDegrees = rotationDegrees
    }
}

public struct ChoiceAnticipationMotion: Equatable, Sendable {
    public let scale: CGFloat
    public let translation: CGVector
    public let rotationDegrees: Double

    public static let resting = ChoiceAnticipationMotion(
        scale: 1,
        translation: .zero,
        rotationDegrees: 0
    )
}

public struct ChoiceWinnerHapticControlPoint: Equatable, Sendable {
    public let relativeTime: TimeInterval
    public let intensity: Float

    public init(relativeTime: TimeInterval, intensity: Float) {
        self.relativeTime = relativeTime
        self.intensity = intensity
    }
}

/// The decisive tactile landing is part of the same timing specification as
/// the visible Chooser ritual. Keeping it here prevents the reveal animation
/// and its physical feedback from drifting into separate, unrelated designs.
public struct ChoiceWinnerHaptic: Equatable, Sendable {
    public let attackTime: TimeInterval
    public let attackIntensity: Float
    public let attackSharpness: Float
    public let bodyStartTime: TimeInterval
    public let bodyDuration: TimeInterval
    public let bodySharpness: Float
    public let intensityCurve: [ChoiceWinnerHapticControlPoint]

    public init(
        attackTime: TimeInterval,
        attackIntensity: Float,
        attackSharpness: Float,
        bodyStartTime: TimeInterval,
        bodyDuration: TimeInterval,
        bodySharpness: Float,
        intensityCurve: [ChoiceWinnerHapticControlPoint]
    ) {
        self.attackTime = attackTime
        self.attackIntensity = attackIntensity
        self.attackSharpness = attackSharpness
        self.bodyStartTime = bodyStartTime
        self.bodyDuration = bodyDuration
        self.bodySharpness = bodySharpness
        self.intensityCurve = intensityCurve
    }
}

/// One authoritative Chooser timeline shared by the state machine, tactile
/// feedback, and SwiftUI ring motion. A beat reaches maximum compression at the
/// exact instant its haptic transient is scheduled.
public struct ChoiceAnticipationTimeline: Equatable, Sendable {
    public static let chooser = ChoiceAnticipationTimeline(
        duration: 2.75,
        winnerRevealDuration: 0.82,
        loserFadeDuration: 0.46,
        winnerCompressionFraction: 0.10,
        compressionLead: 0.100,
        reboundDelay: 0.100,
        settleDelay: 0.320,
        interBeatReboundFraction: 0.42,
        beats: [
            ChoiceAnticipationBeat(
                time: 0.24,
                intensity: 0.26,
                sharpness: 0.16,
                fallbackWeight: .medium,
                fallbackIntensity: 0.42,
                compressionScale: 0.994,
                reboundScale: 1.002,
                translation: 1.4,
                rotationDegrees: 0.18
            ),
            ChoiceAnticipationBeat(
                time: 0.78,
                intensity: 0.34,
                sharpness: 0.18,
                fallbackWeight: .medium,
                fallbackIntensity: 0.52,
                compressionScale: 0.991,
                reboundScale: 1.003,
                translation: 2.1,
                rotationDegrees: 0.30
            ),
            ChoiceAnticipationBeat(
                time: 1.28,
                intensity: 0.43,
                sharpness: 0.20,
                fallbackWeight: .medium,
                fallbackIntensity: 0.62,
                compressionScale: 0.987,
                reboundScale: 1.004,
                translation: 3.0,
                rotationDegrees: 0.44
            ),
            ChoiceAnticipationBeat(
                time: 1.72,
                intensity: 0.53,
                sharpness: 0.22,
                fallbackWeight: .medium,
                fallbackIntensity: 0.72,
                compressionScale: 0.982,
                reboundScale: 1.006,
                translation: 4.0,
                rotationDegrees: 0.60
            ),
            ChoiceAnticipationBeat(
                time: 2.10,
                intensity: 0.63,
                sharpness: 0.24,
                fallbackWeight: .heavy,
                fallbackIntensity: 0.84,
                compressionScale: 0.976,
                reboundScale: 1.008,
                translation: 5.0,
                rotationDegrees: 0.76
            ),
            ChoiceAnticipationBeat(
                time: 2.43,
                intensity: 0.74,
                sharpness: 0.27,
                fallbackWeight: .heavy,
                fallbackIntensity: 0.96,
                compressionScale: 0.968,
                reboundScale: 1.011,
                translation: 6.0,
                rotationDegrees: 0.94
            )
        ],
        winnerHaptic: ChoiceWinnerHaptic(
            attackTime: 0,
            attackIntensity: 1.0,
            attackSharpness: 0.20,
            bodyStartTime: 0.012,
            bodyDuration: 0.78,
            bodySharpness: 0.07,
            intensityCurve: [
                .init(relativeTime: 0, intensity: 0.82),
                .init(relativeTime: 0.060, intensity: 0.96),
                .init(relativeTime: 0.180, intensity: 0.78),
                .init(relativeTime: 0.340, intensity: 0.56),
                .init(relativeTime: 0.520, intensity: 0.36),
                .init(relativeTime: 0.680, intensity: 0.18),
                .init(relativeTime: 0.780, intensity: 0.05)
            ]
        )
    )

    public let duration: TimeInterval
    public let winnerRevealDuration: TimeInterval
    public let loserFadeDuration: TimeInterval
    public let winnerCompressionFraction: Double
    public let compressionLead: TimeInterval
    public let reboundDelay: TimeInterval
    public let settleDelay: TimeInterval
    public let interBeatReboundFraction: Double
    public let beats: [ChoiceAnticipationBeat]
    public let winnerHaptic: ChoiceWinnerHaptic

    public init(
        duration: TimeInterval,
        winnerRevealDuration: TimeInterval,
        loserFadeDuration: TimeInterval,
        winnerCompressionFraction: Double,
        compressionLead: TimeInterval,
        reboundDelay: TimeInterval,
        settleDelay: TimeInterval,
        interBeatReboundFraction: Double,
        beats: [ChoiceAnticipationBeat],
        winnerHaptic: ChoiceWinnerHaptic
    ) {
        precondition(duration.isFinite && duration > 0)
        precondition(winnerRevealDuration.isFinite && winnerRevealDuration >= 0)
        precondition(loserFadeDuration.isFinite && loserFadeDuration >= 0)
        precondition(
            winnerCompressionFraction.isFinite
                && winnerCompressionFraction > 0
                && winnerCompressionFraction < 1
        )
        precondition(compressionLead.isFinite && compressionLead > 0)
        precondition(reboundDelay.isFinite && reboundDelay > 0)
        precondition(settleDelay.isFinite && settleDelay > reboundDelay)
        precondition(interBeatReboundFraction > 0 && interBeatReboundFraction < 1)
        precondition(!beats.isEmpty)
        precondition(beats.allSatisfy { beat in
            beat.time >= compressionLead
                && beat.time < duration
                && (0...1).contains(beat.intensity)
                && (0...1).contains(beat.sharpness)
                && beat.compressionScale > 0
                && beat.reboundScale > 0
                && beat.translation >= 0
                && beat.rotationDegrees >= 0
        })
        precondition(zip(beats, beats.dropFirst()).allSatisfy { $0.time < $1.time })
        precondition((beats.last?.time ?? 0) + settleDelay <= duration + 0.000_001)
        precondition((0...1).contains(winnerHaptic.attackIntensity))
        precondition((0...1).contains(winnerHaptic.attackSharpness))
        precondition((0...1).contains(winnerHaptic.bodySharpness))
        precondition(winnerHaptic.attackTime >= 0)
        precondition(winnerHaptic.bodyStartTime >= 0)
        precondition(winnerHaptic.bodyDuration > 0)
        precondition(!winnerHaptic.intensityCurve.isEmpty)
        precondition(winnerHaptic.intensityCurve.allSatisfy {
            $0.relativeTime >= 0
                && $0.relativeTime <= winnerHaptic.bodyDuration
                && (0...1).contains($0.intensity)
        })

        self.duration = duration
        self.winnerRevealDuration = winnerRevealDuration
        self.loserFadeDuration = loserFadeDuration
        self.winnerCompressionFraction = winnerCompressionFraction
        self.compressionLead = compressionLead
        self.reboundDelay = reboundDelay
        self.settleDelay = settleDelay
        self.interBeatReboundFraction = interBeatReboundFraction
        self.beats = beats
        self.winnerHaptic = winnerHaptic
    }

    /// The exact reveal-relative instant when the winning ring reaches its
    /// deepest visible contact. Chooser haptics schedule their attack here so
    /// the decisive physical hit never leads the rendered compression.
    public var winnerContactTime: TimeInterval {
        winnerRevealDuration * winnerCompressionFraction
    }

    public var maximumScale: CGFloat {
        max(1, beats.map(\.reboundScale).max() ?? 1)
    }

    public var maximumTranslation: CGFloat {
        beats.map(\.translation).max() ?? 0
    }

    public func reboundTime(afterBeatAt index: Int) -> TimeInterval? {
        guard beats.indices.contains(index) else { return nil }
        if beats.indices.contains(index + 1) {
            let beat = beats[index]
            let nextBeat = beats[index + 1]
            return beat.time
                + (nextBeat.time - beat.time) * interBeatReboundFraction
        }
        return beats[index].time + reboundDelay
    }

    public func motion(
        at elapsed: TimeInterval,
        ringSeed: UInt64,
        reduceMotion: Bool
    ) -> ChoiceAnticipationMotion {
        guard elapsed.isFinite, elapsed >= 0, elapsed < duration else {
            return .resting
        }

        guard let firstBeat = beats.first, let lastBeat = beats.last else {
            return .resting
        }

        let firstResponseStart = firstBeat.time - compressionLead
        guard elapsed >= firstResponseStart else { return .resting }

        let sample: ChoiceAnticipationMotionSample
        if elapsed <= firstBeat.time {
            let progress = smoothStep(normalized(
                elapsed,
                from: firstResponseStart,
                to: firstBeat.time
            ))
            sample = interpolate(
                from: .resting,
                to: peakSample(for: firstBeat, index: 0),
                progress: progress
            )
        } else if let index = beats.indices.dropLast().first(where: {
            elapsed <= beats[$0 + 1].time
        }) {
            let beat = beats[index]
            let nextBeat = beats[index + 1]
            guard let reboundTime = reboundTime(afterBeatAt: index) else {
                return .resting
            }
            let peak = peakSample(for: beat, index: index)
            let rebound = reboundSample(for: beat, index: index)
            let nextPeak = peakSample(for: nextBeat, index: index + 1)

            if elapsed <= reboundTime {
                sample = interpolate(
                    from: peak,
                    to: rebound,
                    progress: smoothStep(normalized(
                        elapsed,
                        from: beat.time,
                        to: reboundTime
                    ))
                )
            } else {
                sample = interpolate(
                    from: rebound,
                    to: nextPeak,
                    progress: smoothStep(normalized(
                        elapsed,
                        from: reboundTime,
                        to: nextBeat.time
                    ))
                )
            }
        } else {
            guard let reboundTime = reboundTime(afterBeatAt: beats.count - 1) else {
                return .resting
            }
            let peak = peakSample(for: lastBeat, index: beats.count - 1)
            let rebound = reboundSample(for: lastBeat, index: beats.count - 1)

            if elapsed <= reboundTime {
                sample = interpolate(
                    from: peak,
                    to: rebound,
                    progress: smoothStep(normalized(
                        elapsed,
                        from: lastBeat.time,
                        to: reboundTime
                    ))
                )
            } else {
                sample = interpolate(
                    from: rebound,
                    to: .resting,
                    progress: smoothStep(normalized(
                        elapsed,
                        from: reboundTime,
                    to: min(duration, lastBeat.time + settleDelay)
                    ))
                )
            }
        }

        let axis = stableAxis(for: ringSeed)
        return ChoiceAnticipationMotion(
            scale: sample.scale,
            translation: reduceMotion
                ? .zero
                : CGVector(
                    dx: axis.dx * sample.scalarTranslation,
                    dy: axis.dy * sample.scalarTranslation
                ),
            rotationDegrees: reduceMotion ? 0 : sample.rotationDegrees
        )
    }

    public func stableAxis(for ringSeed: UInt64) -> CGVector {
        var value = ringSeed &+ 0x9E37_79B9_7F4A_7C15
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        value ^= value >> 31
        let fraction = Double(value >> 11) / Double(1 << 53)
        let angle = fraction * 2 * Double.pi
        return CGVector(dx: cos(angle), dy: sin(angle))
    }

    private func normalized(
        _ value: TimeInterval,
        from start: TimeInterval,
        to end: TimeInterval
    ) -> CGFloat {
        guard end > start else { return 1 }
        return min(1, max(0, CGFloat((value - start) / (end - start))))
    }

    private func peakSample(
        for beat: ChoiceAnticipationBeat,
        index: Int
    ) -> ChoiceAnticipationMotionSample {
        let direction = index.isMultiple(of: 2) ? 1.0 : -1.0
        return ChoiceAnticipationMotionSample(
            scale: beat.compressionScale,
            scalarTranslation: CGFloat(direction) * beat.translation,
            rotationDegrees: direction * beat.rotationDegrees
        )
    }

    private func reboundSample(
        for beat: ChoiceAnticipationBeat,
        index: Int
    ) -> ChoiceAnticipationMotionSample {
        let direction = index.isMultiple(of: 2) ? -1.0 : 1.0
        return ChoiceAnticipationMotionSample(
            scale: beat.reboundScale,
            scalarTranslation: CGFloat(direction) * beat.translation * 0.34,
            rotationDegrees: direction * beat.rotationDegrees * 0.34
        )
    }

    private func smoothStep(_ progress: CGFloat) -> CGFloat {
        progress * progress * (3 - 2 * progress)
    }

    private func interpolate(
        from start: ChoiceAnticipationMotionSample,
        to end: ChoiceAnticipationMotionSample,
        progress: CGFloat
    ) -> ChoiceAnticipationMotionSample {
        ChoiceAnticipationMotionSample(
            scale: interpolate(from: start.scale, to: end.scale, progress: progress),
            scalarTranslation: interpolate(
                from: start.scalarTranslation,
                to: end.scalarTranslation,
                progress: progress
            ),
            rotationDegrees: interpolate(
                from: start.rotationDegrees,
                to: end.rotationDegrees,
                progress: Double(progress)
            )
        )
    }

    private func interpolate(
        from start: CGFloat,
        to end: CGFloat,
        progress: CGFloat
    ) -> CGFloat {
        start + (end - start) * progress
    }

    private func interpolate(
        from start: Double,
        to end: Double,
        progress: Double
    ) -> Double {
        start + (end - start) * progress
    }
}

private struct ChoiceAnticipationMotionSample {
    let scale: CGFloat
    let scalarTranslation: CGFloat
    let rotationDegrees: Double

    static let resting = ChoiceAnticipationMotionSample(
        scale: 1,
        scalarTranslation: 0,
        rotationDegrees: 0
    )
}
