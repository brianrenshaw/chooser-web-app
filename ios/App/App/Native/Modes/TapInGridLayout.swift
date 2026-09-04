import CoreGraphics

public struct TapInGridResult: Equatable, Sendable {
    public let diameter: CGFloat
    public let positions: [CGPoint]
}

public enum TapInGridLayout {
    /// Takes a scale rather than a size on purpose. The size already drives the
    /// cell fit inside `make`, and passing it twice would let the two disagree
    /// about which board this is.
    public static func preferredRingDiameter(for count: Int, scale: CGFloat = 1) -> CGFloat {
        let s = max(1, scale)
        guard count > 5 else { return 156 * s }
        return max(48 * s, (156 * s * sqrt(5 / CGFloat(count))).rounded())
    }

    /// `scale` defaults to the one derived from `size`, so both call sites stay
    /// correct without repeating the derivation; the onboarding miniature passes
    /// `1` explicitly because it must show the layout the player will meet.
    public static func make(
        count: Int,
        in size: CGSize,
        scale: CGFloat? = nil
    ) -> TapInGridResult {
        let scale = scale ?? BoardPieceVisualMetrics.boardScale(for: size)
        guard count > 0, size.width > 0, size.height > 0 else {
            return TapInGridResult(diameter: 156 * max(1, scale), positions: [])
        }

        let horizontalPadding: CGFloat = (size.width > size.height ? 8 : 16) * scale
        let verticalPadding: CGFloat = 8 * scale
        let gap: CGFloat = (count >= 30 ? 6 : (count >= 12 ? 8 : 12)) * scale
        let usableWidth = max(1, size.width - horizontalPadding * 2)
        let usableHeight = max(1, size.height - verticalPadding * 2)
        let preferred = preferredRingDiameter(for: count, scale: scale)

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
            diameter: diameter,
            scale: scale
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
                diameter: diameter,
                scale: scale
            )
        }

        return TapInGridResult(diameter: diameter, positions: positions)
    }

    /// The diameter of the revealed winner.
    ///
    /// The `max` against the grid diameter is the point of the function. At low
    /// entry counts on a large board the grid already draws chits bigger than
    /// the winner cap, and without this the chosen chit would visibly *shrink*
    /// at the exact moment it is announced — an anticlimax at the one frame the
    /// whole mode exists to deliver.
    public static func winnerDiameter(
        gridDiameter: CGFloat,
        in size: CGSize,
        scale: CGFloat = 1
    ) -> CGFloat {
        let s = max(1, scale)
        let capped = min(
            172 * s,
            max(104 * s, min(size.width, size.height) - 56 * s)
        )
        return max(capped, gridDiameter)
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
        diameter: CGFloat,
        scale: CGFloat
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
                margin: 0,
                scale: scale
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
