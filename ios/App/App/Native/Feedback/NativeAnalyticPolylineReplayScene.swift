@preconcurrency import SpriteKit
import UIKit

public struct NativeReplayRegion {
    public let id: String
    public let polygon: [CGPoint]
    public let fillColor: UIColor
    public let strokeColor: UIColor
    public let lineWidth: CGFloat

    public init(
        id: String,
        polygon: [CGPoint],
        fillColor: UIColor,
        strokeColor: UIColor,
        lineWidth: CGFloat = 1.5
    ) {
        self.id = id
        self.polygon = polygon
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
    }
}

public struct NativeReplayWinnerFlash {
    public let id: String
    public let point: CGPoint?
    public let regionID: String?
    public let color: UIColor
    public let radius: CGFloat
    public let delay: TimeInterval
    public let repetitions: Int

    public init(
        id: String,
        point: CGPoint,
        color: UIColor = .systemYellow,
        radius: CGFloat = 34,
        delay: TimeInterval = 0,
        repetitions: Int = 2
    ) {
        self.id = id
        self.point = point
        self.regionID = nil
        self.color = color
        self.radius = radius
        self.delay = max(0, delay)
        self.repetitions = max(1, repetitions)
    }

    public init(
        id: String,
        regionID: String,
        color: UIColor = .systemYellow,
        radius: CGFloat = 34,
        delay: TimeInterval = 0,
        repetitions: Int = 2
    ) {
        self.id = id
        self.point = nil
        self.regionID = regionID
        self.color = color
        self.radius = radius
        self.delay = max(0, delay)
        self.repetitions = max(1, repetitions)
    }
}

public struct NativeReplayVisualStyle {
    public let backgroundColor: UIColor
    public let guideColor: UIColor
    public let trailColor: UIColor
    public let cursorColor: UIColor
    public let trailWidth: CGFloat
    public let trailGlowWidth: CGFloat
    public let cursorRadius: CGFloat
    public let showsGuide: Bool

    public init(
        backgroundColor: UIColor = .clear,
        guideColor: UIColor = UIColor.white.withAlphaComponent(0.12),
        trailColor: UIColor = .systemCyan,
        cursorColor: UIColor = .white,
        trailWidth: CGFloat = 4,
        trailGlowWidth: CGFloat = 10,
        cursorRadius: CGFloat = 7,
        showsGuide: Bool = true
    ) {
        self.backgroundColor = backgroundColor
        self.guideColor = guideColor
        self.trailColor = trailColor
        self.cursorColor = cursorColor
        self.trailWidth = trailWidth
        self.trailGlowWidth = trailGlowWidth
        self.cursorRadius = cursorRadius
        self.showsGuide = showsGuide
    }
}

public struct NativeAnalyticReplayPlan {
    public let polyline: [CGPoint]
    public let duration: TimeInterval
    public let regions: [NativeReplayRegion]
    public let winnerFlashes: [NativeReplayWinnerFlash]
    public let style: NativeReplayVisualStyle

    public init(
        polyline: [CGPoint],
        duration: TimeInterval,
        regions: [NativeReplayRegion] = [],
        winnerFlashes: [NativeReplayWinnerFlash] = [],
        style: NativeReplayVisualStyle = NativeReplayVisualStyle()
    ) {
        self.polyline = polyline
        self.duration = max(0, duration)
        self.regions = regions
        self.winnerFlashes = winnerFlashes
        self.style = style
    }
}

public struct NativeAnalyticReplayCallbacks {
    public var onProgress: (_ progress: Double, _ point: CGPoint) -> Void
    public var onWinnerFlash: (_ flashID: String) -> Void
    public var onFinished: () -> Void
    public var onCancelled: () -> Void

    public init(
        onProgress: @escaping (_ progress: Double, _ point: CGPoint) -> Void = { _, _ in },
        onWinnerFlash: @escaping (_ flashID: String) -> Void = { _ in },
        onFinished: @escaping () -> Void = {},
        onCancelled: @escaping () -> Void = {}
    ) {
        self.onProgress = onProgress
        self.onWinnerFlash = onWinnerFlash
        self.onFinished = onFinished
        self.onCancelled = onCancelled
    }
}

/// Maps analytics coordinates into SpriteKit scene coordinates. The scene size is supplied on
/// every rebuild so hosts can handle portrait, landscape, safe-area insets, or normalized data.
public typealias NativeReplayPointMapper = (_ analyticPoint: CGPoint, _ sceneSize: CGSize) -> CGPoint

/// Converts normalized elapsed time to normalized distance along the analytic polyline.
/// The identity default is constant speed; callers can inject an analytic deceleration curve.
public typealias NativeReplayProgressMapper = (_ normalizedTime: Double) -> Double

/// Deterministically samples a supplied polyline by arc length. It intentionally has no collision,
/// body, force, or simulation layer: playback is entirely analytic and time based.
public final class NativeAnalyticPolylineReplayScene: SKScene {
    private let regionLayer = SKNode()
    private let guideLayer = SKNode()
    private let replayLayer = SKNode()
    private let flashLayer = SKNode()

    private let guideNode = SKShapeNode()
    private let trailNode = SKShapeNode()
    private let cursorNode = SKShapeNode()

    private var rawPlan: NativeAnalyticReplayPlan?
    private var pointMapper: NativeReplayPointMapper = { point, _ in point }
    private var progressMapper: NativeReplayProgressMapper = { $0 }
    private var callbacks = NativeAnalyticReplayCallbacks()
    private var sampler = PolylineSampler(points: [])
    private var resolvedFlashes: [ResolvedFlash] = []

    private var replayStartTime: TimeInterval?
    private var replayIsActive = false
    private var currentProgress = 0.0

    public override init(size: CGSize) {
        super.init(size: size)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        scaleMode = .resizeFill
        backgroundColor = .clear
        addChild(regionLayer)
        addChild(guideLayer)
        addChild(replayLayer)
        addChild(flashLayer)

        guideNode.zPosition = 10
        trailNode.zPosition = 20
        cursorNode.zPosition = 30
        guideLayer.addChild(guideNode)
        replayLayer.addChild(trailNode)
        replayLayer.addChild(cursorNode)
    }

    /// Starts a replay. Points are interpreted in analytic space and transformed by `pointMapper`.
    public func replay(
        _ plan: NativeAnalyticReplayPlan,
        pointMapper: @escaping NativeReplayPointMapper = { point, _ in point },
        progressMapper: @escaping NativeReplayProgressMapper = { $0 },
        callbacks: NativeAnalyticReplayCallbacks = NativeAnalyticReplayCallbacks()
    ) {
        cancelReplay(notify: false)
        self.rawPlan = plan
        self.pointMapper = pointMapper
        self.progressMapper = progressMapper
        self.callbacks = callbacks
        currentProgress = 0
        replayStartTime = nil
        replayIsActive = !plan.polyline.isEmpty
        rebuildForCurrentSize()

        guard replayIsActive else {
            callbacks.onFinished()
            return
        }

        if plan.duration == 0 {
            render(progress: 1)
            finishReplay()
        } else {
            render(progress: 0)
        }
    }

    public func cancelReplay() {
        cancelReplay(notify: true)
    }

    public override func update(_ currentTime: TimeInterval) {
        guard replayIsActive, let plan = rawPlan else { return }

        if replayStartTime == nil {
            replayStartTime = currentTime
        }
        let elapsed = currentTime - (replayStartTime ?? currentTime)
        let normalizedTime = min(1, max(0, elapsed / max(plan.duration, .leastNonzeroMagnitude)))
        render(progress: min(1, max(0, progressMapper(normalizedTime))))

        if normalizedTime >= 1 {
            finishReplay()
        }
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard rawPlan != nil else { return }
        rebuildForCurrentSize()
        render(progress: currentProgress)
        if !replayIsActive && currentProgress >= 1 {
            drawWinnerFlashes(notify: false)
        }
    }

    private func rebuildForCurrentSize() {
        guard let plan = rawPlan else { return }
        backgroundColor = plan.style.backgroundColor
        flashLayer.removeAllChildren()

        let mappedPoints = plan.polyline.map { pointMapper($0, size) }
        sampler = PolylineSampler(points: mappedPoints)

        regionLayer.removeAllChildren()
        for (index, region) in plan.regions.enumerated() {
            let mappedPolygon = region.polygon.map { pointMapper($0, size) }
            guard let path = polygonPath(points: mappedPolygon) else { continue }
            let node = SKShapeNode(path: path)
            node.name = "region:\(region.id)"
            node.fillColor = region.fillColor
            node.strokeColor = region.strokeColor
            node.lineWidth = region.lineWidth
            node.lineJoin = .round
            node.zPosition = CGFloat(index)
            regionLayer.addChild(node)
        }

        resolvedFlashes = plan.winnerFlashes.compactMap { flash in
            let analyticPoint: CGPoint?
            if let point = flash.point {
                analyticPoint = point
            } else if let regionID = flash.regionID,
                      let region = plan.regions.first(where: { $0.id == regionID }) {
                analyticPoint = centroid(of: region.polygon)
            } else {
                analyticPoint = nil
            }
            guard let analyticPoint else { return nil }
            return ResolvedFlash(
                id: flash.id,
                point: pointMapper(analyticPoint, size),
                color: flash.color,
                radius: flash.radius,
                delay: flash.delay,
                repetitions: flash.repetitions
            )
        }

        configureReplayNodes(style: plan.style)
    }

    private func configureReplayNodes(style: NativeReplayVisualStyle) {
        let fullPath = path(points: sampler.points)
        guideNode.path = style.showsGuide ? fullPath : nil
        guideNode.strokeColor = style.guideColor
        guideNode.lineWidth = max(1, style.trailWidth * 0.55)
        guideNode.lineCap = .round
        guideNode.lineJoin = .round

        trailNode.strokeColor = style.trailColor
        trailNode.lineWidth = style.trailWidth
        trailNode.glowWidth = style.trailGlowWidth
        trailNode.lineCap = .round
        trailNode.lineJoin = .round

        let radius = max(0, style.cursorRadius)
        cursorNode.path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        cursorNode.fillColor = style.cursorColor
        cursorNode.strokeColor = style.trailColor
        cursorNode.lineWidth = max(1, style.trailWidth * 0.45)
        cursorNode.glowWidth = max(2, style.trailGlowWidth * 0.75)
        cursorNode.isHidden = sampler.points.isEmpty || radius == 0
    }

    private func render(progress: Double) {
        guard !sampler.points.isEmpty else { return }
        currentProgress = min(1, max(0, progress))
        let prefix = sampler.prefix(at: currentProgress)
        trailNode.path = path(points: prefix)
        let point = sampler.point(at: currentProgress)
        cursorNode.position = point
        callbacks.onProgress(currentProgress, point)
    }

    private func finishReplay() {
        guard replayIsActive else { return }
        replayIsActive = false
        replayStartTime = nil
        if currentProgress < 1 {
            render(progress: 1)
        }
        drawWinnerFlashes(notify: true)
        callbacks.onFinished()
    }

    private func cancelReplay(notify: Bool) {
        let wasActive = replayIsActive
        replayIsActive = false
        replayStartTime = nil
        flashLayer.removeAllChildren()
        if notify && wasActive {
            callbacks.onCancelled()
        }
    }

    private func drawWinnerFlashes(notify: Bool) {
        flashLayer.removeAllChildren()
        for flash in resolvedFlashes {
            let node = SKShapeNode(circleOfRadius: flash.radius)
            node.name = "winner-flash:\(flash.id)"
            node.position = flash.point
            node.fillColor = flash.color.withAlphaComponent(0.18)
            node.strokeColor = flash.color
            node.lineWidth = 3
            node.glowWidth = 16
            node.alpha = 0
            node.zPosition = 100
            flashLayer.addChild(node)

            let pulse = SKAction.sequence([
                SKAction.group([
                    SKAction.fadeAlpha(to: 0.95, duration: 0.05),
                    SKAction.scale(to: 0.28, duration: 0)
                ]),
                SKAction.group([
                    SKAction.scale(to: 1.25, duration: 0.24),
                    SKAction.fadeOut(withDuration: 0.24)
                ])
            ])
            let repeated = SKAction.repeat(pulse, count: flash.repetitions)
            var actions: [SKAction] = [.wait(forDuration: flash.delay)]
            if notify {
                actions.append(.run { [weak self] in
                    self?.callbacks.onWinnerFlash(flash.id)
                })
            }
            actions.append(contentsOf: [repeated, .removeFromParent()])
            node.run(.sequence(actions))
        }
    }

    private func path(points: [CGPoint]) -> CGPath? {
        guard let first = points.first else { return nil }
        let result = CGMutablePath()
        result.move(to: first)
        for point in points.dropFirst() {
            result.addLine(to: point)
        }
        return result
    }

    private func polygonPath(points: [CGPoint]) -> CGPath? {
        guard points.count >= 3, let first = points.first else { return nil }
        let result = CGMutablePath()
        result.move(to: first)
        for point in points.dropFirst() {
            result.addLine(to: point)
        }
        result.closeSubpath()
        return result
    }

    private func centroid(of points: [CGPoint]) -> CGPoint? {
        guard !points.isEmpty else { return nil }
        let total = points.reduce(CGPoint.zero) { partial, point in
            CGPoint(x: partial.x + point.x, y: partial.y + point.y)
        }
        return CGPoint(x: total.x / CGFloat(points.count), y: total.y / CGFloat(points.count))
    }

    private struct ResolvedFlash {
        let id: String
        let point: CGPoint
        let color: UIColor
        let radius: CGFloat
        let delay: TimeInterval
        let repetitions: Int
    }
}

private struct PolylineSampler {
    let points: [CGPoint]
    private let cumulativeLengths: [CGFloat]
    private let totalLength: CGFloat

    init(points: [CGPoint]) {
        self.points = points
        guard !points.isEmpty else {
            cumulativeLengths = []
            totalLength = 0
            return
        }

        var cumulative: [CGFloat] = [0]
        cumulative.reserveCapacity(points.count)
        for index in 1..<points.count {
            let dx = points[index].x - points[index - 1].x
            let dy = points[index].y - points[index - 1].y
            cumulative.append(cumulative[index - 1] + hypot(dx, dy))
        }
        cumulativeLengths = cumulative
        totalLength = cumulative.last ?? 0
    }

    func point(at progress: Double) -> CGPoint {
        guard let first = points.first else { return .zero }
        guard points.count > 1, totalLength > 0 else { return first }

        let target = CGFloat(min(1, max(0, progress))) * totalLength
        let segment = segmentIndex(for: target)
        let startLength = cumulativeLengths[segment - 1]
        let endLength = cumulativeLengths[segment]
        let segmentLength = endLength - startLength
        guard segmentLength > 0 else { return points[segment] }
        let localProgress = (target - startLength) / segmentLength
        let start = points[segment - 1]
        let end = points[segment]
        return CGPoint(
            x: start.x + (end.x - start.x) * localProgress,
            y: start.y + (end.y - start.y) * localProgress
        )
    }

    func prefix(at progress: Double) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        guard points.count > 1, totalLength > 0 else { return [points[0]] }

        let target = CGFloat(min(1, max(0, progress))) * totalLength
        let segment = segmentIndex(for: target)
        var result = Array(points.prefix(segment))
        let interpolated = point(at: progress)
        if result.last != interpolated {
            result.append(interpolated)
        }
        return result
    }

    private func segmentIndex(for target: CGFloat) -> Int {
        guard cumulativeLengths.count > 1 else { return 0 }
        var lower = 1
        var upper = cumulativeLengths.count - 1
        while lower < upper {
            let middle = (lower + upper) / 2
            if cumulativeLengths[middle] < target {
                lower = middle + 1
            } else {
                upper = middle
            }
        }
        return lower
    }
}
