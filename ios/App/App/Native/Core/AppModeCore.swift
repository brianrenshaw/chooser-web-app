import Foundation
import Observation

public enum AppMode: String, CaseIterable, Codable, Sendable {
    case together
    case tapIn
    case pinball

    public var accessibilityName: String {
        switch self {
        case .together:
            return "Chooser"
        case .tapIn:
            return "Tap In"
        case .pinball:
            return "Pinball"
        }
    }

    /// Stable, brand-owned links used by App Shortcuts and Spotlight. They
    /// select a session mode without silently changing the launch default.
    public var deepLinkURL: URL {
        let path: String
        switch self {
        case .together: path = "chooser"
        case .tapIn: path = "tap-in"
        case .pinball: path = "pinball"
        }
        return URL(string: "whosfirst://mode/\(path)")!
    }

    public init?(deepLinkURL url: URL) {
        guard url.scheme?.lowercased() == "whosfirst",
              url.host?.lowercased() == "mode" else {
            return nil
        }
        switch url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased() {
        case "chooser": self = .together
        case "tap-in": self = .tapIn
        case "pinball": self = .pinball
        default: return nil
        }
    }
}

/// The only persisted native-core value is the mode used to begin a future
/// launch. Round participants, winners, and in-progress timers are not stored.
@MainActor
public protocol LaunchDefaultModePersisting: AnyObject {
    func loadLaunchDefaultMode() -> AppMode?
    func saveLaunchDefaultMode(_ mode: AppMode)
}

@MainActor
public final class UserDefaultsLaunchDefaultModeStore: LaunchDefaultModePersisting {
    public static let defaultKey = "chooser.launch-default-mode"
    public static let defaultMigrationKey = "chooser.launch-default-mode.migration-version"
    public static let currentMigrationVersion = 2

    private let defaults: UserDefaults
    private let key: String
    private let migrationKey: String

    public init(
        defaults: UserDefaults = .standard,
        key: String = UserDefaultsLaunchDefaultModeStore.defaultKey,
        migrationKey: String? = nil
    ) {
        self.defaults = defaults
        self.key = key
        self.migrationKey = migrationKey ?? "\(key).migration-version"
    }

    public func loadLaunchDefaultMode() -> AppMode? {
        // Build 16 establishes Chooser as the product's initial experience.
        // Reset an older saved default exactly once on upgrade, then honor any
        // explicit default the person chooses after seeing this version.
        if defaults.integer(forKey: migrationKey) < Self.currentMigrationVersion {
            defaults.set(AppMode.together.rawValue, forKey: key)
            defaults.set(Self.currentMigrationVersion, forKey: migrationKey)
            return .together
        }

        guard let rawValue = defaults.string(forKey: key) else {
            return nil
        }
        return AppMode(rawValue: rawValue)
    }

    public func saveLaunchDefaultMode(_ mode: AppMode) {
        defaults.set(mode.rawValue, forKey: key)
    }
}

public struct AppModeSnapshot: Equatable, Sendable {
    public let currentMode: AppMode
    public let launchDefaultMode: AppMode
}

public enum AppModeCoreEvent: Equatable, Sendable {
    case stateChanged(AppModeSnapshot)
    case accessibilityAnnouncement(AccessibilityAnnouncement)
}

@MainActor
@Observable
public final class AppModeCore {
    public typealias EventHandler = @MainActor @Sendable (AppModeCoreEvent) -> Void

    public private(set) var currentMode: AppMode
    public private(set) var launchDefaultMode: AppMode
    @ObservationIgnored public var eventHandler: EventHandler?

    @ObservationIgnored private let store: LaunchDefaultModePersisting

    public var snapshot: AppModeSnapshot {
        AppModeSnapshot(
            currentMode: currentMode,
            launchDefaultMode: launchDefaultMode
        )
    }

    public init(
        store: LaunchDefaultModePersisting = UserDefaultsLaunchDefaultModeStore(),
        fallbackLaunchMode: AppMode = .together,
        eventHandler: EventHandler? = nil
    ) {
        self.store = store
        let persistedMode = store.loadLaunchDefaultMode() ?? fallbackLaunchMode
        currentMode = persistedMode
        launchDefaultMode = persistedMode
        self.eventHandler = eventHandler
    }

    /// Selects a mode for this session. When requested, the same mode becomes
    /// the sole persisted launch default; no chooser round state is persisted.
    public func select(
        _ mode: AppMode,
        persistAsLaunchDefault: Bool = false
    ) {
        let currentModeChanged = currentMode != mode
        let launchDefaultChanged = persistAsLaunchDefault && launchDefaultMode != mode

        currentMode = mode
        if persistAsLaunchDefault {
            launchDefaultMode = mode
        }
        if launchDefaultChanged {
            store.saveLaunchDefaultMode(mode)
        }

        if currentModeChanged || launchDefaultChanged {
            eventHandler?(.stateChanged(snapshot))
        }
        if currentModeChanged {
            eventHandler?(
                .accessibilityAnnouncement(
                    AccessibilityAnnouncement("\(mode.accessibilityName) mode.")
                )
            )
        }
    }

    /// Changes only the mode used on the next launch.
    public func setLaunchDefault(_ mode: AppMode) {
        guard launchDefaultMode != mode else {
            return
        }
        launchDefaultMode = mode
        store.saveLaunchDefaultMode(mode)
        eventHandler?(.stateChanged(snapshot))
    }
}
