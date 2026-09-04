import Accessibility
import CoreGraphics
import Foundation
import Observation

public struct TogetherTouchVisual: Equatable {
    public let id: TogetherTouchIdentity
    public var location: CGPoint
    public let colorIndex: Int
}

public struct TapInPendingVisual: Equatable {
    public let touchID: UInt64
    public var location: CGPoint
    public let number: Int
}

public struct NativePinballSeat: Identifiable, Equatable, Sendable {
    public let id: Int
    public var normalizedLocation: CGPoint

    public init(id: Int, normalizedLocation: CGPoint) {
        self.id = id
        self.normalizedLocation = normalizedLocation
    }
}

public struct NativePinballRun: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let result: PinballRoundResult
    public let curve: PinballMotionProfile
    public let normalizedStrength: Double
    public let launchEnergy: Double

    public init(
        id: UUID = UUID(),
        result: PinballRoundResult,
        curve: PinballMotionProfile,
        normalizedStrength: Double = 0.5,
        launchEnergy: Double? = nil
    ) {
        let clampedStrength = min(1, max(0, normalizedStrength))
        self.id = id
        self.result = result
        self.curve = curve
        self.normalizedStrength = clampedStrength
        self.launchEnergy = min(
            1,
            max(
                0,
                launchEnergy ?? Double(
                    PinballFlickLaunchPolicy.launchEnergy(
                        forStrength: CGFloat(clampedStrength)
                    )
                )
            )
        )
    }
}

public enum NativePinballPhase: Equatable, Sendable {
    case collecting
    case running(NativePinballRun)
    case revealing(run: NativePinballRun, pulse: Int, isLit: Bool)
    case revealed(NativePinballRun)

    public var run: NativePinballRun? {
        switch self {
        case .collecting:
            nil
        case .running(let run), .revealed(let run):
            run
        case .revealing(let run, _, _):
            run
        }
    }

    public var winnerSeatID: Int? {
        switch self {
        case .collecting, .running:
            nil
        case .revealing(let run, _, _), .revealed(let run):
            run.result.winningSeatID
        }
    }
}

public enum ChooserConfirmation: Identifiable, Equatable {
    case clearTapIn(count: Int)
    case clearPinball(count: Int)

    public var id: String {
        switch self {
        case .clearTapIn: "clear-tap-in"
        case .clearPinball: "clear-pinball"
        }
    }
}

struct NativePinballCollisionFeedbackEvent: Equatable, Sendable {
    let vertexIndex: Int
    let progress: Double
    let time: TimeInterval
    let speedFraction: Double
    let isCorner: Bool
    let isFairnessDeflection: Bool
}

private struct TogetherRevealedThemeShuffleBackup {
    let snapshot: TogetherChooserSnapshot
    let visuals: [TogetherTouchIdentity: TogetherTouchVisual]
    let hueIndex: Int
    let capturedAt: Date
}

/// Identifies a settled seat layout. Seats are stored normalized, so the board
/// size and the normalized positions together determine the layout completely.
struct PinballLayoutCacheKey: Equatable {
    let playfieldSize: CGSize
    let seats: [CGPoint]
}

@MainActor
@Observable
public final class ChooserAppModel {
    private static let pinballWinnerRevealDuration = Duration.milliseconds(480)
    static let pinballDistanceRangeInPerimeters = PinballFlickLaunchPolicy.distanceInPerimetersRange
    static let pinballFlightDuration: TimeInterval = 4.00
    static let pinballCollisionMinimumSpacing: TimeInterval = 0.10
    static let pinballWinnerQuietWindow: TimeInterval = 0.30

    public private(set) var mode: AppMode
    public private(set) var launchDefaultMode: AppMode
    public private(set) var togetherSnapshot: TogetherChooserSnapshot
    public private(set) var tapInSnapshot: TapInChooserSnapshot
    public private(set) var togetherVisuals: [TogetherTouchIdentity: TogetherTouchVisual] = [:]
    public private(set) var tapInPending: [UInt64: TapInPendingVisual] = [:]
    public private(set) var tapInTravelOrigins: [UInt64: CGPoint] = [:]
    public private(set) var pinballSeats: [NativePinballSeat] = []
    public private(set) var pinballTravelOrigins: [Int: CGPoint] = [:]
    public private(set) var pinballPhase: NativePinballPhase = .collecting
    public private(set) var pinballPlayfieldSize: CGSize = .zero
    public private(set) var countdownStartedAt: Date?
    public private(set) var colorTheme: ChooserColorTheme
    public var confirmation: ChooserConfirmation?
    /// Which first-run surface is showing, if any.
    ///
    /// Writable for the same reason `confirmation` is: SwiftUI presentation
    /// modifiers need a `Binding` and this model deliberately does not import
    /// SwiftUI. Every transition still goes through a method below; the view
    /// layer only ever writes `nil`, and it routes that back into
    /// `completeOnboarding()`.
    public var presentedOnboarding: OnboardingMoment?
    public private(set) var toastMessage: String?

    @ObservationIgnored private let modeCore: AppModeCore
    @ObservationIgnored private let togetherCore: TogetherChooserCore
    @ObservationIgnored private let tapInCore: TapInChooserCore
    @ObservationIgnored private let feedback: any NativeFeedbackCoordinating
    @ObservationIgnored private let colorThemeStore: any ChooserColorThemePersisting
    @ObservationIgnored private let onboardingStore: any OnboardingProgressPersisting
    @ObservationIgnored private let colorThemeRandomIndexGenerator: any RandomIndexGenerating
    /// Mirror of the store. Mutated **only** by `markOnboardingMomentsSeen(_:)`;
    /// any second mutation site would silently desync it from `UserDefaults`.
    @ObservationIgnored private var seenOnboardingMoments: Set<OnboardingMoment>
    @ObservationIgnored private var isWelcomeReplayRequested = false
    @ObservationIgnored private var pinballTask: Task<Void, Never>?
    @ObservationIgnored private var pinballPendingCollisionFeedback: [Int: NativePinballCollisionFeedbackEvent] = [:]
    @ObservationIgnored private var pinballLayoutCache: (key: PinballLayoutCacheKey, layout: PinballSeatTokenLayout?)?
    @ObservationIgnored private var pinballEndpointSettleCueRunID: UUID?
    @ObservationIgnored private var pinballFinishEnqueuedRunID: UUID?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    @ObservationIgnored private var togetherHueIndex = 0
    @ObservationIgnored private var isSceneActive = true
    @ObservationIgnored private var colorThemeTransitionBlockedUntil = Date.distantPast
    @ObservationIgnored private var togetherRevealedThemeShuffleBackup: TogetherRevealedThemeShuffleBackup?
    @ObservationIgnored private var isRestoringTogetherRevealForThemeShuffle = false

    public init(
        modeStore: LaunchDefaultModePersisting = UserDefaultsLaunchDefaultModeStore(),
        colorThemeStore: ChooserColorThemePersisting = UserDefaultsChooserColorThemeStore(),
        onboardingStore: OnboardingProgressPersisting = UserDefaultsOnboardingProgressStore(),
        togetherCore: TogetherChooserCore = TogetherChooserCore(),
        tapInCore: TapInChooserCore = TapInChooserCore(),
        colorThemeRandomIndexGenerator: any RandomIndexGenerating = SecureRandomIndexGenerator(),
        feedback: (any NativeFeedbackCoordinating)? = nil
    ) {
        let modeCore = AppModeCore(store: modeStore)
        self.modeCore = modeCore
        self.togetherCore = togetherCore
        self.tapInCore = tapInCore
        self.colorThemeStore = colorThemeStore
        self.onboardingStore = onboardingStore
        self.colorThemeRandomIndexGenerator = colorThemeRandomIndexGenerator
        self.feedback = feedback ?? NativeFeedbackCoordinator(audioPolicy: .whenCoreHapticsUnavailable)
        // A pure load with no presentation policy: `presentedOnboarding` stays
        // nil until a view explicitly asks via `startOnboardingIfNeeded()`.
        seenOnboardingMoments = onboardingStore.loadSeenMoments()
        mode = modeCore.currentMode
        launchDefaultMode = modeCore.launchDefaultMode
        colorTheme = colorThemeStore.loadColorTheme() ?? .wingspanOriginal
        togetherSnapshot = togetherCore.snapshot
        tapInSnapshot = tapInCore.snapshot
        wireCoreEvents()
        self.feedback.prepare()
    }

    deinit {
        pinballTask?.cancel()
        toastTask?.cancel()
    }

    public var selectedModeID: String { mode.rawValue }

    public var colorThemeOptions: [ChooserColorTheme] { ChooserColorTheme.allCases }

    /// A theme shuffle is intentionally narrower than a mode change. It is
    /// safe only when no provisional touch can commit and no authored feedback
    /// sequence is in flight. Results and committed groups remain intact.
    public var canRandomizeColorTheme: Bool {
        guard isSceneActive,
              confirmation == nil,
              Date() >= colorThemeTransitionBlockedUntil else {
            return false
        }

        switch mode {
        case .together:
            switch togetherSnapshot.phase {
            case .idle:
                return togetherSnapshot.participantTouchIDs.isEmpty && togetherVisuals.isEmpty
            case .revealed:
                return true
            case .settling, .countdown:
                return false
            }
        case .tapIn:
            switch tapInSnapshot.phase {
            case .collecting:
                return tapInPending.isEmpty
            case .revealed:
                return true
            case .countdown:
                return false
            }
        case .pinball:
            switch pinballPhase {
            case .collecting, .revealed:
                return true
            case .running, .revealing:
                return false
            }
        }
    }

    public func participantHue(at index: Int) -> Double {
        colorTheme.participantHue(at: index)
    }

    public var modeOptions: NativeModeTriplet {
        NativeModeTriplet(
            first: NativeModeOption(id: AppMode.together.rawValue, name: "Chooser", iconArtwork: .orbit),
            second: NativeModeOption(id: AppMode.tapIn.rawValue, name: "Tap In", iconArtwork: .numberedTokens),
            third: NativeModeOption(id: AppMode.pinball.rawValue, name: "Pinball", iconArtwork: .analyticTrail)
        )
    }

    public var isModeChangeEnabled: Bool {
        switch mode {
        case .together:
            switch togetherSnapshot.phase {
            case .idle, .settling, .revealed:
                return true
            case .countdown:
                return false
            }
        case .tapIn:
            if case .countdown = tapInSnapshot.phase { return false }
            return true
        case .pinball:
            switch pinballPhase {
            case .collecting, .revealed:
                return true
            case .running, .revealing:
                return false
            }
        }
    }

    public var isCriticalInteractionActive: Bool {
        switch mode {
        case .together:
            switch togetherSnapshot.phase {
            case .countdown: true
            case .idle, .settling, .revealed: false
            }
        case .tapIn:
            if case .countdown = tapInSnapshot.phase { true } else { false }
        case .pinball:
            switch pinballPhase {
            case .running, .revealing: true
            case .collecting, .revealed: false
            }
        }
    }

    public var isSettingsEnabled: Bool {
        // A first-run surface owns the screen while it is up, so the toolbar
        // button also renders disabled rather than merely refusing to open.
        // Note the deliberate asymmetry with `isModeChangeEnabled`, which must
        // NOT be gated this way — see `requestModeChange(to:)`.
        guard presentedOnboarding == nil else { return false }
        switch mode {
        case .together:
            switch togetherSnapshot.phase {
            case .idle:
                return togetherSnapshot.participantTouchIDs.isEmpty
            case .revealed:
                return true
            case .settling, .countdown:
                return false
            }
        case .tapIn:
            if case .countdown = tapInSnapshot.phase { return false }
            return true
        case .pinball:
            switch pinballPhase {
            case .collecting, .revealed:
                return true
            case .running, .revealing:
                return false
            }
        }
    }

    public var tapInCanPick: Bool {
        guard tapInPending.isEmpty, tapInSnapshot.entries.count >= 2 else { return false }
        if case .collecting = tapInSnapshot.phase { return true }
        return false
    }

    public var pinballCanStart: Bool {
        guard pinballSeats.count >= 2, pinballPlayfieldSize.width > 0, pinballPlayfieldSize.height > 0 else {
            return false
        }
        if case .collecting = pinballPhase { return true }
        return false
    }

    public func requestModeSelection(_ option: NativeModeOption) {
        guard let target = AppMode(rawValue: option.id), target != mode else { return }
        requestModeChange(to: target)
    }

    public func requestModeChange(to target: AppMode) {
        // Deliberately NOT gated on `presentedOnboarding`. This is the path a
        // `whosfirst://mode/...` App Shortcut takes, and on a cold launch it
        // races the first-run presentation. Refusing here would silently
        // swallow the shortcut with no visible failure. The mode changes
        // underneath the welcome instead, and completing the welcome retires
        // the card for whichever mode actually arrived.
        guard target != mode, isModeChangeEnabled else { return }
        confirmation = nil
        switchImmediately(to: target)
    }

    public func dismissConfirmation() {
        confirmation = nil
    }

    public func setCurrentModeAsLaunchDefault() {
        modeCore.setLaunchDefault(mode)
        launchDefaultMode = modeCore.launchDefaultMode
        feedback.play(.confirmation)
        showToast("\(mode.accessibilityName) set as default.")
        announce("\(mode.accessibilityName) set as default.")
    }

    public func selectColorTheme(_ theme: ChooserColorTheme) {
        guard theme != colorTheme else { return }
        colorTheme = theme
        colorThemeStore.saveColorTheme(theme)
        colorThemeTransitionBlockedUntil = Date().addingTimeInterval(0.24)
        feedback.play(.modeChanged)
        announce("\(theme.name) colors selected.")
    }

    /// Selects uniformly from every theme except the currently visible one.
    /// The existing selection path remains the single authority for saving,
    /// feedback, animation, and accessibility announcements.
    @discardableResult
    public func randomizeColorTheme() -> Bool {
        guard canRandomizeColorTheme else { return false }
        let candidates = colorThemeOptions.filter { $0 != colorTheme }
        guard !candidates.isEmpty else { return false }

        do {
            let index = try colorThemeRandomIndexGenerator.randomIndex(
                upperBound: candidates.count
            )
            guard candidates.indices.contains(index) else { return false }
            selectColorTheme(candidates[index])
            return true
        } catch {
            return false
        }
    }

    /// Entry point used only by the window-level physical gesture. Together's
    /// result surface also accepts the first touch of a normal new round, so a
    /// quick three-finger tap briefly replaces that result before UIKit sends
    /// cancellation. Restore the saved reveal before applying the theme so the
    /// shortcut preserves the displayed choice like it does in the other modes.
    @discardableResult
    public func randomizeColorThemeAfterPhysicalGesture() -> Bool {
        restoreTogetherRevealForThemeShuffleIfNeeded()
        return randomizeColorTheme()
    }

    @discardableResult
    public func prepareToPresentSettings() -> Bool {
        // The settings sheet and the welcome cover are presented from the same
        // anchor, so they must never overlap. That invariant is enforced here
        // and by `isSettingsEnabled`, not by SwiftUI. Adding a third
        // presentation to `ChooserRootView` would break it silently.
        guard presentedOnboarding == nil else { return false }
        guard isSettingsEnabled else { return false }
        // A second finger may open Settings while a Tap In touch is still
        // provisional. Preserve committed players, but never let that pending
        // gesture commit invisibly behind the sheet.
        if mode == .tapIn {
            tapInPending.removeAll()
        }
        return true
    }

    // MARK: - First-run introduction

    /// Called once from the root view's first appearance. Idempotent.
    public func startOnboardingIfNeeded() {
        presentOnboardingIfNeeded()
    }

    /// The mode card currently showing, if any, as a welcome page identity.
    public var presentedModeIntroPage: NativeWelcomePage? {
        guard case .modeCard(let mode) = presentedOnboarding else { return nil }
        return NativeWelcomePage(mode: mode)
    }

    /// Ordered precedence, shared by the first appearance and every session
    /// mode change, so the two are order independent on a cold launch.
    private func presentOnboardingIfNeeded() {
        // 1. Never stack one introduction on another.
        guard presentedOnboarding == nil else { return }
        // 2. Never cover a live draw or an alert, and never queue behind one.
        //    Defensive in practice: `isModeChangeEnabled` is already false
        //    during a critical interaction, so a mode change cannot land here
        //    mid-flight.
        guard confirmation == nil, !isCriticalInteractionActive else { return }
        // 3. The welcome outranks any per-mode card.
        guard seenOnboardingMoments.contains(.welcome) else {
            presentedOnboarding = .welcome
            return
        }
        // 4. Otherwise introduce the mode being entered, once.
        guard !seenOnboardingMoments.contains(.modeCard(mode)) else { return }
        presentedOnboarding = .modeCard(mode)
    }

    /// Retires whatever is showing. Finishing or skipping the welcome also
    /// retires the card for the mode on screen at that instant: the carousel
    /// just covered it, so following it with a second modal is noise. The other
    /// modes still get their card the first time they are actually opened.
    public func completeOnboarding() {
        guard let moment = presentedOnboarding else { return }
        switch moment {
        case .welcome:
            markOnboardingMomentsSeen([.welcome, .modeCard(mode)])
        case .modeCard(let cardMode):
            markOnboardingMomentsSeen([.modeCard(cardMode)])
        }
        presentedOnboarding = nil
        feedback.play(.confirmation)
    }

    /// Skipping writes exactly the same progress as finishing, so "seen" has a
    /// single meaning.
    public func skipOnboarding() {
        completeOnboarding()
    }

    /// Dismisses a visible mode card as soon as the person touches the board.
    /// Someone who already knows what to do should not have to aim at a button.
    public func noteModeInteraction() {
        guard case .modeCard = presentedOnboarding else { return }
        completeOnboarding()
    }

    /// Arms a replay from Settings. Clears no progress: replaying shows the
    /// welcome again and never restores the per-mode cards.
    public func requestWelcomeReplay() {
        isWelcomeReplayRequested = true
    }

    /// Consumed from the settings sheet's `onDismiss`, so the cover is never
    /// asked to present while the sheet is still on screen.
    public func presentWelcomeReplayIfRequested() {
        guard isWelcomeReplayRequested else { return }
        isWelcomeReplayRequested = false
        guard presentedOnboarding == nil,
              confirmation == nil,
              !isCriticalInteractionActive else { return }
        presentedOnboarding = .welcome
    }

    /// The only method that writes the onboarding store. One user action is one
    /// write, and an unchanged set writes nothing at all — which is what makes
    /// a replay provably free of side effects.
    private func markOnboardingMomentsSeen(_ moments: Set<OnboardingMoment>) {
        let updated = seenOnboardingMoments.union(moments)
        guard updated != seenOnboardingMoments else { return }
        seenOnboardingMoments = updated
        onboardingStore.saveSeenMoments(updated)
    }

    public func togetherTouchBegan(_ event: NativeTouchEvent) {
        guard mode == .together else { return }
        // The first touch on the board retires a visible introduction card.
        noteModeInteraction()
        if togetherSnapshot.participantTouchIDs.isEmpty {
            feedback.prepare()
        }
        let identity = TogetherTouchIdentity(rawValue: event.id)
        if case .revealed = togetherSnapshot.phase {
            togetherRevealedThemeShuffleBackup = TogetherRevealedThemeShuffleBackup(
                snapshot: togetherSnapshot,
                visuals: togetherVisuals,
                hueIndex: togetherHueIndex,
                capturedAt: Date()
            )
            togetherVisuals.removeAll()
            togetherHueIndex = 0
        }
        let visual = TogetherTouchVisual(
            id: identity,
            location: event.location,
            colorIndex: togetherHueIndex
        )
        if togetherCore.touchBegan(identity) {
            togetherVisuals[identity] = visual
            togetherHueIndex += 1
            feedback.play(.entryCommitted)
        }
    }

    public func togetherTouchMoved(_ event: NativeTouchEvent) {
        guard mode == .together else { return }
        let identity = TogetherTouchIdentity(rawValue: event.id)
        togetherVisuals[identity]?.location = event.location
    }

    public func togetherTouchEnded(_ event: NativeTouchEvent, cancelled: Bool) {
        guard mode == .together else { return }
        if !cancelled {
            // A completed touch is an ordinary request to begin a fresh round,
            // not the window recognizer cancelling its provisional touches.
            togetherRevealedThemeShuffleBackup = nil
        }
        let identity = TogetherTouchIdentity(rawValue: event.id)
        if cancelled {
            _ = togetherCore.touchCancelled(identity)
        } else {
            _ = togetherCore.touchEnded(identity)
        }
        if case .revealed = togetherSnapshot.phase {
            return
        }
        togetherVisuals.removeValue(forKey: identity)
    }

    /// Semantic fallback for people who cannot place several physical fingers
    /// at once. The same Together state machine, timing, haptics, and secure
    /// selection are used; only the touch identities and positions are virtual.
    @discardableResult
    public func chooseTogetherForAccessibility(
        participantCount: Int,
        in playfieldSize: CGSize
    ) -> Bool {
        guard mode == .together,
              (2...5).contains(participantCount),
              playfieldSize.width.isFinite,
              playfieldSize.height.isFinite,
              playfieldSize.width > 0,
              playfieldSize.height > 0,
              isModeChangeEnabled else {
            return false
        }

        // Parity with a physical board touch: activating the stage via an
        // accessibility action also retires a visible introduction card.
        noteModeInteraction()
        feedback.cancelSequence()
        countdownStartedAt = nil
        togetherCore.reset()
        togetherVisuals.removeAll()
        togetherHueIndex = 0

        let radiusX = min(playfieldSize.width * 0.29, 128)
        let radiusY = min(playfieldSize.height * 0.27, 112)
        let center = CGPoint(
            x: playfieldSize.width / 2,
            y: playfieldSize.height / 2
        )
        for index in 0..<participantCount {
            let angle = -CGFloat.pi / 2
                + 2 * CGFloat.pi * CGFloat(index) / CGFloat(participantCount)
            togetherTouchBegan(
                NativeTouchEvent(
                    id: UInt64.max - UInt64(index),
                    location: CGPoint(
                        x: center.x + cos(angle) * radiusX,
                        y: center.y + sin(angle) * radiusY
                    )
                )
            )
        }
        announce("Choosing from \(participantCount) people.")
        return true
    }

    public func tapInTouchBegan(_ event: NativeTouchEvent) {
        guard mode == .tapIn, case .collecting = tapInSnapshot.phase else { return }
        // The first touch on the board retires a visible introduction card.
        noteModeInteraction()
        guard tapInSnapshot.entries.count + tapInPending.count < TapInChooserCore.maximumPlayerCount else {
            feedback.play(.warning)
            announce("50-player limit reached. Pick when ready.")
            return
        }
        let number = tapInSnapshot.entries.count + tapInPending.count + 1
        tapInPending[event.id] = TapInPendingVisual(
            touchID: event.id,
            location: event.location,
            number: number
        )
    }

    public func tapInTouchMoved(_ event: NativeTouchEvent) {
        guard mode == .tapIn else { return }
        tapInPending[event.id]?.location = event.location
    }

    public func tapInTouchEnded(_ event: NativeTouchEvent, cancelled: Bool) {
        guard mode == .tapIn else { return }
        guard let pending = tapInPending.removeValue(forKey: event.id) else { return }
        guard !cancelled else { return }
        do {
            let entry = try tapInCore.addEntry()
            tapInTravelOrigins[entry.id] = pending.location
            feedback.play(.entryCommitted)
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(60))
                self?.tapInTravelOrigins.removeValue(forKey: entry.id)
            }
        } catch {
            feedback.play(.warning)
        }
    }

    @discardableResult
    public func addTapInEntryForAccessibility() -> Bool {
        guard mode == .tapIn, case .collecting = tapInSnapshot.phase else { return false }
        // Parity with a physical board touch: activating the stage via an
        // accessibility action also retires a visible introduction card.
        noteModeInteraction()
        do {
            _ = try tapInCore.addEntry()
            feedback.play(.entryCommitted)
            return true
        } catch {
            feedback.play(.warning)
            return false
        }
    }

    public func undoTapIn() {
        do {
            let removed = try tapInCore.undo()
            tapInTravelOrigins.removeValue(forKey: removed.id)
            feedback.play(.undo)
        } catch {
            feedback.play(.warning)
        }
    }

    public func requestClearTapIn() {
        guard !tapInSnapshot.entries.isEmpty else { return }
        confirmation = .clearTapIn(count: tapInSnapshot.entries.count)
    }

    public func confirmClearTapIn() {
        confirmation = nil
        guard !tapInSnapshot.entries.isEmpty else { return }
        do {
            try tapInCore.clear()
            tapInTravelOrigins.removeAll()
            feedback.play(.clearCommitted)
        } catch {
            feedback.play(.warning)
        }
    }

    public func pickTapIn() {
        guard tapInCanPick else { return }
        do {
            try tapInCore.pick()
        } catch {
            feedback.play(.warning)
        }
    }

    public func pickTapInAgain() {
        do {
            try tapInCore.pickAgain()
        } catch {
            feedback.play(.warning)
        }
    }

    public func dismissTapInResult() {
        do {
            try tapInCore.dismissResult()
        } catch {
            feedback.play(.warning)
        }
    }

    public func newTapInGroup() {
        tapInCore.newGroup()
        tapInPending.removeAll()
        tapInTravelOrigins.removeAll()
        feedback.play(.clearCommitted)
    }

    public func updatePinballPlayfield(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let changed = abs(size.width - pinballPlayfieldSize.width) > 0.5 ||
            abs(size.height - pinballPlayfieldSize.height) > 0.5
        guard changed else { return }
        if pinballPhase.run != nil {
            cancelPinballRun(announceCancellation: true)
        }
        pinballPlayfieldSize = size
    }

    public func addPinballSeat(at point: CGPoint) {
        guard mode == .pinball, case .collecting = pinballPhase else { return }
        // The first touch on the board retires a visible introduction card.
        noteModeInteraction()
        guard pinballSeats.count < 12 else {
            feedback.play(.warning)
            announce("12-seat limit reached. Flick when ready.")
            return
        }
        guard pinballPlayfieldSize.width > 0, pinballPlayfieldSize.height > 0 else { return }

        let normalized = normalizedPinballPoint(point)
        let centerDistance = hypot(normalized.x - 0.5, normalized.y - 0.5)
        guard centerDistance > 0.025 else {
            feedback.play(.warning)
            announce("Tap nearer your seat around the edge of the playfield.")
            return
        }

        let seat = NativePinballSeat(id: pinballSeats.count + 1, normalizedLocation: normalized)
        pinballSeats.append(seat)
        pinballTravelOrigins[seat.id] = point
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(70))
            self?.pinballTravelOrigins.removeValue(forKey: seat.id)
        }
        feedback.play(.entryCommitted)
        let readiness = pinballSeats.count == 2
            ? " Flick in any direction when ready."
            : ""
        announce("Seat \(seat.id) added. \(pinballSeats.count) seats total.\(readiness)")
    }

    @discardableResult
    public func addPinballSeatForAccessibility() -> Bool {
        guard pinballSeats.count < 12 else { return false }
        // Parity with a physical board touch: activating the stage via an
        // accessibility action also retires a visible introduction card.
        noteModeInteraction()
        configureAccessiblePinballSeats(count: max(2, pinballSeats.count + 1))
        return true
    }

    public func configureAccessiblePinballSeats(count: Int) {
        guard mode == .pinball, case .collecting = pinballPhase else { return }
        let count = min(12, max(2, count))
        pinballSeats = (0..<count).map { index in
            let angle = -CGFloat.pi / 2 + 2 * CGFloat.pi * CGFloat(index) / CGFloat(count)
            return NativePinballSeat(
                id: index + 1,
                normalizedLocation: CGPoint(
                    x: 0.5 + cos(angle) * 0.43,
                    y: 0.5 + sin(angle) * 0.43
                )
            )
        }
        pinballTravelOrigins.removeAll()
        feedback.play(.confirmation)
        announce("Configured \(count) evenly spaced seats. Flick in any direction when ready.")
    }

    public func undoPinballSeat() {
        guard case .collecting = pinballPhase, let removed = pinballSeats.popLast() else { return }
        pinballTravelOrigins.removeValue(forKey: removed.id)
        feedback.play(.undo)
        announce("Seat \(removed.id) removed. \(pinballSeats.count) seats total.")
    }

    public func requestClearPinball() {
        guard !pinballSeats.isEmpty else { return }
        confirmation = .clearPinball(count: pinballSeats.count)
    }

    public func confirmClearPinball() {
        confirmation = nil
        guard !pinballSeats.isEmpty else { return }
        clearPinballGroup()
        feedback.play(.clearCommitted)
    }

    public func handlePinballGesture(
        _ action: NativePinballGestureAction,
        reduceMotion: Bool
    ) {
        guard mode == .pinball, case .collecting = pinballPhase else { return }
        // The first touch on the board retires a visible introduction card.
        noteModeInteraction()
        switch action {
        case .seat(let payload):
            addPinballSeat(at: payload.end)
        case .flick(let payload):
            guard pinballCanStart, let intent = payload.flickIntent else {
                feedback.play(.warning)
                announce("Add at least two seats before flicking.")
                return
            }
            startPinball(flickIntent: intent, reduceMotion: reduceMotion)
        }
    }

    public func startPinball(
        flickIntent: PinballFlickIntent,
        reduceMotion: Bool
    ) {
        guard pinballCanStart else { return }
        do {
            let partition = try makePinballPartition()
            let result = try PinballRoundResolver.secureFlickRound(
                partition: partition,
                intent: flickIntent,
                bumpers: pinballBumperField(for: partition)
            )
            let duration = try PinballFlickLaunchPolicy.flightDuration(
                forSpeed: flickIntent.speed
            )
            let strength = try PinballFlickLaunchPolicy.normalizedStrength(
                forSpeed: flickIntent.speed
            )
            try beginPinballRun(
                result: result,
                flightDuration: duration,
                normalizedStrength: strength,
                reduceMotion: reduceMotion
            )
        } catch {
            feedback.play(.warning)
            announce("Pinball could not launch. Flick again when ready.")
        }
    }

    /// Accessibility fallback for people who cannot perform a directional flick.
    /// The system generator supplies a secure direction from the visible center
    /// release point when a directional gesture is unavailable.
    public func startPinball(reduceMotion: Bool) {
        guard pinballCanStart else { return }
        do {
            let partition = try makePinballPartition()
            var random = SecurePinballRandomSource()
            let speed = PinballFlickLaunchPolicy.speedRange.lowerBound +
                (PinballFlickLaunchPolicy.speedRange.upperBound -
                    PinballFlickLaunchPolicy.speedRange.lowerBound) / 2
            let intent = try PinballFlickIntent(
                releasePoint: partition.center,
                direction: PinballSampling.uniformDirection(using: &random),
                speed: speed
            )
            let result = try PinballRoundResolver.flickRound(
                partition: partition,
                intent: intent,
                using: &random,
                bumpers: pinballBumperField(for: partition)
            )
            try beginPinballRun(
                result: result,
                flightDuration: try PinballFlickLaunchPolicy.flightDuration(forSpeed: speed),
                normalizedStrength: try PinballFlickLaunchPolicy.normalizedStrength(
                    forSpeed: speed
                ),
                reduceMotion: reduceMotion
            )
        } catch {
            feedback.play(.warning)
            announce("Pinball could not launch. Try again when ready.")
        }
    }

    private func beginPinballRun(
        result: PinballRoundResult,
        flightDuration: TimeInterval,
        normalizedStrength: CGFloat,
        reduceMotion: Bool
    ) throws {
        pinballTask?.cancel()
        pinballTask = nil
        pinballPendingCollisionFeedback.removeAll()
        pinballEndpointSettleCueRunID = nil
        pinballFinishEnqueuedRunID = nil
        let curve = try PinballMotionProfile(duration: flightDuration)
        let launchEnergy = PinballFlickLaunchPolicy.launchEnergy(
            forStrength: normalizedStrength
        )
        let run = NativePinballRun(
            result: result,
            curve: curve,
            normalizedStrength: Double(normalizedStrength),
            launchEnergy: Double(launchEnergy)
        )

        if reduceMotion {
            pinballPhase = .revealing(run: run, pulse: 1, isLit: true)
            feedback.play(.pinballSettle)
            announce("Seat \(result.winningSeatID) goes first.")
            pinballTask = Task { @MainActor [weak self] in
                do {
                    try await Task.sleep(for: Self.pinballWinnerRevealDuration)
                } catch {
                    return
                }
                guard !Task.isCancelled,
                      let self,
                      case .revealing(let activeRun, _, _) = self.pinballPhase,
                      activeRun.id == run.id else { return }
                self.pinballPhase = .revealed(run)
            }
        } else {
            pinballPhase = .running(run)
            pinballPendingCollisionFeedback = Dictionary(
                uniqueKeysWithValues: Self.pinballCollisionFeedbackEvents(for: run).map {
                    ($0.vertexIndex, $0)
                }
            )
            feedback.play(.pinballLaunch(strength: Double(normalizedStrength)))
            announce("Pinball running from \(pinballSeats.count) seats.")
        }
    }

    /// Delivers a collision cue only when the active SpriteKit replay presents
    /// the corresponding analytic wall vertex. Removing the expected event
    /// makes duplicated frames, rebuilt views, and stale scene callbacks inert.
    func handlePinballRenderedImpact(
        runID: UUID,
        impact: NativeAnalyticReplayImpact
    ) {
        guard case .running(let run) = pinballPhase,
              run.id == runID,
              let expected = pinballPendingCollisionFeedback[impact.vertexIndex],
              abs(expected.progress - impact.progress) <= 1e-7,
              expected.isFairnessDeflection == impact.isFairnessDeflection else { return }

        pinballPendingCollisionFeedback.removeValue(forKey: impact.vertexIndex)
        if expected.isFairnessDeflection {
            feedback.play(
                .pinballFairBounce(
                    speedFraction: impact.speedFraction,
                    normalImpulseFraction: impact.wallNormalImpulseFraction
                )
            )
            announce("Fair bounce.")
        } else {
            feedback.play(
                .pinballCollision(
                speedFraction: impact.speedFraction,
                normalImpulseFraction: impact.wallNormalImpulseFraction,
                isCorner: impact.isCorner
                )
            )
        }
    }

    /// The replay scene owns the physical endpoint settle. Deliver its thud on
    /// the exact frame that visibly reaches maximum compression, while the
    /// ball is still the same running SpriteKit object.
    func handlePinballRenderedEndpointCompression(runID: UUID) {
        guard case .running(let run) = pinballPhase,
              run.id == runID,
              pinballEndpointSettleCueRunID != runID else { return }

        pinballEndpointSettleCueRunID = runID
        pinballPendingCollisionFeedback.removeAll()
        feedback.play(.pinballSettle)
    }

    /// The visible replay owns completion timing. The resolved analytic run
    /// remains the sole authority for endpoint and winner identity.
    func handlePinballReplayFinished(runID: UUID) {
        guard case .running(let run) = pinballPhase,
              run.id == runID,
              pinballFinishEnqueuedRunID != runID else { return }

        pinballFinishEnqueuedRunID = runID
        pinballTask?.cancel()
        pinballTask = Task { @MainActor [weak self] in
            // Leave the SpriteKit update stack before publishing SwiftUI state.
            await Task.yield()
            guard !Task.isCancelled, let self else { return }
            await self.performPinballReveal(run)
        }
    }

    public func playPinballAgain(reduceMotion: Bool) {
        guard case .revealed = pinballPhase else { return }
        pinballPhase = .collecting
        announce("Same seats ready. Flick when ready.")
    }

    public func dismissPinballResult() {
        guard case .revealed = pinballPhase else { return }
        pinballPhase = .collecting
        announce("Same seats ready. Flick when ready.")
    }

    public func newPinballGroup() {
        clearPinballGroup()
        feedback.play(.clearCommitted)
        announce("New Pinball group ready.")
    }

    public func pinballPartition() -> PinballRadialPartition? {
        try? makePinballPartition()
    }

    public func pinballPoint(for seat: NativePinballSeat) -> CGPoint {
        CGPoint(
            x: seat.normalizedLocation.x * pinballPlayfieldSize.width,
            y: seat.normalizedLocation.y * pinballPlayfieldSize.height
        )
    }

    /// The settled seat token layout, computed once and reused.
    ///
    /// Bumper aware: seats shrink when they would otherwise leave the ball no
    /// way between adjacent rings.
    ///
    /// The drawn chit and the physics circle must be the same circle. They used
    /// to be two separate `bumperAwareLayout` calls that happened to receive
    /// identical arguments — the same value by coincidence, not the same object.
    /// Every parameter added to that call was another chance for the two to
    /// drift, and a drift is silent: the ball would collide with circles that
    /// are not where the numbers are drawn, which feeds the reachability solver
    /// and so is unfairness-adjacent, not merely cosmetic. One cache, one call.
    ///
    /// The cache also matters for cost: the layout runs a nested binary search
    /// and the view asks for it inside a `GeometryReader` body.
    func pinballSeatTokenLayout(
        for partition: PinballRadialPartition
    ) -> PinballSeatTokenLayout? {
        let key = PinballLayoutCacheKey(
            playfieldSize: pinballPlayfieldSize,
            seats: pinballSeats.map(\.normalizedLocation)
        )
        if let cached = pinballLayoutCache, cached.key == key {
            return cached.layout
        }
        let layout = PinballSeatTokenSizing.bumperAwareLayout(
            for: partition,
            in: pinballPlayfieldSize,
            ballRadius: NativePinballReplayMetrics.ballDiameter / 2
        )
        pinballLayoutCache = (key, layout)
        return layout
    }

    public func pinballSeatTokenLayout() -> PinballSeatTokenLayout? {
        guard let partition = pinballPartition() else { return nil }
        return pinballSeatTokenLayout(for: partition)
    }

    /// The bumper field for the current seats, or an empty field when the board
    /// is not laid out yet. Shares the cached layout above, so the physics
    /// circles are literally the drawn circles.
    func pinballBumperField(for partition: PinballRadialPartition) -> PinballBumperField {
        guard let layout = pinballSeatTokenLayout(for: partition) else { return .empty }
        return PinballBumperField(
            from: layout,
            ballRadius: NativePinballReplayMetrics.ballDiameter / 2
        )
    }

    /// Bumper contacts along a run's path, for presentation.
    ///
    /// Resolves against `pinballBumperField(for:)` — the same field the marcher
    /// collided with — so a lit ring is provably the circle the ball hit.
    func pinballBumperContacts(for run: NativePinballRun) -> [PinballBumperContact] {
        guard let partition = pinballPartition() else { return [] }
        return run.result.trajectory.bumperContacts(in: pinballBumperField(for: partition))
    }

    public func handleSceneBecameInactive() {
        // Deliberately does NOT clear `presentedOnboarding`, which is the one
        // exception to this method's "wipe transient state" contract. The
        // introduction is not round state: dismissing it on a phone call would
        // lose the tour without ever writing the flag, so it would come back on
        // some later launch. Do not "tidy" this by adding it below.
        isSceneActive = false
        togetherRevealedThemeShuffleBackup = nil
        countdownStartedAt = nil
        feedback.stopAll()
        tapInPending.removeAll()
        togetherCore.cancelForLifecycle()
        togetherVisuals.removeAll()
        tapInCore.cancelForLifecycle()
        if pinballPhase.run != nil {
            cancelPinballRun(announceCancellation: true)
        }
    }

    public func handleSceneBecameActive() {
        isSceneActive = true
        feedback.prepare()
    }

    private func wireCoreEvents() {
        modeCore.eventHandler = { [weak self] event in
            guard let self else { return }
            switch event {
            case .stateChanged(let snapshot):
                self.mode = snapshot.currentMode
                self.launchDefaultMode = snapshot.launchDefaultMode
            case .accessibilityAnnouncement(let announcement):
                self.announce(announcement.message)
            }
        }

        togetherCore.eventHandler = { [weak self] event in
            guard let self else { return }
            switch event {
            case .stateChanged(let snapshot):
                let previousPhase = self.togetherSnapshot.phase
                self.togetherSnapshot = snapshot
                self.syncTogetherVisuals(with: snapshot)
                self.handleTogetherPhaseChange(from: previousPhase, to: snapshot.phase)
            case .accessibilityAnnouncement(let announcement):
                self.announce(announcement.message)
            case .failure:
                self.feedback.play(.warning)
            }
        }

        tapInCore.eventHandler = { [weak self] event in
            guard let self else { return }
            switch event {
            case .stateChanged(let snapshot):
                let previousPhase = self.tapInSnapshot.phase
                self.tapInSnapshot = snapshot
                self.handleTapInPhaseChange(from: previousPhase, to: snapshot.phase)
            case .accessibilityAnnouncement(let announcement):
                self.announce(announcement.message)
            case .failure:
                self.feedback.play(.warning)
            }
        }
    }

    private func switchImmediately(to target: AppMode) {
        resetCurrentMode()
        modeCore.select(target, persistAsLaunchDefault: false)
        mode = target
        feedback.play(.modeChanged)
        // The single mode-change authority for the menu, App Shortcuts, and
        // deep links alike, so this one hook covers every route into a mode.
        presentOnboardingIfNeeded()
    }

    private func resetCurrentMode() {
        countdownStartedAt = nil
        togetherRevealedThemeShuffleBackup = nil
        // A mode selection is an immediate reset. Stop the full tactile/audio
        // envelope as well as scheduled anticipation and collision events.
        feedback.stopAll()
        switch mode {
        case .together:
            togetherCore.reset()
            togetherVisuals.removeAll()
            togetherHueIndex = 0
        case .tapIn:
            tapInCore.newGroup()
            tapInPending.removeAll()
            tapInTravelOrigins.removeAll()
        case .pinball:
            clearPinballGroup()
        }
    }

    private func syncTogetherVisuals(with snapshot: TogetherChooserSnapshot) {
        if case .revealed = snapshot.phase { return }
        let active = Set(snapshot.participantTouchIDs)
        togetherVisuals = togetherVisuals.filter { active.contains($0.key) }
        if active.isEmpty {
            togetherHueIndex = 0
        }
    }

    private func handleTogetherPhaseChange(from old: TogetherPhase, to new: TogetherPhase) {
        if isRestoringTogetherRevealForThemeShuffle {
            countdownStartedAt = nil
            feedback.cancelSequence()
            return
        }

        switch new {
        case .countdown where !sameTogetherPhaseKind(old, new):
            togetherRevealedThemeShuffleBackup = nil
            startCountdownFeedback(.togetherCountdown)
        case .countdown:
            break
        case .revealed where !sameTogetherPhaseKind(old, new):
            countdownStartedAt = nil
            feedback.cancelSequence()
            feedback.play(.chooserWinner)
        case .settling:
            countdownStartedAt = nil
            // A late finger can move an active countdown back into the silent
            // stability window. Stop the old anticipation envelope so its
            // remaining impacts cannot leak into the restarted settle.
            if case .countdown = old {
                feedback.cancelSequence()
            }
            feedback.play(.settling(duration: togetherCore.settlingDuration))
        case .idle:
            countdownStartedAt = nil
            feedback.cancelSequence()
        case .revealed:
            break
        }
    }

    private func restoreTogetherRevealForThemeShuffleIfNeeded() {
        guard mode == .together,
              let backup = togetherRevealedThemeShuffleBackup else {
            return
        }
        togetherRevealedThemeShuffleBackup = nil

        // A UIKit tap recognizer resolves quickly. Bounding this restoration
        // prevents an unrelated later gesture from reviving a stale result if
        // the system cancelled touches for some other reason.
        guard Date().timeIntervalSince(backup.capturedAt) <= 2 else { return }

        isRestoringTogetherRevealForThemeShuffle = true
        defer { isRestoringTogetherRevealForThemeShuffle = false }
        guard togetherCore.restoreRevealedSnapshot(backup.snapshot) else { return }
        togetherVisuals = backup.visuals
        togetherHueIndex = backup.hueIndex
    }

    private func handleTapInPhaseChange(from old: TapInPhase, to new: TapInPhase) {
        switch new {
        case .countdown where !sameTapInPhaseKind(old, new):
            startCountdownFeedback(.tapInCountdown(duration: 1.0))
        case .countdown:
            break
        case .revealed where !sameTapInPhaseKind(old, new):
            countdownStartedAt = nil
            feedback.cancelSequence()
            feedback.play(.choiceWinner)
        case .collecting:
            countdownStartedAt = nil
            feedback.cancelSequence()
        case .revealed:
            break
        }
    }

    private func startCountdownFeedback(_ cue: NativeFeedbackCue) {
        // Start the authored pattern first, then anchor the visual clock as
        // close as possible to the player's real start. If Core Haptics must
        // restart its engine, setup latency is paid before SwiftUI begins the
        // matching compression timeline instead of visibly leading it.
        feedback.play(cue)
        countdownStartedAt = Date()
    }

    private func makePinballPartition() throws -> PinballRadialPartition {
        // Keep the complete satin ball and its contact shadow inside the
        // clipped playfield while still letting it visually compress at walls.
        let collisionInset = NativePinballReplayMetrics.collisionInset
        let bounds = CGRect(origin: .zero, size: pinballPlayfieldSize).insetBy(
            dx: collisionInset,
            dy: collisionInset
        )
        let taps = pinballSeats.map { seat in
            let raw = pinballPoint(for: seat)
            let clamped = CGPoint(
                x: min(max(raw.x, bounds.minX), bounds.maxX),
                y: min(max(raw.y, bounds.minY), bounds.maxY)
            )
            return PinballSeatTap(seatID: seat.id, point: clamped)
        }
        return try PinballRadialPartition(bounds: bounds, taps: taps)
    }

    private func normalizedPinballPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(1, max(0, point.x / pinballPlayfieldSize.width)),
            y: min(1, max(0, point.y / pinballPlayfieldSize.height))
        )
    }

    private func performPinballReveal(_ run: NativePinballRun) async {
        guard case .running(let activeRun) = pinballPhase,
              activeRun.id == run.id else { return }

        pinballPendingCollisionFeedback.removeAll()

        pinballPhase = .revealing(run: run, pulse: 1, isLit: true)
        announce("Seat \(run.result.winningSeatID) goes first.")

        do {
            try await Task.sleep(for: Self.pinballWinnerRevealDuration)
        } catch {
            return
        }
        guard !Task.isCancelled,
              case .revealing(let activeRun, _, _) = pinballPhase,
              activeRun.id == run.id else { return }
        pinballPhase = .revealed(run)
        pinballFinishEnqueuedRunID = nil
        pinballTask = nil
    }

    private func cancelPinballRun(announceCancellation: Bool) {
        pinballTask?.cancel()
        pinballTask = nil
        pinballPendingCollisionFeedback.removeAll()
        pinballEndpointSettleCueRunID = nil
        pinballFinishEnqueuedRunID = nil
        pinballPhase = .collecting
        feedback.stopAll()
        if announceCancellation {
            announce("Pinball canceled. Flick again when ready.")
        }
    }

    private func clearPinballGroup() {
        pinballTask?.cancel()
        pinballTask = nil
        pinballPendingCollisionFeedback.removeAll()
        pinballEndpointSettleCueRunID = nil
        pinballFinishEnqueuedRunID = nil
        pinballSeats.removeAll()
        pinballTravelOrigins.removeAll()
        pinballPhase = .collecting
    }

    private func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            self?.toastMessage = nil
        }
    }

    static func pinballCollisionFeedbackEvents(
        for run: NativePinballRun
    ) -> [NativePinballCollisionFeedbackEvent] {
        let trajectory = run.result.trajectory
        let totalDistance = trajectory.launch.distance
        guard totalDistance > 0 else { return [] }

        let lastAllowedTime = max(0, run.curve.duration - pinballWinnerQuietWindow)
        var events: [NativePinballCollisionFeedbackEvent] = []
        var lastAcceptedTime: TimeInterval = 0
        let fairnessDeflectorVertexIndex = run.result.fairnessDeflectorVertexIndex

        for (segmentOffset, segment) in trajectory.segments.dropLast().enumerated() {
            let vertexIndex = segmentOffset + 1
            let pathProgress = min(1, max(0, segment.endDistance / totalDistance))
            let time = run.curve.elapsedTime(atProgress: pathProgress)
            let isFairnessDeflection = vertexIndex == fairnessDeflectorVertexIndex

            // Leave the launch and winner their own tactile space. Closely
            // clustered early bounces remain visible but become one readable
            // physical impact instead of saturating the Taptic Engine. The one
            // authored Fair Bounce is exempt: its haptic is part of explaining
            // the visible intervention and must land on that exact frame.
            if !isFairnessDeflection {
                guard time >= pinballCollisionMinimumSpacing,
                      time <= lastAllowedTime,
                      time - lastAcceptedTime >= pinballCollisionMinimumSpacing else { continue }
            }

            events.append(
                NativePinballCollisionFeedbackEvent(
                    vertexIndex: vertexIndex,
                    progress: pathProgress,
                    time: time,
                    speedFraction: run.launchEnergy *
                        Double(run.curve.remainingSpeedFraction(at: time)),
                    isCorner: Self.isPinballCorner(segment.end, in: trajectory.bounds),
                    isFairnessDeflection: isFairnessDeflection
                )
            )
            // A Fair Bounce cannot be thinned, but it still reserves tactile
            // space so a routine wall tap cannot blur its springy body.
            lastAcceptedTime = time
        }

        return events
    }

    private static func isPinballCorner(_ point: CGPoint, in bounds: CGRect) -> Bool {
        let tolerance = max(1e-6, max(bounds.width, bounds.height) * 1e-9)
        let hitsVertical = abs(point.x - bounds.minX) <= tolerance ||
            abs(point.x - bounds.maxX) <= tolerance
        let hitsHorizontal = abs(point.y - bounds.minY) <= tolerance ||
            abs(point.y - bounds.maxY) <= tolerance
        return hitsVertical && hitsHorizontal
    }

    private func announce(_ message: String) {
        AccessibilityNotification.Announcement(message).post()
    }

    private func sameTogetherPhaseKind(_ lhs: TogetherPhase, _ rhs: TogetherPhase) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.settling, .settling), (.countdown, .countdown), (.revealed, .revealed): true
        default: false
        }
    }

    private func sameTapInPhaseKind(_ lhs: TapInPhase, _ rhs: TapInPhase) -> Bool {
        switch (lhs, rhs) {
        case (.collecting, .collecting), (.countdown, .countdown), (.revealed, .revealed): true
        default: false
        }
    }
}
