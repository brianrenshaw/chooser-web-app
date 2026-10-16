import CoreGraphics

/// One layer drawn over the shared ball layers: white light, or pigment in
/// the ball's edge color.
struct PinballBallOrnamentLayer {
    let path: CGPath
    let fillAlpha: CGFloat
    let strokeAlpha: CGFloat
    let lineWidth: CGFloat
    /// Drawn in the ball's edge color instead of white: egg speckles and a
    /// pupil are pigment, not light.
    var darkFillAlpha: CGFloat = 0
}

/// The single source of ornament geometry for both the SpriteKit flight ball
/// and every SwiftUI miniature, so the two can never drift apart.
///
/// Paths are centered on the origin. `yUp` flips them for SpriteKit, whose y
/// axis points up; the light always sits to the upper left.
enum PinballBallOrnamentGeometry {
    static func layers(
        for ornament: PinballBallOrnament,
        radius: CGFloat,
        yUp: Bool
    ) -> [PinballBallOrnamentLayer] {
        let flip: CGFloat = yUp ? -1 : 1
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * radius, y: y * radius * flip)
        }
        func ellipse(centerX: CGFloat, centerY: CGFloat, width: CGFloat, height: CGFloat) -> CGPath {
            let center = point(centerX, centerY)
            return CGPath(ellipseIn: CGRect(
                x: center.x - width * radius / 2,
                y: center.y - height * radius / 2,
                width: width * radius,
                height: height * radius
            ), transform: nil)
        }
        let sparkle = PinballBallOrnamentLayer(
            path: ellipse(centerX: -0.32, centerY: -0.38, width: 0.36, height: 0.22),
            fillAlpha: 0.88, strokeAlpha: 0, lineWidth: 0
        )

        switch ornament {
        case .none:
            return []
        case .glassBead:
            return [
                PinballBallOrnamentLayer(
                    path: ellipse(centerX: -0.10, centerY: -0.10, width: 1.24, height: 1.24),
                    fillAlpha: 0.14, strokeAlpha: 0, lineWidth: 0
                ),
                sparkle
            ]
        case .facetedGem:
            let table = CGMutablePath()
            let rays = CGMutablePath()
            for index in 0..<8 {
                let angle = (22.5 + 45 * Double(index)) * .pi / 180
                let inner = point(0.46 * cos(angle), 0.46 * sin(angle))
                let outer = point(0.92 * cos(angle), 0.92 * sin(angle))
                if index == 0 { table.move(to: inner) } else { table.addLine(to: inner) }
                rays.move(to: inner)
                rays.addLine(to: outer)
            }
            table.closeSubpath()
            return [
                PinballBallOrnamentLayer(
                    path: table, fillAlpha: 0.22, strokeAlpha: 0.62,
                    lineWidth: max(0.5, radius * 0.05)
                ),
                PinballBallOrnamentLayer(
                    path: rays, fillAlpha: 0, strokeAlpha: 0.40,
                    lineWidth: max(0.5, radius * 0.05)
                ),
                sparkle
            ]
        case .clearGlass:
            let caustic = CGMutablePath()
            let causticRadius = 0.70 * radius
            // A bright arc on the far side from the light, as a glass bead
            // focuses it.
            caustic.addArc(
                center: .zero,
                radius: causticRadius,
                startAngle: yUp ? -20 * .pi / 180 : 20 * .pi / 180,
                endAngle: yUp ? -110 * .pi / 180 : 110 * .pi / 180,
                clockwise: yUp
            )
            return [
                PinballBallOrnamentLayer(
                    path: ellipse(centerX: 0, centerY: 0, width: 2, height: 2),
                    fillAlpha: 0.18, strokeAlpha: 0, lineWidth: 0
                ),
                PinballBallOrnamentLayer(
                    path: caustic, fillAlpha: 0, strokeAlpha: 0.90,
                    lineWidth: max(0.8, radius * 0.13)
                ),
                sparkle
            ]
        case .speckledEgg:
            // A fixed scatter of dark specks, so the egg looks the same in
            // flight and in Settings.
            let specks = CGMutablePath()
            for (x, y, size) in [
                (0.30, -0.10, 0.10), (-0.20, 0.34, 0.08), (0.46, 0.30, 0.07),
                (-0.48, 0.02, 0.07), (0.06, 0.52, 0.06), (0.24, -0.46, 0.06),
                (-0.06, 0.12, 0.05)
            ] as [(CGFloat, CGFloat, CGFloat)] {
                specks.addPath(ellipse(centerX: x, centerY: y, width: size * 2, height: size * 1.6))
            }
            return [
                PinballBallOrnamentLayer(path: specks, fillAlpha: 0, strokeAlpha: 0, lineWidth: 0, darkFillAlpha: 0.55),
                sparkle
            ]
        case .coin:
            let milled = CGMutablePath()
            for index in 0..<24 {
                let angle = Double(index) / 24 * 2 * .pi
                milled.move(to: point(0.80 * cos(angle), 0.80 * sin(angle)))
                milled.addLine(to: point(0.96 * cos(angle), 0.96 * sin(angle)))
            }
            return [
                PinballBallOrnamentLayer(
                    path: milled, fillAlpha: 0, strokeAlpha: 0.38,
                    lineWidth: max(0.5, radius * 0.07)
                ),
                PinballBallOrnamentLayer(
                    path: ellipse(centerX: 0, centerY: 0, width: 1.16, height: 1.16),
                    fillAlpha: 0, strokeAlpha: 0.55,
                    lineWidth: max(0.5, radius * 0.07)
                ),
                sparkle
            ]
        case .slitPupil:
            return [
                PinballBallOrnamentLayer(
                    path: ellipse(centerX: 0, centerY: 0, width: 0.34, height: 1.30),
                    fillAlpha: 0, strokeAlpha: 0, lineWidth: 0, darkFillAlpha: 0.92
                ),
                sparkle
            ]
        }
    }
}
