import CoreGraphics
import Foundation

/// Deterministic leaded-glass shards for the Sagrada world: a Voronoi diagram
/// built by clipping a bounding polygon with the perpendicular bisector of
/// every other site. Pure and dependency-free, so phone, iPad and Settings
/// miniatures all draw the same pattern for a seed, scaled to their size.
///
/// Sites are kept out of a central disc so the rose window owns the middle of
/// the board; the shards behind it are simply covered.
public struct LeadedGlassTessellation: Equatable, Sendable {
    public struct Cell: Equatable, Sendable {
        /// Polygon vertices in board coordinates, in order.
        public let vertices: [CGPoint]
        /// Index into the authored pane palette.
        public let paletteIndex: Int
    }

    public let size: CGSize
    public let cells: [Cell]

    /// - Parameters:
    ///   - size: The board size the cells should cover.
    ///   - seed: The theme's texture seed, so the pattern is stable.
    ///   - clearRadius: Sites closer than this to `clearCenter` are skipped.
    ///   - paletteCount: How many pane colors the caller will cycle through.
    public init(
        size: CGSize,
        seed: UInt64,
        clearCenter: CGPoint,
        clearRadius: CGFloat,
        paletteCount: Int
    ) {
        self.size = size
        guard size.width > 0, size.height > 0, paletteCount > 0 else {
            cells = []
            return
        }

        // Shard size follows the short edge, so a phone and a 13-inch iPad get
        // the same number of shards across rather than a dense mosaic.
        let shortEdge = min(size.width, size.height)
        let minimumSpacing = max(8, shortEdge * 0.15)
        let margin = minimumSpacing * 0.4
        let targetCount = Int((size.width * size.height) / (minimumSpacing * minimumSpacing) * 0.9)

        var generator = SeededGenerator(seed: seed)
        var sites: [CGPoint] = []
        var attempts = 0
        while sites.count < max(6, targetCount), attempts < 6_000 {
            attempts += 1
            let candidate = CGPoint(
                x: -margin + generator.unit() * (size.width + margin * 2),
                y: -margin + generator.unit() * (size.height + margin * 2)
            )
            if hypot(candidate.x - clearCenter.x, candidate.y - clearCenter.y) < clearRadius {
                continue
            }
            if sites.allSatisfy({ hypot($0.x - candidate.x, $0.y - candidate.y) >= minimumSpacing }) {
                sites.append(candidate)
            }
        }

        let bounds = [
            CGPoint(x: -margin * 2, y: -margin * 2),
            CGPoint(x: size.width + margin * 2, y: -margin * 2),
            CGPoint(x: size.width + margin * 2, y: size.height + margin * 2),
            CGPoint(x: -margin * 2, y: size.height + margin * 2)
        ]

        var built: [Cell] = []
        for (index, site) in sites.enumerated() {
            var polygon = bounds
            for (otherIndex, other) in sites.enumerated() where otherIndex != index {
                // Keep the half-plane closer to `site`: a·p <= c.
                let a = CGPoint(x: other.x - site.x, y: other.y - site.y)
                let c = (other.x * other.x + other.y * other.y - site.x * site.x - site.y * site.y) / 2
                polygon = Self.clip(polygon, a: a, c: c)
                if polygon.isEmpty { break }
            }
            guard polygon.count >= 3 else { continue }
            built.append(Cell(
                vertices: polygon,
                paletteIndex: Int(generator.unit() * CGFloat(paletteCount)) % paletteCount
            ))
        }
        cells = built
    }

    /// Sutherland–Hodgman against one half-plane.
    static func clip(_ polygon: [CGPoint], a: CGPoint, c: CGFloat) -> [CGPoint] {
        guard !polygon.isEmpty else { return [] }
        var output: [CGPoint] = []
        for index in polygon.indices {
            let current = polygon[index]
            let next = polygon[(index + 1) % polygon.count]
            let currentValue = a.x * current.x + a.y * current.y - c
            let nextValue = a.x * next.x + a.y * next.y - c
            if currentValue <= 0 { output.append(current) }
            if (currentValue < 0) != (nextValue < 0), currentValue != nextValue {
                let t = currentValue / (currentValue - nextValue)
                output.append(CGPoint(
                    x: current.x + t * (next.x - current.x),
                    y: current.y + t * (next.y - current.y)
                ))
            }
        }
        return output
    }

    /// Signed-area magnitude, used by tests to prove the cells tile the board.
    public static func area(of polygon: [CGPoint]) -> CGFloat {
        guard polygon.count >= 3 else { return 0 }
        var sum: CGFloat = 0
        for index in polygon.indices {
            let p = polygon[index]
            let q = polygon[(index + 1) % polygon.count]
            sum += p.x * q.y - q.x * p.y
        }
        return abs(sum) / 2
    }

    private struct SeededGenerator {
        private var state: UInt64

        init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }

        mutating func unit() -> CGFloat {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return CGFloat(Double(state >> 11) / Double(1 << 53))
        }
    }
}
