import Foundation
import SwiftUI
import UIKit
import XCTest
@testable import App

@MainActor
final class ChooserColorThemeTests: XCTestCase {
    private struct ExpectedTheme {
        let theme: ChooserColorTheme
        let name: String
        let appearance: ChooserThemeAppearance
        let composition: BoardSurfaceComposition
        let stops: [BoardSurfaceStop]
        let atmosphere: [String]
        let atmosphereOpacities: [Double]
        let surfaceTexture: BoardSurfaceTextureKind
        let surfaceInk: String
        let onChromeInk: String
        let chrome: String
        let action: String
        let detail: String
        let secondaryDetail: String?
        let participants: [String]
        let finish: BoardPieceFinish
        let pinballMaterial: PinballMaterialKind
        let ball: String
        let ballEdge: String
        let ballTail: String
        let ballImpact: String
        let divider: String
        let dividerSecondary: String?
        let textureOpacity: Double
        let separatorOpacity: Double
        let dividerOpacity: Double
    }

    private let expectedThemes: [ExpectedTheme] = [
        ExpectedTheme(
            theme: .wingspanOriginal, name: "Wingspan Original", appearance: .light,
            composition: .verticalWatercolorWash,
            stops: [stop("#E9ECE3", 0), stop("#D3DFDA", 0.55), stop("#8DB9D0", 1)],
            atmosphere: ["#D95C4E", "#3D78A1"], atmosphereOpacities: [0.08, 0.10],
            surfaceTexture: .watercolorFlecks,
            surfaceInk: "#27363B", onChromeInk: "#101D21", chrome: "#6E9FB7",
            action: "#D95C4E", detail: "#D5A62D", secondaryDetail: "#7EAFCA",
            participants: ["#D95C4E", "#D5A62D", "#3D78A1", "#508467", "#80658A"],
            finish: .watercolorEggshell, pinballMaterial: .coralEnamel,
            ball: "#9FD0E3", ballEdge: "#4E8AA4", ballTail: "#7EAFCA", ballImpact: "#27363B",
            divider: "#4A4F52", dividerSecondary: "#F7F4EC",
            textureOpacity: 0.026, separatorOpacity: 0.30, dividerOpacity: 0.55
        ),
        ExpectedTheme(
            theme: .wingspanNectar, name: "Wingspan Asia", appearance: .dark,
            composition: .redLacquerField,
            stops: [stop("#C24B4E", 0), stop("#9E2F36", 0.50), stop("#5A141C", 1)],
            atmosphere: ["#E07068", "#FFFFFF"], atmosphereOpacities: [0.16, 0.14],
            surfaceTexture: .featherFibers,
            surfaceInk: "#FFF5E8", onChromeInk: "#FFF5E8", chrome: "#0C6B4D",
            action: "#0C6B4D", detail: "#2BA5A1", secondaryDetail: "#D4A42E",
            participants: ["#0C6B4D", "#20539A", "#F3E3C3", "#2BA5A1", "#D4A42E"],
            finish: .peacockJewelEnamel, pinballMaterial: .emeraldEnamel,
            ball: "#0C6B4D", ballEdge: "#033524", ballTail: "#2BA5A1", ballImpact: "#D4A42E",
            divider: "#F3E3C3", dividerSecondary: "#3E0C12",
            textureOpacity: 0.032, separatorOpacity: 0.38, dividerOpacity: 0.60
        ),
        ExpectedTheme(
            theme: .wingspanHummingbirds, name: "Wingspan Americas", appearance: .dark,
            composition: .rainforestClearing,
            stops: [stop("#5DB46E", 0), stop("#2E7A47", 0.45), stop("#0E3424", 1)],
            atmosphere: ["#0B2B21", "#EF4770"], atmosphereOpacities: [0.40, 0.03],
            surfaceTexture: .leafFibers,
            surfaceInk: "#FFF9E9", onChromeInk: "#FFF9E9", chrome: "#075D38",
            action: "#EF4770", detail: "#E85A3B", secondaryDetail: "#F1D35A",
            participants: ["#B0234A", "#EF4770", "#E85A3B", "#F1D35A", "#0A7880"],
            finish: .featherJewelEnamel, pinballMaterial: .flamingoEnamel,
            ball: "#EF4770", ballEdge: "#8E1F3F", ballTail: "#EF4770", ballImpact: "#F1D35A",
            divider: "#FFF9E9", dividerSecondary: "#0B2B21",
            textureOpacity: 0.028, separatorOpacity: 0.36, dividerOpacity: 0.60
        ),
        ExpectedTheme(
            theme: .nidavellir, name: "Nidavellir", appearance: .dark,
            composition: .slateForge,
            stops: [stop("#4E5860", 0), stop("#363D43", 0.60), stop("#1E2226", 1)],
            atmosphere: ["#D97A1E", "#9AA3AA"], atmosphereOpacities: [0.28, 0.06],
            surfaceTexture: .parchmentPatina,
            surfaceInk: "#F3F0E9", onChromeInk: "#F3F0E9", chrome: "#2A3034",
            action: "#D4A93A", detail: "#788B94", secondaryDetail: "#C9A03A",
            participants: ["#6B3F8C", "#3F7F3A", "#2F5F9E", "#D97A1E", "#B02E2E"],
            finish: .hammeredMetal, pinballMaterial: .agedCopper,
            ball: "#D4A93A", ballEdge: "#7E5E14", ballTail: "#D4A93A", ballImpact: "#F3F0E9",
            divider: "#C9A03A", dividerSecondary: "#14171A",
            textureOpacity: 0.040, separatorOpacity: 0.36, dividerOpacity: 0.60
        ),
        ExpectedTheme(
            theme: .concordia, name: "Concordia", appearance: .light,
            composition: .mediterraneanMap,
            stops: [stop("#8BA7BC", 0), stop("#5F7F98", 1)],
            atmosphere: ["#D9B44A", "#C25A35", "#E8DDC0"], atmosphereOpacities: [0.24, 0.18, 0.22],
            surfaceTexture: .frescoGrain,
            surfaceInk: "#2A1E14", onChromeInk: "#FFF0D5", chrome: "#701426",
            action: "#D7AA34", detail: "#5A3E22", secondaryDetail: "#E8DDC0",
            participants: ["#D9B44A", "#5E4E8E", "#C25A35", "#7E8F4A", "#B27AA0"],
            finish: .frescoEnamel, pinballMaterial: .romanGold,
            ball: "#B07A3A", ballEdge: "#5A3A12", ballTail: "#B07A3A", ballImpact: "#701426",
            divider: "#5A3E22", dividerSecondary: "#E8DDC0",
            textureOpacity: 0.034, separatorOpacity: 0.36, dividerOpacity: 0.60
        ),
        ExpectedTheme(
            theme: .everdell, name: "Everdell", appearance: .dark,
            composition: .honeyAutumnTree,
            stops: [stop("#F0C46A", 0), stop("#C98A3A", 0.35), stop("#6B3A1E", 0.72), stop("#2A1A10", 1)],
            atmosphere: ["#E8B85A", "#C25A28", "#963F50"], atmosphereOpacities: [0.40, 0.35, 0.35],
            surfaceTexture: .pressedPaper,
            surfaceInk: "#F3EBC9", onChromeInk: "#F3EBC9", chrome: "#3A2412",
            action: "#D5892D", detail: "#E8B85A", secondaryDetail: "#963F50",
            participants: ["#D98A1E", "#5B2A5E", "#5E743B", "#B8B4AA", "#963F50"],
            finish: .pressedWoodPaper, pinballMaterial: .amberResin,
            ball: "#6E2F70", ballEdge: "#2E0F30", ballTail: "#963F50", ballImpact: "#F3EBC9",
            divider: "#A87445", dividerSecondary: "#2A1A10",
            textureOpacity: 0.036, separatorOpacity: 0.38, dividerOpacity: 0.60
        ),
        ExpectedTheme(
            theme: .lizardWizard, name: "Lizard Wizard", appearance: .dark,
            composition: .amberPlumPainting,
            stops: [stop("#D09A48", 0), stop("#8A5A4E", 0.30), stop("#4A2E50", 0.62), stop("#2A1A30", 1)],
            atmosphere: ["#2A1A30", "#F6E6C6"], atmosphereOpacities: [0.30, 0.05],
            surfaceTexture: .midnightSpeckle,
            surfaceInk: "#F6F0E5", onChromeInk: "#F6F0E5", chrome: "#5A3A62",
            action: "#F0C060", detail: "#1697A9", secondaryDetail: "#72813A",
            participants: ["#2F6FB5", "#5A3A5E", "#1697A9", "#F0C060", "#72813A"],
            finish: .midnightEnamel, pinballMaterial: .manaEnamel,
            ball: "#9BB33A", ballEdge: "#3A4710", ballTail: "#F0C060", ballImpact: "#F6F0E5",
            divider: "#F6E6C6", dividerSecondary: "#2A1A30",
            textureOpacity: 0.030, separatorOpacity: 0.38, dividerOpacity: 0.60
        ),
        ExpectedTheme(
            theme: .leaders, name: "Leaders", appearance: .light,
            composition: .layeredScreenprint,
            stops: [stop("#F1E6D3", 0), stop("#E8DDCB", 0.62), stop("#D9E6DF", 1)],
            atmosphere: ["#43B2BA", "#C73366", "#B8902A"], atmosphereOpacities: [0.08, 0.035, 0.40],
            surfaceTexture: .screenprintRegistration,
            surfaceInk: "#053842", onChromeInk: "#FFF7E9", chrome: "#08747C",
            action: "#D28D00", detail: "#C73366", secondaryDetail: "#43B2BA",
            participants: ["#08747C", "#43B2BA", "#053842", "#C73366", "#D28D00"],
            finish: .flatScreenprint, pinballMaterial: .saffronScreenprint,
            ball: "#D28D00", ballEdge: "#7A5100", ballTail: "#D28D00", ballImpact: "#C73366",
            divider: "#B8902A", dividerSecondary: "#053842",
            textureOpacity: 0.024, separatorOpacity: 0.30, dividerOpacity: 0.60
        ),
        ExpectedTheme(
            theme: .resArcana, name: "Res Arcana", appearance: .dark,
            composition: .tooledGrimoire,
            stops: [stop("#4E0E15", 0), stop("#2A080C", 0.38), stop("#110406", 0.78), stop("#070203", 1)],
            atmosphere: ["#9A1E16", "#E07A70", "#000000"], atmosphereOpacities: [0.30, 0.10, 0.40],
            surfaceTexture: .leatherGrain,
            surfaceInk: "#EADCC5", onChromeInk: "#EADCC5", chrome: "#170A0C",
            action: "#D9482A", detail: "#CDB79A", secondaryDetail: "#A3121F",
            participants: ["#A3121F", "#E4D6BE", "#2E2024", "#D9482A", "#8A7D7A"],
            finish: .waxSeal, pinballMaterial: .garnetBead,
            ball: "#C21A2A", ballEdge: "#4A0610", ballTail: "#E0442C", ballImpact: "#E4D6BE",
            divider: "#CDB79A", dividerSecondary: "#050102",
            textureOpacity: 0.040, separatorOpacity: 0.36, dividerOpacity: 0.55
        ),
        ExpectedTheme(
            theme: .everdellEmerland, name: "Everdell Emerland", appearance: .light,
            composition: .canopyRiverValley,
            stops: [stop("#E4F5DC", 0), stop("#A9DDB2", 0.32), stop("#4A9A6B", 0.66), stop("#143F34", 1)],
            atmosphere: ["#0B3A33", "#8FE0D6", "#FFFBE6", "#E063A6"],
            atmosphereOpacities: [0.40, 0.40, 0.34, 0.40],
            surfaceTexture: .paintedCanopy,
            surfaceInk: "#0E2A20", onChromeInk: "#F4F1DE", chrome: "#0F4A40",
            action: "#DE5A9E", detail: "#0E97AA", secondaryDetail: "#F29B30",
            participants: ["#DE5A9E", "#F29B30", "#0E97AA", "#7E55BF", "#8A5A38"],
            finish: .paintedWood, pinballMaterial: .cutEmerald,
            ball: "#138A52", ballEdge: "#033A22", ballTail: "#BFF5D8", ballImpact: "#F29B30",
            divider: "#C7A06A", dividerSecondary: "#3F2A14",
            textureOpacity: 0.034, separatorOpacity: 0.32, dividerOpacity: 0.60
        ),
        ExpectedTheme(
            theme: .sagrada, name: "Sagrada", appearance: .dark,
            composition: .roseWindow,
            stops: [stop("#22305E", 0), stop("#1A1638", 0.55), stop("#0D080A", 1)],
            atmosphere: ["#FFE7A8", "#FFF4D6"], atmosphereOpacities: [0.26, 0.22],
            surfaceTexture: .cathedralGlass,
            surfaceInk: "#F2EFE6", onChromeInk: "#F2EFE6", chrome: "#3A3D3B",
            action: "#F5C518", detail: "#A6A296", secondaryDetail: "#1C6FD0",
            participants: ["#F5C518", "#E0262E", "#1C6FD0", "#23A04A", "#9A2DB5"],
            finish: .leadedGlass, pinballMaterial: .clearGlassBead,
            ball: "#CFE3F0", ballEdge: "#6F8CA6", ballTail: "#FFFFFF", ballImpact: "#F5C518",
            divider: "#A6A296", dividerSecondary: "#0D080A",
            textureOpacity: 0.032, separatorOpacity: 0.36, dividerOpacity: 0.60
        ),
        ExpectedTheme(
            theme: .wyrmspan, name: "Wyrmspan", appearance: .light,
            composition: .watercolorSky,
            stops: [stop("#F3F5F2", 0), stop("#E6EEEC", 0.50), stop("#BFD9DC", 1)],
            atmosphere: ["#8FBFC8", "#6FA6B2"], atmosphereOpacities: [0.34, 0.26],
            surfaceTexture: .eggshellSpeckle,
            surfaceInk: "#27343A", onChromeInk: "#F3F5F2", chrome: "#244C56",
            action: "#8A2433", detail: "#5C96A4", secondaryDetail: "#B9A64A",
            participants: ["#8A2433", "#5C96A4", "#5B2E6F", "#8E9B33", "#E7E2D8"],
            finish: .speckledEgg, pinballMaterial: .jadeEgg,
            ball: "#B9A64A", ballEdge: "#5E6A1C", ballTail: "#5C96A4", ballImpact: "#8A2433",
            divider: "#5A3A28", dividerSecondary: "#F3F5F2",
            textureOpacity: 0.030, separatorOpacity: 0.30, dividerOpacity: 0.55
        ),
        ExpectedTheme(
            theme: .harmonies, name: "Harmonies", appearance: .light,
            composition: .sunlitMeadow,
            stops: [stop("#F2E7CC", 0), stop("#E9DCC0", 0.55), stop("#DCCBA6", 1)],
            atmosphere: ["#F7DB7A", "#E08A3C"], atmosphereOpacities: [0.40, 0.12],
            surfaceTexture: .sandedWood,
            surfaceInk: "#3A2E1F", onChromeInk: "#FFF6E4", chrome: "#2F5293",
            action: "#BE4252", detail: "#3F9AA6", secondaryDetail: "#F2C94C",
            participants: ["#3F9AA6", "#BE4252", "#6BA35C", "#7D8590", "#8B5A3C"],
            finish: .lacqueredToken, pinballMaterial: .amberBead,
            ball: "#E9A040", ballEdge: "#8A4F12", ballTail: "#F2C94C", ballImpact: "#2F5293",
            divider: "#8B5A3C", dividerSecondary: "#F2E7CC",
            textureOpacity: 0.032, separatorOpacity: 0.30, dividerOpacity: 0.60
        ),
        ExpectedTheme(
            theme: .finspan, name: "Finspan", appearance: .dark,
            composition: .oceanDescent,
            stops: [
                stop("#7FD2D6", 0), stop("#1E6E8A", 0.18), stop("#143E5E", 0.55),
                stop("#0A1C2E", 0.80), stop("#040A14", 1)
            ],
            atmosphere: ["#C6ECEC", "#9FE8E0"], atmosphereOpacities: [0.40, 0.10],
            surfaceTexture: .seaFoam,
            surfaceInk: "#E8F4F4", onChromeInk: "#E8F4F4", chrome: "#0E2E44",
            action: "#F0674D", detail: "#5FC9A9", secondaryDetail: "#F2C230",
            participants: ["#5FC9A9", "#F0674D", "#F2C230", "#F28BB0", "#F2F4EE"],
            finish: .bubbleBead, pinballMaterial: .foamBubble,
            ball: "#E8F4F4", ballEdge: "#6FA3B8", ballTail: "#9FE8E0", ballImpact: "#F0674D",
            divider: "#E8F4F4", dividerSecondary: "#0B2538",
            textureOpacity: 0.030, separatorOpacity: 0.36, dividerOpacity: 0.60
        )
    ]

    private static func stop(_ hex: String, _ location: Double) -> BoardSurfaceStop {
        BoardSurfaceStop(hex: hex, location: location)
    }

    func testThemesExposeExactCompleteVisualRoles() {
        XCTAssertEqual(ChooserColorTheme.defaultTheme, .wingspanOriginal)
        XCTAssertEqual(ChooserColorTheme.allCases, expectedThemes.map(\.theme))
        XCTAssertEqual(ChooserColorTheme.allCases.map(\.rawValue), [
            "wingspan-original", "wingspan-nectar", "wingspan-hummingbirds", "nidavellir",
            "concordia", "everdell", "lizard-wizard", "leaders",
            "res-arcana", "everdell-emerland", "sagrada",
            "wyrmspan", "harmonies", "finspan"
        ])

        for expected in expectedThemes {
            let theme = expected.theme.visualTheme
            XCTAssertEqual(expected.theme.name, expected.name)
            XCTAssertEqual(theme.appearance, expected.appearance)
            XCTAssertEqual(theme.surfaceRecipe.composition, expected.composition)
            XCTAssertEqual(theme.surfaceRecipe.stops, expected.stops)
            XCTAssertEqual(theme.surfaceRecipe.atmosphereHexValues, expected.atmosphere)
            XCTAssertEqual(theme.surfaceRecipe.atmosphereOpacities, expected.atmosphereOpacities)
            XCTAssertEqual(theme.surfaceRecipe.texture, expected.surfaceTexture)
            XCTAssertEqual(theme.surfaceInkHex, expected.surfaceInk)
            XCTAssertEqual(theme.onChromeInkHex, expected.onChromeInk)
            XCTAssertEqual(theme.chromeHex, expected.chrome)
            XCTAssertEqual(theme.actionAccentHex, expected.action)
            XCTAssertEqual(theme.detailAccentHex, expected.detail)
            XCTAssertEqual(theme.secondaryDetailHex, expected.secondaryDetail)
            XCTAssertEqual(theme.participantHexValues, expected.participants)
            XCTAssertEqual(theme.pieceFinish, expected.finish)
            XCTAssertEqual(theme.pinballMaterial, expected.pinballMaterial)
            XCTAssertEqual(theme.ballHex, expected.ball)
            XCTAssertEqual(theme.ballEdgeHex, expected.ballEdge)
            XCTAssertEqual(theme.ballTailHex, expected.ballTail)
            XCTAssertEqual(theme.ballImpactHex, expected.ballImpact)
            XCTAssertEqual(theme.dividerHex, expected.divider)
            XCTAssertEqual(theme.dividerSecondaryHex, expected.dividerSecondary)
            XCTAssertEqual(theme.textureOpacity, expected.textureOpacity, accuracy: 0.000_001)
            XCTAssertEqual(theme.separatorOpacity, expected.separatorOpacity, accuracy: 0.000_001)
            XCTAssertEqual(theme.dividerOpacity, expected.dividerOpacity, accuracy: 0.000_001)

            // Compatibility roles intentionally forward to the new explicit ones.
            XCTAssertEqual(theme.surfaceStartHex, expected.stops.first?.hex)
            XCTAssertEqual(theme.surfaceEndHex, expected.stops.last?.hex)
            XCTAssertEqual(theme.primaryInkHex, expected.surfaceInk)
            XCTAssertEqual(theme.accentHex, expected.action)
            XCTAssertEqual(theme.secondaryAccentHex, expected.detail)
            XCTAssertEqual(theme.pinballHex, expected.ball)
        }
    }

    func testThemesHaveDistinctSurfacesFinishesSeedsAndInternalSwatches() {
        let worldCount = expectedThemes.count
        XCTAssertEqual(worldCount, 14)
        XCTAssertEqual(Set(expectedThemes.map { $0.composition }).count, worldCount)
        XCTAssertEqual(Set(expectedThemes.map { $0.surfaceTexture }).count, worldCount)
        XCTAssertEqual(Set(expectedThemes.map { $0.stops.map(\.hex).joined(separator: ":") }).count, worldCount)
        XCTAssertEqual(Set(expectedThemes.map(\.finish)).count, worldCount)
        XCTAssertEqual(Set(expectedThemes.map(\.pinballMaterial)).count, worldCount)
        XCTAssertEqual(Set(ChooserColorTheme.allCases.map { $0.visualTheme.textureSeed }).count, worldCount)
        XCTAssertEqual(Set(ChooserColorTheme.allCases.map { $0.visualTheme.subjectArt }).count, worldCount)

        for expected in expectedThemes {
            XCTAssertEqual(expected.participants.count, 5)
            XCTAssertEqual(Set(expected.participants).count, 5, expected.name)
            XCTAssertGreaterThanOrEqual(expected.stops.count, 2, expected.name)
            XCTAssertNotEqual(expected.stops.first?.hex, expected.stops.last?.hex, expected.name)
        }

        XCTAssertEqual(
            ChooserColorTheme.allCases.filter { $0.appearance == .light },
            [.wingspanOriginal, .concordia, .leaders, .everdellEmerland, .wyrmspan, .harmonies]
        )
        XCTAssertEqual(ChooserColorTheme.allCases.filter { $0.appearance == .dark }.count, 8)
    }

    func testEveryWorldHasItsOwnDividerStyleAndBallOrnament() {
        let expectedDividers: [ChooserColorTheme: BoardDividerStyle] = [
            .wingspanOriginal: .pencil,
            .wingspanNectar: .inkKeyline,
            .wingspanHummingbirds: .inkKeyline,
            .nidavellir: .goldInlay,
            .concordia: .dottedRoute,
            .everdell: .twig,
            .lizardWizard: .inkKeyline,
            .leaders: .goldInlay,
            .resArcana: .stitchedSeam,
            .everdellEmerland: .rope,
            .sagrada: .stoneMullion,
            .wyrmspan: .pencil,
            .harmonies: .dottedRoute,
            .finspan: .inkKeyline
        ]
        let expectedOrnaments: [ChooserColorTheme: PinballBallOrnament] = [
            .wingspanOriginal: .speckledEgg,
            .wingspanNectar: .glassBead,
            .wingspanHummingbirds: .glassBead,
            .nidavellir: .coin,
            .concordia: .coin,
            .everdell: .glassBead,
            .lizardWizard: .slitPupil,
            .leaders: .glassBead,
            .resArcana: .glassBead,
            .everdellEmerland: .facetedGem,
            .sagrada: .clearGlass,
            .wyrmspan: .speckledEgg,
            .harmonies: .glassBead,
            .finspan: .clearGlass
        ]
        XCTAssertEqual(Set(expectedDividers.keys), Set(ChooserColorTheme.allCases))
        for theme in ChooserColorTheme.allCases {
            XCTAssertEqual(theme.visualTheme.dividerStyle, expectedDividers[theme], theme.name)
            XCTAssertEqual(theme.pinballMaterial.presentation.ornament, expectedOrnaments[theme], theme.name)
        }
    }

    func testOnlyResArcanaReplacesTheSharedDestructiveRed() {
        for theme in ChooserColorTheme.allCases {
            XCTAssertEqual(
                theme.destructiveControlHex,
                theme == .resArcana ? "#E4D6BE" : "#982B37",
                theme.name
            )
        }
    }

    func testBoostedSurfaceTexturesStayUnderTheRendererCeiling() {
        for theme in ChooserColorTheme.allCases {
            XCTAssertGreaterThanOrEqual(theme.textureKind.surfaceStrength, 1, theme.name)
            XCTAssertLessThanOrEqual(
                theme.visualTheme.textureOpacity * theme.textureKind.surfaceStrength,
                0.12,
                theme.name
            )
        }
    }

    func testLegacyWingspanRawIDsMigrateToClearBoxLedDisplayNames() throws {
        XCTAssertEqual(ChooserColorTheme.wingspanAsia, .wingspanNectar)
        XCTAssertEqual(ChooserColorTheme.wingspanAmericas, .wingspanHummingbirds)
        XCTAssertEqual(ChooserColorTheme.wingspanAsia.rawValue, "wingspan-nectar")
        XCTAssertEqual(ChooserColorTheme.wingspanAmericas.rawValue, "wingspan-hummingbirds")
        XCTAssertEqual(ChooserColorTheme.wingspanAsia.name, "Wingspan Asia")
        XCTAssertEqual(ChooserColorTheme.wingspanAmericas.name, "Wingspan Americas")
        XCTAssertEqual(try JSONDecoder().decode(ChooserColorTheme.self, from: Data("\"wingspan-nectar\"".utf8)), .wingspanAsia)
        XCTAssertEqual(try JSONDecoder().decode(ChooserColorTheme.self, from: Data("\"wingspan-hummingbirds\"".utf8)), .wingspanAmericas)
    }

    func testParticipantColorsCycleWithoutGeneratedIntermediateHues() {
        for theme in ChooserColorTheme.allCases {
            let colors = theme.participantHexValues
            XCTAssertEqual(theme.participantHex(at: -1), colors.last)
            for index in 0..<(colors.count * 5) {
                XCTAssertEqual(theme.participantHex(at: index), colors[index % colors.count])
                assertSameColor(
                    theme.participantColor(at: index),
                    theme.participantColor(at: index + colors.count),
                    message: "\(theme.name) should cycle at index \(index)"
                )
            }
        }
    }

    func testNumeralsAndAccentForegroundMeetNormalTextContrast() {
        for theme in ChooserColorTheme.allCases {
            for index in theme.participantHexValues.indices {
                let face = rgbaComponents(theme.participantColor(at: index), appearance: theme.appearance)
                let numeral = rgbaComponents(theme.participantNumeralColor(at: index), appearance: theme.appearance)
                XCTAssertGreaterThanOrEqual(
                    contrastRatio(face, numeral),
                    4.5,
                    "\(theme.name) participant \(index + 1) numeral"
                )
            }

            let accent = rgbaComponents(theme.accentColor, appearance: theme.appearance)
            let foreground = rgbaComponents(theme.accentForegroundColor, appearance: theme.appearance)
            XCTAssertGreaterThanOrEqual(contrastRatio(accent, foreground), 4.5, "\(theme.name) accent")
        }
    }

    func testEveryActualTextBackingPairMeetsNormalTextContrast() {
        for theme in ChooserColorTheme.allCases {
            let visualTheme = theme.visualTheme
            XCTAssertTrue(
                visualTheme.surfaceStopHexValues.contains(visualTheme.informationPanelHex),
                "\(theme.name) panel should remain part of its authored surface"
            )
            XCTAssertGreaterThanOrEqual(
                ChooserColorTheme.contrastRatio(
                    between: visualTheme.surfaceInkHex,
                    and: visualTheme.informationPanelHex
                ),
                4.5,
                "\(theme.name) information panel"
            )
            XCTAssertGreaterThanOrEqual(
                ChooserColorTheme.contrastRatio(
                    between: visualTheme.onChromeInkHex,
                    and: visualTheme.chromeHex
                ),
                4.5,
                "\(theme.name) chrome label"
            )
            XCTAssertGreaterThanOrEqual(
                ChooserColorTheme.contrastRatio(
                    between: visualTheme.interactiveTextHex,
                    and: visualTheme.informationPanelHex
                ),
                4.5,
                "\(theme.name) navigation and unfilled link"
            )
            XCTAssertGreaterThanOrEqual(
                ChooserColorTheme.contrastRatio(
                    between: visualTheme.informationPanelSystemInkHex,
                    and: visualTheme.informationPanelHex
                ),
                4.5,
                "\(theme.name) native navigation title"
            )
            XCTAssertGreaterThanOrEqual(
                ChooserColorTheme.contrastRatio(
                    between: visualTheme.destructiveControlForegroundHex,
                    and: visualTheme.destructiveControlHex
                ),
                4.5,
                "\(theme.name) destructive control"
            )
            let action = rgbaComponents(visualTheme.actionAccentColor, appearance: theme.appearance)
            let actionForeground = rgbaComponents(
                visualTheme.accentForegroundColor,
                appearance: theme.appearance
            )
            XCTAssertGreaterThanOrEqual(
                contrastRatio(action, actionForeground),
                4.5,
                "\(theme.name) filled action"
            )
            XCTAssertGreaterThanOrEqual(visualTheme.chromeControlBackingOpacity, 0.90)

            let chrome = rgbaComponents(visualTheme.chromeTintColor, appearance: theme.appearance)
            let onChrome = rgbaComponents(visualTheme.onChromeInkColor, appearance: theme.appearance)
            for stop in visualTheme.surfaceRecipe.stops {
                let surface = rgbaComponents(
                    ChooserColorTheme.color(hex: stop.hex),
                    appearance: theme.appearance
                )
                let renderedChrome = blended(
                    chrome,
                    opacity: visualTheme.chromeControlBackingOpacity,
                    over: surface
                )
                XCTAssertGreaterThanOrEqual(
                    contrastRatio(renderedChrome, onChrome),
                    4.5,
                    "\(theme.name) glass chrome over \(stop.hex)"
                )
            }
        }

        XCTAssertEqual(ChooserColorTheme.everdell.informationPanelHex, "#2A1A10")
        XCTAssertNotEqual(
            ChooserColorTheme.everdell.informationPanelHex,
            ChooserColorTheme.everdell.surfaceStartHex
        )
    }

    func testBoardPieceStyleUsesThemeMaterialAndAuthoredRoles() {
        for theme in ChooserColorTheme.allCases {
            for index in theme.participantHexValues.indices {
                let style = BoardPieceStyle.participant(theme: theme, index: index)
                assertSameColor(style.face, theme.participantColor(at: index), message: "\(theme.name) face")
                assertSameColor(style.bevel, theme.participantBevelColor(at: index), message: "\(theme.name) bevel")
                assertSameColor(style.shade, theme.participantShadeColor(at: index), message: "\(theme.name) shade")
                assertSameColor(style.keyline, theme.participantKeylineColor(at: index), message: "\(theme.name) keyline")
                assertSameColor(style.textureInk, style.shade, message: "\(theme.name) material grain")
                assertSameColor(style.foreground, theme.participantNumeralColor(at: index), message: "\(theme.name) numeral")
                XCTAssertEqual(style.finish, theme.finish)
                XCTAssertEqual(
                    style.textureOpacity,
                    min(0.09, theme.visualTheme.textureOpacity * theme.finish.presentation.textureMultiplier),
                    accuracy: 0.000_001
                )
                XCTAssertLessThanOrEqual(style.textureOpacity, 0.09)

                let face = rgbaComponents(style.face, appearance: theme.appearance)
                let edge = rgbaComponents(style.keyline, appearance: theme.appearance)
                let edgeContrast = contrastRatio(face, edge)
                XCTAssertGreaterThan(edgeContrast, 1.10, "\(theme.name) edge needs legible relief")
                XCTAssertLessThan(
                    edgeContrast,
                    3,
                    "\(theme.name) edge should stay tinted, not become a hard black keyline"
                )
                XCTAssertGreaterThan(
                    edge.red + edge.green + edge.blue,
                    0.05,
                    "\(theme.name) edge must retain participant hue"
                )
            }
        }
    }

    func testEveryWorldHasASeparateAuthoredMaterialTreatment() {
        let piecePresentations = expectedThemes.map(\.finish).map(\.presentation)
        XCTAssertEqual(Set(piecePresentations.map {
            "\($0.outerEdgeWidth):\($0.innerEdgeWidth):\($0.bevelOpacity):\($0.edgeTintOpacity):\($0.reliefOpacity):\($0.innerOcclusionOpacity):\($0.reliefRotationDegrees):\($0.textureMultiplier):\($0.shadowMultiplier)"
        }).count, expectedThemes.count)

        for presentation in piecePresentations {
            XCTAssertTrue((0.54...0.76).contains(presentation.edgeTintOpacity))
            XCTAssertTrue((0.08...0.31).contains(presentation.reliefOpacity))
            XCTAssertTrue((0.22...0.42).contains(presentation.innerOcclusionOpacity))
        }

        let ballPresentations = expectedThemes.map(\.pinballMaterial).map(\.presentation)
        XCTAssertEqual(Set(ballPresentations.map {
            "\($0.edgeWidth):\($0.shadeRadius):\($0.shadeAlpha):\($0.rimWidth):\($0.rimAlpha):\($0.markRadius):\($0.markAlpha)"
        }).count, expectedThemes.count)
        XCTAssertNotEqual(
            ChooserColorTheme.wingspanAsia.pinballMaterial,
            ChooserColorTheme.wingspanAmericas.pinballMaterial
        )
        XCTAssertEqual(ChooserColorTheme.wingspanAsia.finish, .peacockJewelEnamel)
        XCTAssertEqual(ChooserColorTheme.wingspanAsia.pinballMaterial, .emeraldEnamel)
    }

    func testPinballDividersUseAContrastingSecondaryKeylineUnderEveryRay() throws {
        for theme in ChooserColorTheme.allCases {
            let visualTheme = theme.visualTheme
            let secondaryHex = try XCTUnwrap(
                visualTheme.dividerSecondaryHex,
                "\(theme.name) must author a divider keyline"
            )
            XCTAssertGreaterThanOrEqual(
                ChooserColorTheme.contrastRatio(
                    between: visualTheme.dividerHex,
                    and: secondaryHex
                ),
                3,
                "\(theme.name) divider core and keyline"
            )
            XCTAssertGreaterThanOrEqual(visualTheme.dividerSecondaryOpacity, 0.68)
            XCTAssertGreaterThan(visualTheme.dividerSecondaryOpacity, visualTheme.dividerOpacity)
        }

        for isDense in [false, true] {
            let metrics = PinballDividerVisualMetrics.base(isDense: isDense)
            XCTAssertGreaterThanOrEqual(
                metrics.keylineWidth - metrics.primaryWidth,
                2.4,
                "The secondary stroke must remain visibly exposed beside the primary ray"
            )
        }
        XCTAssertGreaterThan(
            PinballDividerVisualMetrics.winner.keylineWidth,
            PinballDividerVisualMetrics.winner.primaryWidth
        )
    }

    /// `scale: 1` is written out rather than left to the default. These are the
    /// phone's authored numbers, and a defaulted call would keep passing while
    /// silently pinning a value the app no longer ships on a larger board — the
    /// assertion would survive the very change it exists to catch.
    func testBoardPieceGeometryUsesBroadBandsAndRestrainedWinnerScale() {
        XCTAssertEqual(BoardPieceVisualMetrics.bandWidth(for: 100, scale: 1), 18, accuracy: 0.001)
        XCTAssertEqual(BoardPieceVisualMetrics.bandWidth(for: 160, scale: 1), 20, accuracy: 0.001)
        XCTAssertEqual(BoardPieceVisualMetrics.bandWidth(for: 176, scale: 1), 22, accuracy: 0.001)
        XCTAssertEqual(BoardPieceVisualMetrics.bandWidth(for: 240, scale: 1), 22, accuracy: 0.001)
        XCTAssertEqual(BoardPieceVisualMetrics.chitRimWidth(for: 50, scale: 1), 7, accuracy: 0.001)
        XCTAssertEqual(BoardPieceVisualMetrics.chitRimWidth(for: 120, scale: 1), 9, accuracy: 0.001)
        XCTAssertEqual(BoardPieceVisualMetrics.ringTextureOpacity(from: 0.05), 0.0675, accuracy: 0.000_001)
        XCTAssertEqual(BoardPieceVisualMetrics.ringTextureOpacity(from: 0.10), 0.12, accuracy: 0.000_001)
        XCTAssertEqual(BoardPieceVisualMetrics.chitTextureOpacity(from: 0.05), 0.059, accuracy: 0.000_001)
        XCTAssertEqual(BoardPieceVisualMetrics.maximumScale(for: .winner), 1.06, accuracy: 0.001)
        XCTAssertEqual(
            BoardPieceVisualMetrics.renderingOverflow(for: 44, emphasis: .resting, scale: 1),
            12
        )
        XCTAssertEqual(
            BoardPieceVisualMetrics.renderingOverflow(for: 176, emphasis: .winner, scale: 1),
            20
        )
    }

    /// The scaled rows. The saturation was the bug, not the ratio: a fixed 22pt
    /// band on a 296pt ring reads as a thin hoop rather than a game piece, so
    /// the clamp bounds scale while `d * 0.125` does not.
    func testBoardPieceGeometryScalesItsClampsWithTheBoard() {
        XCTAssertEqual(BoardPieceVisualMetrics.bandWidth(for: 296, scale: 1.68), 36.96, accuracy: 0.001)
        XCTAssertEqual(BoardPieceVisualMetrics.bandWidth(for: 176, scale: 1.68), 30.24, accuracy: 0.001)
        XCTAssertEqual(BoardPieceVisualMetrics.chitRimWidth(for: 240, scale: 1.68), 15.12, accuracy: 0.001)
        XCTAssertEqual(
            BoardPieceVisualMetrics.renderingOverflow(for: 296, emphasis: .winner, scale: 1.68),
            33.6,
            accuracy: 0.001
        )
    }

    /// The invariant the authored 12/20 anchors exist to satisfy. They are kept
    /// and multiplied rather than derived from the shadow, because the slack
    /// differs between them and any single formula that reproduces one misses
    /// the others — so assert the property instead.
    ///
    /// The slack per emphasis, at any scale: resting 3, winner 2, and **pulsing
    /// exactly 0** — its 7.5 radius plus 4.5 offset lands precisely on the 12pt
    /// overflow. That is shipping 1.0 behaviour, not something scaling
    /// introduced, and it is why this asserts coverage rather than coverage plus
    /// a margin. An earlier version demanded 2 points of headroom and failed at
    /// every scale including 1 — the test being wrong about the code, not the
    /// code being wrong.
    func testRenderingOverflowAlwaysCoversTheCompleteContactShadow() {
        let emphases: [BoardPieceEmphasis] = [.resting, .pulsing(), .winner, .receded, .dimmed]
        for emphasis in emphases {
            for scale in stride(from: CGFloat(1), through: 2, by: 0.1) {
                let shadow = BoardPieceVisualMetrics.shadowMetrics(for: emphasis, scale: scale)
                let overflow = BoardPieceVisualMetrics.renderingOverflow(
                    for: 176,
                    emphasis: emphasis,
                    scale: scale
                )
                XCTAssertGreaterThanOrEqual(
                    overflow,
                    shadow.radius + shadow.y - 0.001,
                    "\(emphasis) at scale \(scale) would clip its own shadow"
                )
            }
        }
    }

    func testDefaultAccessibilityAppearancePolicyPreservesBuild14Materials() {
        let policy = BoardAccessibilityAppearancePolicy()

        XCTAssertEqual(policy.surfaceAtmosphereOpacityMultiplier, 1, accuracy: 0.000_001)
        XCTAssertEqual(policy.surfaceTextureOpacityMultiplier, 1, accuracy: 0.000_001)
        XCTAssertEqual(policy.materialTextureOpacityMultiplier, 1, accuracy: 0.000_001)
        XCTAssertEqual(policy.materialReliefOpacityMultiplier, 1, accuracy: 0.000_001)
        XCTAssertEqual(policy.edgeWidthMultiplier, 1, accuracy: 0.000_001)
        XCTAssertEqual(policy.edgeOpacityMultiplier, 1, accuracy: 0.000_001)
        XCTAssertEqual(policy.shadowOpacityMultiplier, 1, accuracy: 0.000_001)
        XCTAssertEqual(policy.dimmedPieceOpacity, 0.22, accuracy: 0.000_001)
        XCTAssertFalse(policy.showsWinnerContour)
    }

    func testReduceTransparencySimplifiesDecorativeLayersWithoutFlatteningTheme() {
        let policy = BoardAccessibilityAppearancePolicy(reduceTransparency: true)

        XCTAssertEqual(policy.surfaceAtmosphereOpacityMultiplier, 0.38, accuracy: 0.000_001)
        XCTAssertEqual(policy.surfaceTextureOpacityMultiplier, 0.78, accuracy: 0.000_001)
        XCTAssertEqual(policy.materialTextureOpacityMultiplier, 0.72, accuracy: 0.000_001)
        XCTAssertEqual(policy.materialReliefOpacityMultiplier, 0.68, accuracy: 0.000_001)
        XCTAssertGreaterThan(policy.surfaceAtmosphereOpacityMultiplier, 0)
        XCTAssertEqual(policy.edgeWidthMultiplier, 1, accuracy: 0.000_001)
        XCTAssertEqual(policy.edgeOpacityMultiplier, 1, accuracy: 0.000_001)
    }

    func testIncreasedContrastStrengthensStructuralMaterialCues() {
        let policy = BoardAccessibilityAppearancePolicy(increasedContrast: true)

        XCTAssertEqual(policy.surfaceAtmosphereOpacityMultiplier, 1, accuracy: 0.000_001)
        XCTAssertEqual(policy.surfaceTextureOpacityMultiplier, 1.22, accuracy: 0.000_001)
        XCTAssertEqual(policy.materialTextureOpacityMultiplier, 1.28, accuracy: 0.000_001)
        XCTAssertEqual(policy.materialReliefOpacityMultiplier, 1.16, accuracy: 0.000_001)
        XCTAssertEqual(policy.edgeWidthMultiplier, 1.32, accuracy: 0.000_001)
        XCTAssertEqual(policy.edgeOpacityMultiplier, 1.24, accuracy: 0.000_001)
        XCTAssertEqual(policy.shadowOpacityMultiplier, 1.18, accuracy: 0.000_001)
        XCTAssertEqual(policy.dimmedPieceOpacity, 0.32, accuracy: 0.000_001)
    }

    func testDifferentiateWithoutColorAddsPatternedWinnerCue() {
        let standard = BoardAccessibilityAppearancePolicy()
        let differentiated = BoardAccessibilityAppearancePolicy(
            differentiateWithoutColor: true
        )

        XCTAssertFalse(standard.showsWinnerContour)
        XCTAssertTrue(differentiated.showsWinnerContour)
    }

    func testAccessibilityAppearancePreferencesComposeDeterministically() {
        let policy = BoardAccessibilityAppearancePolicy(
            reduceTransparency: true,
            increasedContrast: true,
            differentiateWithoutColor: true
        )

        XCTAssertEqual(policy.surfaceTextureOpacityMultiplier, 0.9516, accuracy: 0.000_001)
        XCTAssertEqual(policy.materialTextureOpacityMultiplier, 0.9216, accuracy: 0.000_001)
        XCTAssertEqual(policy.materialReliefOpacityMultiplier, 0.7888, accuracy: 0.000_001)
        XCTAssertEqual(policy.edgeWidthMultiplier, 1.32, accuracy: 0.000_001)
        XCTAssertTrue(policy.showsWinnerContour)
    }

    func testBuild13CapturesTactileRingReferencesInBothOrientations() throws {
        let captures: [(theme: ChooserColorTheme, size: CGSize, name: String)] = [
            (.wingspanOriginal, CGSize(width: 393, height: 852), "Build13-Wingspan-Original-Portrait"),
            (.wingspanOriginal, CGSize(width: 852, height: 393), "Build13-Wingspan-Original-Landscape"),
            (.nidavellir, CGSize(width: 393, height: 852), "Build13-Nidavellir-Portrait"),
            (.nidavellir, CGSize(width: 852, height: 393), "Build13-Nidavellir-Landscape")
        ]

        for capture in captures {
            let renderer = ImageRenderer(
                content: Build13RingMaterialReference(
                    theme: capture.theme,
                    size: capture.size
                )
                .frame(width: capture.size.width, height: capture.size.height)
            )
            renderer.scale = 2
            let image = try XCTUnwrap(renderer.uiImage, "Could not render \(capture.name)")
            let attachment = XCTAttachment(image: image)
            attachment.name = capture.name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    func testUserDefaultsThemeStorePreservesRawValuesAndFallsBackFromUnknownValues() throws {
        let suiteName = "ChooserColorThemeTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsChooserColorThemeStore(defaults: defaults, key: "theme")

        XCTAssertEqual(store.loadColorTheme(), .wingspanOriginal)
        for theme in ChooserColorTheme.allCases {
            store.saveColorTheme(theme)
            XCTAssertEqual(store.loadColorTheme(), theme)
            XCTAssertEqual(defaults.string(forKey: "theme"), theme.rawValue)
        }
        for unknownValue in ["aurora", "ultraviolet", "not-a-theme"] {
            defaults.set(unknownValue, forKey: "theme")
            XCTAssertEqual(store.loadColorTheme(), .wingspanOriginal)
        }
    }

    func testSelectingThemePersistsWithoutChangingTapInGroupOrMode() {
        let store = MemoryChooserColorThemeStore(storedTheme: .wingspanOriginal)
        let model = ChooserAppModel(
            modeStore: MemoryLaunchDefaultModeStore(storedMode: .tapIn),
            colorThemeStore: store,
            onboardingStore: MemoryOnboardingProgressStore(),
            feedback: NativeNoopFeedbackCoordinator()
        )
        XCTAssertTrue(model.addTapInEntryForAccessibility())
        XCTAssertTrue(model.addTapInEntryForAccessibility())
        let entries = model.tapInSnapshot.entries

        model.selectColorTheme(.leaders)

        XCTAssertEqual(model.colorTheme, .leaders)
        XCTAssertEqual(store.savedThemes, [.leaders])
        XCTAssertEqual(model.mode, .tapIn)
        XCTAssertEqual(model.tapInSnapshot.entries, entries)
    }

    private typealias RGBA = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)

    private func assertSameColor(
        _ first: Color,
        _ second: Color,
        message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let firstComponents = rgbaComponents(first, appearance: .dark, file: file, line: line)
        let secondComponents = rgbaComponents(second, appearance: .dark, file: file, line: line)
        XCTAssertEqual(firstComponents.red, secondComponents.red, accuracy: 0.000_001, message, file: file, line: line)
        XCTAssertEqual(firstComponents.green, secondComponents.green, accuracy: 0.000_001, message, file: file, line: line)
        XCTAssertEqual(firstComponents.blue, secondComponents.blue, accuracy: 0.000_001, message, file: file, line: line)
        XCTAssertEqual(firstComponents.alpha, secondComponents.alpha, accuracy: 0.000_001, message, file: file, line: line)
    }

    private func rgbaComponents(
        _ color: Color,
        appearance: ChooserThemeAppearance,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> RGBA {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        let style: UIUserInterfaceStyle = appearance == .light ? .light : .dark
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        XCTAssertTrue(
            resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha),
            "Expected an RGB-compatible color",
            file: file,
            line: line
        )
        return (red, green, blue, alpha)
    }

    private func contrastRatio(_ first: RGBA, _ second: RGBA) -> Double {
        let firstLuminance = relativeLuminance(first)
        let secondLuminance = relativeLuminance(second)
        return (max(firstLuminance, secondLuminance) + 0.05) / (min(firstLuminance, secondLuminance) + 0.05)
    }

    private func blended(_ foreground: RGBA, opacity: Double, over background: RGBA) -> RGBA {
        let alpha = CGFloat(min(max(opacity, 0), 1))
        return (
            foreground.red * alpha + background.red * (1 - alpha),
            foreground.green * alpha + background.green * (1 - alpha),
            foreground.blue * alpha + background.blue * (1 - alpha),
            1
        )
    }

    private func relativeLuminance(_ color: RGBA) -> Double {
        0.2126 * linearized(color.red) + 0.7152 * linearized(color.green) + 0.0722 * linearized(color.blue)
    }

    private func linearized(_ component: CGFloat) -> Double {
        let component = Double(component)
        return component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
    }
}

private struct Build13RingMaterialReference: View {
    let theme: ChooserColorTheme
    let size: CGSize

    var body: some View {
        ZStack {
            BoardSurfaceView(theme: theme)

            if size.width > size.height {
                ring(index: 0, diameter: 150, emphasis: .resting)
                    .position(x: size.width * 0.22, y: size.height * 0.50)
                ring(index: 1, diameter: 150, emphasis: .winner)
                    .position(x: size.width * 0.50, y: size.height * 0.48)
                ring(index: 2, diameter: 150, emphasis: .resting)
                    .position(x: size.width * 0.78, y: size.height * 0.50)
            } else {
                ring(index: 0, diameter: 168, emphasis: .resting)
                    .position(x: size.width * 0.29, y: size.height * 0.25)
                ring(index: 1, diameter: 168, emphasis: .winner)
                    .position(x: size.width * 0.70, y: size.height * 0.51)
                ring(index: 2, diameter: 168, emphasis: .resting)
                    .position(x: size.width * 0.31, y: size.height * 0.77)
            }
        }
        .clipped()
    }

    private func ring(
        index: Int,
        diameter: CGFloat,
        emphasis: BoardPieceEmphasis
    ) -> some View {
        BoardRingView(
            diameter: diameter,
            lineWidth: BoardPieceVisualMetrics.bandWidth(for: diameter),
            style: .participant(theme: theme, index: index),
            emphasis: emphasis,
            accessibilityLabel: "Material reference ring"
        )
    }
}
