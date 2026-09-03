import SwiftUI

@MainActor
public struct ChooserRootView: View {
    @Bindable private var model: ChooserAppModel
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSettingsPresented = false

    public init(model: ChooserAppModel) {
        self.model = model
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                BoardSurfaceView(theme: model.colorTheme)
                    .ignoresSafeArea()
                    .id(model.colorTheme.id)
                    .transition(reduceMotion ? .identity : .opacity)

                activeModeView
                    .id(model.mode)
                    .transition(.opacity)

                // The toast and the mode introduction card both want the top of
                // the screen, so they share one column and can never overlap.
                // Both live here rather than inside a mode view: changing a
                // mode's own layout would resize its playfield GeometryReader
                // and trip Pinball's rotation-safety cancellation mid-round.
                VStack(spacing: 8) {
                    if let toast = model.toastMessage {
                        Text(toast)
                            .font(.system(.callout, design: .rounded, weight: .bold))
                            .foregroundStyle(model.colorTheme.accentForegroundColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(model.colorTheme.accentColor, in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(model.colorTheme.primaryInkColor.opacity(0.16), lineWidth: 1)
                            }
                            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
                            .accessibilityAddTraits(.isStaticText)
                            .transition(reduceMotion ? .identity : .move(edge: .top).combined(with: .opacity))
                            .allowsHitTesting(false)
                    }

                    if let introPage = model.presentedModeIntroPage,
                       let instructions = introInstructions(for: introPage) {
                        NativeModeIntroCard(
                            page: introPage,
                            instructions: instructions,
                            colorTheme: model.colorTheme,
                            onDismiss: model.completeOnboarding
                        )
                        .transition(reduceMotion ? .identity : .move(edge: .top).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 6)
                .padding(.horizontal, 16)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NativeModeMenu(
                        selectedModeID: model.selectedModeID,
                        modes: model.modeOptions,
                        isEnabled: model.isModeChangeEnabled,
                        onModeChange: model.requestModeSelection,
                        onSetDefaultMode: { _ in model.setCurrentModeAsLaunchDefault() }
                    )
                }

                ToolbarItem(placement: .topBarTrailing) {
                    NativeSettingsButton(
                        isEnabled: model.isSettingsEnabled,
                        action: {
                            if model.prepareToPresentSettings() {
                                isSettingsPresented = true
                            }
                        }
                    )
                    .accessibilityAction(named: Text("Shuffle colors")) {
                        _ = model.randomizeColorTheme()
                    }
                }
            }
        }
        .background {
            NativeThreeFingerThemeShuffleGesture {
                _ = model.randomizeColorThemeAfterPhysicalGesture()
            }
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
        }
        .animation(reduceMotion ? .linear(duration: 0.01) : .smooth(duration: 0.22), value: model.mode)
        .animation(reduceMotion ? .linear(duration: 0.01) : .smooth(duration: 0.24), value: model.colorTheme)
        .animation(reduceMotion ? .linear(duration: 0.01) : .spring(duration: 0.3, bounce: 0.3), value: model.toastMessage)
        .animation(reduceMotion ? .linear(duration: 0.01) : .spring(duration: 0.3, bounce: 0.3), value: model.presentedOnboarding)
        .environment(\.chooserAccentColor, model.colorTheme.accentColor)
        .environment(\.chooserColorTheme, model.colorTheme)
        .environment(\.chooserVisualTheme, model.colorTheme.visualTheme)
        .environment(\.colorScheme, model.colorTheme.preferredColorScheme)
        .tint(model.colorTheme.interactiveTextColor)
        .statusBarHidden(true)
        // `onDismiss` rather than a delay: a full screen cover presented while
        // this sheet is still dismissing can silently fail to appear, and
        // SwiftUI runs this only after the dismissal transition completes.
        .sheet(
            isPresented: $isSettingsPresented,
            onDismiss: { model.presentWelcomeReplayIfRequested() }
        ) {
            NativeOfflineInformationFlow(
                copy: .chooser(version: appVersion),
                selectedColorTheme: model.colorTheme,
                colorThemes: model.colorThemeOptions,
                onSelectColorTheme: model.selectColorTheme,
                onShuffleColorTheme: model.randomizeColorTheme,
                onDismiss: { isSettingsPresented = false },
                onSupport: {
                    if let url = URL(string: "mailto:contact@foliohtml.com") {
                        openURL(url)
                    }
                },
                onShowWelcome: {
                    model.requestWelcomeReplay()
                    isSettingsPresented = false
                }
            )
            .environment(\.chooserAccentColor, model.colorTheme.accentColor)
            .environment(\.chooserColorTheme, model.colorTheme)
            .environment(\.chooserVisualTheme, model.colorTheme.visualTheme)
            .environment(\.colorScheme, model.colorTheme.preferredColorScheme)
            .presentationBackground(model.colorTheme.visualTheme.surfaceGradient)
            .presentationDragIndicator(.visible)
            .presentationSizing(.form)
        }
        // Presented OVER this view, never instead of it. Replacing
        // `ChooserRootView` with the carousel would unmount `.onOpenURL` below
        // and silently swallow an App Shortcut's cold-launch deep link.
        .fullScreenCover(item: welcomeBinding) { _ in
            NativeWelcomeCarousel(
                copy: .chooser(version: appVersion),
                colorTheme: model.colorTheme,
                onFinish: model.completeOnboarding,
                onSkip: model.skipOnboarding,
                onShuffleColorTheme: model.randomizeColorTheme
            )
        }
        .alert(item: $model.confirmation, content: confirmationAlert)
        .onOpenURL { url in
            guard let requestedMode = AppMode(deepLinkURL: url) else { return }
            model.requestModeChange(to: requestedMode)
        }
        .task {
            model.startOnboardingIfNeeded()
        }
    }

    /// Filtered so only the welcome reaches the cover; the per-mode card is an
    /// overlay instead. The nil-setter matters: a VoiceOver escape gesture or a
    /// Guided Access dismissal bypasses the buttons entirely, and without this
    /// those people would meet the tour again on every launch.
    private var welcomeBinding: Binding<OnboardingMoment?> {
        Binding(
            get: { model.presentedOnboarding == .welcome ? model.presentedOnboarding : nil },
            set: { if $0 == nil { model.completeOnboarding() } }
        )
    }

    private func introInstructions(for page: NativeWelcomePage) -> NativeModeInstructions? {
        NativeOfflineInformationCopy.chooser(version: appVersion)
            .modes.first { $0.id == page.rawValue }
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
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "18"
        return "\(version) (\(build))"
    }

    private func confirmationAlert(_ confirmation: ChooserConfirmation) -> Alert {
        switch confirmation {
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
