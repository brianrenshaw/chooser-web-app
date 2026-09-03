import SwiftUI
import UIKit

/// Complete, testable measurement of one single-finger Pinball gesture.
public struct NativePinballGesturePayload: Equatable, Sendable {
    public let start: CGPoint
    public let end: CGPoint
    public let translation: CGVector
    public let velocity: CGVector
    public let duration: TimeInterval

    public init(
        start: CGPoint,
        end: CGPoint,
        velocity: CGVector,
        duration: TimeInterval
    ) {
        self.start = start
        self.end = end
        self.translation = CGVector(dx: end.x - start.x, dy: end.y - start.y)
        self.velocity = velocity
        self.duration = duration
    }

    public var distance: CGFloat { hypot(translation.dx, translation.dy) }
    public var speed: CGFloat { hypot(velocity.dx, velocity.dy) }

    public var flickIntent: PinballFlickIntent? {
        try? PinballFlickIntent(
            releasePoint: end,
            direction: velocity,
            speed: speed
        )
    }
}

/// Live, non-random gesture state used to make Pinball feel like direct
/// manipulation. The themed ball is only presented once this measurement
/// satisfies the exact same distance and speed thresholds as a committed
/// flick; ordinary seat taps therefore never flash a ball onto the board.
public struct NativePinballGestureTracking: Equatable, Sendable {
    public let start: CGPoint
    public let current: CGPoint
    public let velocity: CGVector
    public let duration: TimeInterval

    public init(
        start: CGPoint,
        current: CGPoint,
        velocity: CGVector,
        duration: TimeInterval
    ) {
        self.start = start
        self.current = current
        self.velocity = velocity
        self.duration = duration
    }

    public var payload: NativePinballGesturePayload {
        NativePinballGesturePayload(
            start: start,
            end: current,
            velocity: velocity,
            duration: duration
        )
    }

    public var isClearFlick: Bool {
        guard case .flick = NativePinballGestureClassifier.classify(payload) else {
            return false
        }
        return true
    }
}

public enum NativePinballGestureAction: Equatable, Sendable {
    case seat(NativePinballGesturePayload)
    case flick(NativePinballGesturePayload)
}

/// One deterministic contract shared by UIKit input and unit tests.
public enum NativePinballGestureClassifier {
    public static let maximumSeatDistance: CGFloat = 22
    public static let minimumFlickDistance: CGFloat = 36
    public static let minimumFlickSpeed: CGFloat = 400

    public static func classify(
        _ payload: NativePinballGesturePayload,
        cancelled: Bool = false
    ) -> NativePinballGestureAction? {
        guard !cancelled,
              payload.start.x.isFinite,
              payload.start.y.isFinite,
              payload.end.x.isFinite,
              payload.end.y.isFinite,
              payload.translation.dx.isFinite,
              payload.translation.dy.isFinite,
              payload.velocity.dx.isFinite,
              payload.velocity.dy.isFinite,
              payload.duration.isFinite,
              payload.duration >= 0 else {
            return nil
        }

        if payload.distance <= maximumSeatDistance {
            return .seat(payload)
        }
        if payload.distance >= minimumFlickDistance,
           payload.speed >= minimumFlickSpeed {
            return .flick(payload)
        }
        return nil
    }
}

struct NativePinballVelocitySample: Equatable, Sendable {
    let location: CGPoint
    let timestamp: TimeInterval
}

/// Estimates the final intentional throw with a recency-weighted regression.
/// Duplicate touch-up samples do not erase a live flick, while a drag that
/// visibly stops before release is rejected instead of launching unexpectedly.
enum NativePinballGestureVelocityEstimator {
    static let regressionWindow: TimeInterval = 0.120
    static let duplicateTouchUpAllowance: TimeInterval = 0.045
    static let stoppedDragThreshold: TimeInterval = 0.080
    static let movementEpsilon: CGFloat = 0.5

    static func releaseVelocity(
        from samples: [NativePinballVelocitySample],
        gestureDuration: TimeInterval
    ) -> CGVector {
        let valid = monotonicFiniteSamples(samples)
        guard valid.count >= 2,
              let release = valid.last,
              let lastMotionIndex = lastMotionIndex(in: valid) else {
            return .zero
        }

        let stoppedDuration = max(
            0,
            release.timestamp - valid[lastMotionIndex].timestamp
        )
        guard stoppedDuration <= stoppedDragThreshold else { return .zero }

        // UIKit may repeat the final coordinate at touch-up. For a short repeat,
        // regress to the last moving sample; a longer pause remains in the data
        // and naturally lowers the resolved release speed.
        let effectiveEndIndex = stoppedDuration <= duplicateTouchUpAllowance
            ? lastMotionIndex
            : valid.count - 1
        let effectiveEnd = valid[effectiveEndIndex]
        let cutoff = effectiveEnd.timestamp - regressionWindow
        var window = Array(
            valid[...effectiveEndIndex].filter { $0.timestamp >= cutoff }
        )

        if window.count < 2,
           effectiveEndIndex > 0,
           effectiveEnd.timestamp - valid[effectiveEndIndex - 1].timestamp <= regressionWindow {
            window.insert(valid[effectiveEndIndex - 1], at: 0)
        }
        window = removingTransientSpikes(from: window)
        guard window.count >= 2 else { return .zero }

        if let velocity = weightedRegressionVelocity(window),
           hypot(velocity.dx, velocity.dy) > 0 {
            return velocity
        }

        // Sparse very-short gestures can legitimately contain only began/ended
        // samples. Keep that path deterministic without reaching farther back
        // than the same 120 ms intent window.
        guard gestureDuration > 0,
              gestureDuration <= regressionWindow,
              let first = window.first,
              let last = window.last else {
            return .zero
        }
        return CGVector(
            dx: (last.location.x - first.location.x) / gestureDuration,
            dy: (last.location.y - first.location.y) / gestureDuration
        )
    }

    private static func monotonicFiniteSamples(
        _ samples: [NativePinballVelocitySample]
    ) -> [NativePinballVelocitySample] {
        var result: [NativePinballVelocitySample] = []
        result.reserveCapacity(samples.count)
        for sample in samples where
            sample.location.x.isFinite &&
            sample.location.y.isFinite &&
            sample.timestamp.isFinite {
            guard result.last.map({ sample.timestamp >= $0.timestamp }) ?? true else {
                continue
            }
            if let last = result.last,
               last.timestamp == sample.timestamp,
               last.location == sample.location {
                continue
            }
            result.append(sample)
        }
        return result
    }

    private static func lastMotionIndex(
        in samples: [NativePinballVelocitySample]
    ) -> Int? {
        guard samples.count >= 2 else { return nil }
        for index in stride(from: samples.count - 1, through: 1, by: -1) {
            let delta = hypot(
                samples[index].location.x - samples[index - 1].location.x,
                samples[index].location.y - samples[index - 1].location.y
            )
            if delta >= movementEpsilon,
               samples[index].timestamp > samples[index - 1].timestamp {
                return index
            }
        }
        return nil
    }

    /// Removes an isolated out-and-back coordinate spike before regression.
    private static func removingTransientSpikes(
        from samples: [NativePinballVelocitySample]
    ) -> [NativePinballVelocitySample] {
        guard samples.count >= 4 else { return samples }
        let segmentSpeeds: [CGFloat] = zip(samples, samples.dropFirst()).compactMap { pair in
            let duration = pair.1.timestamp - pair.0.timestamp
            guard duration > 0 else { return nil }
            return hypot(
                pair.1.location.x - pair.0.location.x,
                pair.1.location.y - pair.0.location.y
            ) / duration
        }.sorted()
        guard !segmentSpeeds.isEmpty else { return samples }
        let median = segmentSpeeds[segmentSpeeds.count / 2]
        guard median > 0 else { return samples }

        var rejected = Set<Int>()
        for index in 1..<(samples.count - 1) {
            let beforeDuration = samples[index].timestamp - samples[index - 1].timestamp
            let afterDuration = samples[index + 1].timestamp - samples[index].timestamp
            guard beforeDuration > 0, afterDuration > 0 else { continue }
            let incoming = CGVector(
                dx: (samples[index].location.x - samples[index - 1].location.x) / beforeDuration,
                dy: (samples[index].location.y - samples[index - 1].location.y) / beforeDuration
            )
            let outgoing = CGVector(
                dx: (samples[index + 1].location.x - samples[index].location.x) / afterDuration,
                dy: (samples[index + 1].location.y - samples[index].location.y) / afterDuration
            )
            let incomingSpeed = hypot(incoming.dx, incoming.dy)
            let outgoingSpeed = hypot(outgoing.dx, outgoing.dy)
            let dot = incoming.dx * outgoing.dx + incoming.dy * outgoing.dy
            if incomingSpeed > median * 2.8,
               outgoingSpeed > median * 2.8,
               dot < 0 {
                rejected.insert(index)
            }
        }
        return samples.enumerated().compactMap { index, sample in
            rejected.contains(index) ? nil : sample
        }
    }

    private static func weightedRegressionVelocity(
        _ samples: [NativePinballVelocitySample]
    ) -> CGVector? {
        guard let first = samples.first, let last = samples.last else { return nil }
        let span = last.timestamp - first.timestamp
        guard span > 0 else { return nil }

        var weightSum = 0.0
        var weightedTime = 0.0
        var weightedX = 0.0
        var weightedY = 0.0
        for sample in samples {
            let time = sample.timestamp - first.timestamp
            let recency = min(1, max(0, time / span))
            let weight = 0.35 + 0.65 * recency
            weightSum += weight
            weightedTime += weight * time
            weightedX += weight * Double(sample.location.x)
            weightedY += weight * Double(sample.location.y)
        }
        guard weightSum > 0 else { return nil }
        let meanTime = weightedTime / weightSum
        let meanX = weightedX / weightSum
        let meanY = weightedY / weightSum
        var denominator = 0.0
        var numeratorX = 0.0
        var numeratorY = 0.0
        for sample in samples {
            let time = sample.timestamp - first.timestamp
            let recency = min(1, max(0, time / span))
            let weight = 0.35 + 0.65 * recency
            let centeredTime = time - meanTime
            denominator += weight * centeredTime * centeredTime
            numeratorX += weight * centeredTime * (Double(sample.location.x) - meanX)
            numeratorY += weight * centeredTime * (Double(sample.location.y) - meanY)
        }
        guard denominator > Double.ulpOfOne else { return nil }
        let velocity = CGVector(
            dx: CGFloat(numeratorX / denominator),
            dy: CGFloat(numeratorY / denominator)
        )
        guard velocity.dx.isFinite, velocity.dy.isFinite else { return nil }
        return velocity
    }
}

/// UIKit-backed single-finger surface that distinguishes deliberate seat taps
/// from velocity-bearing flicks without letting ambiguous gestures do either.
@MainActor
public struct NativePinballGestureSurface: UIViewRepresentable {
    public var isEnabled: Bool
    public var accessibilityLabel: String
    public var accessibilityHint: String
    public var onAction: (NativePinballGestureAction) -> Void
    public var onTrackingChanged: (NativePinballGestureTracking) -> Void
    public var onTrackingEnded: (NativePinballGestureAction?) -> Void
    public var onAccessibilityActivate: () -> Bool

    public init(
        isEnabled: Bool = true,
        accessibilityLabel: String,
        accessibilityHint: String,
        onAction: @escaping (NativePinballGestureAction) -> Void,
        onTrackingChanged: @escaping (NativePinballGestureTracking) -> Void = { _ in },
        onTrackingEnded: @escaping (NativePinballGestureAction?) -> Void = { _ in },
        onAccessibilityActivate: @escaping () -> Bool = { false }
    ) {
        self.isEnabled = isEnabled
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.onAction = onAction
        self.onTrackingChanged = onTrackingChanged
        self.onTrackingEnded = onTrackingEnded
        self.onAccessibilityActivate = onAccessibilityActivate
    }

    public func makeUIView(context: Context) -> NativePinballGestureView {
        let view = NativePinballGestureView()
        update(view)
        return view
    }

    public func updateUIView(_ uiView: NativePinballGestureView, context: Context) {
        update(uiView)
    }

    private func update(_ view: NativePinballGestureView) {
        view.inputEnabled = isEnabled
        view.accessibilityLabel = accessibilityLabel
        view.accessibilityHint = accessibilityHint
        view.onAction = onAction
        view.onTrackingChanged = onTrackingChanged
        view.onTrackingEnded = onTrackingEnded
        view.onAccessibilityActivate = onAccessibilityActivate
    }
}

@MainActor
public final class NativePinballGestureView: UIView {
    var onAction: (NativePinballGestureAction) -> Void = { _ in }
    var onTrackingChanged: (NativePinballGestureTracking) -> Void = { _ in }
    var onTrackingEnded: (NativePinballGestureAction?) -> Void = { _ in }
    var onAccessibilityActivate: () -> Bool = { false }

    var inputEnabled = true {
        didSet {
            isUserInteractionEnabled = inputEnabled
            accessibilityTraits = inputEnabled ? [.button] : [.button, .notEnabled]
            if !inputEnabled, activeTouchID != nil {
                onTrackingEnded(nil)
                resetTracking()
            }
        }
    }

    private var activeTouchID: ObjectIdentifier?
    private var startSample: NativePinballVelocitySample?
    private var samples: [NativePinballVelocitySample] = []

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        isMultipleTouchEnabled = false
        isExclusiveTouch = true
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard inputEnabled, activeTouchID == nil, let touch = touches.first else { return }
        activeTouchID = ObjectIdentifier(touch)
        appendSamples(for: touch, event: event)
        startSample = samples.first
        publishTrackingPreview()
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard inputEnabled,
              let activeTouchID,
              let touch = touches.first(where: { ObjectIdentifier($0) == activeTouchID }) else {
            return
        }
        appendSamples(for: touch, event: event)
        publishTrackingPreview()
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches, event: event, cancelled: false)
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches, event: event, cancelled: true)
    }

    public override func accessibilityActivate() -> Bool {
        guard inputEnabled else { return false }
        return onAccessibilityActivate()
    }

    private func finish(
        _ touches: Set<UITouch>,
        event: UIEvent?,
        cancelled: Bool
    ) {
        guard let activeTouchID,
              let touch = touches.first(where: { ObjectIdentifier($0) == activeTouchID }) else {
            return
        }
        appendSamples(for: touch, event: event)

        publishTrackingPreview()
        var completedAction: NativePinballGestureAction?
        defer {
            onTrackingEnded(completedAction)
            resetTracking()
        }
        guard let start = startSample, let end = samples.last else { return }
        let duration = max(0, end.timestamp - start.timestamp)
        let payload = NativePinballGesturePayload(
            start: start.location,
            end: end.location,
            velocity: releaseVelocity(duration: duration),
            duration: duration
        )
        if let action = NativePinballGestureClassifier.classify(
            payload,
            cancelled: cancelled
        ) {
            completedAction = action
            onAction(action)
        }
    }

    private func appendSamples(for touch: UITouch, event: UIEvent?) {
        let touches = event?.coalescedTouches(for: touch) ?? [touch]
        for touch in touches {
            let sample = NativePinballVelocitySample(
                location: touch.location(in: self),
                timestamp: touch.timestamp
            )
            if let last = samples.last,
               last.timestamp == sample.timestamp,
               last.location == sample.location {
                continue
            }
            samples.append(sample)
        }
    }

    private func releaseVelocity(duration: TimeInterval) -> CGVector {
        NativePinballGestureVelocityEstimator.releaseVelocity(
            from: samples,
            gestureDuration: duration
        )
    }

    /// Publishes the physical finger location together with the same regression
    /// vector that will be committed on release. The SwiftUI layer decides when
    /// the measurement is unambiguously a flick and only then reveals the ball.
    private func publishTrackingPreview() {
        guard let origin = startSample, let current = samples.last else { return }
        let duration = max(0, current.timestamp - origin.timestamp)
        let velocity = releaseVelocity(duration: duration)
        onTrackingChanged(
            NativePinballGestureTracking(
                start: origin.location,
                current: current.location,
                velocity: velocity,
                duration: duration
            )
        )
    }

    private func resetTracking() {
        activeTouchID = nil
        startSample = nil
        samples.removeAll(keepingCapacity: true)
    }
}
