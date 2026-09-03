import SwiftUI

/// The themed panel used by every first-run surface. It is the same recipe as
/// `NativeInfoSectionCard`, so the welcome carousel and the mode introduction
/// card read as siblings of the Settings information screens.
///
/// Every text element in the onboarding feature must sit on one of these.
/// `interactiveTextColor` and `informationPanelInkColor` are both solved for
/// 4.5:1 against `informationPanelHex`, *not* against the board surface, so
/// floating text directly on `BoardSurfaceView` is a latent contrast failure
/// that only shows up on some of the eight worlds.
struct NativeBoardPanel: ViewModifier {
    let cornerRadius: CGFloat
    @Environment(\.chooserVisualTheme) private var visualTheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    init(cornerRadius: CGFloat = 22) {
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        let edgeWidth = colorSchemeContrast == .increased ? 1.32 : 1.0
        return content
            .foregroundStyle(visualTheme.informationPanelInkColor)
            .background(
                visualTheme.informationPanelColor,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(visualTheme.separatorColor, lineWidth: edgeWidth)
            }
    }
}

extension View {
    func nativeBoardPanel(cornerRadius: CGFloat = 22) -> some View {
        modifier(NativeBoardPanel(cornerRadius: cornerRadius))
    }
}

/// How much of the board vocabulary a welcome illustration draws.
enum NativeWelcomeArtworkDensity {
    /// Full page illustration for the carousel.
    case full
    /// A single piece, sized for the 52pt badge on the mode introduction card.
    case compact
}

/// Living illustrations for the first-run surfaces, drawn with the *production*
/// board components rather than SF Symbols, so the preview cannot drift from
/// what the user actually sees.
///
/// Everything here is deliberately **static**. The release checklist verifies
/// "no idle pulse" on the live board, and a looping onboarding illustration
/// would contradict that claim. It also makes Reduce Motion vacuous for the
/// artwork: there is no motion to reduce.
struct NativeWelcomeArtwork: View {
    let page: NativeWelcomePage
    let theme: ChooserColorTheme
    let density: NativeWelcomeArtworkDensity

    init(
        page: NativeWelcomePage,
        theme: ChooserColorTheme,
        density: NativeWelcomeArtworkDensity = .full
    ) {
        self.page = page
        self.theme = theme
        self.density = density
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                switch page {
                case .chooser: chooserArtwork(in: size)
                case .tapIn: tapInArtwork(in: size)
                case .pinball: pinballArtwork(in: size)
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Chooser

    @ViewBuilder
    private func chooserArtwork(in size: CGSize) -> some View {
        let shortEdge = min(size.width, size.height)

        if density == .compact {
            let diameter = compactRingDiameter(in: size)
            ring(diameter: diameter, index: 0, emphasis: .resting)
                .position(x: size.width / 2, y: size.height / 2)
        } else {
            // Losing rings stay `.resting` rather than `.dimmed`. At the live
            // board's 0.22 dimmed opacity they read as broken rather than as
            // "three fingers are down".
            let diameter = max(44, shortEdge * 0.40)
            let spots: [(CGPoint, BoardPieceEmphasis)] = [
                (CGPoint(x: 0.28, y: 0.30), .resting),
                (CGPoint(x: 0.74, y: 0.34), .resting),
                (CGPoint(x: 0.50, y: 0.76), .winner)
            ]
            ForEach(Array(spots.enumerated()), id: \.offset) { index, spot in
                let center = clamped(unit: spot.0, in: size, diameter: diameter)
                ring(diameter: diameter, index: index, emphasis: spot.1)
                    .position(x: center.x, y: center.y)
            }
        }
    }

    private func ring(
        diameter: CGFloat,
        index: Int,
        emphasis: BoardPieceEmphasis
    ) -> some View {
        BoardRingView(
            diameter: diameter,
            lineWidth: BoardPieceVisualMetrics.bandWidth(for: diameter),
            style: .participant(theme: theme, index: index),
            emphasis: emphasis
        )
    }

    // MARK: - Tap In

    @ViewBuilder
    private func tapInArtwork(in size: CGSize) -> some View {
        if density == .compact {
            let diameter = compactRingDiameter(in: size)
            NumberedChitView(
                number: 1,
                diameter: diameter,
                style: .participant(theme: theme, index: 0)
            )
            .position(x: size.width / 2, y: size.height / 2)
        } else {
            // The production grid engine, so the miniature is literally the
            // layout the user will meet. It is documented to stay
            // geometrically correct at preview sizes.
            let inset = CGSize(width: size.width * 0.86, height: size.height * 0.86)
            let originX = (size.width - inset.width) / 2
            let originY = (size.height - inset.height) / 2
            let layout = TapInGridLayout.make(count: 4, in: inset)

            ForEach(Array(layout.positions.enumerated()), id: \.offset) { index, point in
                NumberedChitView(
                    number: index + 1,
                    diameter: layout.diameter,
                    style: .participant(theme: theme, index: index),
                    emphasis: index == 2 ? .winner : .resting
                )
                .position(x: originX + point.x, y: originY + point.y)
            }
        }
    }

    // MARK: - Pinball

    @ViewBuilder
    private func pinballArtwork(in size: CGSize) -> some View {
        let shortEdge = min(size.width, size.height)

        if density == .compact {
            let ballDiameter = max(16, shortEdge * 0.42)
            ZStack {
                Canvas { context, canvasSize in
                    var trail = Path()
                    trail.move(to: CGPoint(x: canvasSize.width * 0.14, y: canvasSize.height * 0.78))
                    trail.addQuadCurve(
                        to: CGPoint(x: canvasSize.width * 0.66, y: canvasSize.height * 0.36),
                        control: CGPoint(x: canvasSize.width * 0.28, y: canvasSize.height * 0.34)
                    )
                    strokeTrail(trail, in: &context)
                }
                PhysicalPinballBallView(theme: theme, diameter: ballDiameter)
                    .position(x: size.width * 0.70, y: size.height * 0.34)
            }
        } else {
            let seatDiameter = max(34, shortEdge * 0.24)
            let ballDiameter = max(18, shortEdge * 0.13)
            let seats: [(CGPoint, BoardPieceEmphasis)] = [
                (CGPoint(x: 0.16, y: 0.24), .resting),
                (CGPoint(x: 0.84, y: 0.24), .winner),
                (CGPoint(x: 0.50, y: 0.86), .resting)
            ]

            ZStack {
                Canvas { context, canvasSize in
                    var trail = Path()
                    trail.move(to: CGPoint(x: canvasSize.width * 0.24, y: canvasSize.height * 0.74))
                    trail.addLine(to: CGPoint(x: canvasSize.width * 0.52, y: canvasSize.height * 0.48))
                    trail.addLine(to: CGPoint(x: canvasSize.width * 0.78, y: canvasSize.height * 0.40))
                    strokeTrail(trail, in: &context)
                }

                ForEach(Array(seats.enumerated()), id: \.offset) { index, seat in
                    let center = clamped(unit: seat.0, in: size, diameter: seatDiameter)
                    NumberedChitView(
                        number: index + 1,
                        diameter: seatDiameter,
                        style: .participant(theme: theme, index: index),
                        emphasis: seat.1
                    )
                    .position(x: center.x, y: center.y)
                }

                PhysicalPinballBallView(theme: theme, diameter: ballDiameter)
                    .position(x: size.width * 0.78, y: size.height * 0.40)
            }
        }
    }

    /// The two-stroke trail already established by the app's own mode icon, so
    /// the visual language is consistent with the toolbar marble.
    private func strokeTrail(_ trail: Path, in context: inout GraphicsContext) {
        context.stroke(
            trail,
            with: .color(theme.onChromeInkColor.opacity(0.42)),
            style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            trail,
            with: .color(theme.pinballTailColor.opacity(0.88)),
            style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round)
        )
    }

    // MARK: - Shared geometry

    /// A 28pt ring actually occupies 52pt once `renderingOverflow` is counted
    /// (12pt resting, 20pt winner). Size the compact badge from the frame down
    /// rather than up, and never clip it — clipping removes the authored
    /// contact shadow, which is what makes the piece read as physical.
    private func compactRingDiameter(in size: CGSize) -> CGFloat {
        let shortEdge = min(size.width, size.height)
        let overflow = BoardPieceVisualMetrics.renderingOverflow(
            for: shortEdge,
            emphasis: .resting
        )
        return max(18, shortEdge - overflow * 2)
    }

    /// Always clamp with `.winner` even for resting pieces: winner overflow is
    /// 20pt against resting's 12pt, and under-reserving clips the lifted
    /// shadow. This mirrors what the live Chooser board does.
    private func clamped(unit: CGPoint, in size: CGSize, diameter: CGFloat) -> CGPoint {
        BoardPieceVisualMetrics.clampedCenter(
            CGPoint(x: unit.x * size.width, y: unit.y * size.height),
            in: size,
            diameter: diameter,
            emphasis: .winner,
            margin: 6
        )
    }
}

#Preview("Welcome artwork — full") {
    ScrollView {
        VStack(spacing: 24) {
            ForEach(ChooserColorTheme.allCases) { theme in
                VStack(spacing: 8) {
                    Text(theme.name).font(.caption.bold())
                    HStack(spacing: 12) {
                        ForEach(NativeWelcomePage.allCases) { page in
                            NativeWelcomeArtwork(page: page, theme: theme, density: .full)
                                .frame(width: 104, height: 132)
                                .background(BoardSurfaceView(theme: theme))
                        }
                    }
                }
                .environment(\.chooserVisualTheme, theme.visualTheme)
                .environment(\.chooserColorTheme, theme)
            }
        }
        .padding()
    }
}

#Preview("Welcome artwork — compact badges") {
    VStack(spacing: 14) {
        ForEach(ChooserColorTheme.allCases) { theme in
            HStack(spacing: 12) {
                ForEach(NativeWelcomePage.allCases) { page in
                    NativeWelcomeArtwork(page: page, theme: theme, density: .compact)
                        .frame(width: 52, height: 52)
                }
                Text(theme.name).font(.caption)
            }
            .environment(\.chooserVisualTheme, theme.visualTheme)
            .environment(\.chooserColorTheme, theme)
        }
    }
    .padding()
}
