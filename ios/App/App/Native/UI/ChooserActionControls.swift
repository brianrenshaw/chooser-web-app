import SwiftUI

/// Shared control vocabulary for the app's action surfaces.
///
/// These were originally private to `ChooserModeViews.swift`. They live here so
/// that `Native/UI` screens (the welcome carousel, the mode introduction card)
/// can use the same recipes without `Native/UI` depending on `Native/Modes`,
/// which would invert the `Core → UI → Modes → App` layering. The bodies are
/// unchanged; only the file and the access level moved.

struct ChooserActionButton: View {
    let title: String
    let systemImage: String
    let accessibilityTitle: String
    let role: ButtonRole?
    let isPrimary: Bool
    let action: () -> Void
    @Environment(\.chooserVisualTheme) private var visualTheme
    @Environment(\.isEnabled) private var isEnabled

    init(
        _ title: String,
        systemImage: String,
        accessibilityLabel: String? = nil,
        role: ButtonRole? = nil,
        isPrimary: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.accessibilityTitle = accessibilityLabel ?? title
        self.role = role
        self.isPrimary = isPrimary
        self.action = action
    }

    var body: some View {
        Group {
            if isPrimary && isEnabled {
                button
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.capsule)
                    .tint(visualTheme.accentColor.opacity(0.90))
                    .foregroundStyle(visualTheme.accentForegroundColor)
            } else if isPrimary {
                button
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
                    .tint(visualTheme.chromeTintColor)
                    .foregroundStyle(visualTheme.primaryInkColor)
            } else {
                button
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.capsule)
                    .tint(
                        role == .destructive
                            ? visualTheme.destructiveControlColor.opacity(
                                visualTheme.chromeControlBackingOpacity
                            )
                            : visualTheme.chromeTintColor.opacity(
                                visualTheme.chromeControlBackingOpacity
                            )
                    )
                    .foregroundStyle(
                        role == .destructive
                            ? visualTheme.destructiveControlForegroundColor
                            : visualTheme.onChromeInkColor
                    )
            }
        }
    }

    private var button: some View {
        Button(role: role, action: action) {
            if isPrimary && !isEnabled {
                Image(systemName: systemImage)
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 44)
            } else {
                ChooserAdaptiveLabel(title, systemImage: systemImage)
            }
        }
        .accessibilityLabel(accessibilityTitle)
    }
}

struct ChooserIconActionButton: View {
    let title: String
    let systemImage: String
    let role: ButtonRole?
    let action: () -> Void
    @Environment(\.chooserVisualTheme) private var visualTheme

    init(
        _ title: String,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .tint(
            role == .destructive
                ? visualTheme.destructiveControlColor.opacity(
                    visualTheme.chromeControlBackingOpacity
                )
                : visualTheme.chromeTintColor.opacity(
                    visualTheme.chromeControlBackingOpacity
                )
        )
        .foregroundStyle(
            role == .destructive
                ? visualTheme.destructiveControlForegroundColor
                : visualTheme.onChromeInkColor
        )
        .accessibilityLabel(title)
    }
}

struct ChooserAdaptiveLabel: View {
    let title: String
    let systemImage: String

    init(_ title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        Label(title, systemImage: systemImage)
        .font(.system(.body, design: .rounded, weight: .bold))
        // Deliberately no `lineLimit`. A cap of 2 truncated these labels at
        // large Dynamic Type sizes, which `performAccessibilityAudit` reports as
        // clipped text. `fixedSize(vertical:)` already lets the label take the
        // height it needs, and every dock that hosts these buttons reflows.
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, minHeight: 44)
    }
}
