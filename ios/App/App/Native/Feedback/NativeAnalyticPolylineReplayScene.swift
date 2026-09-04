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
    public let ballEdgeColor: UIColor
    public let impactColor: UIColor
    public let ballMaterial: PinballMaterialKind?
    public let trailWidth: CGFloat
    public let trailGlowWidth: CGFloat
    public let cursorRadius: CGFloat
    public let showsGuide: Bool
    public let settlesAtEndpoint: Bool
    public let reducesMotion: Bool
    /// Accessibility preferences, carried as plain Bools rather than as a
    /// `BoardAccessibilityAppearancePolicy` because that type is internal and
    /// this style is public. The scene composes the policy from these.
    public let increasesContrast: Bool
    public let reducesTransparency: Bool
    public let differentiatesWithoutColor: Bool

    public init(
        backgroundColor: UIColor = .clear,
        guideColor: UIColor = UIColor.white.withAlphaComponent(0.12),
        trailColor: UIColor = .systemCyan,
        cursorColor: UIColor = .white,
        ballEdgeColor: UIColor? = nil,
        impactColor: UIColor? = nil,
        ballMaterial: PinballMaterialKind? = nil,
        trailWidth: CGFloat = 4,
        trailGlowWidth: CGFloat = 10,
        cursorRadius: CGFloat = 7,
        showsGuide: Bool = true,
        settlesAtEndpoint: Bool = false,
        reducesMotion: Bool = false,
        increasesContrast: Bool = false,
        reducesTransparency: Bool = false,
        differentiatesWithoutColor: Bool = false
    ) {
        self.backgroundColor = backgroundColor
        self.guideColor = guideColor
        self.trailColor = trailColor
        self.cursorColor = cursorColor
        self.ballEdgeColor = ballEdgeColor ?? trailColor
        self.impactColor = impactColor ?? trailColor
        self.ballMaterial = ballMaterial
        self.trailWidth = trailWidth
        self.trailGlowWidth = trailGlowWidth
        self.cursorRadius = cursorRadius
        self.showsGuide = showsGuide
        self.settlesAtEndpoint = settlesAtEndpoint
        self.reducesMotion = reducesMotion
        self.increasesContrast = increasesContrast
        self.reducesTransparency = reducesTransparency
        self.differentiatesWithoutColor = differentiatesWithoutColor
    }
}

/// Shared physical dimensions for the SpriteKit ball and its collision
/// playfield. Hosts should inset their analytic partition by `collisionInset`.
public enum NativePinballReplayMetrics {
    public static let ballDiameter: CGFloat = 30
    public static let collisionInset: CGFloat = 18
    public static let minimumTailLength: CGFloat = 12
    public static let maximumTailLength: CGFloat = 40
    public static let compressionDuration: TimeInterval = 0.025
    public static let reboundDuration: TimeInterval = 0.060
    public static let settleDuration: TimeInterval = 0.080
    public static let endpointCompressionDuration: TimeInterval = 0.060
    public static let endpointReboundDuration: TimeInterval = 0.090
    public static let endpointRecoveryDuration: TimeInterval = 0.120
    public static let endpointSettleDuration: TimeInterval =
        endpointCompressionDuration + endpointReboundDuration + endpointRecoveryDuration
    public static let maximumImpactTangentScale: CGFloat = 1.08
    public static let auraRadiusScale: CGFloat = 0.96
    public static let auraOffset: CGFloat = 1.5

    /// Includes the widest authored ball edge, contact shadow, collision
    /// compression, and rebound. This must remain within `collisionInset`.
    public static let maximumRenderedRadius: CGFloat = {
        let faceAndEdge = (ballDiameter / 2 + 1.25) * maximumImpactTangentScale
        let aura = (ballDiameter / 2 * auraRadiusScale + auraOffset) * maximumImpactTangentScale
        return max(faceAndEdge, aura)
    }()
}

/// A seat ring the analytic marcher recorded the ball bouncing off.
///
/// Authored by the host from `PinballTrajectory.vertexKinds` and keyed by
/// polyline vertex index, the same side-channel discipline as
/// `fairnessDeflectorVertexIndex`. The scene cannot derive this: reflection-sign
/// analysis drops a glancing circular bounce and misreads a steep one as a wall.
public struct NativeReplayBumperMark: Equatable, Sendable {
    public let seatID: Int
    /// Ring center in analytic coordinates; mapped through the point mapper.
    public let center: CGPoint
    /// Ring radius in analytic units. Only a fallback: the scene prefers a
    /// radius measured from the mapped contact point, which survives any mapper.
    public let radius: CGFloat

    public init(seatID: Int, center: CGPoint, radius: CGFloat) {
        self.seatID = seatID
        self.center = center
        self.radius = radius
    }
}

public struct NativeAnalyticReplayPlan {
    public let polyline: [CGPoint]
    public let duration: TimeInterval
    /// Index in `polyline` of the one disclosed fairness deflector. It is not
    /// rendered as an ordinary wall impact even though it occurs on an edge.
    public let fairnessDeflectorVertexIndex: Int?
    /// Seat rings struck along the path, keyed by `polyline` vertex index.
    public let bumperMarks: [Int: NativeReplayBumperMark]
    public let regions: [NativeReplayRegion]
    public let winnerFlashes: [NativeReplayWinnerFlash]
    public let style: NativeReplayVisualStyle

    public init(
        polyline: [CGPoint],
        duration: TimeInterval,
        fairnessDeflectorVertexIndex: Int? = nil,
        bumperMarks: [Int: NativeReplayBumperMark] = [:],
        regions: [NativeReplayRegion] = [],
        winnerFlashes: [NativeReplayWinnerFlash] = [],
        style: NativeReplayVisualStyle = NativeReplayVisualStyle()
    ) {
        self.polyline = polyline
        self.duration = max(0, duration)
        self.fairnessDeflectorVertexIndex = fairnessDeflectorVertexIndex
        self.bumperMarks = bumperMarks
        self.regions = regions
        self.winnerFlashes = winnerFlashes
        self.style = style
    }
}

/// A wall contact emitted on the exact SpriteKit frame that presents it.
/// `vertexIndex` identifies the immutable analytic polyline vertex, allowing
/// hosts to de-duplicate callbacks without making rendered timing authoritative
/// for winner selection or endpoint geometry.
public struct NativeAnalyticReplayImpact: Equatable, Sendable {
    public let vertexIndex: Int
    public let progress: Double
    public let speedFraction: Double
    /// The incoming velocity component perpendicular to the contacted wall,
    /// normalized to `0...1`. A glancing contact is deliberately lighter than
    /// a head-on hit even when both occur at the same travel speed.
    public let wallNormalImpulseFraction: Double
    public let isCorner: Bool
    public let isFairnessDeflection: Bool

    public init(
        vertexIndex: Int,
        progress: Double,
        speedFraction: Double,
        wallNormalImpulseFraction: Double = 1,
        isCorner: Bool,
        isFairnessDeflection: Bool = false
    ) {
        self.vertexIndex = vertexIndex
        self.progress = progress
        self.speedFraction = speedFraction
        self.wallNormalImpulseFraction = min(1, max(0, wallNormalImpulseFraction))
        self.isCorner = isCorner
        self.isFairnessDeflection = isFairnessDeflection
    }
}

public struct NativeAnalyticReplayCallbacks {
    public var onProgress: (_ progress: Double, _ point: CGPoint) -> Void
    public var onImpact: (_ impact: NativeAnalyticReplayImpact) -> Void
    public var onEndpointCompression: () -> Void
    public var onWinnerFlash: (_ flashID: String) -> Void
    public var onFinished: () -> Void
    public var onCancelled: () -> Void

    public init(
        onProgress: @escaping (_ progress: Double, _ point: CGPoint) -> Void = { _, _ in },
        onImpact: @escaping (_ impact: NativeAnalyticReplayImpact) -> Void = { _ in },
        onEndpointCompression: @escaping () -> Void = {},
        onWinnerFlash: @escaping (_ flashID: String) -> Void = { _ in },
        onFinished: @escaping () -> Void = {},
        onCancelled: @escaping () -> Void = {}
    ) {
        self.onProgress = onProgress
        self.onImpact = onImpact
        self.onEndpointCompression = onEndpointCompression
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

/// Converts normalized elapsed time to speed relative to launch velocity.
/// Pinball supplies this from the same analytic profile used for path progress,
/// keeping the motion tail and collision presentation in exact agreement.
public typealias NativeReplaySpeedMapper = (_ normalizedTime: Double) -> Double

enum PolylineImpactEdge: Hashable, Sendable {
    case left
    case right
    case top
    case bottom
}

/// A resolved seat contact: which ring, and where on it, in scene coordinates.
struct PolylineBumperContact: Equatable, Sendable {
    let seatID: Int
    let center: CGPoint
    let radius: CGFloat
    /// Unit outward normal at the contact point.
    let normal: CGVector
}

struct PolylineImpact: Equatable, Sendable {
    let vertexIndex: Int
    let progress: Double
    let point: CGPoint
    let edges: Set<PolylineImpactEdge>
    let wallNormalImpulseFraction: Double
    /// Set only for a seat-ring contact, which is authored rather than derived.
    /// A bumper impact carries no `edges`, so it is never drawn on a wall and
    /// is never reported as a corner.
    let bumper: PolylineBumperContact?

    // Explicit rather than memberwise: `bumper` needs a default so the two
    // existing construction sites keep compiling unchanged.
    init(
        vertexIndex: Int,
        progress: Double,
        point: CGPoint,
        edges: Set<PolylineImpactEdge>,
        wallNormalImpulseFraction: Double,
        bumper: PolylineBumperContact? = nil
    ) {
        self.vertexIndex = vertexIndex
        self.progress = progress
        self.point = point
        self.edges = edges
        self.wallNormalImpulseFraction = wallNormalImpulseFraction
        self.bumper = bumper
    }
}

enum PolylineImpactAnalysis {
    /// Internal vertices in an analytic billiards polyline are immutable wall
    /// events. Reflection direction identifies the impacted edge without needing
    /// mutable physics bodies or another source of randomness.
    static func impacts(in points: [CGPoint], tolerance: CGFloat = 1e-7) -> [PolylineImpact] {
        guard points.count >= 3 else { return [] }

        var cumulativeLengths = [CGFloat](repeating: 0, count: points.count)
        for index in 1..<points.count {
            cumulativeLengths[index] = cumulativeLengths[index - 1] + distance(points[index - 1], points[index])
        }
        guard let totalLength = cumulativeLengths.last, totalLength > tolerance else { return [] }

        return (1..<(points.count - 1)).compactMap { index in
            let incoming = normalizedVector(from: points[index - 1], to: points[index], tolerance: tolerance)
            let outgoing = normalizedVector(from: points[index], to: points[index + 1], tolerance: tolerance)
            guard let incoming, let outgoing else { return nil }

            var edges: Set<PolylineImpactEdge> = []
            if incoming.dx * outgoing.dx < -tolerance {
                edges.insert(incoming.dx > 0 ? .right : .left)
            }
            if incoming.dy * outgoing.dy < -tolerance {
                edges.insert(incoming.dy > 0 ? .top : .bottom)
            }
            guard !edges.isEmpty else { return nil }

            let normalMagnitudeSquared = edges.reduce(CGFloat.zero) { partial, edge in
                switch edge {
                case .left, .right:
                    partial + incoming.dx * incoming.dx
                case .top, .bottom:
                    partial + incoming.dy * incoming.dy
                }
            }
            let wallNormalImpulseFraction = Double(
                min(1, max(0, sqrt(normalMagnitudeSquared)))
            )

            return PolylineImpact(
                vertexIndex: index,
                progress: Double(cumulativeLengths[index] / totalLength),
                point: points[index],
                edges: edges,
                wallNormalImpulseFraction: wallNormalImpulseFraction
            )
        }
    }

    private static func normalizedVector(
        from start: CGPoint,
        to end: CGPoint,
        tolerance: CGFloat
    ) -> CGVector? {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let magnitude = hypot(dx, dy)
        guard magnitude > tolerance else { return nil }
        return CGVector(dx: dx / magnitude, dy: dy / magnitude)
    }

    private static func distance(_ first: CGPoint, _ second: CGPoint) -> CGFloat {
        hypot(second.x - first.x, second.y - first.y)
    }
}

struct RollingMaterialMarkSample: Equatable, Sendable {
    let position: CGPoint
    let satellitePosition: CGPoint
    let alpha: CGFloat
    let scale: CGFloat
    let rotation: CGFloat
}

enum RollingMaterialMarkPresentation {
    /// Projects a small authored material fleck across the visible face using
    /// travelled distance, not elapsed time. The fleck disappears around the
    /// back half of the ball and returns from the opposite edge, making slow
    /// late-flight movement continue to read as rolling rather than sliding.
    static func sample(
        distance: CGFloat,
        tangent: CGVector,
        ballRadius: CGFloat
    ) -> RollingMaterialMarkSample {
        let radius = max(1, ballRadius)
        let tangentMagnitude = hypot(tangent.dx, tangent.dy)
        let direction = tangentMagnitude > 0
            ? CGVector(dx: tangent.dx / tangentMagnitude, dy: tangent.dy / tangentMagnitude)
            : CGVector(dx: 1, dy: 0)
        let normal = CGVector(dx: -direction.dy, dy: direction.dx)
        let phase = distance / radius
        let acrossFace = sin(phase)
        let frontDepth = max(0, cos(phase))
        let travelOffset = radius * 0.54 * acrossFace
        let lateralOffset = radius * 0.10 * frontDepth
        let position = CGPoint(
            x: direction.dx * travelOffset + normal.dx * lateralOffset,
            y: direction.dy * travelOffset + normal.dy * lateralOffset
        )
        let satellitePosition = CGPoint(
            x: position.x + normal.dx * radius * 0.13,
            y: position.y + normal.dy * radius * 0.13
        )

        return RollingMaterialMarkSample(
            position: position,
            satellitePosition: satellitePosition,
            alpha: pow(frontDepth, 0.62),
            scale: 0.56 + 0.44 * frontDepth,
            rotation: atan2(direction.dy, direction.dx) + phase * 0.16
        )
    }
}

enum PolylineImpactPresentation {
    /// Analytic collisions happen at the ball-center inset. The impact mark,
    /// however, belongs on the visible playfield edge so it reads as contact
    /// with the wall rather than a spark floating inside the board.
    static func visibleEdgePoint(
        for edge: PolylineImpactEdge,
        impactPoint: CGPoint,
        sceneSize: CGSize
    ) -> CGPoint {
        switch edge {
        case .left:
            return CGPoint(x: 0, y: min(sceneSize.height, max(0, impactPoint.y)))
        case .right:
            return CGPoint(x: sceneSize.width, y: min(sceneSize.height, max(0, impactPoint.y)))
        case .top:
            return CGPoint(x: min(sceneSize.width, max(0, impactPoint.x)), y: sceneSize.height)
        case .bottom:
            return CGPoint(x: min(sceneSize.width, max(0, impactPoint.x)), y: 0)
        }
    }
}

/// Deterministically samples a supplied polyline by arc length. It intentionally has no collision,
/// body, force, or simulation layer: playback is entirely analytic and time based.
public final class NativeAnalyticPolylineReplayScene: SKScene {
    private let regionLayer = SKNode()
    private let guideLayer = SKNode()
    private let replayLayer = SKNode()
    /// Pinball lengths for the board this scene is drawing. The scene's size is
    /// the playfield size, so this agrees with the model by construction.
    private var boardMetrics: PinballBoardMetrics {
        PinballBoardMetrics(playfieldSize: size)
    }

    private let impactLayer = SKNode()
    private let flashLayer = SKNode()

    private let guideNode = SKShapeNode()
    private let tailNodes = (0..<1).map { _ in SKShapeNode() }
    private let cursorNode = SKNode()
    private let cursorAuraNode = SKShapeNode()
    private let cursorPearlNode = SKShapeNode()
    private let cursorShadeNode = SKShapeNode()
    private let cursorRimNode = SKShapeNode()
    private let cursorHighlightNode = SKShapeNode()
    private let cursorHighlightDotNode = SKShapeNode()

    private var rawPlan: NativeAnalyticReplayPlan?
    private var pointMapper: NativeReplayPointMapper = { point, _ in point }
    private var progressMapper: NativeReplayProgressMapper = { $0 }
    private var speedMapper: NativeReplaySpeedMapper?
    private var callbacks = NativeAnalyticReplayCallbacks()
    private var sampler = PolylineSampler(points: [])
    private var impacts: [PolylineImpact] = []
    private var nextImpactIndex = 0
    private var impactPlaybackEnabled = false
    private var impactColor = UIColor.systemCyan
    private var rollingMarkBaseAlpha: CGFloat = 0
    private var resolvedFlashes: [ResolvedFlash] = []

    private var replayStartTime: TimeInterval?
    private var replayIsActive = false
    private var endpointSettleStartTime: TimeInterval?
    private var endpointSettleElapsed: TimeInterval = 0
    private var endpointSettleIsActive = false
    private var endpointCompressionWasDelivered = false
    private var fairnessDeflectorWasDelivered = false
    private var completionWasDelivered = false
    private var currentProgress = 0.0
    private var currentTailSpeedFraction: CGFloat = 1

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
        addChild(impactLayer)
        addChild(flashLayer)

        guideNode.zPosition = 10
        for (index, tailNode) in tailNodes.enumerated() {
            tailNode.zPosition = 20 + CGFloat(index)
            replayLayer.addChild(tailNode)
        }
        impactLayer.zPosition = 28
        cursorNode.zPosition = 30
        guideLayer.addChild(guideNode)
        replayLayer.addChild(cursorNode)

        cursorNode.addChild(cursorAuraNode)
        cursorNode.addChild(cursorPearlNode)
        cursorNode.addChild(cursorShadeNode)
        cursorNode.addChild(cursorRimNode)
        cursorNode.addChild(cursorHighlightNode)
        cursorNode.addChild(cursorHighlightDotNode)
    }

    /// Starts a replay. Points are interpreted in analytic space and transformed by `pointMapper`.
    public func replay(
        _ plan: NativeAnalyticReplayPlan,
        pointMapper: @escaping NativeReplayPointMapper = { point, _ in point },
        progressMapper: @escaping NativeReplayProgressMapper = { $0 },
        speedMapper: NativeReplaySpeedMapper? = nil,
        callbacks: NativeAnalyticReplayCallbacks = NativeAnalyticReplayCallbacks()
    ) {
        cancelReplay(notify: false)
        self.rawPlan = plan
        self.pointMapper = pointMapper
        self.progressMapper = progressMapper
        self.speedMapper = speedMapper
        self.callbacks = callbacks
        currentProgress = 0
        currentTailSpeedFraction = 1
        nextImpactIndex = 0
        impactPlaybackEnabled = plan.duration > 0
        replayStartTime = nil
        endpointSettleStartTime = nil
        endpointSettleElapsed = 0
        endpointSettleIsActive = false
        endpointCompressionWasDelivered = false
        fairnessDeflectorWasDelivered = false
        completionWasDelivered = false
        replayIsActive = !plan.polyline.isEmpty
        rebuildForCurrentSize()

        guard replayIsActive else {
            completeReplay()
            return
        }

        if plan.duration == 0 {
            render(progress: 1, tailSpeedFraction: 0)
            replayIsActive = false
            completeReplay()
        } else {
            render(progress: 0, tailSpeedFraction: 1)
            deliverInitialFairnessDeflectorIfNeeded()
        }
    }

    public func cancelReplay() {
        cancelReplay(notify: true)
    }

    public override func update(_ currentTime: TimeInterval) {
        if endpointSettleIsActive {
            updateEndpointSettle(at: currentTime)
            return
        }
        guard replayIsActive, let plan = rawPlan else { return }

        if replayStartTime == nil {
            replayStartTime = currentTime
        }
        let elapsed = currentTime - (replayStartTime ?? currentTime)
        let normalizedTime = min(1, max(0, elapsed / max(plan.duration, .leastNonzeroMagnitude)))
        let mappedProgress = min(1, max(0, progressMapper(normalizedTime)))
        let speedFraction: CGFloat
        if let speedMapper {
            speedFraction = CGFloat(min(1, max(0, speedMapper(normalizedTime))))
        } else {
            let derivativeStep = min(1.0 / 120.0, max(normalizedTime, 0.000_001))
            let previousTime = max(0, normalizedTime - derivativeStep)
            let previousMappedProgress = min(1, max(0, progressMapper(previousTime)))
            let currentSlope = (mappedProgress - previousMappedProgress) /
                max(normalizedTime - previousTime, 0.000_001)
            let initialStep = 1.0 / 120.0
            let initialSlope = max(
                0.000_001,
                (progressMapper(initialStep) - progressMapper(0)) / initialStep
            )
            speedFraction = CGFloat(min(1, max(0, currentSlope / initialSlope)))
        }
        render(progress: mappedProgress, tailSpeedFraction: speedFraction)

        if normalizedTime >= 1 {
            finishMovement(at: currentTime)
        }
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard rawPlan != nil else { return }
        rebuildForCurrentSize()
        render(
            progress: currentProgress,
            tailSpeedFraction: currentTailSpeedFraction
        )
        if endpointSettleIsActive {
            applyEndpointSettle(elapsed: endpointSettleElapsed)
        } else if completionWasDelivered && currentProgress >= 1 {
            drawWinnerFlashes(notify: false)
        }
    }

    private func rebuildForCurrentSize() {
        guard let plan = rawPlan else { return }
        backgroundColor = plan.style.backgroundColor
        flashLayer.removeAllChildren()

        let mappedPoints = plan.polyline.map { pointMapper($0, size) }
        sampler = PolylineSampler(points: mappedPoints)
        impacts = PolylineImpactAnalysis.impacts(in: mappedPoints)
        applyAuthoredBumperContacts(plan.bumperMarks, in: mappedPoints)
        injectTaggedFairnessDeflectorIfNeeded(
            at: plan.fairnessDeflectorVertexIndex,
            in: mappedPoints
        )
        nextImpactIndex = impacts.firstIndex(where: { $0.progress > currentProgress + 1e-9 }) ?? impacts.count
        impactLayer.removeAllChildren()

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

    /// A nearly tangent first leg can have such a small normal component that
    /// reflection-sign analysis intentionally ignores it as numerical noise.
    /// Authored metadata is stronger evidence: the tagged wall vertex must
    /// still disclose and emit its single Fair Bounce event.
    /// Replaces or synthesizes impacts at vertices the marcher recorded as seat
    /// contacts.
    ///
    /// `PolylineImpactAnalysis` is deliberately left alone: it stays a pure
    /// geometric function over points, and relaxing it would both break its
    /// collinear-vertex contract and emit spurious impacts for the float noise
    /// its tolerance exists to suppress. Authored metadata is stronger evidence,
    /// exactly as it is for the tagged fairness deflector below.
    ///
    /// Two fixes fall out. A glancing bounce preserves both direction-component
    /// signs, so geometry finds no impact at all and one is synthesized here. A
    /// steep bounce is found but misattributed to a wall, so it is replaced with
    /// empty `edges` — which keeps it off `showOrdinaryImpactMark`, and so out of
    /// `visibleEdgePoint`, which would otherwise snap its mark to the border.
    private func applyAuthoredBumperContacts(
        _ marks: [Int: NativeReplayBumperMark],
        in points: [CGPoint]
    ) {
        guard !marks.isEmpty, points.count > 2 else { return }

        var cumulativeLengths = [CGFloat](repeating: 0, count: points.count)
        for pointIndex in 1..<points.count {
            cumulativeLengths[pointIndex] = cumulativeLengths[pointIndex - 1] + hypot(
                points[pointIndex].x - points[pointIndex - 1].x,
                points[pointIndex].y - points[pointIndex - 1].y
            )
        }
        guard let totalLength = cumulativeLengths.last, totalLength > 0 else { return }

        let ballRadius = boardMetrics.ballRadius

        for (index, mark) in marks {
            guard index > 0, index < points.count - 1 else { continue }
            // A deflector is authored on a wall and can never also be a bumper.
            // Skipping keeps a future change to the splice degrading to today's
            // behaviour instead of drawing a ring on the playfield border.
            if rawPlan?.fairnessDeflectorVertexIndex == index { continue }

            let contactPoint = points[index]
            let sceneCenter = pointMapper(mark.center, size)

            // Radius and normal come from mapped points, never from mapping a
            // vector: `NativeReplayPointMapper` maps points and has no defined
            // linear part, and the Pinball mapper is a Y-flip that would negate
            // a naively mapped normal into a translated garbage vector.
            var normalX = contactPoint.x - sceneCenter.x
            var normalY = contactPoint.y - sceneCenter.y
            let centerDistance = hypot(normalX, normalY)
            guard centerDistance > 0 else { continue }
            normalX /= centerDistance
            normalY /= centerDistance

            // Inverse of the Minkowski inflation the marcher collided against,
            // so the drawn ring lands on the artwork under any isometric mapper.
            let measuredRadius = centerDistance - ballRadius
            let sceneRadius = measuredRadius > 0 ? measuredRadius : mark.radius

            let incoming = CGVector(
                dx: contactPoint.x - points[index - 1].x,
                dy: contactPoint.y - points[index - 1].y
            )
            let incomingMagnitude = max(hypot(incoming.dx, incoming.dy), .leastNonzeroMagnitude)
            let normalComponent = abs(
                incoming.dx * normalX + incoming.dy * normalY
            ) / incomingMagnitude

            let repaired = PolylineImpact(
                vertexIndex: index,
                progress: Double(cumulativeLengths[index] / totalLength),
                point: contactPoint,
                edges: [],
                wallNormalImpulseFraction: Double(min(1, max(0, normalComponent))),
                bumper: PolylineBumperContact(
                    seatID: mark.seatID,
                    center: sceneCenter,
                    radius: sceneRadius,
                    normal: CGVector(dx: normalX, dy: normalY)
                )
            )

            if let existing = impacts.firstIndex(where: { $0.vertexIndex == index }) {
                impacts[existing] = repaired
            } else {
                impacts.append(repaired)
            }
        }

        impacts.sort { first, second in
            if first.progress == second.progress {
                return first.vertexIndex < second.vertexIndex
            }
            return first.progress < second.progress
        }
    }

    private func injectTaggedFairnessDeflectorIfNeeded(
        at optionalIndex: Int?,
        in points: [CGPoint]
    ) {
        guard let index = optionalIndex,
              index > 0,
              index < points.count - 1,
              !impacts.contains(where: { $0.vertexIndex == index }) else { return }

        var cumulativeLengths = [CGFloat](repeating: 0, count: points.count)
        for pointIndex in 1..<points.count {
            cumulativeLengths[pointIndex] = cumulativeLengths[pointIndex - 1] + hypot(
                points[pointIndex].x - points[pointIndex - 1].x,
                points[pointIndex].y - points[pointIndex - 1].y
            )
        }
        guard let totalLength = cumulativeLengths.last, totalLength > 0 else { return }

        let edge = nearestEdge(to: points[index])
        let incoming = CGVector(
            dx: points[index].x - points[index - 1].x,
            dy: points[index].y - points[index - 1].y
        )
        let incomingMagnitude = max(hypot(incoming.dx, incoming.dy), .leastNonzeroMagnitude)
        let normalComponent: CGFloat
        switch edge {
        case .left, .right:
            normalComponent = abs(incoming.dx) / incomingMagnitude
        case .top, .bottom:
            normalComponent = abs(incoming.dy) / incomingMagnitude
        }
        impacts.append(
            PolylineImpact(
                vertexIndex: index,
                progress: Double(cumulativeLengths[index] / totalLength),
                point: points[index],
                edges: [edge],
                wallNormalImpulseFraction: Double(min(1, max(0, normalComponent)))
            )
        )
        impacts.sort { first, second in
            if first.progress == second.progress {
                return first.vertexIndex < second.vertexIndex
            }
            return first.progress < second.progress
        }
    }

    private func configureReplayNodes(style: NativeReplayVisualStyle) {
        let fullPath = path(points: sampler.points)
        guideNode.path = style.showsGuide ? fullPath : nil
        guideNode.strokeColor = style.guideColor
        guideNode.lineWidth = max(1, style.trailWidth * 0.55)
        guideNode.lineCap = .round
        guideNode.lineJoin = .round

        let bandAlpha: [CGFloat] = [0.30]
        let bandWidth: [CGFloat] = [0.92]
        for index in tailNodes.indices {
            let node = tailNodes[index]
            node.strokeColor = style.trailColor.withAlphaComponent(bandAlpha[index])
            node.lineWidth = max(1, style.trailWidth * bandWidth[index])
            node.glowWidth = 0
            node.lineCap = .round
            node.lineJoin = .round
        }

        impactColor = style.impactColor
        configurePearl(style: style)
    }

    private func configurePearl(style: NativeReplayVisualStyle) {
        cursorNode.removeAllActions()
        cursorNode.xScale = 1
        cursorNode.yScale = 1
        guard style.cursorRadius > 0 else {
            cursorNode.isHidden = true
            return
        }

        let diameter = boardMetrics.ballDiameter
        let radius = diameter / 2
        let material = style.ballMaterial?.presentation ?? .fallback
        cursorNode.isHidden = sampler.points.isEmpty

        cursorAuraNode.path = circlePath(radius: radius * NativePinballReplayMetrics.auraRadiusScale)
        cursorAuraNode.position = CGPoint(x: 0, y: -NativePinballReplayMetrics.auraOffset)
        cursorAuraNode.fillColor = UIColor.black.withAlphaComponent(0.34)
        cursorAuraNode.strokeColor = .clear
        cursorAuraNode.lineWidth = 0
        cursorAuraNode.glowWidth = 0

        cursorPearlNode.path = circlePath(radius: radius)
        cursorPearlNode.fillColor = style.cursorColor
        cursorPearlNode.strokeColor = style.ballEdgeColor.withAlphaComponent(0.88)
        cursorPearlNode.lineWidth = material.edgeWidth
        cursorPearlNode.glowWidth = 0

        cursorShadeNode.path = circlePath(radius: radius * material.shadeRadius)
        cursorShadeNode.position = CGPoint(x: radius * 0.20, y: -radius * 0.22)
        cursorShadeNode.fillColor = style.ballEdgeColor.withAlphaComponent(material.shadeAlpha)
        cursorShadeNode.strokeColor = .clear

        cursorRimNode.path = circlePath(radius: radius)
        cursorRimNode.fillColor = .clear
        cursorRimNode.strokeColor = style.ballEdgeColor.withAlphaComponent(material.rimAlpha)
        cursorRimNode.lineWidth = material.rimWidth
        cursorRimNode.glowWidth = 0

        cursorHighlightNode.path = material.markRadius > 0
            ? circlePath(radius: radius * material.markRadius)
            : nil
        cursorHighlightNode.position = CGPoint(x: -radius * 0.28, y: radius * 0.27)
        cursorHighlightNode.fillColor = style.ballEdgeColor.withAlphaComponent(material.markAlpha)
        cursorHighlightNode.strokeColor = .clear
        cursorHighlightNode.glowWidth = 0

        let rollingMarkRadius = max(radius * max(material.markRadius, 0.09) * 0.54, 1.2)
        cursorHighlightDotNode.path = circlePath(radius: rollingMarkRadius)
        cursorHighlightDotNode.position = .zero
        cursorHighlightDotNode.fillColor = style.ballEdgeColor.withAlphaComponent(0.74)
        cursorHighlightDotNode.strokeColor = .clear
        rollingMarkBaseAlpha = max(0.28, material.markAlpha * 2.4)
    }

    private func render(progress: Double, tailSpeedFraction: CGFloat) {
        guard !sampler.points.isEmpty else { return }
        let previousProgress = currentProgress
        currentProgress = min(1, max(0, progress))
        currentTailSpeedFraction = min(1, max(0, tailSpeedFraction))
        // Tail lengths are lengths and scale; the impact durations above are
        // times and deliberately do not.
        let tailMetrics = boardMetrics
        let tailLength = tailMetrics.minimumTailLength +
            (tailMetrics.maximumTailLength -
                tailMetrics.minimumTailLength) * currentTailSpeedFraction
        let bands = sampler.tailBandsSinceLastVertex(
            at: currentProgress,
            maximumLength: tailLength,
            bandCount: tailNodes.count
        )
        for index in tailNodes.indices {
            tailNodes[index].path = index < bands.count ? path(points: bands[index]) : nil
        }
        let point = sampler.point(at: currentProgress)
        cursorNode.position = point
        updateRollingMaterialMark()
        triggerImpacts(from: previousProgress, through: currentProgress)
        callbacks.onProgress(currentProgress, point)
    }

    private func updateRollingMaterialMark() {
        let sample = RollingMaterialMarkPresentation.sample(
            distance: sampler.distance(at: currentProgress),
            tangent: sampler.tangent(at: currentProgress),
            ballRadius: boardMetrics.ballRadius
        )
        cursorHighlightNode.position = sample.position
        cursorHighlightNode.alpha = sample.alpha
        cursorHighlightNode.setScale(sample.scale)
        cursorHighlightNode.zRotation = sample.rotation
        cursorHighlightDotNode.position = sample.satellitePosition
        cursorHighlightDotNode.alpha = sample.alpha * rollingMarkBaseAlpha
        cursorHighlightDotNode.setScale(sample.scale)
    }

    private func triggerImpacts(from previousProgress: Double, through progress: Double) {
        guard impactPlaybackEnabled, progress > previousProgress else { return }
        while nextImpactIndex < impacts.count {
            let impact = impacts[nextImpactIndex]
            guard impact.progress <= progress + 1e-9 else { break }
            nextImpactIndex += 1
            guard impact.progress > previousProgress + 1e-9 else { continue }
            showImpact(impact)
        }
    }

    private func showImpact(_ impact: PolylineImpact) {
        let isFairnessDeflection = rawPlan?.fairnessDeflectorVertexIndex == impact.vertexIndex
        if let bumper = impact.bumper {
            showBumperStrike(bumper)
        } else if isFairnessDeflection {
            showFairnessDeflector(impact)
        } else {
            showOrdinaryImpactMark(impact)
        }

        // A bumper carries no edges, so give `squashPearl` the dominant axis of
        // its contact normal. It only reads the set to choose a compression
        // axis, so this is faithful to the real contact.
        squashPearl(
            for: impact.bumper.map { Self.dominantAxisEdges(for: $0.normal) } ?? impact.edges,
            wallNormalImpulseFraction: CGFloat(impact.wallNormalImpulseFraction)
        )
        callbacks.onImpact(
            NativeAnalyticReplayImpact(
                vertexIndex: impact.vertexIndex,
                progress: impact.progress,
                speedFraction: Double(currentTailSpeedFraction),
                wallNormalImpulseFraction: impact.wallNormalImpulseFraction,
                isCorner: impact.edges.count > 1,
                isFairnessDeflection: isFairnessDeflection
            )
        )
    }

    private func showOrdinaryImpactMark(_ impact: PolylineImpact) {
        for edge in impact.edges {
            let tangent: CGVector
            switch edge {
            case .left:
                tangent = CGVector(dx: 0, dy: 1)
            case .right:
                tangent = CGVector(dx: 0, dy: 1)
            case .top:
                tangent = CGVector(dx: 1, dy: 0)
            case .bottom:
                tangent = CGVector(dx: 1, dy: 0)
            }

            let edgePath = CGMutablePath()
            edgePath.move(
                to: CGPoint(
                    x: -tangent.dx * 18,
                    y: -tangent.dy * 18
                )
            )
            edgePath.addLine(
                to: CGPoint(
                    x: tangent.dx * 18,
                    y: tangent.dy * 18
                )
            )
            let edgeFlash = SKShapeNode(path: edgePath)
            edgeFlash.name = "impact-edge"
            edgeFlash.position = PolylineImpactPresentation.visibleEdgePoint(
                for: edge,
                impactPoint: impact.point,
                sceneSize: size
            )
            let impulse = CGFloat(impact.wallNormalImpulseFraction)
            edgeFlash.strokeColor = impactColor.withAlphaComponent(0.38 + 0.32 * impulse)
            edgeFlash.lineWidth = 1.5 + 0.9 * impulse
            edgeFlash.lineCap = .round
            edgeFlash.glowWidth = 0
            edgeFlash.zPosition = 1
            impactLayer.addChild(edgeFlash)
            edgeFlash.run(
                .sequence([
                    .group([
                        .fadeOut(withDuration: 0.14),
                        .scale(to: 1.12, duration: 0.14)
                    ]),
                    .removeFromParent()
                ])
            )
        }
    }

    /// Makes the one non-specular fairness intervention belong to the wall.
    /// A short piece of the contacted edge curls inward, flexes under the ball,
    /// and springs back in the current theme colors. There is deliberately no
    /// label or free-floating effect: when no deflector metadata is present,
    /// this wall transformation is never rendered.
    private func showFairnessDeflector(_ impact: PolylineImpact) {
        guard !fairnessDeflectorWasDelivered, let style = rawPlan?.style else { return }
        fairnessDeflectorWasDelivered = true

        for edge in orderedEdges(impact.edges) {
            let position = PolylineImpactPresentation.visibleEdgePoint(
                for: edge,
                impactPoint: impact.point,
                sceneSize: size
            )
            let wall = fairnessWallTransformation(
                for: edge,
                position: position,
                style: style
            )
            impactLayer.addChild(wall)
            runFairnessWallLifetime(
                on: wall,
                edge: edge,
                reducesMotion: style.reducesMotion
            )
        }
    }

    private func deliverInitialFairnessDeflectorIfNeeded() {
        guard rawPlan?.fairnessDeflectorVertexIndex == 0,
              !fairnessDeflectorWasDelivered,
              let point = sampler.points.first else { return }
        let edge = nearestEdge(to: point)
        showImpact(
            PolylineImpact(
                vertexIndex: 0,
                progress: 0,
                point: point,
                edges: [edge],
                wallNormalImpulseFraction: 1
            )
        )
    }

    private func fairnessWallTransformation(
        for edge: PolylineImpactEdge,
        position: CGPoint,
        style: NativeReplayVisualStyle
    ) -> SKNode {
        let wall = SKNode()
        wall.name = "fairness-wall-transform"
        wall.position = position
        wall.zPosition = 3

        let wallPath = fairnessWallPath(for: edge)

        // The broad edge-colored layer reads as the original wall bending,
        // rather than a new object or a floating spark appearing beside it.
        let depth = SKShapeNode(path: wallPath)
        depth.name = "fairness-wall-depth"
        depth.strokeColor = style.ballEdgeColor.withAlphaComponent(0.38)
        depth.lineWidth = 12
        depth.lineCap = .round
        depth.lineJoin = .round
        depth.zPosition = 0
        wall.addChild(depth)

        let face = SKShapeNode(path: wallPath)
        face.name = "fairness-wall-face"
        face.strokeColor = style.impactColor.withAlphaComponent(0.98)
        face.lineWidth = 7
        face.lineCap = .round
        face.lineJoin = .round
        face.zPosition = 1
        wall.addChild(face)

        // A narrow second theme color gives the elastic wall a playful,
        // game-piece finish without using white shine or neon bloom.
        let inlay = SKShapeNode(path: wallPath)
        inlay.name = "fairness-wall-inlay"
        inlay.strokeColor = style.trailColor.withAlphaComponent(0.72)
        inlay.lineWidth = 2.2
        inlay.lineCap = .round
        inlay.lineJoin = .round
        inlay.zPosition = 2
        wall.addChild(inlay)

        return wall
    }

    private func fairnessWallPath(for edge: PolylineImpactEdge) -> CGPath {
        let path = CGMutablePath()
        let halfLength: CGFloat = 22
        let curl: CGFloat = 9
        switch edge {
        case .left:
            path.move(to: CGPoint(x: 0, y: -halfLength))
            path.addQuadCurve(
                to: CGPoint(x: 0, y: halfLength),
                control: CGPoint(x: curl, y: 0)
            )
        case .right:
            path.move(to: CGPoint(x: 0, y: -halfLength))
            path.addQuadCurve(
                to: CGPoint(x: 0, y: halfLength),
                control: CGPoint(x: -curl, y: 0)
            )
        case .top:
            path.move(to: CGPoint(x: -halfLength, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: halfLength, y: 0),
                control: CGPoint(x: 0, y: -curl)
            )
        case .bottom:
            path.move(to: CGPoint(x: -halfLength, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: halfLength, y: 0),
                control: CGPoint(x: 0, y: curl)
            )
        }
        return path
    }

    private func runFairnessWallLifetime(
        on wall: SKNode,
        edge: PolylineImpactEdge,
        reducesMotion: Bool
    ) {
        wall.alpha = 1
        if reducesMotion {
            setFairnessWallScale(on: wall, edge: edge, normal: 1, tangent: 1)
            wall.run(.sequence([
                .wait(forDuration: 0.46),
                .fadeOut(withDuration: 0.14),
                .removeFromParent()
            ]))
            return
        }

        // The first rendered frame is already a curved, compressed wall at the
        // exact turn. It flattens for one quick contact frame, then overshoots
        // inward and settles, making the redirected motion feel spring-loaded.
        setFairnessWallScale(on: wall, edge: edge, normal: 0.68, tangent: 1.07)
        let compress = fairnessWallScaleAction(
            edge: edge,
            normal: 0.42,
            tangent: 1.11,
            duration: 0.025
        )
        compress.timingMode = .easeOut
        let spring = fairnessWallScaleAction(
            edge: edge,
            normal: 1.28,
            tangent: 0.96,
            duration: 0.075
        )
        spring.timingMode = .easeOut
        let settle = fairnessWallScaleAction(
            edge: edge,
            normal: 1,
            tangent: 1,
            duration: 0.11
        )
        settle.timingMode = .easeInEaseOut
        wall.run(.sequence([
            compress,
            spring,
            settle,
            .wait(forDuration: 0.22),
            .fadeOut(withDuration: 0.16),
            .removeFromParent()
        ]))
    }

    private func setFairnessWallScale(
        on wall: SKNode,
        edge: PolylineImpactEdge,
        normal: CGFloat,
        tangent: CGFloat
    ) {
        switch edge {
        case .left, .right:
            wall.xScale = normal
            wall.yScale = tangent
        case .top, .bottom:
            wall.xScale = tangent
            wall.yScale = normal
        }
    }

    private func fairnessWallScaleAction(
        edge: PolylineImpactEdge,
        normal: CGFloat,
        tangent: CGFloat,
        duration: TimeInterval
    ) -> SKAction {
        switch edge {
        case .left, .right:
            return .group([
                .scaleX(to: normal, duration: duration),
                .scaleY(to: tangent, duration: duration)
            ])
        case .top, .bottom:
            return .group([
                .scaleX(to: tangent, duration: duration),
                .scaleY(to: normal, duration: duration)
            ])
        }
    }

    private func orderedEdges(_ edges: Set<PolylineImpactEdge>) -> [PolylineImpactEdge] {
        [.left, .right, .top, .bottom].filter(edges.contains)
    }

    private func nearestEdge(to point: CGPoint) -> PolylineImpactEdge {
        let distances: [(PolylineImpactEdge, CGFloat)] = [
            (.left, point.x),
            (.right, size.width - point.x),
            (.bottom, point.y),
            (.top, size.height - point.y)
        ]
        return distances.min(by: { $0.1 < $1.1 })?.0 ?? .left
    }

    private func squashPearl(
        for edges: Set<PolylineImpactEdge>,
        wallNormalImpulseFraction: CGFloat
    ) {
        let hitsVertical = edges.contains(.left) || edges.contains(.right)
        let hitsHorizontal = edges.contains(.top) || edges.contains(.bottom)
        let impulse = min(1, max(0, wallNormalImpulseFraction))
        let normalSquash = 0.88 - 0.20 * impulse
        let tangentStretch = 1.01 + 0.07 * impulse
        let squashX: CGFloat
        let squashY: CGFloat
        if hitsVertical && hitsHorizontal {
            let cornerSquash = 0.90 - 0.10 * impulse
            squashX = cornerSquash
            squashY = cornerSquash
        } else if hitsVertical {
            squashX = normalSquash
            squashY = tangentStretch
        } else {
            squashX = tangentStretch
            squashY = normalSquash
        }

        cursorNode.removeAction(forKey: "wall-impact")
        cursorNode.xScale = 1
        cursorNode.yScale = 1
        let compress = SKAction.group([
            .scaleX(to: squashX, duration: NativePinballReplayMetrics.compressionDuration),
            .scaleY(to: squashY, duration: NativePinballReplayMetrics.compressionDuration)
        ])
        compress.timingMode = .easeOut
        let rebound = SKAction.group([
            .scaleX(to: 1.04, duration: NativePinballReplayMetrics.reboundDuration),
            .scaleY(to: 1.04, duration: NativePinballReplayMetrics.reboundDuration)
        ])
        rebound.timingMode = .easeOut
        let settle = SKAction.group([
            .scaleX(to: 1, duration: NativePinballReplayMetrics.settleDuration),
            .scaleY(to: 1, duration: NativePinballReplayMetrics.settleDuration)
        ])
        settle.timingMode = .easeInEaseOut
        cursorNode.run(.sequence([compress, rebound, settle]), withKey: "wall-impact")
    }

    private func circlePath(radius: CGFloat) -> CGPath {
        CGPath(
            ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2),
            transform: nil
        )
    }

    private func finishMovement(at currentTime: TimeInterval) {
        guard replayIsActive else { return }
        replayIsActive = false
        replayStartTime = nil
        if currentProgress < 1 {
            render(progress: 1, tailSpeedFraction: 0)
        }
        impactPlaybackEnabled = false
        if rawPlan?.style.settlesAtEndpoint == true {
            beginEndpointSettle(at: currentTime)
        } else {
            completeReplay()
        }
    }

    private func beginEndpointSettle(at currentTime: TimeInterval) {
        guard !endpointSettleIsActive, !completionWasDelivered else { return }
        cursorNode.removeAction(forKey: "wall-impact")
        cursorNode.xScale = 1
        cursorNode.yScale = 1
        endpointSettleStartTime = currentTime
        endpointSettleElapsed = 0
        endpointCompressionWasDelivered = false
        endpointSettleIsActive = true
        applyEndpointSettle(elapsed: 0)
    }

    private func updateEndpointSettle(at currentTime: TimeInterval) {
        guard endpointSettleIsActive else { return }
        if endpointSettleStartTime == nil {
            endpointSettleStartTime = currentTime
        }
        let elapsed = min(
            NativePinballReplayMetrics.endpointSettleDuration,
            max(0, currentTime - (endpointSettleStartTime ?? currentTime))
        )

        if !endpointCompressionWasDelivered,
           elapsed >= NativePinballReplayMetrics.endpointCompressionDuration {
            // Hold the authored maximum compression for this rendered frame so
            // the tactile cue cannot arrive after the rebound has already begun.
            endpointSettleElapsed = NativePinballReplayMetrics.endpointCompressionDuration
            applyEndpointSettle(elapsed: endpointSettleElapsed)
            endpointCompressionWasDelivered = true
            callbacks.onEndpointCompression()
            return
        }

        endpointSettleElapsed = elapsed
        applyEndpointSettle(elapsed: endpointSettleElapsed)

        guard endpointSettleElapsed >= NativePinballReplayMetrics.endpointSettleDuration else {
            return
        }
        endpointSettleIsActive = false
        endpointSettleStartTime = nil
        cursorNode.xScale = 1
        cursorNode.yScale = 1
        completeReplay()
    }

    private func applyEndpointSettle(elapsed: TimeInterval) {
        let compression = NativePinballReplayMetrics.endpointCompressionDuration
        let rebound = NativePinballReplayMetrics.endpointReboundDuration
        let recovery = NativePinballReplayMetrics.endpointRecoveryDuration
        let xScale: CGFloat
        let yScale: CGFloat

        if elapsed <= compression {
            let progress = easedOutFraction(elapsed / max(compression, .leastNonzeroMagnitude))
            xScale = interpolate(from: 1, to: 1.08, progress: progress)
            yScale = interpolate(from: 1, to: 0.84, progress: progress)
        } else if elapsed <= compression + rebound {
            let progress = easedOutFraction(
                (elapsed - compression) / max(rebound, .leastNonzeroMagnitude)
            )
            xScale = interpolate(from: 1.08, to: 0.98, progress: progress)
            yScale = interpolate(from: 0.84, to: 1.04, progress: progress)
        } else {
            let progress = smoothFraction(
                (elapsed - compression - rebound) / max(recovery, .leastNonzeroMagnitude)
            )
            xScale = interpolate(from: 0.98, to: 1, progress: progress)
            yScale = interpolate(from: 1.04, to: 1, progress: progress)
        }
        cursorNode.xScale = xScale
        cursorNode.yScale = yScale
    }

    private func completeReplay() {
        guard !completionWasDelivered else { return }
        completionWasDelivered = true
        drawWinnerFlashes(notify: true)
        callbacks.onFinished()
    }

    private func interpolate(from start: CGFloat, to end: CGFloat, progress: Double) -> CGFloat {
        start + (end - start) * CGFloat(min(1, max(0, progress)))
    }

    private func easedOutFraction(_ rawProgress: Double) -> Double {
        let progress = min(1, max(0, rawProgress))
        return 1 - pow(1 - progress, 2)
    }

    private func smoothFraction(_ rawProgress: Double) -> Double {
        let progress = min(1, max(0, rawProgress))
        return progress * progress * (3 - 2 * progress)
    }

    private func cancelReplay(notify: Bool) {
        let wasActive = replayIsActive || endpointSettleIsActive
        replayIsActive = false
        replayStartTime = nil
        endpointSettleStartTime = nil
        endpointSettleElapsed = 0
        endpointSettleIsActive = false
        endpointCompressionWasDelivered = false
        fairnessDeflectorWasDelivered = false
        impactPlaybackEnabled = false
        impactLayer.removeAllChildren()
        cursorNode.removeAction(forKey: "wall-impact")
        cursorNode.xScale = 1
        cursorNode.yScale = 1
        flashLayer.removeAllChildren()
        if notify && wasActive {
            callbacks.onCancelled()
        }
    }

    /// The compression axis for a contact normal, in the vocabulary
    /// `squashPearl` already understands.
    private static func dominantAxisEdges(for normal: CGVector) -> Set<PolylineImpactEdge> {
        if abs(normal.dx) >= abs(normal.dy) {
            return [normal.dx > 0 ? .right : .left]
        }
        return [normal.dy > 0 ? .top : .bottom]
    }

    /// Lights the whole struck seat ring on the frame the contact is drawn.
    ///
    /// The entire disc lights, not an outline or a contact arc: a seat is a
    /// solid game piece and reads as one thing being hit. During flight the
    /// chits are receded to 0.22 opacity, so the strike has to restore the
    /// piece to full presence to register at all.
    ///
    /// Runs from the render pass, so the light appears in the very frame that
    /// draws the ball at the vertex — the same discipline the endpoint settle
    /// uses to keep its cue from arriving after the rebound.
    ///
    /// Hue does no work here. What separates a seat strike from a wall mark is
    /// position (on a ring, not the border), extent (a filled disc, not a line),
    /// and motion (a bloom and decay, not a fade).
    private func showBumperStrike(_ bumper: PolylineBumperContact) {
        guard let style = rawPlan?.style else { return }
        let policy = BoardAccessibilityAppearancePolicy(
            reduceTransparency: style.reducesTransparency,
            increasedContrast: style.increasesContrast,
            differentiateWithoutColor: style.differentiatesWithoutColor
        )

        let name = "bumper-strike:\(bumper.seatID)"
        // Restart rather than composite to double brightness when the ball
        // strikes the same ring twice.
        impactLayer.childNode(withName: name)?.removeFromParent()

        let node = SKNode()
        node.name = name
        node.position = bumper.center
        node.zPosition = 4
        node.alpha = 0

        // Reduce Transparency means less see-through, so the wash gets denser
        // rather than thinner.
        let fillAlpha = policy.reduceTransparency ? 0.88 : 0.58
        let fill = SKShapeNode(circleOfRadius: bumper.radius)
        fill.name = "bumper-strike-fill"
        fill.fillColor = style.impactColor.withAlphaComponent(fillAlpha)
        fill.strokeColor = .clear
        fill.lineWidth = 0
        fill.glowWidth = 0
        node.addChild(fill)

        let rim = SKShapeNode(circleOfRadius: bumper.radius)
        rim.name = "bumper-strike-rim"
        rim.fillColor = .clear
        rim.strokeColor = style.impactColor.withAlphaComponent(
            min(1, 0.95 * policy.edgeOpacityMultiplier)
        )
        rim.lineWidth = 2.6 * policy.edgeWidthMultiplier
        rim.glowWidth = 0
        node.addChild(rim)

        // Differentiate Without Color adds a dashed outer contour, the same
        // shape redundancy the winner ring uses, so the cue survives when hue
        // is not available to distinguish it.
        if policy.showsWinnerContour {
            let contourPath = CGMutablePath()
            contourPath.addEllipse(
                in: CGRect(
                    x: -bumper.radius - 3.5,
                    y: -bumper.radius - 3.5,
                    width: (bumper.radius + 3.5) * 2,
                    height: (bumper.radius + 3.5) * 2
                )
            )
            let contour = SKShapeNode(
                path: contourPath.copy(dashingWithPhase: 0, lengths: [5, 3.4])
            )
            contour.name = "bumper-strike-contour"
            contour.fillColor = .clear
            contour.strokeColor = style.impactColor
            contour.lineWidth = 2 * policy.edgeWidthMultiplier
            contour.glowWidth = 0
            node.addChild(contour)
        }

        impactLayer.addChild(node)

        // Node-scoped actions only. Neither `scene.run` nor a `Task` is torn
        // down by `cancelReplay`, which clears this layer.
        if style.reducesMotion {
            node.setScale(1)
            node.run(.sequence([
                .fadeAlpha(to: 1, duration: 0.05),
                .wait(forDuration: 0.26),
                .fadeOut(withDuration: 0.22),
                .removeFromParent()
            ]))
        } else {
            // Blooms at full size and decays. It must not expand from a point
            // like the winner flash: that reads as a ripple passing through,
            // not as this piece being struck.
            //
            // The rise stays fast so the light is unmistakably on the contact
            // frame, but it then holds briefly before decaying. Without the
            // hold the seat reads as flickering rather than as lit, especially
            // at speed when the ball is already several rings away.
            node.setScale(0.94)
            node.run(.sequence([
                .group([
                    .fadeAlpha(to: 1, duration: 0.05),
                    .scale(to: 1.09, duration: 0.05)
                ]),
                .wait(forDuration: 0.09),
                .group([
                    .scale(to: 1, duration: 0.42),
                    .fadeOut(withDuration: 0.42)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func drawWinnerFlashes(notify: Bool) {
        flashLayer.removeAllChildren()
        for flash in resolvedFlashes {
            let node = SKShapeNode(circleOfRadius: flash.radius)
            node.name = "winner-flash:\(flash.id)"
            node.position = flash.point
            node.fillColor = flash.color.withAlphaComponent(0.08)
            node.strokeColor = flash.color.withAlphaComponent(0.72)
            node.lineWidth = 2.2
            node.glowWidth = 0
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

struct PolylineSampler {
    let points: [CGPoint]
    private let cumulativeLengths: [CGFloat]
    let totalLength: CGFloat

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
        return point(atDistance: target)
    }

    func distance(at progress: Double) -> CGFloat {
        CGFloat(min(1, max(0, progress))) * totalLength
    }

    func tangent(at progress: Double) -> CGVector {
        guard points.count > 1, totalLength > 0 else {
            return CGVector(dx: 1, dy: 0)
        }
        let target = distance(at: progress)
        let segment = segmentIndex(for: target)
        let start = points[segment - 1]
        let end = points[segment]
        let dx = end.x - start.x
        let dy = end.y - start.y
        let magnitude = hypot(dx, dy)
        guard magnitude > 0 else { return CGVector(dx: 1, dy: 0) }
        return CGVector(dx: dx / magnitude, dy: dy / magnitude)
    }

    /// Returns equal-distance pieces of a bounded route ending at `progress`.
    /// Pieces are ordered oldest to newest so callers can style them with
    /// progressively stronger opacity without retaining the travelled route.
    func tailBands(
        at progress: Double,
        maximumLength: CGFloat,
        bandCount: Int
    ) -> [[CGPoint]] {
        guard bandCount > 0,
              points.count > 1,
              totalLength > 0,
              maximumLength > 0 else {
            return []
        }

        let endDistance = CGFloat(min(1, max(0, progress))) * totalLength
        guard endDistance > 0 else { return [] }
        let startDistance = max(0, endDistance - maximumLength)
        let visibleLength = endDistance - startDistance
        guard visibleLength > 0 else { return [] }

        return (0..<bandCount).map { index in
            let lowerFraction = CGFloat(index) / CGFloat(bandCount)
            let upperFraction = CGFloat(index + 1) / CGFloat(bandCount)
            return points(
                fromDistance: startDistance + visibleLength * lowerFraction,
                toDistance: startDistance + visibleLength * upperFraction
            )
        }
    }

    /// A speed-length tail confined to the current physical leg. The tail
    /// disappears behind a wall at impact instead of drawing an angular V across
    /// two reflected segments.
    func tailBandsSinceLastVertex(
        at progress: Double,
        maximumLength: CGFloat,
        bandCount: Int
    ) -> [[CGPoint]] {
        guard bandCount > 0,
              points.count > 1,
              totalLength > 0,
              maximumLength > 0 else {
            return []
        }

        let endDistance = CGFloat(min(1, max(0, progress))) * totalLength
        guard endDistance > 0 else { return [] }
        let activeSegment = segmentIndex(for: endDistance)
        let segmentStartDistance = cumulativeLengths[max(0, activeSegment - 1)]
        let startDistance = max(
            segmentStartDistance,
            endDistance - maximumLength
        )
        let visibleLength = endDistance - startDistance
        guard visibleLength > 0 else { return [] }

        return (0..<bandCount).map { index in
            let lowerFraction = CGFloat(index) / CGFloat(bandCount)
            let upperFraction = CGFloat(index + 1) / CGFloat(bandCount)
            return points(
                fromDistance: startDistance + visibleLength * lowerFraction,
                toDistance: startDistance + visibleLength * upperFraction
            )
        }
    }

    private func points(fromDistance rawStart: CGFloat, toDistance rawEnd: CGFloat) -> [CGPoint] {
        let startDistance = min(totalLength, max(0, rawStart))
        let endDistance = min(totalLength, max(startDistance, rawEnd))
        let startPoint = point(atDistance: startDistance)
        guard endDistance > startDistance else { return [startPoint] }

        var result = [startPoint]
        if cumulativeLengths.count > 2 {
            for index in 1..<(cumulativeLengths.count - 1) {
                let vertexDistance = cumulativeLengths[index]
                guard vertexDistance > startDistance, vertexDistance < endDistance else { continue }
                if result.last != points[index] {
                    result.append(points[index])
                }
            }
        }

        let endPoint = point(atDistance: endDistance)
        if result.last != endPoint {
            result.append(endPoint)
        }
        return result
    }

    private func point(atDistance rawTarget: CGFloat) -> CGPoint {
        guard let first = points.first else { return .zero }
        guard points.count > 1, totalLength > 0 else { return first }

        let target = min(totalLength, max(0, rawTarget))
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
