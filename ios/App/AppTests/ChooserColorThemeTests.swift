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
            stops: [stop("#DFE6E0", 0), stop("#C9D7D4", 0.58), stop("#7EAFCA", 1)],
            atmosphere: ["#F7F4EC", "#D95C4E"], atmosphereOpacities: [0.04, 0.025],
            surfaceTexture: .watercolorFlecks,
            surfaceInk: "#27363B", onChromeInk: "#101D21", chrome: "#6E9FB7",
            action: "#D95C4E", detail: "#D5A62D", secondaryDetail: "#7EAFCA",
            participants: ["#D95C4E", "#D5A62D", "#3D78A1", "#508467", "#80658A"],
            finish: .watercolorEggshell, pinballMaterial: .coralEnamel,
            ball: "#D95C4E", ballEdge: "#9E3F39", ballTail: "#D95C4E", ballImpact: "#27363B",
            divider: "#27363B", dividerSecondary: "#F7F4EC",
            textureOpacity: 0.026, separatorOpacity: 0.30, dividerOpacity: 0.32
        ),
        ExpectedTheme(
            theme: .wingspanNectar, name: "Wingspan Asia", appearance: .dark,
            composition: .coralFeatherField,
            stops: [stop("#A5353C", 0), stop("#B43F43", 0.52), stop("#BC4848", 1)],
            atmosphere: ["#D66358", "#2BA5A1"], atmosphereOpacities: [0.10, 0.035],
            surfaceTexture: .featherFibers,
            surfaceInk: "#FFF5E8", onChromeInk: "#FFF5E8", chrome: "#0C6B4D",
            action: "#0C6B4D", detail: "#2BA5A1", secondaryDetail: "#D4A42E",
            participants: ["#0C6B4D", "#20539A", "#142D4A", "#2BA5A1", "#D4A42E"],
            finish: .peacockJewelEnamel, pinballMaterial: .emeraldEnamel,
            ball: "#0C6B4D", ballEdge: "#064832", ballTail: "#2BA5A1", ballImpact: "#D4A42E",
            divider: "#FFF5E8", dividerSecondary: "#064832",
            textureOpacity: 0.032, separatorOpacity: 0.38, dividerOpacity: 0.38
        ),
        ExpectedTheme(
            theme: .wingspanHummingbirds, name: "Wingspan Americas", appearance: .dark,
            composition: .brightLeafField,
            stops: [stop("#37AD4B", 0), stop("#25A047", 0.55), stop("#16883E", 1)],
            atmosphere: ["#0B6D35", "#EF4770"], atmosphereOpacities: [0.16, 0.025],
            surfaceTexture: .leafFibers,
            surfaceInk: "#0B2B21", onChromeInk: "#FFF9E9", chrome: "#075D38",
            action: "#EF4770", detail: "#E85A3B", secondaryDetail: "#F1D35A",
            participants: ["#075D38", "#EF4770", "#E85A3B", "#F1D35A", "#0A7880"],
            finish: .featherJewelEnamel, pinballMaterial: .flamingoEnamel,
            ball: "#EF4770", ballEdge: "#A92E51", ballTail: "#EF4770", ballImpact: "#E85A3B",
            divider: "#0B2B21", dividerSecondary: "#FFF9E9",
            textureOpacity: 0.028, separatorOpacity: 0.36, dividerOpacity: 0.58
        ),
        ExpectedTheme(
            theme: .nidavellir, name: "Nidavellir", appearance: .light,
            composition: .parchmentMedallion,
            stops: [stop("#F3F1EC", 0), stop("#DDDCD8", 1)],
            atmosphere: ["#32383C", "#956C4D"], atmosphereOpacities: [0.18, 0.12],
            surfaceTexture: .parchmentPatina,
            surfaceInk: "#24292C", onChromeInk: "#F3F0E9", chrome: "#343A3D",
            action: "#B87945", detail: "#788B94", secondaryDetail: "#956C4D",
            participants: ["#B96D38", "#C6A44D", "#607B8C", "#A54D45", "#58715E"],
            finish: .hammeredMetal, pinballMaterial: .agedCopper,
            ball: "#B87945", ballEdge: "#704328", ballTail: "#B87945", ballImpact: "#788B94",
            divider: "#24292C", dividerSecondary: "#F3F0E9",
            textureOpacity: 0.040, separatorOpacity: 0.36, dividerOpacity: 0.38
        ),
        ExpectedTheme(
            theme: .concordia, name: "Concordia", appearance: .light,
            composition: .warmFrescoMedallion,
            stops: [stop("#C4815E", 0), stop("#E2B98B", 1)],
            atmosphere: ["#701426", "#8BC4DD", "#F5E7CB"], atmosphereOpacities: [0.24, 0.12, 0.14],
            surfaceTexture: .frescoGrain,
            surfaceInk: "#4C1820", onChromeInk: "#FFF0D5", chrome: "#701426",
            action: "#D7AA34", detail: "#6EAECB", secondaryDetail: "#F5E7CB",
            participants: ["#B73F45", "#3D7EA6", "#72863F", "#D2A52E", "#57515A"],
            finish: .frescoEnamel, pinballMaterial: .romanGold,
            ball: "#D7AA34", ballEdge: "#896716", ballTail: "#D7AA34", ballImpact: "#6EAECB",
            divider: "#701426", dividerSecondary: "#F5E7CB",
            textureOpacity: 0.034, separatorOpacity: 0.36, dividerOpacity: 0.54
        ),
        ExpectedTheme(
            theme: .everdell, name: "Everdell", appearance: .dark,
            composition: .goldenForestClearing,
            stops: [stop("#D6B34A", 0), stop("#43542D", 0.58), stop("#102518", 1)],
            atmosphere: ["#795035", "#88B7C2"], atmosphereOpacities: [0.10, 0.055],
            surfaceTexture: .pressedPaper,
            surfaceInk: "#F3EBC9", onChromeInk: "#F3EBC9", chrome: "#203821",
            action: "#D5892D", detail: "#88B7C2", secondaryDetail: "#795035",
            participants: ["#5E743B", "#795035", "#88B7C2", "#D37A2C", "#963F50"],
            finish: .pressedWoodPaper, pinballMaterial: .amberResin,
            ball: "#D5892D", ballEdge: "#85521B", ballTail: "#D5892D", ballImpact: "#88B7C2",
            divider: "#102417", dividerSecondary: "#F3EBC9",
            textureOpacity: 0.036, separatorOpacity: 0.38, dividerOpacity: 0.58
        ),
        ExpectedTheme(
            theme: .lizardWizard, name: "Lizard Wizard", appearance: .dark,
            composition: .midnightRedEdge,
            stops: [stop("#111B38", 0), stop("#080E25", 1)],
            atmosphere: ["#A32F39", "#F6F0E5"], atmosphereOpacities: [0.34, 0.065],
            surfaceTexture: .midnightSpeckle,
            surfaceInk: "#F6F0E5", onChromeInk: "#F6F0E5", chrome: "#A32F39",
            action: "#D99B2F", detail: "#1697A9", secondaryDetail: "#72813A",
            participants: ["#1697A9", "#22776F", "#A93842", "#D99B2F", "#72813A"],
            finish: .midnightEnamel, pinballMaterial: .manaEnamel,
            ball: "#1697A9", ballEdge: "#0C5966", ballTail: "#1697A9", ballImpact: "#D99B2F",
            divider: "#F6F0E5", dividerSecondary: "#080E25",
            textureOpacity: 0.030, separatorOpacity: 0.38, dividerOpacity: 0.36
        ),
        ExpectedTheme(
            theme: .leaders, name: "Leaders", appearance: .light,
            composition: .layeredScreenprint,
            stops: [stop("#F1E6D3", 0), stop("#E8DDCB", 0.62), stop("#D9E6DF", 1)],
            atmosphere: ["#43B2BA", "#C73366"], atmosphereOpacities: [0.08, 0.035],
            surfaceTexture: .screenprintRegistration,
            surfaceInk: "#053842", onChromeInk: "#FFF7E9", chrome: "#08747C",
            action: "#D28D00", detail: "#C73366", secondaryDetail: "#43B2BA",
            participants: ["#08747C", "#43B2BA", "#053842", "#C73366", "#D28D00"],
            finish: .flatScreenprint, pinballMaterial: .saffronScreenprint,
            ball: "#D28D00", ballEdge: "#815700", ballTail: "#D28D00", ballImpact: "#C73366",
            divider: "#053842", dividerSecondary: "#FFF7E9",
            textureOpacity: 0.024, separatorOpacity: 0.30, dividerOpacity: 0.32
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
            "concordia", "everdell", "lizard-wizard", "leaders"
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
        XCTAssertEqual(Set(expectedThemes.map { $0.composition }).count, 8)
        XCTAssertEqual(Set(expectedThemes.map { $0.surfaceTexture }).count, 8)
        XCTAssertEqual(Set(expectedThemes.map { $0.stops.map(\.hex).joined(separator: ":") }).count, 8)
        XCTAssertEqual(Set(expectedThemes.map(\.finish)).count, 8)
        XCTAssertEqual(Set(expectedThemes.map(\.pinballMaterial)).count, 8)
        XCTAssertEqual(Set(ChooserColorTheme.allCases.map { $0.visualTheme.textureSeed }).count, 8)

        for expected in expectedThemes {
            XCTAssertEqual(expected.participants.count, 5)
            XCTAssertEqual(Set(expected.participants).count, 5, expected.name)
            XCTAssertGreaterThanOrEqual(expected.stops.count, 2, expected.name)
            XCTAssertNotEqual(expected.stops.first?.hex, expected.stops.last?.hex, expected.name)
        }

        XCTAssertEqual(
            ChooserColorTheme.allCases.filter { $0.appearance == .light },
            [.wingspanOriginal, .nidavellir, .concordia, .leaders]
        )
        XCTAssertEqual(ChooserColorTheme.allCases.filter { $0.appearance == .dark }.count, 4)
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

        XCTAssertEqual(ChooserColorTheme.everdell.informationPanelHex, "#102518")
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

    func testBoardPieceGeometryUsesBroadBandsAndRestrainedWinnerScale() {
        XCTAssertEqual(BoardPieceVisualMetrics.bandWidth(for: 100), 18, accuracy: 0.001)
        XCTAssertEqual(BoardPieceVisualMetrics.bandWidth(for: 160), 20, accuracy: 0.001)
        XCTAssertEqual(BoardPieceVisualMetrics.bandWidth(for: 176), 22, accuracy: 0.001)
        XCTAssertEqual(BoardPieceVisualMetrics.bandWidth(for: 240), 22, accuracy: 0.001)
        XCTAssertEqual(BoardPieceVisualMetrics.chitRimWidth(for: 50), 7, accuracy: 0.001)
        XCTAssertEqual(BoardPieceVisualMetrics.chitRimWidth(for: 120), 9, accuracy: 0.001)
        XCTAssertEqual(BoardPieceVisualMetrics.ringTextureOpacity(from: 0.05), 0.0675, accuracy: 0.000_001)
        XCTAssertEqual(BoardPieceVisualMetrics.ringTextureOpacity(from: 0.10), 0.12, accuracy: 0.000_001)
        XCTAssertEqual(BoardPieceVisualMetrics.chitTextureOpacity(from: 0.05), 0.059, accuracy: 0.000_001)
        XCTAssertEqual(BoardPieceVisualMetrics.maximumScale(for: .winner), 1.06, accuracy: 0.001)
        XCTAssertEqual(BoardPieceVisualMetrics.renderingOverflow(for: 44, emphasis: .resting), 12)
        XCTAssertEqual(BoardPieceVisualMetrics.renderingOverflow(for: 176, emphasis: .winner), 20)
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
