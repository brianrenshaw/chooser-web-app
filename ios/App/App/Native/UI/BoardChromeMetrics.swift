import SwiftUI

/// Resolved chrome measurements for one presentation context.
///
/// Carries **numbers, not a flag**. A `isIPad`-style boolean spreads the device
/// question to every consumer and invites each of them to answer it slightly
/// differently; resolved values mean a surface that never learned about iPad
/// simply reads today's phone number and is unchanged.
///
/// This is the only place a size class is consulted, and only for the three
/// "is this a phone-shaped reading column?" questions plus the dock. Board
/// *pieces* must never be sized this way — see `resolve` for why.
public struct BoardChromeMetrics: Equatable, Sendable {
    /// The reading column for text-led surfaces: the welcome carousel, the
    /// information screens.
    public var readableWidth: CGFloat

    /// A cap for a row of action buttons, or `nil` to leave it uncapped.
    /// Optional rather than `.infinity` so a phone applies no frame at all
    /// instead of an identity one.
    public var actionRowMaxWidth: CGFloat?

    /// The one-time mode introduction card.
    public var introCardMaxWidth: CGFloat

    /// The fixed height of a mode's bottom dock.
    ///
    /// Must be resolvable without knowing the round's phase, the seat count, or
    /// how a `ViewThatFits` resolved. Pinball watches its playfield for changes
    /// greater than half a point and cancels a running round when one lands, so
    /// a dock that changed height mid-round would end the round.
    public var dockHeight: CGFloat

    public init(
        readableWidth: CGFloat,
        actionRowMaxWidth: CGFloat?,
        introCardMaxWidth: CGFloat,
        dockHeight: CGFloat
    ) {
        self.readableWidth = readableWidth
        self.actionRowMaxWidth = actionRowMaxWidth
        self.introCardMaxWidth = introCardMaxWidth
        self.dockHeight = dockHeight
    }

    /// Exactly today's values. The default, so an un-injected surface — a
    /// preview, a test host, a sheet whose environment someone forgot to
    /// populate — renders as it always has rather than as an iPad.
    public static let phone = BoardChromeMetrics(
        readableWidth: 620,
        actionRowMaxWidth: nil,
        introCardMaxWidth: 520,
        dockHeight: 108
    )

    /// A phone on its side. Only the dock differs, and by the same 4 points it
    /// always has.
    public static let landscapePhone = BoardChromeMetrics(
        readableWidth: 620,
        actionRowMaxWidth: nil,
        introCardMaxWidth: 520,
        dockHeight: 104
    )

    public static let tablet = BoardChromeMetrics(
        readableWidth: 760,
        actionRowMaxWidth: 520,
        introCardMaxWidth: 620,
        dockHeight: 124
    )

    /// Both axes regular, deliberately — not `horizontalSizeClass` alone.
    ///
    /// A Pro Max in landscape reports a **regular** horizontal size class, so
    /// the horizontal axis by itself does not mean "tablet"; it would hand a
    /// phone with 246 points of playfield a 124pt dock and a capped action row,
    /// regressing a shipping device the moment the user rotates it. The
    /// conjunction is true on iPad and false on every iPhone.
    ///
    /// It is also correctly false for an iPad in Slide Over or a narrow Split
    /// View, where the column is compact and genuinely phone-shaped.
    public static func resolve(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?
    ) -> BoardChromeMetrics {
        if horizontalSizeClass == .regular, verticalSizeClass == .regular {
            return .tablet
        }
        return verticalSizeClass == .compact ? .landscapePhone : .phone
    }
}

public extension EnvironmentValues {
    @Entry var boardChromeMetrics: BoardChromeMetrics = .phone
}

public extension View {
    /// Resolve and publish chrome metrics for this subtree.
    ///
    /// A sheet is a separate environment tree, so this has to be applied inside
    /// each sheet's content as well as at the root — inheriting it is exactly
    /// the assumption that silently leaves a presented surface on phone values.
    func boardChromeMetrics() -> some View {
        modifier(BoardChromeMetricsModifier())
    }
}

private struct BoardChromeMetricsModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    func body(content: Content) -> some View {
        content.environment(
            \.boardChromeMetrics,
            .resolve(
                horizontalSizeClass: horizontalSizeClass,
                verticalSizeClass: verticalSizeClass
            )
        )
    }
}

public extension View {
    /// Cap a row of action buttons, or leave it alone.
    ///
    /// Applied to the row rather than the buttons, and **outside** any
    /// `ViewThatFits`: capping inside would shrink the space the row is
    /// measured against and could flip it to the stacked branch on a board with
    /// room to spare. `nil` applies no frame at all rather than an identity
    /// one, so a phone's layout is untouched.
    @ViewBuilder
    func boardActionRowWidth(_ maxWidth: CGFloat?) -> some View {
        if let maxWidth {
            frame(maxWidth: maxWidth)
        } else {
            self
        }
    }
}
