import SwiftUI

@MainActor
public struct ChooserRootView: View {
    @Bindable private var model: ChooserAppModel
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(model: ChooserAppModel) {
        self.model = model
    }

    public var body: some View {
        ZStack {
            NativeChooserBackground()

            VStack(spacing: 0) {
                NativeAppChrome(
                    selectedModeID: Binding(
                        get: { model.selectedModeID },
                        set: { _ in }
                    ),
                    modes: model.modeOptions,
                    isModeChangeEnabled: model.isModeChangeEnabled,
                    onModeChange: model.requestModeCycle,
                    onSetDefaultMode: { _ in model.setCurrentModeAsLaunchDefault() },
                    onOpenInformation: { model.isInformationPresented = true }
                )
                .disabled(model.isCriticalInteractionActive)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

                activeModeView
                    .id(model.mode)
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .opacity.combined(with: .scale(scale: 0.985))
                    )
            }

            if let toast = model.toastMessage {
                Text(toast)
                    .font(.system(.callout, design: .rounded, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.cyan, in: Capsule())
                    .shadow(color: .cyan.opacity(0.4), radius: 18)
                    .accessibilityAddTraits(.isStaticText)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 58)
                    .allowsHitTesting(false)
            }
        }
        .animation(reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.2), value: model.mode)
        .animation(reduceMotion ? .linear(duration: 0.01) : .spring(duration: 0.3, bounce: 0.3), value: model.toastMessage)
        .sheet(isPresented: $model.isInformationPresented) {
            NativeOfflineInformationFlow(
                copy: .chooser(version: appVersion),
                onDismiss: { model.isInformationPresented = false },
                onSupport: {
                    if let url = URL(string: "mailto:contact@foliohtml.com") {
                        openURL(url)
                    }
                }
            )
            .presentationBackground(.black)
        }
        .alert(item: $model.confirmation, content: confirmationAlert)
    }

    @ViewBuilder
    private var activeModeView: some View {
        switch model.mode {
        case .together:
            TogetherModeView(model: model)
        case .tapIn:
            TapInModeView(model: model)
        case .pinball:
            PinballModeView(model: model)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "3"
        return "\(version) (\(build))"
    }

    private func confirmationAlert(_ confirmation: ChooserConfirmation) -> Alert {
        switch confirmation {
        case .switchMode(let target, let count, let itemName):
            return Alert(
                title: Text("Switch to \(target.accessibilityName)?"),
                message: Text("This clears \(count) \(itemName)."),
                primaryButton: .default(Text("Switch"), action: model.confirmPendingModeChange),
                secondaryButton: .cancel(Text("Cancel"), action: model.dismissConfirmation)
            )
        case .clearTapIn(let count):
            return Alert(
                title: Text("Clear \(count) \(count == 1 ? "player" : "players")?"),
                message: Text("Everyone will need to tap in again."),
                primaryButton: .destructive(Text("Clear"), action: model.confirmClearTapIn),
                secondaryButton: .cancel(Text("Keep players"), action: model.dismissConfirmation)
            )
        case .clearPinball(let count):
            return Alert(
                title: Text("Clear \(count) \(count == 1 ? "seat" : "seats")?"),
                message: Text("Everyone will need to choose a seat again."),
                primaryButton: .destructive(Text("Clear"), action: model.confirmClearPinball),
                secondaryButton: .cancel(Text("Keep seats"), action: model.dismissConfirmation)
            )
        }
    }
}

private struct NativeChooserBackground: View {
    var body: some View {
        ZStack {
            Color.black
            RadialGradient(
                colors: [.cyan.opacity(0.07), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 420
            )
            RadialGradient(
                colors: [.pink.opacity(0.045), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 460
            )
        }
        .ignoresSafeArea()
    }
}
