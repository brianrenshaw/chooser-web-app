import Foundation
import Observation

public struct TapInEntry: Hashable, Codable, Sendable {
    public let id: UInt64
    public let number: Int

    public init(id: UInt64, number: Int) {
        self.id = id
        self.number = number
    }
}

public enum TapInPhase: Equatable, Sendable {
    case collecting
    case countdown
    case revealed(winner: TapInEntry)
}

public struct TapInChooserSnapshot: Equatable, Sendable {
    public let phase: TapInPhase
    public let entries: [TapInEntry]
    /// Frozen when a draw starts and retained through reveal for auditability.
    public let drawSnapshot: [TapInEntry]

    public var winner: TapInEntry? {
        guard case let .revealed(winner) = phase else {
            return nil
        }
        return winner
    }
}

public enum TapInActionError: Error, Equatable, Sendable {
    case invalidPhase
    case minimumPlayersRequired(Int)
    case maximumPlayersReached(Int)
    case noEntries
}

public enum TapInChooserEvent: Equatable, Sendable {
    case stateChanged(TapInChooserSnapshot)
    case accessibilityAnnouncement(AccessibilityAnnouncement)
    case failure(ChooserCoreFailure)
}

/// State machine for sequential player entry and a snapshot-based draw. All
/// calls and scheduler callbacks must be serialized by the caller.
@MainActor
@Observable
public final class TapInChooserCore {
    public typealias EventHandler = @MainActor @Sendable (TapInChooserEvent) -> Void

    public static let minimumPlayerCount = 2
    public static let maximumPlayerCount = 50

    public private(set) var phase: TapInPhase = .collecting
    @ObservationIgnored public var eventHandler: EventHandler?

    @ObservationIgnored private let scheduler: ChooserScheduling
    @ObservationIgnored private let randomIndexGenerator: RandomIndexGenerating
    @ObservationIgnored private let countdownDuration: TimeInterval

    private var entries: [TapInEntry] = []
    private var drawSnapshot: [TapInEntry] = []
    private var nextEntryID: UInt64 = 1
    private var nextPlayerNumber: Int = 1
    @ObservationIgnored private var scheduledDraw: ChooserScheduledTask?
    @ObservationIgnored private var drawGeneration: UInt64 = 0

    public var snapshot: TapInChooserSnapshot {
        TapInChooserSnapshot(
            phase: phase,
            entries: entries,
            drawSnapshot: drawSnapshot
        )
    }

    public init(
        scheduler: ChooserScheduling = TaskChooserScheduler(),
        randomIndexGenerator: RandomIndexGenerating = SecureRandomIndexGenerator(),
        countdownDuration: TimeInterval = 1.0,
        eventHandler: EventHandler? = nil
    ) {
        precondition(
            countdownDuration.isFinite && countdownDuration >= 0,
            "Countdown duration must be finite and cannot be negative."
        )
        self.scheduler = scheduler
        self.randomIndexGenerator = randomIndexGenerator
        self.countdownDuration = countdownDuration
        self.eventHandler = eventHandler
    }

    @discardableResult
    public func addEntry() throws -> TapInEntry {
        guard case .collecting = phase else {
            throw TapInActionError.invalidPhase
        }
        guard entries.count < TapInChooserCore.maximumPlayerCount else {
            announce("50-player limit reached. Pick when ready.")
            throw TapInActionError.maximumPlayersReached(
                TapInChooserCore.maximumPlayerCount
            )
        }

        let entry = TapInEntry(id: nextEntryID, number: nextPlayerNumber)
        nextEntryID &+= 1
        nextPlayerNumber += 1
        entries.append(entry)
        publishState()
        announce(
            "Player \(entry.number) added. \(entries.count) " +
            "\(entries.count == 1 ? "player" : "players") total."
        )
        return entry
    }

    @discardableResult
    public func undo() throws -> TapInEntry {
        guard case .collecting = phase else {
            throw TapInActionError.invalidPhase
        }
        guard let removedEntry = entries.popLast() else {
            throw TapInActionError.noEntries
        }

        nextPlayerNumber = removedEntry.number
        publishState()
        announce(
            "Player \(removedEntry.number) removed. \(entries.count) " +
            "\(entries.count == 1 ? "player" : "players") total."
        )
        return removedEntry
    }

    public func clear() throws {
        guard case .collecting = phase else {
            throw TapInActionError.invalidPhase
        }
        guard !entries.isEmpty else {
            throw TapInActionError.noEntries
        }

        resetEntries()
        publishState()
        announce("All players cleared.")
    }

    public func pick() throws {
        guard case .collecting = phase else {
            throw TapInActionError.invalidPhase
        }
        try beginDraw()
    }

    public func pickAgain() throws {
        guard case .revealed = phase else {
            throw TapInActionError.invalidPhase
        }
        try beginDraw()
    }

    /// Dismisses a completed result without changing the entered group.
    /// The next action is explicit: another Pick or a new group.
    public func dismissResult() throws {
        guard case .revealed = phase else {
            throw TapInActionError.invalidPhase
        }
        drawSnapshot.removeAll()
        phase = .collecting
        publishState()
        announce("Same group ready. Pick when ready.")
    }

    public func newGroup() {
        cancelScheduledDraw()
        resetEntries()
        phase = .collecting
        publishState()
        announce("New group ready. Each player taps once.")
    }

    /// A background transition cancels an in-progress draw but preserves the
    /// entered group. A completed result remains available on return.
    public func cancelForLifecycle() {
        cancelScheduledDraw()
        guard case .countdown = phase else {
            return
        }

        phase = .collecting
        drawSnapshot.removeAll()
        publishState()
        announce("Draw canceled. Pick again when ready.")
    }

    private func beginDraw() throws {
        guard entries.count >= TapInChooserCore.minimumPlayerCount else {
            announce("Add at least two players before picking.")
            throw TapInActionError.minimumPlayersRequired(
                TapInChooserCore.minimumPlayerCount
            )
        }

        cancelScheduledDraw()
        drawSnapshot = entries
        phase = .countdown
        scheduleDraw(after: countdownDuration)
        publishState()
        announce("Drawing from \(drawSnapshot.count) players.")
    }

    private func finishDraw() {
        guard case .countdown = phase, !drawSnapshot.isEmpty else {
            return
        }

        do {
            let index = try randomIndexGenerator.randomIndex(
                upperBound: drawSnapshot.count
            )
            guard drawSnapshot.indices.contains(index) else {
                throw ChooserCoreFailure.randomSelectionUnavailable
            }

            let winner = drawSnapshot[index]
            phase = .revealed(winner: winner)
            publishState()
            announce("Player \(winner.number) goes first.")
        } catch {
            phase = .collecting
            drawSnapshot.removeAll()
            publishState()
            eventHandler?(.failure(.randomSelectionUnavailable))
            announce("A player could not be chosen. Please pick again.")
        }
    }

    private func scheduleDraw(after delay: TimeInterval) {
        cancelScheduledDraw()
        let generation = drawGeneration
        scheduledDraw = scheduler.schedule(after: delay) { [weak self] in
            guard let self = self, self.drawGeneration == generation else {
                return
            }
            self.scheduledDraw = nil
            self.finishDraw()
        }
    }

    private func cancelScheduledDraw() {
        drawGeneration &+= 1
        scheduledDraw?.cancel()
        scheduledDraw = nil
    }

    private func resetEntries() {
        entries.removeAll()
        drawSnapshot.removeAll()
        nextEntryID = 1
        nextPlayerNumber = 1
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
