import SwiftUI
import UIKit
import XCTest
@testable import App

/// Renders every world's board surface to PNG files so the subject art can be
/// looked at, not just compiled. Portrait phone, landscape phone and a
/// Settings-tile miniature of each world land in
/// `/private/tmp/whos-first-world-renders/<world>-<variant>.png`.
///
/// This is a visual check for authoring, not a regression gate: nothing is
/// compared, so the tests only fail when a board cannot render at all.
@MainActor
final class BoardSubjectArtRenderTests: XCTestCase {
    static let outputDirectory = URL(fileURLWithPath: "/private/tmp/whos-first-world-renders", isDirectory: true)

    private static let variants: [(name: String, size: CGSize)] = [
        ("portrait", CGSize(width: 390, height: 844)),
        ("landscape", CGSize(width: 844, height: 390)),
        ("tile", CGSize(width: 104, height: 132))
    ]

    func testEveryWorldDeclaresItsOwnSubject() {
        XCTAssertEqual(
            Set(ChooserColorTheme.allCases.map { $0.visualTheme.subjectArt }).count,
            ChooserColorTheme.allCases.count
        )
        XCTAssertEqual(Set(ChooserColorTheme.allCases.map { $0.visualTheme.subjectArt }), Set(BoardSubjectArt.allCases))
    }

    func testRender_wingspanOriginal() throws { try render(.wingspanOriginal) }
    func testRender_wingspanAsia() throws { try render(.wingspanNectar) }
    func testRender_wingspanAmericas() throws { try render(.wingspanHummingbirds) }
    func testRender_nidavellir() throws { try render(.nidavellir) }
    func testRender_concordia() throws { try render(.concordia) }
    func testRender_everdell() throws { try render(.everdell) }
    func testRender_lizardWizard() throws { try render(.lizardWizard) }
    func testRender_leaders() throws { try render(.leaders) }
    func testRender_resArcana() throws { try render(.resArcana) }
    func testRender_everdellEmerland() throws { try render(.everdellEmerland) }
    func testRender_sagrada() throws { try render(.sagrada) }
    func testRender_wyrmspan() throws { try render(.wyrmspan) }
    func testRender_harmonies() throws { try render(.harmonies) }
    func testRender_finspan() throws { try render(.finspan) }

    private func render(_ theme: ChooserColorTheme) throws {
        try FileManager.default.createDirectory(at: Self.outputDirectory, withIntermediateDirectories: true)
        for variant in Self.variants {
            let renderer = ImageRenderer(
                content: WorldRenderReference(theme: theme, size: variant.size)
                    .frame(width: variant.size.width, height: variant.size.height)
                    .environment(\.colorScheme, theme.preferredColorScheme)
            )
            renderer.scale = variant.name == "tile" ? 3 : 2
            let image = try XCTUnwrap(renderer.uiImage, "Could not render \(theme.name) \(variant.name)")
            let data = try XCTUnwrap(image.pngData())
            try data.write(to: Self.outputDirectory.appendingPathComponent("\(theme.rawValue)-\(variant.name).png"))
        }
    }
}

/// The board with three resting rings on it, so the subject can be judged
/// under the pieces it has to live with.
private struct WorldRenderReference: View {
    let theme: ChooserColorTheme
    let size: CGSize

    var body: some View {
        ZStack {
            BoardSurfaceView(theme: theme)
            if size.width > 200 {
                let diameter = min(size.width, size.height) * 0.40
                let positions: [CGPoint] = size.width > size.height
                    ? [CGPoint(x: 0.22, y: 0.50), CGPoint(x: 0.50, y: 0.48), CGPoint(x: 0.78, y: 0.50)]
                    : [CGPoint(x: 0.30, y: 0.30), CGPoint(x: 0.68, y: 0.52), CGPoint(x: 0.34, y: 0.76)]
                ForEach(Array(positions.enumerated()), id: \.offset) { index, unit in
                    BoardRingView(
                        diameter: diameter,
                        lineWidth: BoardPieceVisualMetrics.bandWidth(for: diameter),
                        style: .participant(theme: theme, index: index),
                        emphasis: index == 1 ? .winner : .resting,
                        accessibilityLabel: "Reference ring"
                    )
                    .position(x: unit.x * size.width, y: unit.y * size.height)
                }
            }
        }
        .clipped()
    }
}
