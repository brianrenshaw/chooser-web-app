import SwiftUI

/// The abstract subject of a world: the thing its box is about, drawn as flat
/// silhouettes and simple forms over the surface washes and under the pieces.
/// A dragon, a shoal of fish, a meadow built from tokens, a peacock's fan.
///
/// Every recipe is original abstract drawing. No logo, lettering, character
/// likeness, card art or proprietary artwork from any game is reproduced; the
/// subjects are generic (a dragon, birds, a lion, a forge) rendered in the
/// world's own palette.
///
/// Recipes are authored on a 390 x 844 phone board, scaled by the short edge
/// so Settings miniatures, phones and iPads keep the same character, and
/// composited in non-linear (sRGB) space like the surfaces they sit on.
public enum BoardSubjectArt: String, Codable, CaseIterable, Sendable {
    /// A perched songbird on a branch, birds on the wing, drifting feathers.
    case fieldGuideBirds
    /// A fanned peacock tail of eye-spot feathers rising from the foot.
    case peacockFan
    /// Hummingbirds hovering at trumpet blooms.
    case hummingbirdsAndBlooms
    /// A dwarven hall gate with runes, an anvil, crossed axes and sparks.
    case dwarvenForge
    /// Laurel, aqueduct arches, a trireme and city houses on the map.
    case romanMap
    /// The great tree with hanging lanterns, falling leaves, a cottage in its roots.
    case everTree
    /// A lizard in a wizard's hat, a cauldron, stars and a crescent moon.
    case lizardWizardry
    /// Character standees on a gold-inlaid hex board, facing each other.
    case leadersStandees
    /// A candle, an orb and alchemical element glyphs at the pentagon's nodes.
    case alchemistsCandle
    /// A toucan, a capybara and butterflies among the canopy.
    case jungleCanopyAnimals
    /// Basilica spires along the foot of the window, and a dove.
    case basilicaAndDove
    /// A dragon: veined wings, a coiled scaled body, head, ruff and a clutch of eggs.
    case wyrmDragon
    /// A meadow built from tokens: trees, mountains, a river, a lion-sun, a fox and cranes.
    case tokenMeadow
    /// A flying fish at the surface, a shoal, a manta, a shark in the deep, bubbles.
    case oceanDescent
}

/// Geometry and palette helpers every subject recipe shares.
///
/// Coordinates are authored on the 390 x 844 phone board. `point` maps an
/// authored position onto the live board (stretching with the board's aspect,
/// the way the surface recipes do), while `scale` sizes shapes by the short
/// edge so they stay in proportion on miniatures and iPads.
struct BoardSubjectCanvas {
    let size: CGSize
    let theme: ChooserVisualTheme
    /// Short-edge scale: 1 on a phone, about 0.27 in a Settings tile, 2.6 on an iPad.
    let scale: CGFloat
    /// Horizontal and vertical position scales (`width / 390`, `height / 844`).
    let sx: CGFloat
    let sy: CGFloat

    init(size: CGSize, theme: ChooserVisualTheme) {
        self.size = size
        self.theme = theme
        scale = max(0.2, min(size.width, size.height) / 390)
        sx = size.width / 390
        sy = size.height / 844
    }

    var width: CGFloat { size.width }
    var height: CGFloat { size.height }
    var bounds: CGRect { CGRect(origin: .zero, size: size) }

    /// An authored position on the live board.
    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x * sx, y: y * sy)
    }

    /// A position measured in from the right edge, so corner motifs stay in
    /// the corner on a wide board instead of drifting toward the middle.
    func fromRight(_ inset: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: size.width - inset * scale, y: y * sy)
    }

    /// A position measured up from the bottom edge.
    func fromBottom(_ x: CGFloat, _ inset: CGFloat) -> CGPoint {
        CGPoint(x: x * sx, y: size.height - inset * scale)
    }

    /// An authored length on the live board.
    func length(_ value: CGFloat) -> CGFloat { value * scale }

    func color(_ hex: String) -> Color { ChooserColorTheme.color(hex: hex) }
    var ink: Color { theme.primaryInkColor }
    func participant(_ index: Int) -> Color { theme.participantColor(at: index) }

    /// A seeded generator for scatter, so a world never changes between frames.
    func generator(salt: UInt64) -> BoardTextureGenerator {
        BoardTextureGenerator(seed: theme.textureSeed ^ salt)
    }

    // MARK: Shapes

    /// A path authored around its own origin, placed on the live board: scaled
    /// by the short edge, rotated, then translated to `position`.
    func placed(_ path: Path, at position: CGPoint, rotation: Double = 0, scale extra: CGFloat = 1) -> Path {
        path.applying(
            CGAffineTransform(scaleX: scale * extra, y: scale * extra)
                .concatenating(CGAffineTransform(rotationAngle: rotation))
                .concatenating(CGAffineTransform(translationX: position.x, y: position.y))
        )
    }

    func circle(at center: CGPoint, radius: CGFloat) -> Path {
        let r = radius * scale
        return Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
    }

    func ellipse(at center: CGPoint, rx: CGFloat, ry: CGFloat) -> Path {
        let w = rx * scale
        let h = ry * scale
        return Path(ellipseIn: CGRect(x: center.x - w, y: center.y - h, width: w * 2, height: h * 2))
    }

    /// A smooth closed blob through authored points (relative to `center`),
    /// for leaves, washes, hills and other organic shapes.
    func blob(center: CGPoint, points: [CGPoint]) -> Path {
        let scaled = points.map { CGPoint(x: center.x + $0.x * scale, y: center.y + $0.y * scale) }
        return Self.smoothClosed(scaled)
    }

    static func smoothClosed(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count > 2 else { return path }
        let count = points.count
        path.move(to: CGPoint(
            x: (points[0].x + points[count - 1].x) / 2,
            y: (points[0].y + points[count - 1].y) / 2
        ))
        for index in 0..<count {
            let current = points[index]
            let next = points[(index + 1) % count]
            path.addQuadCurve(
                to: CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2),
                control: current
            )
        }
        path.closeSubpath()
        return path
    }

    /// A thick line with a visible taper: `widths` are authored stroke widths
    /// at successive segments of `segments` (each a cubic from the previous
    /// end). Returns the fillable outline, so it can be used for clipping.
    func taperedStroke(
        from start: CGPoint,
        segments: [(to: CGPoint, control1: CGPoint, control2: CGPoint, width: CGFloat)]
    ) -> Path {
        var outline = Path()
        var from = start
        for segment in segments {
            var piece = Path()
            piece.move(to: from)
            piece.addCurve(to: segment.to, control1: segment.control1, control2: segment.control2)
            outline.addPath(piece.strokedPath(StrokeStyle(
                lineWidth: segment.width * scale,
                lineCap: .round,
                lineJoin: .round
            )))
            from = segment.to
        }
        return outline
    }
}

/// Dispatches each world's subject to its recipe. One file per world under
/// `SubjectArt/`, each an extension adding `drawXxx(in:on:)`.
enum BoardSubjectArtRenderer {
    static func draw(_ art: BoardSubjectArt, in context: inout GraphicsContext, on board: BoardSubjectCanvas) {
        switch art {
        case .fieldGuideBirds: drawFieldGuideBirds(in: &context, on: board)
        case .peacockFan: drawPeacockFan(in: &context, on: board)
        case .hummingbirdsAndBlooms: drawHummingbirdsAndBlooms(in: &context, on: board)
        case .dwarvenForge: drawDwarvenForge(in: &context, on: board)
        case .romanMap: drawRomanMap(in: &context, on: board)
        case .everTree: drawEverTree(in: &context, on: board)
        case .lizardWizardry: drawLizardWizardry(in: &context, on: board)
        case .leadersStandees: drawLeadersStandees(in: &context, on: board)
        case .alchemistsCandle: drawAlchemistsCandle(in: &context, on: board)
        case .jungleCanopyAnimals: drawJungleCanopyAnimals(in: &context, on: board)
        case .basilicaAndDove: drawBasilicaAndDove(in: &context, on: board)
        case .wyrmDragon: drawWyrmDragon(in: &context, on: board)
        case .tokenMeadow: drawTokenMeadow(in: &context, on: board)
        case .oceanDescent: drawOceanDescent(in: &context, on: board)
        }
    }
}

/// The subject layer of a board: between the surface's atmosphere and its
/// grain, under every piece.
struct BoardSubjectArtView: View {
    let visualTheme: ChooserVisualTheme

    var body: some View {
        Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: true) { context, size in
            BoardSubjectArtRenderer.draw(
                visualTheme.subjectArt,
                in: &context,
                on: BoardSubjectCanvas(size: size, theme: visualTheme)
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
