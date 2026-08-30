import Foundation
import Observation

/// A platform-neutral identity supplied by the input layer for one physical
/// touch. UIKit code can maintain its own UITouch-to-identity mapping.
public struct TogetherTouchIdentity: Hashable, Codable, Sendable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
}

public struct TogetherTiming: Equatable, Sendable {
    public let settlingDuration: TimeInterval
    public let countdownDuration: TimeInterval

    public init(
        settlingDuration: TimeInterval = 1.5,
        countdownDuration: TimeInterval = 1.0
    ) {
        precondition(
            settlingDuration.isFinite && settlingDuration >= 0,
            "Settling duration must be finite and cannot be negative."
        )
        precondition(
            countdownDuration.isFinite && countdownDuration >= 0,
            "Countdown duration must be finite and cannot be negative."
        )
        self.settlingDuration = settlingDuration
        self.countdownDuration = countdownDuration
    }
}

public enum TogetherPhase: Equatable, Sendable {
    case idle
    case settling
    case countdown
    case revealed(winner: TogetherTouchIdentity)
}

public struct TogetherChooserSnapshot: Equatable, Sendable {
    public let phase: TogetherPhase
    public let participantTouchIDs: [TogetherTouchIdentity]

    public var winner: TogetherTouchIdentity? {
        guard case let .revealed(winner) = phase else {
            return nil
        }
        return winner
    }
}

public enum TogetherChooserEvent: Equatable, Sendable {
    case stateChanged(TogetherChooserSnapshot)
    case accessibilityAnnouncement(AccessibilityAnnouncement)
    case failure(ChooserCoreFailure)
}

/// State machine for simultaneous-finger selection. All calls and scheduler
/// callbacks are main-actor isolated; the default scheduler uses a cancellable
/// structured-concurrency task.
@MainActor
@Observable
public final class TogetherChooserCore {
    public typealias EventHandler = @MainActor @Sendable (TogetherChooserEvent) -> Void

    public private(set) var phase: TogetherPhase = .idle
    @ObservationIgnored public var eventHandler: EventHandler?

    @ObservationIgnored private let scheduler: ChooserScheduling
    @ObservationIgnored private let randomIndexGenerator: RandomIndexGenerating
    @ObservationIgnored private let timing: TogetherTiming

    private var participantTouchIDs: [TogetherTouchIdentity] = []
    @ObservationIgnored private var participantTouchIDSet: Set<TogetherTouchIdentity> = []
    @ObservationIgnored private var scheduledTransition: ChooserScheduledTask?
    @ObservationIgnored private var transitionGeneration: UInt64 = 0

    public var snapshot: TogetherChooserSnapshot {
        TogetherChooserSnapshot(
            phase: phase,
            participantTouchIDs: participantTouchIDs
        )
    }

    public init(
        scheduler: ChooserScheduling = TaskChooserScheduler(),
        randomIndexGenerator: RandomIndexGenerating = SecureRandomIndexGenerator(),
        timing: TogetherTiming = TogetherTiming(),
        eventHandler: EventHandler? = nil
    ) {
        self.scheduler = scheduler
        self.randomIndexGenerator = randomIndexGenerator
        self.timing = timing
        self.eventHandler = eventHandler
    }

    @discardableResult
    public func touchBegan(_ identity: TogetherTouchIdentity) -> Bool {
        if case .revealed = phase {
            cancelScheduledTransition()
            participantTouchIDs = [identity]
            participantTouchIDSet = [identity]
            phase = .idle
            publishState()
            announce("One finger detected. Add at least one more.")
            return true
        }

        guard participantTouchIDSet.insert(identity).inserted else {
            return false
        }
        participantTouchIDs.append(identity)

        if participantTouchIDs.count < 2 {
            publishState()
            announce("One finger detected. Add at least one more.")
        } else {
            beginSettling()
        }
        return true
    }

    @discardableResult
    public func touchEnded(_ identity: TogetherTouchIdentity) -> Bool {
        guard participantTouchIDSet.contains(identity) else {
            return false
        }

        // Hold the completed choice until a new touch begins a fresh round.
        if case .revealed = phase {
            return true
        }

        participantTouchIDSet.remove(identity)
        participantTouchIDs.removeAll { $0 == identity }

        switch phase {
        case .settling:
            if participantTouchIDs.count >= 2 {
                beginSettling()
            } else {
                returnToIdleAfterParticipantChange()
            }
        case .countdown:
            if participantTouchIDs.count < 2 {
                returnToIdleAfterParticipantChange()
            } else {
                // Match the original Together interaction: once the visible
                // countdown has begun, removing one of three or more fingers
                // keeps it moving and samples only the identities still down.
                publishState()
            }
        case .idle:
            publishState()
        case .revealed:
            break
        }
        return true
    }

    @discardableResult
    public func touchCancelled(_ identity: TogetherTouchIdentity) -> Bool {
        touchEnded(identity)
    }

    public func reset() {
        cancelScheduledTransition()
        participantTouchIDs.removeAll()
        participantTouchIDSet.removeAll()
        phase = .idle
        publishState()
    }

    /// Cancels all in-flight settling/countdown work and discards physical
    /// touches so returning from the background always requires a fresh round.
    public func cancelForLifecycle() {
        let hadActiveRound = phase != .idle || !participantTouchIDs.isEmpty
        cancelScheduledTransition()
        participantTouchIDs.removeAll()
        participantTouchIDSet.removeAll()
        phase = .idle

        guard hadActiveRound else {
            return
        }
        publishState()
        announce("Choice canceled. Place fingers again when ready.")
    }

    private func beginSettling() {
        phase = .settling
        scheduleTransition(after: timing.settlingDuration) { core in
            core.finishSettling()
        }
        publishState()
        announce("\(participantTouchIDs.count) fingers detected. Hold still.")
    }

    private func finishSettling() {
        guard case .settling = phase, participantTouchIDs.count >= 2 else {
            returnToIdleAfterParticipantChange()
            return
        }

        phase = .countdown
        scheduleTransition(after: timing.countdownDuration) { core in
            core.revealWinner()
        }
        publishState()
        announce("Choosing who goes first.")
    }

    private func revealWinner() {
        guard case .countdown = phase, participantTouchIDs.count >= 2 else {
            returnToIdleAfterParticipantChange()
            return
        }

        do {
            let index = try randomIndexGenerator.randomIndex(
                upperBound: participantTouchIDs.count
            )
            guard participantTouchIDs.indices.contains(index) else {
                throw ChooserCoreFailure.randomSelectionUnavailable
            }
            let winner = participantTouchIDs[index]
            phase = .revealed(winner: winner)
            publishState()
            announce("The glowing finger goes first.")
        } catch {
            phase = .idle
            publishState()
            eventHandler?(.failure(.randomSelectionUnavailable))
            announce("A choice could not be made. Lift and try again.")
        }
    }

    private func returnToIdleAfterParticipantChange() {
        cancelScheduledTransition()
        phase = .idle
        publishState()
        if participantTouchIDs.count == 1 {
            announce("One finger remains. Add at least one more.")
        } else if participantTouchIDs.isEmpty {
            announce("Place two or more fingers.")
        }
    }

    private func scheduleTransition(
        after delay: TimeInterval,
        _ transition: @escaping @MainActor @Sendable (TogetherChooserCore) -> Void
    ) {
        cancelScheduledTransition()
        let generation = transitionGeneration
        scheduledTransition = scheduler.schedule(after: delay) { [weak self] in
            guard let self = self, self.transitionGeneration == generation else {
                return
            }
            self.scheduledTransition = nil
            transition(self)
        }
    }

    private func cancelScheduledTransition() {
        transitionGeneration &+= 1
        scheduledTransition?.cancel()
        scheduledTransition = nil
    }

    private func publishState() {
        eventHandler?(.stateChanged(snapshot))
    }

    private func announce(_ message: String) {
        eventHandler?(
            .accessibilityAnnouncement(AccessibilityAnnouncement(message))
        )
    }
}
