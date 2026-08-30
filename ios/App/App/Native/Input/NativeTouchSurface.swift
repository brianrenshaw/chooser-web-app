import SwiftUI
import UIKit

public struct NativeTouchEvent: Equatable, Sendable {
    public let id: UInt64
    public let location: CGPoint

    public init(id: UInt64, location: CGPoint) {
        self.id = id
        self.location = location
    }
}

/// A UIKit-backed surface that exposes every physical touch independently.
/// SwiftUI gestures intentionally do not sit above it, so simultaneous fingers
/// retain stable identities from `touchesBegan` through cancellation.
@MainActor
public struct NativeTouchSurface: UIViewRepresentable {
    public var isEnabled: Bool
    public var accessibilityLabel: String
    public var accessibilityHint: String
    public var onBegan: (NativeTouchEvent) -> Void
    public var onMoved: (NativeTouchEvent) -> Void
    public var onEnded: (NativeTouchEvent) -> Void
    public var onCancelled: (NativeTouchEvent) -> Void
    public var onAccessibilityActivate: () -> Bool

    public init(
        isEnabled: Bool = true,
        accessibilityLabel: String,
        accessibilityHint: String,
        onBegan: @escaping (NativeTouchEvent) -> Void,
        onMoved: @escaping (NativeTouchEvent) -> Void = { _ in },
        onEnded: @escaping (NativeTouchEvent) -> Void,
        onCancelled: @escaping (NativeTouchEvent) -> Void,
        onAccessibilityActivate: @escaping () -> Bool = { false }
    ) {
        self.isEnabled = isEnabled
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.onBegan = onBegan
        self.onMoved = onMoved
        self.onEnded = onEnded
        self.onCancelled = onCancelled
        self.onAccessibilityActivate = onAccessibilityActivate
    }

    public func makeUIView(context: Context) -> NativeMultitouchView {
        let view = NativeMultitouchView()
        update(view)
        return view
    }

    public func updateUIView(_ uiView: NativeMultitouchView, context: Context) {
        update(uiView)
    }

    private func update(_ view: NativeMultitouchView) {
        view.inputEnabled = isEnabled
        view.accessibilityLabel = accessibilityLabel
        view.accessibilityHint = accessibilityHint
        view.onBegan = onBegan
        view.onMoved = onMoved
        view.onEnded = onEnded
        view.onCancelled = onCancelled
        view.onAccessibilityActivate = onAccessibilityActivate
    }
}

@MainActor
public final class NativeMultitouchView: UIView {
    var onBegan: (NativeTouchEvent) -> Void = { _ in }
    var onMoved: (NativeTouchEvent) -> Void = { _ in }
    var onEnded: (NativeTouchEvent) -> Void = { _ in }
    var onCancelled: (NativeTouchEvent) -> Void = { _ in }
    var onAccessibilityActivate: () -> Bool = { false }

    var inputEnabled = true {
        didSet {
            isUserInteractionEnabled = inputEnabled
            accessibilityTraits = inputEnabled ? [.button] : [.button, .notEnabled]
            if !inputEnabled {
                touchIDs.removeAll()
            }
        }
    }

    private var touchIDs: [ObjectIdentifier: UInt64] = [:]
    private var nextTouchID: UInt64 = 1

    override public init(frame: CGRect) {
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
        isMultipleTouchEnabled = true
        isExclusiveTouch = false
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard inputEnabled else { return }
        for touch in touches {
            let objectID = ObjectIdentifier(touch)
            guard touchIDs[objectID] == nil else { continue }
            let id = nextTouchID
            nextTouchID &+= 1
            touchIDs[objectID] = id
            onBegan(NativeTouchEvent(id: id, location: touch.location(in: self)))
        }
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard inputEnabled else { return }
        for touch in touches {
            guard let id = touchIDs[ObjectIdentifier(touch)] else { continue }
            onMoved(NativeTouchEvent(id: id, location: touch.location(in: self)))
        }
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches, cancelled: false)
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches, cancelled: true)
    }

    private func finish(_ touches: Set<UITouch>, cancelled: Bool) {
        for touch in touches {
            let objectID = ObjectIdentifier(touch)
            guard let id = touchIDs.removeValue(forKey: objectID) else { continue }
            let event = NativeTouchEvent(id: id, location: touch.location(in: self))
            if cancelled {
                onCancelled(event)
            } else {
                onEnded(event)
            }
        }
    }

    override public func accessibilityActivate() -> Bool {
        guard inputEnabled else { return false }
        return onAccessibilityActivate()
    }
}
