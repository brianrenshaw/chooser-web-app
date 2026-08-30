import Foundation

/// A platform-neutral announcement that a UI layer can forward to its
/// accessibility system.
public struct AccessibilityAnnouncement: Equatable, Sendable {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }
}

public enum ChooserCoreFailure: Error, Equatable, Sendable {
    case randomSelectionUnavailable
}

@MainActor
public protocol ChooserScheduledTask: AnyObject {
    var isCancelled: Bool { get }
    func cancel()
}

/// A one-shot scheduler. Inject `ManualChooserScheduler` in tests so timed
/// transitions never depend on wall-clock time.
@MainActor
public protocol ChooserScheduling: AnyObject {
    @discardableResult
    func schedule(
        after delay: TimeInterval,
        _ action: @escaping @MainActor @Sendable () -> Void
    ) -> ChooserScheduledTask
}

/// Production scheduler backed by a cancellable structured-concurrency task.
@MainActor
public final class TaskChooserScheduler: ChooserScheduling {
    public init() {}

    @discardableResult
    public func schedule(
        after delay: TimeInterval,
        _ action: @escaping @MainActor @Sendable () -> Void
    ) -> ChooserScheduledTask {
        precondition(
            delay.isFinite && delay >= 0,
            "Scheduled delays must be finite and cannot be negative."
        )
        return TaskChooserScheduledTask(delay: delay, action: action)
    }
}

@MainActor
private final class TaskChooserScheduledTask: ChooserScheduledTask {
    private var task: Task<Void, Never>?

    var isCancelled: Bool {
        task?.isCancelled ?? true
    }

    init(
        delay: TimeInterval,
        action: @escaping @MainActor @Sendable () -> Void
    ) {
        task = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(delay))
            } catch {
                return
            }
            guard !Task.isCancelled else {
                return
            }
            action()
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

/// A deterministic scheduler intended for unit tests and previews of the core.
/// It is deliberately single-threaded; call it from the same executor as the
/// state machine under test.
@MainActor
public final class ManualChooserScheduler: ChooserScheduling {
    @MainActor
    private final class ScheduledAction: ChooserScheduledTask {
        let deadline: TimeInterval
        let order: UInt64
        private var action: (@MainActor @Sendable () -> Void)?

        var isCancelled: Bool {
            action == nil
        }

        init(
            deadline: TimeInterval,
            order: UInt64,
            action: @escaping @MainActor @Sendable () -> Void
        ) {
            self.deadline = deadline
            self.order = order
            self.action = action
        }

        func cancel() {
            action = nil
        }

        func run() {
            let pendingAction = action
            action = nil
            pendingAction?()
        }
    }

    public private(set) var now: TimeInterval

    private var nextOrder: UInt64 = 0
    private var tasks: [ScheduledAction] = []

    public init(now: TimeInterval = 0) {
        self.now = now
    }

    @discardableResult
    public func schedule(
        after delay: TimeInterval,
        _ action: @escaping @MainActor @Sendable () -> Void
    ) -> ChooserScheduledTask {
        precondition(
            delay.isFinite && delay >= 0,
            "Scheduled delays must be finite and cannot be negative."
        )
        nextOrder &+= 1
        let task = ScheduledAction(
            deadline: now + delay,
            order: nextOrder,
            action: action
        )
        tasks.append(task)
        return task
    }

    public func advance(by interval: TimeInterval) {
        precondition(
            interval.isFinite && interval >= 0,
            "Clock advances must be finite and cannot be negative."
        )
        run(until: now + interval)
    }

    public func runReadyTasks() {
        run(until: now)
    }

    private func run(until targetTime: TimeInterval) {
        precondition(targetTime >= now, "A manual clock cannot run backwards.")

        while let taskIndex = indexOfNextTask(dueBy: targetTime) {
            let task = tasks.remove(at: taskIndex)
            now = task.deadline
            task.run()
        }

        now = targetTime
        tasks.removeAll { $0.isCancelled }
    }

    private func indexOfNextTask(dueBy targetTime: TimeInterval) -> Int? {
        var bestIndex: Int?

        for index in tasks.indices {
            let candidate = tasks[index]
            guard !candidate.isCancelled, candidate.deadline <= targetTime else {
                continue
            }

            guard let currentBestIndex = bestIndex else {
                bestIndex = index
                continue
            }

            let currentBest = tasks[currentBestIndex]
            if candidate.deadline < currentBest.deadline ||
                (candidate.deadline == currentBest.deadline && candidate.order < currentBest.order) {
                bestIndex = index
            }
        }

        return bestIndex
    }
}
