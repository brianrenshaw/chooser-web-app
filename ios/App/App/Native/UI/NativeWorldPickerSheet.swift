import SwiftUI

/// The quick world picker: a sheet of labeled preview tiles over the live
/// board. Tapping a tile applies that world at once, so the board behind the
/// sheet (and the sheet itself) change while the picker stays up for
/// browsing. Swipe down or tap Done to leave it.
///
/// Settings keeps its own, fuller grid; this one exists so a table can change
/// the look in two taps without entering Settings.
public struct NativeWorldPickerSheet: View {
    private let selectedColorTheme: ChooserColorTheme
    private let colorThemes: [ChooserColorTheme]
    private let onSelectColorTheme: (ChooserColorTheme) -> Void
    private let onDismiss: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        selectedColorTheme: ChooserColorTheme,
        colorThemes: [ChooserColorTheme] = ChooserColorTheme.allCases,
        onSelectColorTheme: @escaping (ChooserColorTheme) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.selectedColorTheme = selectedColorTheme
        self.colorThemes = colorThemes
        self.onSelectColorTheme = onSelectColorTheme
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(colorThemes) { theme in
                    NativeWorldTile(
                        theme: theme,
                        isSelected: theme == selectedColorTheme,
                        action: { onSelectColorTheme(theme) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 28)
            .accessibilityIdentifier("world-picker")
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                Text("Worlds")
                    .font(.headline)
                    .foregroundStyle(selectedColorTheme.onChromeInkColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        selectedColorTheme.chromeTintColor.opacity(selectedColorTheme.chromeControlBackingOpacity),
                        in: Capsule()
                    )
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button(action: onDismiss) {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(selectedColorTheme.onChromeInkColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .frame(minHeight: 44)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .background(
                    selectedColorTheme.chromeTintColor.opacity(selectedColorTheme.chromeControlBackingOpacity),
                    in: Capsule()
                )
                .accessibilityIdentifier("world-picker-done")
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 8)
        }
        .background(BoardSurfaceView(theme: selectedColorTheme).ignoresSafeArea())
        .accessibilityIdentifier("world-picker-sheet")
        .animation(reduceMotion ? nil : .smooth(duration: 0.24), value: selectedColorTheme)
    }

    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: 12)]
        }
        let count = horizontalSizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }
}

/// One world: its living board miniature with the name on a chrome bar.
/// The selected world carries its accent outline and a check.
struct NativeWorldTile: View {
    let theme: ChooserColorTheme
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottom) {
                NativeThemeBoardPreview(theme: theme)
                    .frame(height: dynamicTypeSize.isAccessibilitySize ? 120 : 96)
                    .accessibilityHidden(true)

                HStack(spacing: 6) {
                    Text(theme.name)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 2)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.footnote.weight(.semibold))
                            .accessibilityHidden(true)
                    }
                }
                .foregroundStyle(theme.onChromeInkColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(theme.chromeTintColor.opacity(theme.chromeControlBackingOpacity))
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected ? theme.actionAccentColor.opacity(0.95) : theme.separatorColor,
                        lineWidth: isSelected ? 2.5 : 1
                    )
            }
            .shadow(color: .black.opacity(isSelected ? 0.22 : 0.10), radius: 5, y: 2)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.name) world")
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("world-tile-\(theme.id)")
    }
}

/// The toolbar action that opens the quick world picker. Styled exactly like
/// the Settings button so the trailing group reads as one control pair.
public struct NativeWorldPickerButton: View {
    private let isEnabled: Bool
    private let action: () -> Void
    @Environment(\.chooserVisualTheme) private var visualTheme

    public init(isEnabled: Bool = true, action: @escaping () -> Void) {
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "paintpalette")
                .font(.system(size: 16, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .frame(width: 44, height: 44)
                .foregroundStyle(visualTheme.primaryInkColor)
        }
        .accessibilityLabel("Worlds")
        .accessibilityHint(
            isEnabled
                ? "Opens the world picker"
                : "Unavailable while a choice is in progress"
        )
        .accessibilityIdentifier("world-picker-button")
        .controlSize(.large)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.38)
        .animation(.easeInOut(duration: 0.15), value: isEnabled)
    }
}
