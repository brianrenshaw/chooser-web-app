import SwiftUI
import UIKit

/// Installs one app-wide, direct-touch gesture on the hosting window. Keeping
/// the recognizer on UIWindow means presented sheets and pushed information
/// screens inherit the same shortcut without creating competing recognizers.
@MainActor
public struct NativeThreeFingerThemeShuffleGesture: UIViewRepresentable {
    public var isEnabled: Bool
    public var onRecognized: () -> Void

    public init(
        isEnabled: Bool = true,
        onRecognized: @escaping () -> Void
    ) {
        self.isEnabled = isEnabled
        self.onRecognized = onRecognized
    }

    public func makeCoordinator() -> NativeThreeFingerThemeShuffleCoordinator {
        NativeThreeFingerThemeShuffleCoordinator()
    }

    public func makeUIView(context: Context) -> NativeWindowAttachmentView {
        let view = NativeWindowAttachmentView()
        view.isUserInteractionEnabled = false
        view.accessibilityElementsHidden = true
        view.onWindowChange = { [weak coordinator = context.coordinator] window in
            coordinator?.install(on: window)
        }
        context.coordinator.update(
            isEnabled: isEnabled,
            onRecognized: onRecognized
        )
        return view
    }

    public func updateUIView(
        _ uiView: NativeWindowAttachmentView,
        context: Context
    ) {
        context.coordinator.update(
            isEnabled: isEnabled,
            onRecognized: onRecognized
        )
        context.coordinator.install(on: uiView.window)
    }

    public static func dismantleUIView(
        _ uiView: NativeWindowAttachmentView,
        coordinator: NativeThreeFingerThemeShuffleCoordinator
    ) {
        uiView.onWindowChange = nil
        coordinator.uninstall()
    }
}

@MainActor
public final class NativeWindowAttachmentView: UIView {
    var onWindowChange: ((UIWindow?) -> Void)?

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        onWindowChange?(window)
    }
}

@MainActor
public final class NativeThreeFingerThemeShuffleCoordinator: NSObject {
    private(set) weak var installedWindow: UIWindow?
    private(set) lazy var gestureRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleRecognizedGesture(_:))
        )
        recognizer.numberOfTapsRequired = 1
        recognizer.numberOfTouchesRequired = 3
        recognizer.allowedTouchTypes = [
            NSNumber(value: UITouch.TouchType.direct.rawValue)
        ]
        recognizer.cancelsTouchesInView = true
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = true
        return recognizer
    }()

    private var requestedEnabled = true
    private var onRecognized: () -> Void = {}

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(voiceOverStatusDidChange),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func update(
        isEnabled: Bool,
        voiceOverRunning: Bool = UIAccessibility.isVoiceOverRunning,
        onRecognized: @escaping () -> Void
    ) {
        requestedEnabled = isEnabled
        self.onRecognized = onRecognized
        gestureRecognizer.isEnabled = isEnabled && !voiceOverRunning
    }

    func install(on window: UIWindow?) {
        guard installedWindow !== window else { return }
        uninstall()
        guard let window else { return }
        window.addGestureRecognizer(gestureRecognizer)
        installedWindow = window
    }

    func uninstall() {
        installedWindow?.removeGestureRecognizer(gestureRecognizer)
        installedWindow = nil
    }

    @objc private func voiceOverStatusDidChange() {
        gestureRecognizer.isEnabled = requestedEnabled && !UIAccessibility.isVoiceOverRunning
    }

    @objc private func handleRecognizedGesture(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended, recognizer.isEnabled else { return }

        // UIKit first cancels touches already delivered to the gameplay view.
        // Yield one main-actor turn so those cancellation callbacks remove all
        // provisional entries before the model evaluates its safety gate.
        Task { @MainActor [weak self] in
            await Task.yield()
            guard let self, self.gestureRecognizer.isEnabled else { return }
            self.onRecognized()
        }
    }
}
