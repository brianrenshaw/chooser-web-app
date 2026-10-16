import Foundation
import SwiftUI

public enum ChooserThemeAppearance: String, Codable, Sendable {
    case light
    case dark

    public var colorScheme: ColorScheme { self == .light ? .light : .dark }
}

/// The authored spatial composition of a complete theme world. These are
/// intentionally abstract recipes rather than copied game imagery.
public enum BoardSurfaceComposition: String, Codable, CaseIterable, Sendable {
    case verticalWatercolorWash
    case redLacquerField
    case rainforestClearing
    case slateForge
    case mediterraneanMap
    case honeyAutumnTree
    case amberPlumPainting
    case layeredScreenprint
    /// Candlelit oxblood leather with blind-tooled circle, ticks and pentagon.
    case tooledGrimoire
    /// Sunlit valley under a dark canopy, with a turquoise river.
    case canopyRiverValley
    /// Leaded dusk-glass shards around a rose window, in a stone frame.
    case roseWindow
}

/// Surface texture is independent from the material used by rings and chits.
public enum BoardSurfaceTextureKind: String, Codable, CaseIterable, Sendable {
    case watercolorFlecks
    case featherFibers
    case leafFibers
    case parchmentPatina
    case frescoGrain
    case pressedPaper
    case midnightSpeckle
    case screenprintRegistration
    case leatherGrain
    case paintedCanopy
    case cathedralGlass

    var rendererFinish: BoardPieceFinish {
        switch self {
        case .watercolorFlecks: .watercolorEggshell
        case .featherFibers: .peacockJewelEnamel
        case .leafFibers: .featherJewelEnamel
        case .parchmentPatina: .hammeredMetal
        case .frescoGrain: .frescoEnamel
        case .pressedPaper: .pressedWoodPaper
        case .midnightSpeckle: .midnightEnamel
        case .screenprintRegistration: .flatScreenprint
        case .leatherGrain: .waxSeal
        // Brushwork on the board reads as soft flecks; grain belongs to the pieces.
        case .paintedCanopy: .watercolorEggshell
        case .cathedralGlass: .leadedGlass
        }
    }

    /// How strongly the surface grain draws relative to the authored texture
    /// opacity. The original eight keep 1, so they render exactly as before;
    /// leather, brushwork and cathedral glass are meant to be felt.
    var surfaceStrength: Double {
        switch self {
        case .featherFibers, .leafFibers, .frescoGrain, .pressedPaper,
             .screenprintRegistration:
            1
        // Cold-press paper, slate and brushwork are meant to be felt.
        case .watercolorFlecks: 1.6
        case .parchmentPatina: 1.6
        case .midnightSpeckle: 1.4
        case .leatherGrain: 1.8
        case .paintedCanopy: 1.8
        case .cathedralGlass: 1.4
        }
    }
}

public struct BoardSurfaceStop: Equatable, Sendable {
    public let hex: String
    public let location: Double

    public init(hex: String, location: Double) {
        precondition((0...1).contains(location), "Surface stop location must be normalized")
        self.hex = hex
        self.location = location
    }
}

public struct BoardSurfaceRecipe: Equatable, Sendable {
    public let composition: BoardSurfaceComposition
    public let stops: [BoardSurfaceStop]
    public let atmosphereHexValues: [String]
    public let atmosphereOpacities: [Double]
    public let texture: BoardSurfaceTextureKind

    public init(
        composition: BoardSurfaceComposition,
        stops: [BoardSurfaceStop],
        atmosphereHexValues: [String] = [],
        atmosphereOpacities: [Double] = [],
        texture: BoardSurfaceTextureKind
    ) {
        precondition(stops.count >= 2, "A theme world needs at least two surface stops")
        precondition(
            zip(stops, stops.dropFirst()).allSatisfy { pair in
                pair.0.location <= pair.1.location
            },
            "Surface stops must be ordered"
        )
        precondition(
            atmosphereHexValues.count == atmosphereOpacities.count,
            "Every atmosphere color needs an opacity"
        )
        precondition(
            atmosphereOpacities.allSatisfy { (0...0.40).contains($0) },
            "Atmosphere layers must remain restrained"
        )
        self.composition = composition
        self.stops = stops
        self.atmosphereHexValues = atmosphereHexValues
        self.atmosphereOpacities = atmosphereOpacities
        self.texture = texture
    }
}

/// Abstract procedural finishes: color relationships are inspired by games,
/// while artwork, logos, characters, symbols, and proprietary fonts are not.
public enum BoardPieceFinish: String, Codable, Sendable {
    case watercolorEggshell
    case peacockJewelEnamel
    case featherJewelEnamel
    case hammeredMetal
    case frescoEnamel
    case pressedWoodPaper
    case midnightEnamel
    case flatScreenprint
    /// Pressed sealing wax: pebbled mottle, a stamped inner ring, a poured rim.
    case waxSeal
    /// Satin paint over wood, with long grain.
    case paintedWood
    /// Lit glass with streaks, held in a near-black lead rim.
    case leadedGlass
}

struct BoardPieceMaterialPresentation: Equatable, Sendable {
    let outerEdgeWidth: CGFloat
    let innerEdgeWidth: CGFloat
    let bevelOpacity: CGFloat
    let edgeTintOpacity: CGFloat
    let reliefOpacity: CGFloat
    let innerOcclusionOpacity: CGFloat
    let reliefRotationDegrees: Double
    let textureMultiplier: Double
    let shadowMultiplier: Double
}

extension BoardPieceFinish {
    var presentation: BoardPieceMaterialPresentation {
        switch self {
        case .watercolorEggshell:
            BoardPieceMaterialPresentation(
                outerEdgeWidth: 2.2, innerEdgeWidth: 1.6, bevelOpacity: 0.22,
                edgeTintOpacity: 0.58, reliefOpacity: 0.17,
                innerOcclusionOpacity: 0.27, reliefRotationDegrees: -28,
                textureMultiplier: 1.85, shadowMultiplier: 0.82
            )
        case .peacockJewelEnamel:
            BoardPieceMaterialPresentation(
                outerEdgeWidth: 2.7, innerEdgeWidth: 1.85, bevelOpacity: 0.39,
                edgeTintOpacity: 0.72, reliefOpacity: 0.30,
                innerOcclusionOpacity: 0.36, reliefRotationDegrees: -42,
                textureMultiplier: 1.90, shadowMultiplier: 1.04
            )
        case .featherJewelEnamel:
            BoardPieceMaterialPresentation(
                outerEdgeWidth: 2.6, innerEdgeWidth: 1.8, bevelOpacity: 0.40,
                edgeTintOpacity: 0.70, reliefOpacity: 0.31,
                innerOcclusionOpacity: 0.35, reliefRotationDegrees: -18,
                textureMultiplier: 1.95, shadowMultiplier: 1.04
            )
        case .hammeredMetal:
            BoardPieceMaterialPresentation(
                outerEdgeWidth: 2.8, innerEdgeWidth: 1.9, bevelOpacity: 0.27,
                edgeTintOpacity: 0.76, reliefOpacity: 0.23,
                innerOcclusionOpacity: 0.42, reliefRotationDegrees: -52,
                textureMultiplier: 2.65, shadowMultiplier: 1.15
            )
        case .frescoEnamel:
            BoardPieceMaterialPresentation(
                outerEdgeWidth: 2.5, innerEdgeWidth: 1.75, bevelOpacity: 0.25,
                edgeTintOpacity: 0.64, reliefOpacity: 0.19,
                innerOcclusionOpacity: 0.31, reliefRotationDegrees: -34,
                textureMultiplier: 2.10, shadowMultiplier: 0.96
            )
        case .pressedWoodPaper:
            BoardPieceMaterialPresentation(
                outerEdgeWidth: 2.3, innerEdgeWidth: 1.65, bevelOpacity: 0.18,
                edgeTintOpacity: 0.60, reliefOpacity: 0.14,
                innerOcclusionOpacity: 0.30, reliefRotationDegrees: -12,
                textureMultiplier: 2.40, shadowMultiplier: 0.92
            )
        case .midnightEnamel:
            BoardPieceMaterialPresentation(
                outerEdgeWidth: 2.7, innerEdgeWidth: 1.85, bevelOpacity: 0.34,
                edgeTintOpacity: 0.74, reliefOpacity: 0.28,
                innerOcclusionOpacity: 0.39, reliefRotationDegrees: -46,
                textureMultiplier: 1.85, shadowMultiplier: 1.08
            )
        case .flatScreenprint:
            BoardPieceMaterialPresentation(
                outerEdgeWidth: 3.0, innerEdgeWidth: 1.65, bevelOpacity: 0.10,
                edgeTintOpacity: 0.54, reliefOpacity: 0.08,
                innerOcclusionOpacity: 0.22, reliefRotationDegrees: 0,
                textureMultiplier: 1.60, shadowMultiplier: 0.76
            )
        case .waxSeal:
            BoardPieceMaterialPresentation(
                outerEdgeWidth: 2.6, innerEdgeWidth: 1.7, bevelOpacity: 0.30,
                edgeTintOpacity: 0.66, reliefOpacity: 0.26,
                innerOcclusionOpacity: 0.38, reliefRotationDegrees: -38,
                textureMultiplier: 2.20, shadowMultiplier: 1.12
            )
        case .paintedWood:
            BoardPieceMaterialPresentation(
                outerEdgeWidth: 2.4, innerEdgeWidth: 1.7, bevelOpacity: 0.22,
                edgeTintOpacity: 0.62, reliefOpacity: 0.16,
                innerOcclusionOpacity: 0.30, reliefRotationDegrees: -8,
                textureMultiplier: 2.30, shadowMultiplier: 0.94
            )
        case .leadedGlass:
            BoardPieceMaterialPresentation(
                outerEdgeWidth: 3.2, innerEdgeWidth: 1.9, bevelOpacity: 0.36,
                edgeTintOpacity: 0.74, reliefOpacity: 0.24,
                innerOcclusionOpacity: 0.34, reliefRotationDegrees: -30,
                textureMultiplier: 1.70, shadowMultiplier: 1.00
            )
        }
    }
}

public enum PinballMaterialKind: String, Codable, Sendable {
    case coralEnamel
    case emeraldEnamel
    case flamingoEnamel
    case agedCopper
    case romanGold
    case amberResin
    case manaEnamel
    case saffronScreenprint
    case garnetBead
    case cutEmerald
    case clearGlassBead
}

/// Extra geometry drawn on top of the shared ball layers. Kept in the shared
/// presentation so the SpriteKit ball and every SwiftUI miniature match.
enum PinballBallOrnament: Equatable, Sendable {
    case none
    /// A hot specular spot and a soft colored aura.
    case glassBead
    /// An octagonal table and eight facet rays.
    case facetedGem
    /// A translucent body with a bright caustic arc.
    case clearGlass
    /// A small sheen and a scatter of speckles, like a wooden egg.
    case speckledEgg
    /// A milled edge and a struck inner ring.
    case coin
    /// A vertical slit pupil and a catch-light: an eye of newt.
    case slitPupil
}

/// How Pinball's ownership rays are stroked. Winner rays always use the
/// participant color, whatever the base style.
public enum BoardDividerStyle: String, Codable, Sendable {
    /// Keyline then primary line. The original look.
    case inkKeyline
    /// A pressed groove with a dashed thread, like a leather seam.
    case stitchedSeam
    /// A twisted rope: primary line with short dark dashes across it.
    case rope
    /// A stone bar: dark lead edge, stone body, thin highlight.
    case stoneMullion
    /// Two slightly offset graphite strokes, like a field-guide sketch.
    case pencil
    /// A dotted land route on a parchment keyline, from a map board.
    case dottedRoute
    /// A twig with small kinks along its length.
    case twig
    /// A fine gold-ink line in a faint groove.
    case goldInlay
}

/// Shared authored ball relief so the live SpriteKit ball and every miniature
/// preview depict the same physical finish instead of two look-alike assets.
struct PinballMaterialPresentation: Equatable, Sendable {
    let edgeWidth: CGFloat
    let shadeRadius: CGFloat
    let shadeAlpha: CGFloat
    let rimWidth: CGFloat
    let rimAlpha: CGFloat
    let markRadius: CGFloat
    let markAlpha: CGFloat
    var ornament: PinballBallOrnament = .none

    static let fallback = PinballMaterialPresentation(
        edgeWidth: 1.7,
        shadeRadius: 0.70,
        shadeAlpha: 0.16,
        rimWidth: 1.1,
        rimAlpha: 0.42,
        markRadius: 0,
        markAlpha: 0
    )
}

extension PinballMaterialKind {
    var presentation: PinballMaterialPresentation {
        switch self {
        case .coralEnamel:
            PinballMaterialPresentation(
                edgeWidth: 2.0, shadeRadius: 0.72, shadeAlpha: 0.15,
                rimWidth: 1.0, rimAlpha: 0.42, markRadius: 0.13, markAlpha: 0.18,
                ornament: .speckledEgg
            )
        case .emeraldEnamel:
            PinballMaterialPresentation(
                edgeWidth: 2.2, shadeRadius: 0.68, shadeAlpha: 0.18,
                rimWidth: 1.3, rimAlpha: 0.48, markRadius: 0.11, markAlpha: 0.16,
                ornament: .glassBead
            )
        case .flamingoEnamel:
            PinballMaterialPresentation(
                edgeWidth: 1.9, shadeRadius: 0.74, shadeAlpha: 0.14,
                rimWidth: 1.1, rimAlpha: 0.40, markRadius: 0.12, markAlpha: 0.16,
                ornament: .glassBead
            )
        case .amberResin:
            PinballMaterialPresentation(
                edgeWidth: 1.5, shadeRadius: 0.78, shadeAlpha: 0.10,
                rimWidth: 1.2, rimAlpha: 0.34, markRadius: 0.18, markAlpha: 0.12,
                ornament: .glassBead
            )
        case .agedCopper:
            PinballMaterialPresentation(
                edgeWidth: 2.3, shadeRadius: 0.66, shadeAlpha: 0.24,
                rimWidth: 1.5, rimAlpha: 0.55, markRadius: 0.10, markAlpha: 0.26,
                ornament: .coin
            )
        case .romanGold:
            PinballMaterialPresentation(
                edgeWidth: 2.1, shadeRadius: 0.70, shadeAlpha: 0.19,
                rimWidth: 1.4, rimAlpha: 0.50, markRadius: 0.12, markAlpha: 0.20,
                ornament: .coin
            )
        case .manaEnamel:
            PinballMaterialPresentation(
                edgeWidth: 2.1, shadeRadius: 0.70, shadeAlpha: 0.17,
                rimWidth: 1.2, rimAlpha: 0.46, markRadius: 0.14, markAlpha: 0.20,
                ornament: .slitPupil
            )
        case .saffronScreenprint:
            PinballMaterialPresentation(
                edgeWidth: 2.5, shadeRadius: 0.68, shadeAlpha: 0.08,
                rimWidth: 1.7, rimAlpha: 0.62, markRadius: 0, markAlpha: 0,
                ornament: .glassBead
            )
        case .garnetBead:
            PinballMaterialPresentation(
                edgeWidth: 1.6, shadeRadius: 0.74, shadeAlpha: 0.30,
                rimWidth: 1.0, rimAlpha: 0.36, markRadius: 0, markAlpha: 0,
                ornament: .glassBead
            )
        case .cutEmerald:
            PinballMaterialPresentation(
                edgeWidth: 1.8, shadeRadius: 0.72, shadeAlpha: 0.26,
                rimWidth: 1.2, rimAlpha: 0.44, markRadius: 0, markAlpha: 0,
                ornament: .facetedGem
            )
        case .clearGlassBead:
            PinballMaterialPresentation(
                edgeWidth: 1.4, shadeRadius: 0.80, shadeAlpha: 0.12,
                rimWidth: 1.3, rimAlpha: 0.70, markRadius: 0, markAlpha: 0,
                ornament: .clearGlass
            )
        }
    }
}

/// The complete set of roles used by SwiftUI, SpriteKit, and Settings previews.
public struct ChooserVisualTheme: Sendable {
    public let appearance: ChooserThemeAppearance
    public let surfaceRecipe: BoardSurfaceRecipe
    public let surfaceInkHex: String
    public let onChromeInkHex: String
    public let chromeHex: String
    public let actionAccentHex: String
    public let detailAccentHex: String
    public let secondaryDetailHex: String?
    public let participantHexValues: [String]
    public let pieceFinish: BoardPieceFinish
    public let authoredPinballMaterial: PinballMaterialKind
    public let ballHex: String
    public let ballEdgeHex: String
    public let ballTailHex: String
    public let ballImpactHex: String
    public let dividerHex: String
    public let dividerSecondaryHex: String?
    public let dividerStyle: BoardDividerStyle
    /// A world whose own palette is red can supply a destructive fill that
    /// still stands apart from its pieces. Nil keeps the shared semantic red.
    public let destructiveOverrideHex: String?
    public let textureSeed: UInt64
    public let textureOpacity: Double
    public let separatorOpacity: Double
    public let dividerOpacity: Double

    public init(
        appearance: ChooserThemeAppearance,
        surfaceRecipe: BoardSurfaceRecipe,
        surfaceInkHex: String,
        onChromeInkHex: String,
        chromeHex: String,
        actionAccentHex: String,
        detailAccentHex: String,
        secondaryDetailHex: String? = nil,
        participantHexValues: [String],
        pieceFinish: BoardPieceFinish,
        pinballMaterial: PinballMaterialKind,
        ballHex: String,
        ballEdgeHex: String,
        ballTailHex: String,
        ballImpactHex: String,
        dividerHex: String,
        dividerSecondaryHex: String? = nil,
        dividerStyle: BoardDividerStyle = .inkKeyline,
        destructiveHex: String? = nil,
        textureSeed: UInt64,
        textureOpacity: Double,
        separatorOpacity: Double,
        dividerOpacity: Double
    ) {
        precondition(!participantHexValues.isEmpty, "A theme needs participant colors")
        precondition((0.02...0.04).contains(textureOpacity), "Board texture must stay low contrast")
        precondition((0.28...0.60).contains(dividerOpacity), "Dividers must remain visible but restrained")
        self.appearance = appearance
        self.surfaceRecipe = surfaceRecipe
        self.surfaceInkHex = surfaceInkHex
        self.onChromeInkHex = onChromeInkHex
        self.chromeHex = chromeHex
        self.actionAccentHex = actionAccentHex
        self.detailAccentHex = detailAccentHex
        self.secondaryDetailHex = secondaryDetailHex
        self.participantHexValues = participantHexValues
        self.pieceFinish = pieceFinish
        self.authoredPinballMaterial = pinballMaterial
        self.ballHex = ballHex
        self.ballEdgeHex = ballEdgeHex
        self.ballTailHex = ballTailHex
        self.ballImpactHex = ballImpactHex
        self.dividerHex = dividerHex
        self.dividerSecondaryHex = dividerSecondaryHex
        self.dividerStyle = dividerStyle
        self.destructiveOverrideHex = destructiveHex
        self.textureSeed = textureSeed
        self.textureOpacity = textureOpacity
        self.separatorOpacity = separatorOpacity
        self.dividerOpacity = dividerOpacity
    }

    // Build 11 compatibility names. New rendering should consume the explicit
    // roles above instead of treating one accent as every kind of emphasis.
    public var surfaceStartHex: String { surfaceRecipe.stops.first!.hex }
    public var surfaceEndHex: String { surfaceRecipe.stops.last!.hex }
    public var primaryInkHex: String { surfaceInkHex }
    public var accentHex: String { actionAccentHex }
    public var secondaryAccentHex: String? { detailAccentHex }
    public var finish: BoardPieceFinish { pieceFinish }
    public var pinballHex: String { ballHex }

    public var preferredColorScheme: ColorScheme { appearance.colorScheme }
    public var textureKind: BoardSurfaceTextureKind { surfaceRecipe.texture }
    public var pinballMaterial: PinballMaterialKind { authoredPinballMaterial }
    public var surfaceStopHexValues: [String] { surfaceRecipe.stops.map(\.hex) }
    public var surfaceStartColor: Color { ChooserColorTheme.color(hex: surfaceStartHex) }
    public var surfaceEndColor: Color { ChooserColorTheme.color(hex: surfaceEndHex) }
    public var primaryInkColor: Color { ChooserColorTheme.color(hex: surfaceInkHex) }
    public var secondaryInkColor: Color { primaryInkColor.opacity(0.68) }
    public var onChromeInkColor: Color { ChooserColorTheme.color(hex: onChromeInkHex) }
    public var chromeTintColor: Color { ChooserColorTheme.color(hex: chromeHex) }
    /// Solid cards use the authored surface stop with the strongest contrast
    /// against surface ink. This keeps the world recognizable while avoiding
    /// assumptions that the first gradient stop is suitable for text.
    public var informationPanelHex: String {
        surfaceStopHexValues.max { first, second in
            ChooserColorTheme.contrastRatio(between: surfaceInkHex, and: first)
                < ChooserColorTheme.contrastRatio(between: surfaceInkHex, and: second)
        } ?? surfaceStartHex
    }
    public var informationPanelColor: Color {
        ChooserColorTheme.color(hex: informationPanelHex)
    }
    public var informationPanelInkColor: Color { primaryInkColor }
    public var informationPanelSystemInkHex: String {
        ChooserColorTheme.bestContrastingHex(
            against: informationPanelHex,
            candidates: ["#000000", "#FFFFFF"]
        )
    }
    public var informationPanelColorScheme: ColorScheme {
        informationPanelSystemInkHex == "#FFFFFF" ? .dark : .light
    }

    /// Navigation and unfilled links need their own foreground role because
    /// neither the action accent nor chrome is guaranteed to read as text on
    /// every world's information panel.
    public var interactiveTextHex: String {
        let authoredCandidates = [
            actionAccentHex,
            detailAccentHex,
            secondaryDetailHex,
            chromeHex,
            surfaceInkHex,
            onChromeInkHex
        ].compactMap { $0 }
        return authoredCandidates.first {
            ChooserColorTheme.contrastRatio(between: $0, and: informationPanelHex) >= 4.5
        } ?? ChooserColorTheme.bestContrastingHex(
            against: informationPanelHex,
            candidates: authoredCandidates + ["#000000", "#FFFFFF"]
        )
    }
    public var interactiveTextColor: Color {
        ChooserColorTheme.color(hex: interactiveTextHex)
    }

    /// Liquid Glass still exposes the underlying board. Keep the authored
    /// chrome nearly opaque so its contrast-tested on-chrome ink remains the
    /// actual visual pair instead of becoming a low-contrast surface blend.
    public var chromeControlBackingOpacity: Double { 0.92 }

    /// Destructive controls are semantic and intentionally consistent across
    /// worlds; their foreground is resolved rather than inherited from chrome.
    public var destructiveControlHex: String { destructiveOverrideHex ?? "#982B37" }
    public var destructiveControlForegroundHex: String {
        ChooserColorTheme.bestContrastingHex(
            against: destructiveControlHex,
            candidates: [onChromeInkHex, surfaceInkHex, "#FFFFFF", "#000000"]
        )
    }
    public var destructiveControlColor: Color {
        ChooserColorTheme.color(hex: destructiveControlHex)
    }
    public var destructiveControlForegroundColor: Color {
        ChooserColorTheme.color(hex: destructiveControlForegroundHex)
    }
    public var accentColor: Color { ChooserColorTheme.color(hex: actionAccentHex) }
    public var actionAccentColor: Color { accentColor }
    public var detailAccentColor: Color { ChooserColorTheme.color(hex: detailAccentHex) }
    public var secondaryAccentColor: Color { detailAccentColor }
    public var secondaryDetailColor: Color {
        ChooserColorTheme.color(hex: secondaryDetailHex ?? detailAccentHex)
    }
    public var separatorColor: Color { primaryInkColor.opacity(separatorOpacity) }
    public var dividerColor: Color {
        ChooserColorTheme.color(hex: dividerHex).opacity(dividerOpacity)
    }
    public var dividerSecondaryOpacity: Double {
        min(0.82, max(0.68, dividerOpacity + 0.24))
    }
    public var dividerSecondaryColor: Color? {
        dividerSecondaryHex.map {
            ChooserColorTheme.color(hex: $0).opacity(dividerSecondaryOpacity)
        }
    }
    public var pinballColor: Color { ChooserColorTheme.color(hex: ballHex) }
    public var pinballEdgeColor: Color { ChooserColorTheme.color(hex: ballEdgeHex) }
    public var pinballTailColor: Color { ChooserColorTheme.color(hex: ballTailHex).opacity(0.52) }
    public var pinballImpactColor: Color { ChooserColorTheme.color(hex: ballImpactHex) }

    public var surfaceGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: surfaceRecipe.stops.map {
                Gradient.Stop(
                    color: ChooserColorTheme.color(hex: $0.hex),
                    location: $0.location
                )
            }),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    public var accentForegroundColor: Color {
        ChooserColorTheme.bestContrastingColor(
            against: actionAccentHex,
            candidates: [surfaceInkHex, onChromeInkHex, "#080A0C", "#F7F4EC", "#000000", "#FFFFFF"]
        )
    }

    public func participantHex(at index: Int) -> String {
        let normalized = ((index % participantHexValues.count) + participantHexValues.count)
            % participantHexValues.count
        return participantHexValues[normalized]
    }

    public func participantColor(at index: Int) -> Color {
        ChooserColorTheme.color(hex: participantHex(at: index))
    }

    public func participantBevelColor(at index: Int) -> Color {
        ChooserColorTheme.components(hex: participantHex(at: index))
            .scaledBrightness(1.11)
            .color
    }

    public func participantShadeColor(at index: Int) -> Color {
        ChooserColorTheme.components(hex: participantHex(at: index))
            .scaledBrightness(0.78)
            .color
    }

    public func participantKeylineColor(at index: Int) -> Color {
        ChooserColorTheme.components(hex: participantHex(at: index))
            .scaledBrightness(0.64)
            .color
    }

    public func participantNumeralColor(at index: Int) -> Color {
        ChooserColorTheme.bestContrastingColor(
            against: participantHex(at: index),
            candidates: [surfaceInkHex, onChromeInkHex, "#080A0C", "#F7F4EC", "#000000", "#FFFFFF"]
        )
    }
}

/// Stable persisted selection. Raw values intentionally match Build 10.
public enum ChooserColorTheme: String, CaseIterable, Codable, Identifiable, Sendable {
    case wingspanOriginal = "wingspan-original"
    case wingspanNectar = "wingspan-nectar"
    case wingspanHummingbirds = "wingspan-hummingbirds"
    case nidavellir
    case concordia
    case everdell
    case lizardWizard = "lizard-wizard"
    case leaders
    case resArcana = "res-arcana"
    case everdellEmerland = "everdell-emerland"
    case sagrada

    public static let defaultTheme: ChooserColorTheme = .wingspanOriginal
    public static var wingspanAsia: ChooserColorTheme { .wingspanNectar }
    public static var wingspanAmericas: ChooserColorTheme { .wingspanHummingbirds }
    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .wingspanOriginal: "Wingspan Original"
        case .wingspanNectar: "Wingspan Asia"
        case .wingspanHummingbirds: "Wingspan Americas"
        case .nidavellir: "Nidavellir"
        case .concordia: "Concordia"
        case .everdell: "Everdell"
        case .lizardWizard: "Lizard Wizard"
        case .leaders: "Leaders"
        case .resArcana: "Res Arcana"
        case .everdellEmerland: "Everdell Emerland"
        case .sagrada: "Sagrada"
        }
    }

    public var visualTheme: ChooserVisualTheme {
        switch self {
        case .wingspanOriginal:
            // Field-guide watercolor on cold-press paper: wet-edged washes,
            // lightly speckled egg pieces, pencil dividers, a robin's-egg ball.
            ChooserVisualTheme(
                appearance: .light,
                surfaceRecipe: BoardSurfaceRecipe(
                    composition: .verticalWatercolorWash,
                    stops: [
                        BoardSurfaceStop(hex: "#E9ECE3", location: 0),
                        BoardSurfaceStop(hex: "#D3DFDA", location: 0.55),
                        BoardSurfaceStop(hex: "#8DB9D0", location: 1)
                    ],
                    atmosphereHexValues: ["#D95C4E", "#3D78A1"],
                    atmosphereOpacities: [0.08, 0.10],
                    texture: .watercolorFlecks
                ),
                surfaceInkHex: "#27363B", onChromeInkHex: "#101D21",
                chromeHex: "#6E9FB7", actionAccentHex: "#D95C4E",
                detailAccentHex: "#D5A62D", secondaryDetailHex: "#7EAFCA",
                participantHexValues: ["#D95C4E", "#D5A62D", "#3D78A1", "#508467", "#80658A"],
                pieceFinish: .watercolorEggshell, pinballMaterial: .coralEnamel,
                ballHex: "#9FD0E3", ballEdgeHex: "#4E8AA4",
                ballTailHex: "#7EAFCA", ballImpactHex: "#27363B",
                dividerHex: "#4A4F52", dividerSecondaryHex: "#F7F4EC",
                dividerStyle: .pencil,
                textureSeed: 0x57494E475350414E, textureOpacity: 0.026,
                separatorOpacity: 0.30, dividerOpacity: 0.55
            )
        case .wingspanNectar:
            // Red lacquer: a lit center, deep edges, a soft gloss and a
            // tone-on-tone peacock eye-spot behind the play area.
            ChooserVisualTheme(
                appearance: .dark,
                surfaceRecipe: BoardSurfaceRecipe(
                    composition: .redLacquerField,
                    stops: [
                        BoardSurfaceStop(hex: "#C24B4E", location: 0),
                        BoardSurfaceStop(hex: "#9E2F36", location: 0.50),
                        BoardSurfaceStop(hex: "#5A141C", location: 1)
                    ],
                    atmosphereHexValues: ["#E07068", "#FFFFFF"],
                    atmosphereOpacities: [0.16, 0.14],
                    texture: .featherFibers
                ),
                surfaceInkHex: "#FFF5E8", onChromeInkHex: "#FFF5E8",
                chromeHex: "#0C6B4D", actionAccentHex: "#0C6B4D",
                detailAccentHex: "#2BA5A1", secondaryDetailHex: "#D4A42E",
                participantHexValues: ["#0C6B4D", "#20539A", "#F3E3C3", "#2BA5A1", "#D4A42E"],
                pieceFinish: .peacockJewelEnamel, pinballMaterial: .emeraldEnamel,
                ballHex: "#0C6B4D", ballEdgeHex: "#033524",
                ballTailHex: "#2BA5A1", ballImpactHex: "#D4A42E",
                dividerHex: "#F3E3C3", dividerSecondaryHex: "#3E0C12",
                textureSeed: 0x4153494150454143, textureOpacity: 0.032,
                separatorOpacity: 0.38, dividerOpacity: 0.60
            )
        case .wingspanHummingbirds:
            // A rainforest clearing that lets iridescent pieces do the shouting.
            ChooserVisualTheme(
                appearance: .dark,
                surfaceRecipe: BoardSurfaceRecipe(
                    composition: .rainforestClearing,
                    stops: [
                        BoardSurfaceStop(hex: "#5DB46E", location: 0),
                        BoardSurfaceStop(hex: "#2E7A47", location: 0.45),
                        BoardSurfaceStop(hex: "#0E3424", location: 1)
                    ],
                    atmosphereHexValues: ["#0B2B21", "#EF4770"],
                    atmosphereOpacities: [0.40, 0.03],
                    texture: .leafFibers
                ),
                surfaceInkHex: "#FFF9E9", onChromeInkHex: "#FFF9E9",
                chromeHex: "#075D38", actionAccentHex: "#EF4770",
                detailAccentHex: "#E85A3B", secondaryDetailHex: "#F1D35A",
                participantHexValues: ["#B0234A", "#EF4770", "#E85A3B", "#F1D35A", "#0A7880"],
                pieceFinish: .featherJewelEnamel, pinballMaterial: .flamingoEnamel,
                ballHex: "#EF4770", ballEdgeHex: "#8E1F3F",
                ballTailHex: "#EF4770", ballImpactHex: "#F1D35A",
                dividerHex: "#FFF9E9", dividerSecondaryHex: "#0B2B21",
                textureSeed: 0x414D455249434153, textureOpacity: 0.028,
                separatorOpacity: 0.36, dividerOpacity: 0.60
            )
        case .nidavellir:
            // Cool slate with a forge glow below, stamped coin pieces in the
            // five dwarf class colors, gold-inlay dividers and a gold coin.
            ChooserVisualTheme(
                appearance: .dark,
                surfaceRecipe: BoardSurfaceRecipe(
                    composition: .slateForge,
                    stops: [
                        BoardSurfaceStop(hex: "#4E5860", location: 0),
                        BoardSurfaceStop(hex: "#363D43", location: 0.60),
                        BoardSurfaceStop(hex: "#1E2226", location: 1)
                    ],
                    atmosphereHexValues: ["#D97A1E", "#9AA3AA"],
                    atmosphereOpacities: [0.28, 0.06],
                    texture: .parchmentPatina
                ),
                surfaceInkHex: "#F3F0E9", onChromeInkHex: "#F3F0E9",
                chromeHex: "#2A3034", actionAccentHex: "#D4A93A",
                detailAccentHex: "#788B94", secondaryDetailHex: "#C9A03A",
                participantHexValues: ["#6B3F8C", "#3F7F3A", "#2F5F9E", "#D97A1E", "#B02E2E"],
                pieceFinish: .hammeredMetal, pinballMaterial: .agedCopper,
                ballHex: "#D4A93A", ballEdgeHex: "#7E5E14",
                ballTailHex: "#D4A93A", ballImpactHex: "#F3F0E9",
                dividerHex: "#C9A03A", dividerSecondaryHex: "#14171A",
                dividerStyle: .goldInlay,
                textureSeed: 0x4E49444156454C4C, textureOpacity: 0.040,
                separatorOpacity: 0.36, dividerOpacity: 0.60
            )
        case .concordia:
            // The map board, not the box: a parchment frame around an
            // engraved sea with province washes, and dotted land routes.
            ChooserVisualTheme(
                appearance: .light,
                surfaceRecipe: BoardSurfaceRecipe(
                    composition: .mediterraneanMap,
                    stops: [
                        BoardSurfaceStop(hex: "#8BA7BC", location: 0),
                        BoardSurfaceStop(hex: "#5F7F98", location: 1)
                    ],
                    atmosphereHexValues: ["#D9B44A", "#C25A35", "#E8DDC0"],
                    atmosphereOpacities: [0.24, 0.18, 0.22],
                    texture: .frescoGrain
                ),
                surfaceInkHex: "#2A1E14", onChromeInkHex: "#FFF0D5",
                chromeHex: "#701426", actionAccentHex: "#D7AA34",
                detailAccentHex: "#5A3E22", secondaryDetailHex: "#E8DDC0",
                participantHexValues: ["#D9B44A", "#5E4E8E", "#C25A35", "#7E8F4A", "#B27AA0"],
                pieceFinish: .frescoEnamel, pinballMaterial: .romanGold,
                ballHex: "#B07A3A", ballEdgeHex: "#5A3A12",
                ballTailHex: "#B07A3A", ballImpactHex: "#701426",
                dividerHex: "#5A3E22", dividerSecondaryHex: "#E8DDC0",
                dividerStyle: .dottedRoute,
                textureSeed: 0x434F4E434F524449, textureOpacity: 0.034,
                separatorOpacity: 0.36, dividerOpacity: 0.60
            )
        case .everdell:
            // Honey light at the heart of the tree falling to russet and
            // umber, amber resin pieces, twig dividers and a berry ball.
            ChooserVisualTheme(
                appearance: .dark,
                surfaceRecipe: BoardSurfaceRecipe(
                    composition: .honeyAutumnTree,
                    stops: [
                        BoardSurfaceStop(hex: "#F0C46A", location: 0),
                        BoardSurfaceStop(hex: "#C98A3A", location: 0.35),
                        BoardSurfaceStop(hex: "#6B3A1E", location: 0.72),
                        BoardSurfaceStop(hex: "#2A1A10", location: 1)
                    ],
                    atmosphereHexValues: ["#E8B85A", "#C25A28", "#963F50"],
                    atmosphereOpacities: [0.40, 0.35, 0.35],
                    texture: .pressedPaper
                ),
                surfaceInkHex: "#F3EBC9", onChromeInkHex: "#F3EBC9",
                chromeHex: "#3A2412", actionAccentHex: "#D5892D",
                detailAccentHex: "#E8B85A", secondaryDetailHex: "#963F50",
                participantHexValues: ["#D98A1E", "#5B2A5E", "#5E743B", "#B8B4AA", "#963F50"],
                pieceFinish: .pressedWoodPaper, pinballMaterial: .amberResin,
                ballHex: "#6E2F70", ballEdgeHex: "#2E0F30",
                ballTailHex: "#963F50", ballImpactHex: "#F3EBC9",
                dividerHex: "#A87445", dividerSecondaryHex: "#2A1A10",
                dividerStyle: .twig,
                textureSeed: 0x4556455244454C4C, textureOpacity: 0.036,
                separatorOpacity: 0.38, dividerOpacity: 0.60
            )
        case .lizardWizard:
            // Plum shadow lit by a warm amber glow near the top, painted like
            // an old fantasy cover; blue mana coin pieces and an eye-of-newt
            // ball. No red frame, so it no longer echoes Res Arcana.
            ChooserVisualTheme(
                appearance: .dark,
                surfaceRecipe: BoardSurfaceRecipe(
                    composition: .amberPlumPainting,
                    stops: [
                        BoardSurfaceStop(hex: "#D09A48", location: 0),
                        BoardSurfaceStop(hex: "#8A5A4E", location: 0.30),
                        BoardSurfaceStop(hex: "#4A2E50", location: 0.62),
                        BoardSurfaceStop(hex: "#2A1A30", location: 1)
                    ],
                    atmosphereHexValues: ["#2A1A30", "#F6E6C6"],
                    atmosphereOpacities: [0.30, 0.05],
                    texture: .midnightSpeckle
                ),
                surfaceInkHex: "#F6F0E5", onChromeInkHex: "#F6F0E5",
                chromeHex: "#5A3A62", actionAccentHex: "#F0C060",
                detailAccentHex: "#1697A9", secondaryDetailHex: "#72813A",
                participantHexValues: ["#2F6FB5", "#5A3A5E", "#1697A9", "#F0C060", "#72813A"],
                pieceFinish: .midnightEnamel, pinballMaterial: .manaEnamel,
                ballHex: "#9BB33A", ballEdgeHex: "#3A4710",
                ballTailHex: "#F0C060", ballImpactHex: "#F6F0E5",
                dividerHex: "#F6E6C6", dividerSecondaryHex: "#2A1A30",
                textureSeed: 0x4C495A415244575A, textureOpacity: 0.030,
                separatorOpacity: 0.38, dividerOpacity: 0.60
            )
        case .leaders:
            // The cream screenprint field, with gold-ink inlay, spot gloss and
            // black-and-white split rims like the two-sided standees.
            ChooserVisualTheme(
                appearance: .light,
                surfaceRecipe: BoardSurfaceRecipe(
                    composition: .layeredScreenprint,
                    stops: [
                        BoardSurfaceStop(hex: "#F1E6D3", location: 0),
                        BoardSurfaceStop(hex: "#E8DDCB", location: 0.62),
                        BoardSurfaceStop(hex: "#D9E6DF", location: 1)
                    ],
                    atmosphereHexValues: ["#43B2BA", "#C73366", "#B8902A"],
                    atmosphereOpacities: [0.08, 0.035, 0.40],
                    texture: .screenprintRegistration
                ),
                surfaceInkHex: "#053842", onChromeInkHex: "#FFF7E9",
                chromeHex: "#08747C", actionAccentHex: "#D28D00",
                detailAccentHex: "#C73366", secondaryDetailHex: "#43B2BA",
                participantHexValues: ["#08747C", "#43B2BA", "#053842", "#C73366", "#D28D00"],
                pieceFinish: .flatScreenprint, pinballMaterial: .saffronScreenprint,
                ballHex: "#D28D00", ballEdgeHex: "#7A5100",
                ballTailHex: "#D28D00", ballImpactHex: "#C73366",
                dividerHex: "#B8902A", dividerSecondaryHex: "#053842",
                dividerStyle: .goldInlay,
                textureSeed: 0x4C45414445525331, textureOpacity: 0.024,
                separatorOpacity: 0.30, dividerOpacity: 0.60
            )
        case .resArcana:
            // A candlelit grimoire: oxblood leather, blind tooling, wax seals,
            // a garnet bead. Deliberately no gold.
            ChooserVisualTheme(
                appearance: .dark,
                surfaceRecipe: BoardSurfaceRecipe(
                    composition: .tooledGrimoire,
                    stops: [
                        BoardSurfaceStop(hex: "#4E0E15", location: 0),
                        BoardSurfaceStop(hex: "#2A080C", location: 0.38),
                        BoardSurfaceStop(hex: "#110406", location: 0.78),
                        BoardSurfaceStop(hex: "#070203", location: 1)
                    ],
                    atmosphereHexValues: ["#9A1E16", "#E07A70", "#000000"],
                    atmosphereOpacities: [0.30, 0.10, 0.40],
                    texture: .leatherGrain
                ),
                surfaceInkHex: "#EADCC5", onChromeInkHex: "#EADCC5",
                chromeHex: "#170A0C", actionAccentHex: "#D9482A",
                detailAccentHex: "#CDB79A", secondaryDetailHex: "#A3121F",
                participantHexValues: ["#A3121F", "#E4D6BE", "#2E2024", "#D9482A", "#8A7D7A"],
                pieceFinish: .waxSeal, pinballMaterial: .garnetBead,
                ballHex: "#C21A2A", ballEdgeHex: "#4A0610",
                ballTailHex: "#E0442C", ballImpactHex: "#E4D6BE",
                dividerHex: "#CDB79A", dividerSecondaryHex: "#050102",
                dividerStyle: .stitchedSeam,
                // Every piece here is red, so Clear is bone to stay distinct.
                destructiveHex: "#E4D6BE",
                textureSeed: 0x5245534152434E41, textureOpacity: 0.040,
                separatorOpacity: 0.36, dividerOpacity: 0.55
            )
        case .everdellEmerland:
            // A sunlit jungle valley: dark canopy edges, misty light, a
            // turquoise river, painted wood pieces and a cut emerald.
            ChooserVisualTheme(
                appearance: .light,
                surfaceRecipe: BoardSurfaceRecipe(
                    composition: .canopyRiverValley,
                    stops: [
                        BoardSurfaceStop(hex: "#E4F5DC", location: 0),
                        BoardSurfaceStop(hex: "#A9DDB2", location: 0.32),
                        BoardSurfaceStop(hex: "#4A9A6B", location: 0.66),
                        BoardSurfaceStop(hex: "#143F34", location: 1)
                    ],
                    atmosphereHexValues: ["#0B3A33", "#8FE0D6", "#FFFBE6", "#E063A6"],
                    atmosphereOpacities: [0.40, 0.40, 0.34, 0.40],
                    texture: .paintedCanopy
                ),
                surfaceInkHex: "#0E2A20", onChromeInkHex: "#F4F1DE",
                chromeHex: "#0F4A40", actionAccentHex: "#DE5A9E",
                detailAccentHex: "#0E97AA", secondaryDetailHex: "#F29B30",
                participantHexValues: ["#DE5A9E", "#F29B30", "#0E97AA", "#7E55BF", "#8A5A38"],
                pieceFinish: .paintedWood, pinballMaterial: .cutEmerald,
                ballHex: "#138A52", ballEdgeHex: "#033A22",
                ballTailHex: "#BFF5D8", ballImpactHex: "#F29B30",
                dividerHex: "#C7A06A", dividerSecondaryHex: "#3F2A14",
                dividerStyle: .rope,
                textureSeed: 0x454D45524C414E44, textureOpacity: 0.034,
                separatorOpacity: 0.32, dividerOpacity: 0.60
            )
        case .sagrada:
            // A cathedral window at dusk: dim leaded shards, a rose window,
            // a stone frame, lit glass pieces and a clear glass bead.
            ChooserVisualTheme(
                appearance: .dark,
                surfaceRecipe: BoardSurfaceRecipe(
                    composition: .roseWindow,
                    stops: [
                        BoardSurfaceStop(hex: "#22305E", location: 0),
                        BoardSurfaceStop(hex: "#1A1638", location: 0.55),
                        BoardSurfaceStop(hex: "#0D080A", location: 1)
                    ],
                    atmosphereHexValues: ["#FFE7A8", "#FFF4D6"],
                    atmosphereOpacities: [0.26, 0.22],
                    texture: .cathedralGlass
                ),
                surfaceInkHex: "#F2EFE6", onChromeInkHex: "#F2EFE6",
                chromeHex: "#3A3D3B", actionAccentHex: "#F5C518",
                detailAccentHex: "#A6A296", secondaryDetailHex: "#1C6FD0",
                participantHexValues: ["#F5C518", "#E0262E", "#1C6FD0", "#23A04A", "#9A2DB5"],
                pieceFinish: .leadedGlass, pinballMaterial: .clearGlassBead,
                ballHex: "#CFE3F0", ballEdgeHex: "#6F8CA6",
                ballTailHex: "#FFFFFF", ballImpactHex: "#F5C518",
                dividerHex: "#A6A296", dividerSecondaryHex: "#0D080A",
                dividerStyle: .stoneMullion,
                textureSeed: 0x53414752414441, textureOpacity: 0.032,
                separatorOpacity: 0.36, dividerOpacity: 0.60
            )
        }
    }

    // Complete theme roles, forwarded for concise integration.
    public var participantHexValues: [String] { visualTheme.participantHexValues }
    public var preferredColorScheme: ColorScheme { visualTheme.preferredColorScheme }
    public var appearance: ChooserThemeAppearance { visualTheme.appearance }
    public var surfaceRecipe: BoardSurfaceRecipe { visualTheme.surfaceRecipe }
    public var surfaceInkHex: String { visualTheme.surfaceInkHex }
    public var onChromeInkHex: String { visualTheme.onChromeInkHex }
    public var chromeHex: String { visualTheme.chromeHex }
    public var actionAccentHex: String { visualTheme.actionAccentHex }
    public var detailAccentHex: String { visualTheme.detailAccentHex }
    public var secondaryDetailHex: String? { visualTheme.secondaryDetailHex }
    public var surfaceStartHex: String { visualTheme.surfaceStartHex }
    public var surfaceEndHex: String { visualTheme.surfaceEndHex }
    public var primaryInkHex: String { visualTheme.primaryInkHex }
    public var accentHex: String { visualTheme.accentHex }
    public var pinballHex: String { visualTheme.pinballHex }
    public var finish: BoardPieceFinish { visualTheme.finish }
    public var textureKind: BoardSurfaceTextureKind { visualTheme.textureKind }
    public var pinballMaterial: PinballMaterialKind { visualTheme.pinballMaterial }
    public var surfaceStartColor: Color { visualTheme.surfaceStartColor }
    public var surfaceEndColor: Color { visualTheme.surfaceEndColor }
    public var primaryInkColor: Color { visualTheme.primaryInkColor }
    public var secondaryInkColor: Color { visualTheme.secondaryInkColor }
    public var onChromeInkColor: Color { visualTheme.onChromeInkColor }
    public var informationPanelHex: String { visualTheme.informationPanelHex }
    public var informationPanelColor: Color { visualTheme.informationPanelColor }
    public var informationPanelInkColor: Color { visualTheme.informationPanelInkColor }
    public var informationPanelSystemInkHex: String { visualTheme.informationPanelSystemInkHex }
    public var informationPanelColorScheme: ColorScheme { visualTheme.informationPanelColorScheme }
    public var interactiveTextHex: String { visualTheme.interactiveTextHex }
    public var interactiveTextColor: Color { visualTheme.interactiveTextColor }
    public var chromeControlBackingOpacity: Double { visualTheme.chromeControlBackingOpacity }
    public var destructiveControlHex: String { visualTheme.destructiveControlHex }
    public var destructiveControlForegroundHex: String { visualTheme.destructiveControlForegroundHex }
    public var destructiveControlColor: Color { visualTheme.destructiveControlColor }
    public var destructiveControlForegroundColor: Color { visualTheme.destructiveControlForegroundColor }
    public var separatorColor: Color { visualTheme.separatorColor }
    public var dividerColor: Color { visualTheme.dividerColor }
    public var dividerSecondaryColor: Color? { visualTheme.dividerSecondaryColor }
    public var dividerSecondaryOpacity: Double { visualTheme.dividerSecondaryOpacity }
    public var chromeTintColor: Color { visualTheme.chromeTintColor }
    public var accentForegroundColor: Color { visualTheme.accentForegroundColor }
    public var accentColor: Color { visualTheme.accentColor }
    public var actionAccentColor: Color { visualTheme.actionAccentColor }
    public var detailAccentColor: Color { visualTheme.detailAccentColor }
    public var secondaryDetailColor: Color { visualTheme.secondaryDetailColor }
    public var pinballColor: Color { visualTheme.pinballColor }
    public var pinballEdgeColor: Color { visualTheme.pinballEdgeColor }
    public var pinballTailColor: Color { visualTheme.pinballTailColor }
    public var pinballImpactColor: Color { visualTheme.pinballImpactColor }

    public func participantHex(at index: Int) -> String { visualTheme.participantHex(at: index) }
    public func participantColor(at index: Int) -> Color { visualTheme.participantColor(at: index) }
    public func participantBevelColor(at index: Int) -> Color { visualTheme.participantBevelColor(at: index) }
    public func participantShadeColor(at index: Int) -> Color { visualTheme.participantShadeColor(at: index) }
    public func participantKeylineColor(at index: Int) -> Color { visualTheme.participantKeylineColor(at: index) }
    public func participantNumeralColor(at index: Int) -> Color { visualTheme.participantNumeralColor(at: index) }

    // Compatibility while remaining universal-color call sites migrate.
    public static let darkFeltHex = "#080A0C"
    public static let warmIvoryHex = "#F7F4EC"
    public static var darkFeltColor: Color { color(hex: darkFeltHex) }
    public static var warmIvoryColor: Color { color(hex: warmIvoryHex) }
    public func participantGlowColor(at index: Int) -> Color { participantBevelColor(at: index) }
    public func participantHue(at index: Int) -> Double { Self.components(hex: participantHex(at: index)).hsb.hue }
    public var seedHue: Double { participantHue(at: 0) }
    public var pinballHue: Double { Self.components(hex: pinballHex).hsb.hue }
    public var saturation: Double { Self.components(hex: participantHex(at: 0)).hsb.saturation }
    public var brightness: Double { Self.components(hex: participantHex(at: 0)).hsb.brightness }
    public var glowSaturation: Double { saturation }
    public var glowBrightness: Double { brightness }

    public static var aurora: Self { .wingspanOriginal }
    public static var ultraviolet: Self { .lizardWizard }
    public static var arcadeFruit: Self { .leaders }
    public static var solarPop: Self { .wingspanNectar }
    public static var deepSea: Self { .concordia }
    public static var emberIce: Self { .nidavellir }
    public static var sorbet: Self { .wingspanHummingbirds }
    public static var laserGarden: Self { .everdell }

    public static func color(hex: String) -> Color { components(hex: hex).color }

    public static func contrastRatio(between firstHex: String, and secondHex: String) -> Double {
        components(hex: firstHex).contrastRatio(with: components(hex: secondHex))
    }

    fileprivate static func bestContrastingColor(against backgroundHex: String, candidates: [String]) -> Color {
        color(hex: bestContrastingHex(against: backgroundHex, candidates: candidates))
    }

    fileprivate static func bestContrastingHex(against backgroundHex: String, candidates: [String]) -> String {
        let background = components(hex: backgroundHex)
        return candidates.max {
            components(hex: $0).contrastRatio(with: background)
                < components(hex: $1).contrastRatio(with: background)
        } ?? "#FFFFFF"
    }

    fileprivate static func components(hex: String) -> RGBComponents {
        guard let components = RGBComponents(hex: hex) else {
            preconditionFailure("Invalid curated color value: \(hex)")
        }
        return components
    }
}

fileprivate struct RGBComponents {
    let red: Double
    let green: Double
    let blue: Double

    init?(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard value.count == 6, let integer = UInt64(value, radix: 16) else { return nil }
        red = Double((integer >> 16) & 0xFF) / 255
        green = Double((integer >> 8) & 0xFF) / 255
        blue = Double(integer & 0xFF) / 255
    }

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: 1) }
    var relativeLuminance: Double {
        0.2126 * Self.linearized(red) + 0.7152 * Self.linearized(green) + 0.0722 * Self.linearized(blue)
    }
    var hsb: (hue: Double, saturation: Double, brightness: Double) {
        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        let delta = maximum - minimum
        let saturation = maximum == 0 ? 0 : delta / maximum
        let hue: Double
        if delta == 0 { hue = 0 }
        else if maximum == red { hue = 60 * ((green - blue) / delta).truncatingRemainder(dividingBy: 6) }
        else if maximum == green { hue = 60 * ((blue - red) / delta + 2) }
        else { hue = 60 * ((red - green) / delta + 4) }
        return (((hue + 360).truncatingRemainder(dividingBy: 360)), saturation, maximum)
    }
    func mixed(toward other: RGBComponents, amount: Double) -> RGBComponents {
        let amount = min(max(amount, 0), 1)
        return RGBComponents(
            red: red + (other.red - red) * amount,
            green: green + (other.green - green) * amount,
            blue: blue + (other.blue - blue) * amount
        )
    }
    func scaledBrightness(_ multiplier: Double) -> RGBComponents {
        let multiplier = max(0, multiplier)
        return RGBComponents(
            red: min(1, red * multiplier),
            green: min(1, green * multiplier),
            blue: min(1, blue * multiplier)
        )
    }
    func contrastRatio(with other: RGBComponents) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }
    private static func linearized(_ component: Double) -> Double {
        component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
    }
}

@MainActor
public protocol ChooserColorThemePersisting: AnyObject {
    func loadColorTheme() -> ChooserColorTheme?
    func saveColorTheme(_ theme: ChooserColorTheme)
}

@MainActor
public final class UserDefaultsChooserColorThemeStore: ChooserColorThemePersisting {
    public static let defaultKey = "chooser.color-theme"
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = UserDefaultsChooserColorThemeStore.defaultKey) {
        self.defaults = defaults
        self.key = key
    }

    public func loadColorTheme() -> ChooserColorTheme? {
        guard let rawValue = defaults.string(forKey: key) else { return .defaultTheme }
        return ChooserColorTheme(rawValue: rawValue) ?? .defaultTheme
    }

    public func saveColorTheme(_ theme: ChooserColorTheme) { defaults.set(theme.rawValue, forKey: key) }
}

private struct ChooserAccentColorEnvironmentKey: EnvironmentKey {
    static let defaultValue = ChooserColorTheme.defaultTheme.accentColor
}

private struct ChooserVisualThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = ChooserColorTheme.defaultTheme.visualTheme
}

private struct ChooserColorThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = ChooserColorTheme.defaultTheme
}

public extension EnvironmentValues {
    var chooserAccentColor: Color {
        get { self[ChooserAccentColorEnvironmentKey.self] }
        set { self[ChooserAccentColorEnvironmentKey.self] = newValue }
    }

    var chooserVisualTheme: ChooserVisualTheme {
        get { self[ChooserVisualThemeEnvironmentKey.self] }
        set { self[ChooserVisualThemeEnvironmentKey.self] = newValue }
    }

    var chooserColorTheme: ChooserColorTheme {
        get { self[ChooserColorThemeEnvironmentKey.self] }
        set { self[ChooserColorThemeEnvironmentKey.self] = newValue }
    }
}
