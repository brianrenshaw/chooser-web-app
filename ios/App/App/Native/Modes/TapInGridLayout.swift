import CoreGraphics

public struct TapInGridResult: Equatable, Sendable {
    public let diameter: CGFloat
    public let positions: [CGPoint]
}

public enum TapInGridLayout {
    public static func preferredRingDiameter(for count: Int) -> CGFloat {
        guard count > 5 else { return 156 }
        return max(48, (156 * sqrt(5 / CGFloat(count))).rounded())
    }

    public static func make(count: Int, in size: CGSize) -> TapInGridResult {
        guard count > 0, size.width > 0, size.height > 0 else {
            return TapInGridResult(diameter: 156, positions: [])
        }

        let horizontalPadding: CGFloat = size.width > size.height ? 8 : 16
        let verticalPadding: CGFloat = 8
        let gap: CGFloat = count >= 30 ? 6 : (count >= 12 ? 8 : 12)
        let usableWidth = max(1, size.width - horizontalPadding * 2)
        let usableHeight = max(1, size.height - verticalPadding * 2)
        let preferred = preferredRingDiameter(for: count)

        var bestColumns = 1
        var bestDiameter: CGFloat = 0
        for columns in 1...count {
            let rows = Int(ceil(Double(count) / Double(columns)))
            let cellWidth = usableWidth / CGFloat(columns)
            let cellHeight = usableHeight / CGFloat(rows)
            // Core circles stay distinct; their soft light is intentionally
            // allowed to mingle, as it does in the original web experience.
            let diameter = min(preferred, cellWidth - gap, cellHeight - gap)
            guard diameter > 0 else { continue }
            if diameter > bestDiameter {
                bestDiameter = diameter
                bestColumns = columns
            }
        }

        // Never force a minimum larger than the winning cell. Real supported
        // iPhone playfields stay comfortably above 32 points at 50 entries,
        // while tiny previews remain geometrically correct instead of clipping.
        var diameter = max(1, floor(bestDiameter))
        let rows = Int(ceil(Double(count) / Double(bestColumns)))
        let cellWidth = usableWidth / CGFloat(bestColumns)
        let cellHeight = usableHeight / CGFloat(rows)
        var positions = settledPositions(
            count: count,
            columns: bestColumns,
            cellWidth: cellWidth,
            cellHeight: cellHeight,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding,
            usableWidth: usableWidth,
            size: size,
            diameter: diameter
        )

        // Edge clamping can move the first or last item a few points toward its
        // neighbor. Resolve that small compression into the core diameter while
        // leaving the much softer halos free to overlap.
        for _ in 0..<4 {
            guard let closest = closestDistance(in: positions), closest + 0.1 < diameter else {
                break
            }
            diameter = max(1, floor(closest))
            positions = settledPositions(
                count: count,
                columns: bestColumns,
                cellWidth: cellWidth,
                cellHeight: cellHeight,
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
                usableWidth: usableWidth,
                size: size,
                diameter: diameter
            )
        }

        return TapInGridResult(diameter: diameter, positions: positions)
    }

    private static func settledPositions(
        count: Int,
        columns: Int,
        cellWidth: CGFloat,
        cellHeight: CGFloat,
        horizontalPadding: CGFloat,
        verticalPadding: CGFloat,
        usableWidth: CGFloat,
        size: CGSize,
        diameter: CGFloat
    ) -> [CGPoint] {
        (0..<count).map { index in
            let row = index / columns
            let column = index % columns
            let itemsInRow = min(columns, count - row * columns)
            let rowWidth = CGFloat(itemsInRow) * cellWidth
            let rowStart = horizontalPadding + (usableWidth - rowWidth) / 2
            let proposed = CGPoint(
                x: rowStart + (CGFloat(column) + 0.5) * cellWidth,
                y: verticalPadding + (CGFloat(row) + 0.5) * cellHeight
            )
            return BoardPieceVisualMetrics.clampedCenter(
                proposed,
                in: size,
                diameter: diameter,
                emphasis: .resting,
                externalScale: 1.05,
                margin: 0
            )
        }
    }

    private static func closestDistance(in positions: [CGPoint]) -> CGFloat? {
        guard positions.count > 1 else { return nil }
        var closest = CGFloat.greatestFiniteMagnitude
        for firstIndex in positions.indices {
            for secondIndex in positions.indices where secondIndex > firstIndex {
                let first = positions[firstIndex]
                let second = positions[secondIndex]
                closest = min(closest, hypot(first.x - second.x, first.y - second.y))
            }
        }
        return closest
    }
}
