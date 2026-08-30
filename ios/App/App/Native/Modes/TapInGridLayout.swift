import CoreGraphics

public struct TapInGridResult: Equatable, Sendable {
    public let diameter: CGFloat
    public let positions: [CGPoint]
}

public enum TapInGridLayout {
    public static func preferredRingDiameter(for count: Int) -> CGFloat {
        guard count > 5 else { return 140 }
        return max(44, (140 * sqrt(5 / CGFloat(count))).rounded())
    }

    public static func make(count: Int, in size: CGSize) -> TapInGridResult {
        guard count > 0, size.width > 0, size.height > 0 else {
            return TapInGridResult(diameter: 140, positions: [])
        }

        let horizontalPadding: CGFloat = 16
        let verticalPadding: CGFloat = 8
        let gap: CGFloat = count > 30 ? 4 : 8
        let usableWidth = max(1, size.width - horizontalPadding * 2)
        let usableHeight = max(1, size.height - verticalPadding * 2)
        let preferred = preferredRingDiameter(for: count)

        var bestColumns = 1
        var bestDiameter: CGFloat = 0
        for columns in 1...count {
            let rows = Int(ceil(Double(count) / Double(columns)))
            let cellWidth = usableWidth / CGFloat(columns)
            let cellHeight = usableHeight / CGFloat(rows)
            let diameter = min(preferred, cellWidth - gap, cellHeight - gap)
            if diameter > bestDiameter {
                bestDiameter = diameter
                bestColumns = columns
            }
        }

        // 36 points is the smallest usable visual token on compact landscape
        // phones. The fitting search normally stays above it; the lower clamp
        // protects only degenerate preview sizes.
        let diameter = max(36, bestDiameter)
        let rows = Int(ceil(Double(count) / Double(bestColumns)))
        let cellWidth = usableWidth / CGFloat(bestColumns)
        let cellHeight = usableHeight / CGFloat(rows)
        var positions: [CGPoint] = []
        positions.reserveCapacity(count)

        for index in 0..<count {
            let row = index / bestColumns
            let column = index % bestColumns
            let itemsInRow = min(bestColumns, count - row * bestColumns)
            let rowWidth = CGFloat(itemsInRow) * cellWidth
            let rowStart = horizontalPadding + (usableWidth - rowWidth) / 2
            positions.append(
                CGPoint(
                    x: rowStart + (CGFloat(column) + 0.5) * cellWidth,
                    y: verticalPadding + (CGFloat(row) + 0.5) * cellHeight
                )
            )
        }

        return TapInGridResult(diameter: diameter, positions: positions)
    }
}
