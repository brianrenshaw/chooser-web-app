import Foundation

/// One thing the first-run introduction can show.
///
/// Modelled as a single enum rather than separate flags so that the welcome and
/// a per-mode card can never be presented at the same time, by construction.
public enum OnboardingMoment: Hashable, Identifiable, Sendable {
    /// The three-page welcome carousel, shown once.
    case welcome
    /// The one-time card shown the first time a given mode is opened.
    case modeCard(AppMode)

    public var id: String { persistenceToken }

    /// The stored form. Derived from `AppMode.rawValue`, so the token set can
    /// never drift from the mode enum.
    public var persistenceToken: String {
        switch self {
        case .welcome: "welcome"
        case .modeCard(let mode): "mode.\(mode.rawValue)"
        }
    }

    public init?(persistenceToken: String) {
        if persistenceToken == "welcome" {
            self = .welcome
            return
        }
        let prefix = "mode."
        guard persistenceToken.hasPrefix(prefix) else { return nil }
        let rawValue = String(persistenceToken.dropFirst(prefix.count))
        guard let mode = AppMode(rawValue: rawValue) else { return nil }
        self = .modeCard(mode)
    }

    public static let all: [OnboardingMoment] =
        [.welcome] + AppMode.allCases.map(OnboardingMoment.modeCard)
}

/// Which parts of the first-run introduction a person has already seen.
///
/// This is the third and last persisted preference in the app, alongside the
/// launch default mode and the selected visual world. It holds no personal
/// data: only which introduction surfaces have been retired.
@MainActor
public protocol OnboardingProgressPersisting: AnyObject {
    func loadSeenMoments() -> Set<OnboardingMoment>
    func saveSeenMoments(_ moments: Set<OnboardingMoment>)
}

@MainActor
public final class UserDefaultsOnboardingProgressStore: OnboardingProgressPersisting {
    public static let defaultKey = "chooser.onboarding"
    public static let defaultVersionKey = "chooser.onboarding.version"
    /// Bump to re-show the introduction after a release that changes it.
    /// Anyone whose stored version is older is treated as having seen nothing.
    public static let currentOnboardingVersion = 1

    private let defaults: UserDefaults
    private let key: String
    private let versionKey: String

    public init(
        defaults: UserDefaults = .standard,
        key: String = UserDefaultsOnboardingProgressStore.defaultKey,
        versionKey: String? = nil
    ) {
        self.defaults = defaults
        self.key = key
        self.versionKey = versionKey ?? "\(key).version"
    }

    /// Deliberately a **pure read** — it must never write.
    ///
    /// `UserDefaultsLaunchDefaultModeStore.loadLaunchDefaultMode()` writes
    /// during its read to perform a one-shot migration, which is exactly why a
    /// brand-new install cannot be told apart from an upgraded one using that
    /// key. Repeating the pattern here would make this key undiagnosable in the
    /// same way, so the version gate returns early without touching `defaults`.
    public func loadSeenMoments() -> Set<OnboardingMoment> {
        guard defaults.integer(forKey: versionKey) >= Self.currentOnboardingVersion else {
            return []
        }
        let tokens = defaults.stringArray(forKey: key) ?? []
        // Tokens written by a future build are ignored rather than crashing.
        return Set(tokens.compactMap(OnboardingMoment.init(persistenceToken:)))
    }

    public func saveSeenMoments(_ moments: Set<OnboardingMoment>) {
        // Sorted so the stored plist is stable and test assertions are
        // deterministic regardless of set iteration order.
        defaults.set(moments.map(\.persistenceToken).sorted(), forKey: key)
        defaults.set(Self.currentOnboardingVersion, forKey: versionKey)
    }
}
