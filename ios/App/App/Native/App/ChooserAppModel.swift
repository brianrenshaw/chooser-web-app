import Accessibility
import CoreGraphics
import Foundation
import Observation

public struct TogetherTouchVisual: Equatable {
    public let id: TogetherTouchIdentity
    public var location: CGPoint
    public let hue: Double
}

public struct TapInPendingVisual: Equatable {
    public let touchID: UInt64
    public var location: CGPoint
    public let number: Int
    public let hue: Double
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
    public let curve: PinballDecelerationCurve

    public init(
        id: UUID = UUID(),
        result: PinballRoundResult,
        curve: PinballDecelerationCurve
    ) {
        self.id = id
        self.result = result
        self.curve = curve
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
    case switchMode(target: AppMode, itemCount: Int, itemName: String)
    case clearTapIn(count: Int)
    case clearPinball(count: Int)

    public var id: String {
        switch self {
        case .switchMode(let target, _, _): "switch-\(target.rawValue)"
        case .clearTapIn: "clear-tap-in"
        case .clearPinball: "clear-pinball"
        }
    }
}

@MainActor
@Observable
public final class ChooserAppModel {
    public private(set) var mode: AppMode
    public private(set) var launchDefaultMode: AppMode
    public private(set) var togetherSnapshot: TogetherChooserSnapshot
    public private(set) var tapInSnapshot: TapInChooserSnapshot
    public private(set) var togetherVisuals: [TogetherTouchIdentity: TogetherTouchVisual] = [:]
    public private(set) var tapInPending: [UInt64: TapInPendingVisual] = [:]
    public private(set) var tapInTravelOrigins: [UInt64: CGPoint] = [:]
    public private(set) var pinballSeats: [NativePinballSeat] = []
    public private(set) var pinballPhase: NativePinballPhase = .collecting
    public private(set) var pinballPlayfieldSize: CGSize = .zero
    public private(set) var countdownStartedAt: Date?
    public var confirmation: ChooserConfirmation?
    public var isInformationPresented = false
    public private(set) var toastMessage: String?

    @ObservationIgnored private let modeCore: AppModeCore
    @ObservationIgnored private let togetherCore: TogetherChooserCore
    @ObservationIgnored private let tapInCore: TapInChooserCore
    @ObservationIgnored private let feedback: any NativeFeedbackCoordinating
    @ObservationIgnored private var countdownFeedbackTask: Task<Void, Never>?
    @ObservationIgnored private var pinballTask: Task<Void, Never>?
    @ObservationIgnored private var pinballCollisionFeedbackTask: Task<Void, Never>?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    @ObservationIgnored private var togetherHueIndex = 0

    public init(
        modeStore: LaunchDefaultModePersisting = UserDefaultsLaunchDefaultModeStore(),
        togetherCore: TogetherChooserCore = TogetherChooserCore(),
        tapInCore: TapInChooserCore = TapInChooserCore(),
        feedback: (any NativeFeedbackCoordinating)? = nil
    ) {
        let modeCore = AppModeCore(store: modeStore)
        self.modeCore = modeCore
        self.togetherCore = togetherCore
        self.tapInCore = tapInCore
        self.feedback = feedback ?? NativeFeedbackCoordinator(audioPolicy: .always)
        mode = modeCore.currentMode
        launchDefaultMode = modeCore.launchDefaultMode
        togetherSnapshot = togetherCore.snapshot
        tapInSnapshot = tapInCore.snapshot
        wireCoreEvents()
        self.feedback.prepare()
    }

    deinit {
        countdownFeedbackTask?.cancel()
        pinballTask?.cancel()
        pinballCollisionFeedbackTask?.cancel()
        toastTask?.cancel()
    }

    public var selectedModeID: String { mode.rawValue }

    public var modeOptions: NativeModeTriplet {
        NativeModeTriplet(
            first: NativeModeOption(id: AppMode.together.rawValue, name: "Together", iconArtwork: .orbit),
            second: NativeModeOption(id: AppMode.tapIn.rawValue, name: "Tap In", iconArtwork: .numberedTokens),
            third: NativeModeOption(id: AppMode.pinball.rawValue, name: "Pinball", iconArtwork: .analyticTrail)
        )
    }

    public var isModeChangeEnabled: Bool {
        guard tapInPending.isEmpty else { return false }
        switch mode {
        case .together:
            if case .countdown = togetherSnapshot.phase { return false }
            return togetherSnapshot.participantTouchIDs.isEmpty
        case .tapIn:
            if case .countdown = tapInSnapshot.phase { return false }
            return true
        case .pinball:
            if case .collecting = pinballPhase { return true }
            return false
        }
    }

    public var isCriticalInteractionActive: Bool {
        switch mode {
        case .together:
            switch togetherSnapshot.phase {
            case .settling, .countdown: true
            case .idle, .revealed: false
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

    public func requestModeCycle(to option: NativeModeOption) {
        guard let target = AppMode(rawValue: option.id), target != mode else { return }
        requestModeChange(to: target)
    }

    public func requestModeChange(to target: AppMode) {
        guard target != mode, isModeChangeEnabled else { return }

        switch mode {
        case .tapIn where !tapInSnapshot.entries.isEmpty:
            confirmation = .switchMode(
                target: target,
                itemCount: tapInSnapshot.entries.count,
                itemName: tapInSnapshot.entries.count == 1 ? "player" : "players"
            )
        case .pinball where !pinballSeats.isEmpty:
            confirmation = .switchMode(
                target: target,
                itemCount: pinballSeats.count,
                itemName: pinballSeats.count == 1 ? "seat" : "seats"
            )
        default:
            switchImmediately(to: target)
        }
    }

    public func confirmPendingModeChange() {
        guard case .switchMode(let target, _, _) = confirmation else { return }
        confirmation = nil
        switchImmediately(to: target)
    }

    public func dismissConfirmation() {
        confirmation = nil
    }

    public func setCurrentModeAsLaunchDefault() {
        modeCore.setLaunchDefault(mode)
        launchDefaultMode = modeCore.launchDefaultMode
        feedback.play(.winner)
        showToast("\(mode.accessibilityName) set as default.")
        announce("\(mode.accessibilityName) set as default.")
    }

    public func togetherTouchBegan(_ event: NativeTouchEvent) {
        guard mode == .together else { return }
        let identity = TogetherTouchIdentity(rawValue: event.id)
        if case .revealed = togetherSnapshot.phase {
            togetherVisuals.removeAll()
            togetherHueIndex = 0
        }
        let visual = TogetherTouchVisual(
            id: identity,
            location: event.location,
            hue: goldenAngleHue(at: togetherHueIndex)
        )
        if togetherCore.touchBegan(identity) {
            togetherVisuals[identity] = visual
            togetherHueIndex += 1
            feedback.play(.entryCommitted)
        }
    }

    public func togetherTouchMoved(_ event: NativeTouchEvent) {
        let identity = TogetherTouchIdentity(rawValue: event.id)
        togetherVisuals[identity]?.location = event.location
    }

    public func togetherTouchEnded(_ event: NativeTouchEvent, cancelled: Bool) {
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

    public func tapInTouchBegan(_ event: NativeTouchEvent) {
        guard mode == .tapIn, case .collecting = tapInSnapshot.phase else { return }
        guard tapInSnapshot.entries.count + tapInPending.count < TapInChooserCore.maximumPlayerCount else {
            feedback.play(.warning)
            announce("50-player limit reached. Pick when ready.")
            return
        }
        let number = tapInSnapshot.entries.count + tapInPending.count + 1
        tapInPending[event.id] = TapInPendingVisual(
            touchID: event.id,
            location: event.location,
            number: number,
            hue: goldenAngleHue(at: number - 1)
        )
        feedback.play(.entryCommitted)
    }

    public func tapInTouchMoved(_ event: NativeTouchEvent) {
        tapInPending[event.id]?.location = event.location
    }

    public func tapInTouchEnded(_ event: NativeTouchEvent, cancelled: Bool) {
        guard let pending = tapInPending.removeValue(forKey: event.id) else { return }
        guard !cancelled else { return }
        do {
            let entry = try tapInCore.addEntry()
            tapInTravelOrigins[entry.id] = pending.location
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
            feedback.play(.modeChanged)
        } catch {
            feedback.play(.warning)
        }
    }

    public func requestClearTapIn() {
        guard !tapInSnapshot.entries.isEmpty else { return }
        confirmation = .clearTapIn(count: tapInSnapshot.entries.count)
    }

    public func confirmClearTapIn() {
        guard case .clearTapIn = confirmation else { return }
        confirmation = nil
        do {
            try tapInCore.clear()
            tapInTravelOrigins.removeAll()
            feedback.play(.destructive)
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

    public func newTapInGroup() {
        tapInCore.newGroup()
        tapInPending.removeAll()
        tapInTravelOrigins.removeAll()
        feedback.play(.destructive)
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
        guard pinballSeats.count < 12 else {
            feedback.play(.warning)
            announce("12-seat limit reached. Start when ready.")
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
        feedback.play(.entryCommitted)
        announce("Seat \(seat.id) added. \(pinballSeats.count) seats total.")
    }

    @discardableResult
    public func addPinballSeatForAccessibility() -> Bool {
        guard pinballSeats.count < 12 else { return false }
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
        feedback.play(.modeChanged)
        announce("Configured \(count) evenly spaced seats.")
    }

    public func undoPinballSeat() {
        guard case .collecting = pinballPhase, let removed = pinballSeats.popLast() else { return }
        feedback.play(.modeChanged)
        announce("Seat \(removed.id) removed. \(pinballSeats.count) seats total.")
    }

    public func requestClearPinball() {
        guard !pinballSeats.isEmpty else { return }
        confirmation = .clearPinball(count: pinballSeats.count)
    }

    public func confirmClearPinball() {
        guard case .clearPinball = confirmation else { return }
        confirmation = nil
        clearPinballGroup()
        feedback.play(.destructive)
    }

    public func startPinball(reduceMotion: Bool) {
        guard pinballCanStart else { return }
        pinballTask?.cancel()

        do {
            let partition = try makePinballPartition()
            let perimeter = partition.bounds.width * 2 + partition.bounds.height * 2
            var random = SecurePinballRandomSource()
            let result = try PinballRoundResolver.randomRound(
                partition: partition,
                distanceRange: (perimeter * 10)...(perimeter * 16),
                using: &random
            )
            let curve = try PinballDecelerationCurve(duration: 5, exponent: 3.2)
            let run = NativePinballRun(result: result, curve: curve)

            if reduceMotion {
                pinballPhase = .revealing(run: run, pulse: 1, isLit: true)
                feedback.play(.winner)
                announce("Seat \(result.winningSeatID) goes first.")
                pinballTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .milliseconds(650))
                    guard !Task.isCancelled else { return }
                    self?.pinballPhase = .revealed(run)
                }
            } else {
                pinballPhase = .running(run)
                announce("Pinball running from \(pinballSeats.count) seats.")
                startPinballCollisionFeedback(for: run)
                pinballTask = Task { @MainActor [weak self] in
                    do {
                        try await Task.sleep(for: .seconds(5))
                        guard !Task.isCancelled else { return }
                        await self?.performPinballReveal(run)
                    } catch {
                        return
                    }
                }
            }
        } catch {
            feedback.play(.warning)
            announce("Pinball could not start. Adjust the seats and try again.")
        }
    }

    public func playPinballAgain(reduceMotion: Bool) {
        guard case .revealed = pinballPhase else { return }
        pinballPhase = .collecting
        startPinball(reduceMotion: reduceMotion)
    }

    public func newPinballGroup() {
        clearPinballGroup()
        feedback.play(.destructive)
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

    public func handleSceneBecameInactive() {
        countdownFeedbackTask?.cancel()
        countdownFeedbackTask = nil
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
    }

    private func resetCurrentMode() {
        countdownFeedbackTask?.cancel()
        countdownStartedAt = nil
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
        switch new {
        case .countdown:
            startCountdownFeedback()
        case .revealed where !sameTogetherPhaseKind(old, new):
            countdownFeedbackTask?.cancel()
            countdownStartedAt = nil
            feedback.play(.winner)
        case .idle, .settling:
            countdownFeedbackTask?.cancel()
            countdownStartedAt = nil
        case .revealed:
            break
        }
    }

    private func handleTapInPhaseChange(from old: TapInPhase, to new: TapInPhase) {
        switch new {
        case .countdown:
            startCountdownFeedback()
        case .revealed where !sameTapInPhaseKind(old, new):
            countdownFeedbackTask?.cancel()
            countdownStartedAt = nil
            feedback.play(.winner)
        case .collecting:
            countdownFeedbackTask?.cancel()
            countdownStartedAt = nil
        case .revealed:
            break
        }
    }

    private func startCountdownFeedback() {
        countdownFeedbackTask?.cancel()
        countdownStartedAt = Date()
        countdownFeedbackTask = Task { @MainActor [weak self] in
            let moments: [(Duration, Double)] = [
                (.zero, 0.12),
                (.milliseconds(360), 0.42),
                (.milliseconds(650), 0.68),
                (.milliseconds(860), 0.90)
            ]
            var elapsed = Duration.zero
            for (moment, progress) in moments {
                do {
                    try await Task.sleep(for: moment - elapsed)
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                self?.feedback.play(.countdown(progress: progress))
                elapsed = moment
            }
        }
    }

    private func makePinballPartition() throws -> PinballRadialPartition {
        let radius: CGFloat = 9
        let bounds = CGRect(origin: .zero, size: pinballPlayfieldSize).insetBy(dx: radius, dy: radius)
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
        pinballCollisionFeedbackTask?.cancel()
        pinballCollisionFeedbackTask = nil
        for pulse in 1...4 {
            guard !Task.isCancelled else { return }
            pinballPhase = .revealing(run: run, pulse: pulse, isLit: true)
            let frequency = 420 + Double(pulse - 1) * 120
            feedback.play(
                .custom(
                    NativeCustomFeedback(
                        intensity: 0.45 + Float(pulse) * 0.12,
                        sharpness: 0.55 + Float(pulse) * 0.08,
                        duration: 0.055,
                        audioFrequencies: [frequency]
                    )
                )
            )
            do {
                try await Task.sleep(for: .milliseconds(180))
            } catch { return }
            pinballPhase = .revealing(run: run, pulse: pulse, isLit: false)
            do {
                try await Task.sleep(for: .milliseconds(260))
            } catch { return }
        }
        pinballPhase = .revealed(run)
        announce("Seat \(run.result.winningSeatID) goes first.")
    }

    private func cancelPinballRun(announceCancellation: Bool) {
        pinballTask?.cancel()
        pinballTask = nil
        pinballCollisionFeedbackTask?.cancel()
        pinballCollisionFeedbackTask = nil
        pinballPhase = .collecting
        feedback.stopAll()
        if announceCancellation {
            announce("Pinball canceled. Start again when ready.")
        }
    }

    private func clearPinballGroup() {
        pinballTask?.cancel()
        pinballTask = nil
        pinballCollisionFeedbackTask?.cancel()
        pinballCollisionFeedbackTask = nil
        pinballSeats.removeAll()
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

    /// Schedules cues from the exact analytic wall-event distances. Converting
    /// each path fraction through the inverse slowdown curve keeps clicks and
    /// taps synchronized without tying correctness to display refresh rate.
    private func startPinballCollisionFeedback(for run: NativePinballRun) {
        pinballCollisionFeedbackTask?.cancel()
        let totalDistance = run.result.trajectory.launch.distance
        guard totalDistance > 0 else { return }

        var collisionTimes: [TimeInterval] = []
        var lastAccepted: TimeInterval = -.infinity
        for segment in run.result.trajectory.segments.dropLast() {
            let pathProgress = min(1, max(0, segment.endDistance / totalDistance))
            let normalizedTime = 1 - pow(1 - Double(pathProgress), 1 / Double(run.curve.exponent))
            let time = normalizedTime * run.curve.duration
            // Extremely fast opening bounces can be closer than hardware can
            // express. Coalesce those while retaining the actual wall timing.
            if time - lastAccepted >= 0.075 {
                collisionTimes.append(time)
                lastAccepted = time
            }
        }

        pinballCollisionFeedbackTask = Task { @MainActor [weak self] in
            var elapsed: TimeInterval = 0
            for collisionTime in collisionTimes {
                do {
                    try await Task.sleep(for: .seconds(max(0, collisionTime - elapsed)))
                } catch { return }
                guard !Task.isCancelled else { return }
                let progress = min(1, collisionTime / run.curve.duration)
                self?.feedback.play(
                    .custom(
                        NativeCustomFeedback(
                            intensity: Float(0.28 + (1 - progress) * 0.34),
                            sharpness: Float(0.42 + (1 - progress) * 0.38),
                            duration: 0.035,
                            audioFrequencies: [105 + (1 - progress) * 95]
                        )
                    )
                )
                elapsed = collisionTime
            }
        }
    }

    private func announce(_ message: String) {
        AccessibilityNotification.Announcement(message).post()
    }

    private func goldenAngleHue(at index: Int) -> Double {
        (Double(index) * 137.508).truncatingRemainder(dividingBy: 360)
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
