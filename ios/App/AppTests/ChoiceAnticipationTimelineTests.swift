import CoreGraphics
import XCTest
@testable import App

final class ChoiceAnticipationTimelineTests: XCTestCase {
    private let accuracy = 0.000_001

    func testChooserTimelineProvidesALongerEscalatingDecisionRitual() throws {
        let timeline = ChoiceAnticipationTimeline.chooser

        XCTAssertEqual(timeline.duration, 2.75, accuracy: accuracy)
        XCTAssertEqual(timeline.winnerRevealDuration, 0.82, accuracy: accuracy)
        XCTAssertEqual(timeline.loserFadeDuration, 0.46, accuracy: accuracy)
        XCTAssertEqual(timeline.winnerCompressionFraction, 0.10, accuracy: accuracy)
        XCTAssertEqual(timeline.winnerContactTime, 0.082, accuracy: accuracy)
        XCTAssertEqual(timeline.beats.map(\.time), [0.24, 0.78, 1.28, 1.72, 2.10, 2.43])
        XCTAssertEqual(timeline.beats.map(\.intensity), [0.26, 0.34, 0.43, 0.53, 0.63, 0.74])
        XCTAssertEqual(timeline.beats.map(\.sharpness), [0.16, 0.18, 0.20, 0.22, 0.24, 0.27])
        XCTAssertEqual(timeline.beats.map(\.compressionScale), [0.994, 0.991, 0.987, 0.982, 0.976, 0.968])
        XCTAssertEqual(timeline.beats.map(\.reboundScale), [1.002, 1.003, 1.004, 1.006, 1.008, 1.011])
        XCTAssertEqual(timeline.beats.map(\.translation), [1.4, 2.1, 3.0, 4.0, 5.0, 6.0])
        XCTAssertEqual(timeline.beats.map(\.rotationDegrees), [0.18, 0.30, 0.44, 0.60, 0.76, 0.94])
        XCTAssertEqual(timeline.maximumScale, 1.011, accuracy: accuracy)
        XCTAssertEqual(timeline.maximumTranslation, 6.0, accuracy: accuracy)
        XCTAssertEqual(
            timeline.duration - (timeline.beats.last?.time ?? 0),
            0.32,
            accuracy: accuracy,
            "The tactile ritual needs a quiet headroom beat before the physical landing"
        )

        let penultimate = try XCTUnwrap(timeline.beats.dropLast().last)
        let decision = try XCTUnwrap(timeline.beats.last)
        XCTAssertLessThan(decision.intensity, 1.0, "The winner landing must remain the strongest cue")
        XCTAssertGreaterThan(decision.translation, penultimate.translation)
        XCTAssertLessThan(decision.compressionScale, penultimate.compressionScale)
    }

    func testWinnerLandingHasAuditedSwellAndLongDecay() {
        let timeline = ChoiceAnticipationTimeline.chooser
        let winner = timeline.winnerHaptic

        XCTAssertEqual(winner.attackTime, 0, accuracy: accuracy)
        XCTAssertEqual(winner.attackIntensity, 1.0, accuracy: Float(accuracy))
        XCTAssertEqual(winner.attackSharpness, 0.20, accuracy: Float(accuracy))
        XCTAssertEqual(winner.bodyStartTime, 0.012, accuracy: accuracy)
        XCTAssertEqual(winner.bodyDuration, 0.78, accuracy: accuracy)
        XCTAssertEqual(winner.bodySharpness, 0.07, accuracy: Float(accuracy))
        XCTAssertEqual(
            winner.intensityCurve,
            [
                .init(relativeTime: 0, intensity: 0.82),
                .init(relativeTime: 0.060, intensity: 0.96),
                .init(relativeTime: 0.180, intensity: 0.78),
                .init(relativeTime: 0.340, intensity: 0.56),
                .init(relativeTime: 0.520, intensity: 0.36),
                .init(relativeTime: 0.680, intensity: 0.18),
                .init(relativeTime: 0.780, intensity: 0.05)
            ]
        )
        XCTAssertGreaterThan(winner.intensityCurve[1].intensity, winner.intensityCurve[0].intensity)
        XCTAssertTrue(zip(
            winner.intensityCurve.dropFirst(),
            winner.intensityCurve.dropFirst(2)
        ).allSatisfy { $0.intensity > $1.intensity })
        XCTAssertEqual(
            timeline.winnerContactTime,
            timeline.winnerRevealDuration * ChooserWinnerLandingMetrics.compressionFraction,
            accuracy: accuracy,
            "The tactile attack must land on maximum visible compression"
        )
    }

    func testEveryHapticInstantIsTheExactCompressionAndMaximumDisplacement() {
        let timeline = ChoiceAnticipationTimeline.chooser
        let seed: UInt64 = 0xC001_CAFE
        let axis = timeline.stableAxis(for: seed)

        for (index, beat) in timeline.beats.enumerated() {
            let motion = timeline.motion(
                at: beat.time,
                ringSeed: seed,
                reduceMotion: false
            )
            XCTAssertEqual(motion.scale, beat.compressionScale, accuracy: accuracy)
            XCTAssertEqual(
                hypot(motion.translation.dx, motion.translation.dy),
                beat.translation,
                accuracy: accuracy
            )
            XCTAssertEqual(abs(motion.rotationDegrees), beat.rotationDegrees, accuracy: accuracy)

            let projection = motion.translation.dx * axis.dx + motion.translation.dy * axis.dy
            if index.isMultiple(of: 2) {
                XCTAssertGreaterThan(projection, 0)
                XCTAssertGreaterThan(motion.rotationDegrees, 0)
            } else {
                XCTAssertLessThan(projection, 0)
                XCTAssertLessThan(motion.rotationDegrees, 0)
            }
        }
    }

    func testRingsKeepMovingBetweenBeatsThenSettleAfterTheDecisiveBeat() throws {
        let timeline = ChoiceAnticipationTimeline.chooser
        let seed: UInt64 = 17

        for (index, beat) in timeline.beats.enumerated() {
            let reboundTime = try XCTUnwrap(timeline.reboundTime(afterBeatAt: index))
            let rebound = timeline.motion(
                at: reboundTime,
                ringSeed: seed,
                reduceMotion: false
            )
            XCTAssertEqual(rebound.scale, beat.reboundScale, accuracy: accuracy)

            if timeline.beats.indices.contains(index + 1) {
                let stillDeciding = timeline.motion(
                    at: timeline.beats[index + 1].time - 0.001,
                    ringSeed: seed,
                    reduceMotion: false
                )
                XCTAssertNotEqual(stillDeciding, .resting)
            }
        }

        assertResting(timeline.motion(
            at: timeline.duration,
            ringSeed: seed,
            reduceMotion: false
        ))
    }

    func testVisibleShakeIsContinuousAtDisplayCadenceAfterItsGentleLeadIn() {
        let timeline = ChoiceAnticipationTimeline.chooser
        let firstMotionTime = timeline.beats[0].time - timeline.compressionLead + 1.0 / 120.0
        var elapsed = firstMotionTime

        while elapsed < timeline.duration - 1.0 / 120.0 {
            XCTAssertNotEqual(
                timeline.motion(at: elapsed, ringSeed: 831, reduceMotion: false),
                .resting,
                "The deciding motion unexpectedly stopped at \(elapsed)s"
            )
            elapsed += 1.0 / 120.0
        }
    }

    func testMotionRestsOutsideResponsesAndUsesAStableUnitAxis() {
        let timeline = ChoiceAnticipationTimeline.chooser
        let seed: UInt64 = 91
        let first = timeline.stableAxis(for: seed)
        let repeated = timeline.stableAxis(for: seed)
        let other = timeline.stableAxis(for: seed + 1)

        XCTAssertEqual(first.dx, repeated.dx, accuracy: accuracy)
        XCTAssertEqual(first.dy, repeated.dy, accuracy: accuracy)
        XCTAssertEqual(hypot(first.dx, first.dy), 1, accuracy: accuracy)
        XCTAssertNotEqual(first, other)
        assertResting(timeline.motion(at: 0, ringSeed: seed, reduceMotion: false))
        assertResting(timeline.motion(at: timeline.duration, ringSeed: seed, reduceMotion: false))
        assertResting(timeline.motion(at: .infinity, ringSeed: seed, reduceMotion: false))
    }

    func testReducedMotionRetainsPressureButRemovesTravelAndRotation() {
        let timeline = ChoiceAnticipationTimeline.chooser

        for beat in timeline.beats {
            let motion = timeline.motion(
                at: beat.time,
                ringSeed: 42,
                reduceMotion: true
            )
            XCTAssertEqual(motion.scale, beat.compressionScale, accuracy: accuracy)
            XCTAssertEqual(motion.translation, .zero)
            XCTAssertEqual(motion.rotationDegrees, 0, accuracy: accuracy)
        }
    }

    @MainActor
    func testChooserClampContainsMaximumReboundAndShakeAtEveryEdge() {
        let timeline = ChoiceAnticipationTimeline.chooser
        let edgeAccuracy: CGFloat = 0.000_001
        let size = CGSize(width: 390, height: 720)
        let diameter: CGFloat = 176
        let footprintRadius = BoardPieceVisualMetrics.footprintRadius(
            diameter: diameter,
            emphasis: .resting,
            externalScale: timeline.maximumScale
        )
        let rawCorners = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: size.width, y: 0),
            CGPoint(x: 0, y: size.height),
            CGPoint(x: size.width, y: size.height)
        ]

        for (cornerIndex, rawCorner) in rawCorners.enumerated() {
            let center = BoardPieceVisualMetrics.clampedCenter(
                rawCorner,
                in: size,
                diameter: diameter,
                emphasis: .resting,
                externalScale: timeline.maximumScale,
                margin: 8 + timeline.maximumTranslation
            )
            for beat in timeline.beats {
                let motion = timeline.motion(
                    at: beat.time,
                    ringSeed: UInt64(cornerIndex + 1),
                    reduceMotion: false
                )
                let displayed = CGPoint(
                    x: center.x + motion.translation.dx,
                    y: center.y + motion.translation.dy
                )
                XCTAssertGreaterThanOrEqual(displayed.x - footprintRadius, 8 - edgeAccuracy)
                XCTAssertGreaterThanOrEqual(displayed.y - footprintRadius, 8 - edgeAccuracy)
                XCTAssertLessThanOrEqual(displayed.x + footprintRadius, size.width - 8 + edgeAccuracy)
                XCTAssertLessThanOrEqual(displayed.y + footprintRadius, size.height - 8 + edgeAccuracy)
            }
        }
    }

    @MainActor
    func testWinnerLandingArcFillsRevealAndStaysInsideEveryEdge() {
        let timeline = ChoiceAnticipationTimeline.chooser
        let edgeAccuracy: CGFloat = 0.000_001
        let size = CGSize(width: 390, height: 720)
        let diameter: CGFloat = 176
        let fractions = [
            ChooserWinnerLandingMetrics.compressionFraction,
            ChooserWinnerLandingMetrics.reboundFraction,
            ChooserWinnerLandingMetrics.counterFraction,
            ChooserWinnerLandingMetrics.settleFraction
        ]
        XCTAssertEqual(fractions.reduce(0, +), 1, accuracy: accuracy)

        let externalScale = max(
            timeline.maximumScale,
            ChooserWinnerLandingMetrics.maximumScale
        )
        let footprintRadius = BoardPieceVisualMetrics.footprintRadius(
            diameter: diameter,
            emphasis: .winner,
            externalScale: externalScale
        )
        let margin = 8 + max(
            timeline.maximumTranslation,
            ChooserWinnerLandingMetrics.maximumTranslation
        )
        let rawCorners = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: size.width, y: 0),
            CGPoint(x: 0, y: size.height),
            CGPoint(x: size.width, y: size.height)
        ]

        for rawCorner in rawCorners {
            let center = BoardPieceVisualMetrics.clampedCenter(
                rawCorner,
                in: size,
                diameter: diameter,
                emphasis: .winner,
                externalScale: externalScale,
                margin: margin
            )
            for direction: CGFloat in [-1, 1] {
                let translations = [
                    CGVector(
                        dx: direction * ChooserWinnerLandingMetrics.compressionX,
                        dy: ChooserWinnerLandingMetrics.compressionY
                    ),
                    CGVector(
                        dx: direction * ChooserWinnerLandingMetrics.reboundX,
                        dy: ChooserWinnerLandingMetrics.reboundY
                    ),
                    CGVector(
                        dx: direction * ChooserWinnerLandingMetrics.counterX,
                        dy: ChooserWinnerLandingMetrics.counterY
                    ),
                    .zero
                ]

                for translation in translations {
                    let displayed = CGPoint(
                        x: center.x + translation.dx,
                        y: center.y + translation.dy
                    )
                    XCTAssertGreaterThanOrEqual(
                        displayed.x - footprintRadius,
                        8 - edgeAccuracy
                    )
                    XCTAssertGreaterThanOrEqual(
                        displayed.y - footprintRadius,
                        8 - edgeAccuracy
                    )
                    XCTAssertLessThanOrEqual(
                        displayed.x + footprintRadius,
                        size.width - 8 + edgeAccuracy
                    )
                    XCTAssertLessThanOrEqual(
                        displayed.y + footprintRadius,
                        size.height - 8 + edgeAccuracy
                    )
                }
            }
        }
    }

    private func assertResting(
        _ motion: ChoiceAnticipationMotion,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(motion.scale, 1, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(motion.translation, .zero, file: file, line: line)
        XCTAssertEqual(motion.rotationDegrees, 0, accuracy: accuracy, file: file, line: line)
    }
}
