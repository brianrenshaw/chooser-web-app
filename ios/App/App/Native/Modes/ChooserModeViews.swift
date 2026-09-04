import SpriteKit
import SwiftUI
import UIKit

@MainActor
public struct TogetherModeView: View {
    @Bindable var model: ChooserAppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(model: ChooserAppModel) {
        self.model = model
    }

    public var body: some View {
        GeometryReader { geometry in
            let timeline = ChoiceAnticipationTimeline.chooser
            let boardScale = BoardPieceVisualMetrics.boardScale(for: geometry.size)
            ZStack {
                    NativeTouchSurface(
                        accessibilityLabel: "Chooser touch area",
                        accessibilityHint: "Place two or more fingers here at the same time, or activate to choose from two people.",
                        onBegan: model.togetherTouchBegan,
                        onMoved: model.togetherTouchMoved,
                        onEnded: { model.togetherTouchEnded($0, cancelled: false) },
                        onCancelled: { model.togetherTouchEnded($0, cancelled: true) },
                        onAccessibilityActivate: {
                            model.chooseTogetherForAccessibility(
                                participantCount: 2,
                                in: geometry.size
                            )
                        }
                    )
                    .accessibilityValue(
                        "\(model.togetherSnapshot.participantTouchIDs.count) people detected"
                    )
                    .accessibilityAction(named: Text("Choose from 3 people")) {
                        _ = model.chooseTogetherForAccessibility(
                            participantCount: 3,
                            in: geometry.size
                        )
                    }
                    .accessibilityAction(named: Text("Choose from 4 people")) {
                        _ = model.chooseTogetherForAccessibility(
                            participantCount: 4,
                            in: geometry.size
                        )
                    }
                    .accessibilityAction(named: Text("Choose from 5 people")) {
                        _ = model.chooseTogetherForAccessibility(
                            participantCount: 5,
                            in: geometry.size
                        )
                    }
                    .accessibilityAction(named: Text("Shuffle colors")) {
                        _ = model.randomizeColorTheme()
                    }
                    .accessibilityIdentifier("together-stage")

                    ChooserAnticipationKeyframes(
                        isActive: isCountdown,
                        startDate: model.countdownStartedAt
                    ) { elapsed in
                        ForEach(sortedVisuals, id: \.id) { visual in
                            let isWinner = model.togetherSnapshot.winner == visual.id
                            let diameter = ChooserRingSizing.diameter(in: geometry.size)
                            let emphasis = ringEmphasis(isWinner: isWinner)
                            let motion = timeline.motion(
                                at: elapsed,
                                ringSeed: visual.id.rawValue,
                                reduceMotion: reduceMotion
                            )
                            BoardRingView(
                                diameter: diameter,
                                lineWidth: BoardPieceVisualMetrics.bandWidth(
                                    for: diameter,
                                    scale: boardScale
                                ),
                                style: .participant(
                                    theme: model.colorTheme,
                                    index: visual.colorIndex
                                ),
                                emphasis: emphasis,
                                emphasisAnimationDuration: isWinner
                                    ? timeline.winnerRevealDuration
                                    : timeline.loserFadeDuration,
                                accessibilityLabel: isWinner ? "Winning finger" : "Finger",
                                boardScale: boardScale
                            )
                            .scaleEffect(motion.scale)
                            .rotationEffect(.degrees(motion.rotationDegrees))
                            .position(
                                BoardPieceVisualMetrics.clampedCenter(
                                    visual.location,
                                    in: geometry.size,
                                    diameter: diameter,
                                    // Any resting ring can become the winner.
                                    // Reserve the complete lifted shadow and
                                    // landing arc from its first frame so the
                                    // result neither clips nor jumps inward.
                                    emphasis: .winner,
                                    externalScale: ChooserRingSizing.externalScale,
                                    margin: ChooserRingSizing.margin,
                                    scale: boardScale
                                )
                            )
                            .offset(
                                x: motion.translation.dx,
                                y: motion.translation.dy
                            )
                            .modifier(
                                ChooserWinnerLandingModifier(
                                    isActive: isWinner,
                                    duration: timeline.winnerRevealDuration,
                                    direction: timeline.stableAxis(
                                        for: visual.id.rawValue
                                    ).dx >= 0 ? 1 : -1
                                )
                            )
                            .transition(
                                reduceMotion
                                    ? .identity
                                    : .scale(scale: 0.7).combined(with: .opacity)
                            )
                        }
                        .allowsHitTesting(false)
                    }
            }
            .clipped()
            .animation(
                reduceMotion ? .linear(duration: 0.01) : .smooth(duration: 0.28),
                value: model.togetherSnapshot.phase
            )
        }
    }

    private var sortedVisuals: [TogetherTouchVisual] {
        model.togetherVisuals.values.sorted { $0.id.rawValue < $1.id.rawValue }
    }

    private var isCountdown: Bool {
        if case .countdown = model.togetherSnapshot.phase { return true }
        return false
    }

    private func ringEmphasis(isWinner: Bool) -> BoardPieceEmphasis {
        if case .revealed = model.togetherSnapshot.phase {
            return isWinner ? .winner : .dimmed
        }
        return .resting
    }
}

@MainActor
public struct TapInModeView: View {
    @Bindable var model: ChooserAppModel
    @AccessibilityFocusState private var resultIsFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: ChooserAppModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let boardScale = BoardPieceVisualMetrics.boardScale(for: geometry.size)
                let layout = TapInGridLayout.make(
                    count: model.tapInSnapshot.entries.count,
                    in: geometry.size,
                    scale: boardScale
                )

                ZStack {
                    NativeTouchSurface(
                        isEnabled: isCollecting,
                        accessibilityLabel: "Tap In entry area",
                        accessibilityHint: "Activate once for each player.",
                        onBegan: model.tapInTouchBegan,
                        onMoved: model.tapInTouchMoved,
                        onEnded: { model.tapInTouchEnded($0, cancelled: false) },
                        onCancelled: { model.tapInTouchEnded($0, cancelled: true) },
                        onAccessibilityActivate: model.addTapInEntryForAccessibility
                    )
                    .accessibilityAction(named: Text("Shuffle colors")) {
                        _ = model.randomizeColorTheme()
                    }
                    .accessibilityIdentifier("tap-in-stage")

                    if case .revealed = model.tapInSnapshot.phase {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture(perform: model.dismissTapInResult)
                            .accessibilityHidden(true)
                    }

                    AcceleratingChooserPulse(
                        isActive: isCountdown,
                        startDate: model.countdownStartedAt
                    ) { pulseScale in
                        ForEach(Array(model.tapInSnapshot.entries.enumerated()), id: \.element.id) { index, entry in
                            let winner = model.tapInSnapshot.winner?.id == entry.id
                            let emphasis = tokenEmphasis(winner: winner)
                            let diameter = tokenDiameter(
                                entry: entry,
                                layout: layout,
                                size: geometry.size,
                                scale: boardScale
                            )
                            NumberedChitView(
                                number: entry.number,
                                diameter: diameter,
                                style: .participant(
                                    theme: model.colorTheme,
                                    index: entry.number - 1
                                ),
                                emphasis: emphasis,
                                boardScale: boardScale
                            )
                            .scaleEffect(pulseScale)
                            .position(
                                tokenPosition(
                                    entry: entry,
                                    index: index,
                                    layout: layout,
                                    size: geometry.size,
                                    diameter: diameter,
                                    emphasis: emphasis,
                                    scale: boardScale
                                )
                            )
                            .zIndex(winner ? 5 : 1)
                            .allowsHitTesting(false)
                            .transition(
                                reduceMotion
                                    ? .identity
                                    : .scale(scale: 0.62).combined(with: .opacity)
                            )
                        }
                    }

                    ForEach(model.tapInPending.values.sorted { $0.touchID < $1.touchID }, id: \.touchID) { pending in
                        let diameter = min(
                            132 * boardScale,
                            max(72 * boardScale, layout.diameter * 0.88)
                        )
                        NumberedChitView(
                            number: pending.number,
                            diameter: diameter,
                            style: .participant(
                                theme: model.colorTheme,
                                index: pending.number - 1
                            ),
                            emphasis: .resting,
                            boardScale: boardScale
                        )
                        .position(
                            BoardPieceVisualMetrics.clampedCenter(
                                pending.location,
                                in: geometry.size,
                                diameter: diameter,
                                emphasis: .resting,
                                scale: boardScale
                            )
                        )
                        .transition(
                            reduceMotion
                                ? .identity
                                : .scale(scale: 0.7).combined(with: .opacity)
                        )
                        .allowsHitTesting(false)
                    }
                }
                .clipped()
                .animation(
                    reduceMotion ? .linear(duration: 0.01) : .smooth(duration: 0.28),
                    value: model.tapInSnapshot.entries
                )
                .animation(
                    reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.24),
                    value: model.tapInTravelOrigins
                )
            }

            tapInDock
        }
        .onChange(of: model.tapInSnapshot.winner?.id) { _, winnerID in
            resultIsFocused = winnerID != nil
        }
    }

    private var tapInDock: some View {
        VStack(spacing: 8) {
            ChooserStatusDock(
                title: tapInTitle,
                detail: tapInDetail,
                accessibilityTitle: tapInAccessibilityTitle,
                accessibilityIdentifier: "tap-in-status"
            )
            .padding(.horizontal, -16)
            .padding(.bottom, -4)
            .accessibilityFocused($resultIsFocused)

            if case .revealed = model.tapInSnapshot.phase {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { tapInResultButtons }
                    VStack(spacing: 10) { tapInResultButtons }
                }
            } else if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 10) {
                    tapInPickButton
                    HStack(spacing: 10) {
                        tapInUndoButton
                        tapInClearButton
                    }
                }
            } else {
                HStack(spacing: 10) {
                    tapInUndoButton
                    tapInClearButton
                    tapInPickButton
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private var tapInUndoButton: some View {
        ChooserIconActionButton("Undo", systemImage: "arrow.uturn.backward", action: model.undoTapIn)
            .disabled(model.tapInSnapshot.entries.isEmpty || !isCollecting)
            .accessibilityIdentifier("tap-in-undo")
    }

    private var tapInClearButton: some View {
        ChooserIconActionButton("Clear", systemImage: "xmark", role: .destructive, action: model.requestClearTapIn)
            .disabled(model.tapInSnapshot.entries.isEmpty || !isCollecting)
            .accessibilityIdentifier("tap-in-clear")
    }

    private var tapInPickButton: some View {
        ChooserActionButton(
            isCountdown ? "Choosing…" : "Pick \(model.tapInSnapshot.entries.count)",
            systemImage: "sparkles",
            accessibilityLabel: isCountdown
                ? "Choosing"
                : "Pick from \(model.tapInSnapshot.entries.count) players",
            isPrimary: true,
            action: model.pickTapIn
        )
        .disabled(!model.tapInCanPick)
        .accessibilityIdentifier("tap-in-pick")
    }

    @ViewBuilder
    private var tapInResultButtons: some View {
        ChooserActionButton(
            "Try Again",
            systemImage: "arrow.clockwise",
            accessibilityLabel: "Try Again",
            isPrimary: true,
            action: model.pickTapInAgain
        )
            .accessibilityIdentifier("tap-in-pick-again")
        ChooserIconActionButton("New group", systemImage: "person.3", action: model.newTapInGroup)
            .accessibilityIdentifier("tap-in-new-group")
    }

    private var isCollecting: Bool {
        if case .collecting = model.tapInSnapshot.phase { return true }
        return false
    }

    private var isCountdown: Bool {
        if case .countdown = model.tapInSnapshot.phase { return true }
        return false
    }

    private var tapInTitle: String {
        switch model.tapInSnapshot.phase {
        case .collecting where model.tapInSnapshot.entries.isEmpty:
            ""
        case .collecting where model.tapInSnapshot.entries.count == 1:
            "1 in"
        case .collecting:
            "\(model.tapInSnapshot.entries.count) in"
        case .countdown:
            ""
        case .revealed:
            ""
        }
    }

    private var tapInAccessibilityTitle: String {
        if case .revealed(let winner) = model.tapInSnapshot.phase {
            return "Player \(winner.number) goes first."
        }
        return tapInTitle
    }

    private var tapInDetail: String {
        switch model.tapInSnapshot.phase {
        case .collecting where model.tapInSnapshot.entries.isEmpty:
            "Pass it around."
        case .collecting where model.tapInSnapshot.entries.count == 1:
            "Add at least one more."
        case .collecting:
            "Keep tapping, or pick when ready."
        case .countdown:
            "Drawing from \(model.tapInSnapshot.drawSnapshot.count) players."
        case .revealed:
            "Pick again keeps this same group."
        }
    }

    private func tokenPosition(
        entry: TapInEntry,
        index: Int,
        layout: TapInGridResult,
        size: CGSize,
        diameter: CGFloat,
        emphasis: BoardPieceEmphasis,
        scale: CGFloat
    ) -> CGPoint {
        let proposed: CGPoint
        if case .revealed(let winner) = model.tapInSnapshot.phase, winner.id == entry.id {
            proposed = CGPoint(x: size.width / 2, y: size.height / 2)
        } else if let origin = model.tapInTravelOrigins[entry.id] {
            proposed = origin
        } else {
            proposed = layout.positions.indices.contains(index) ? layout.positions[index] : .zero
        }
        return BoardPieceVisualMetrics.clampedCenter(
            proposed,
            in: size,
            diameter: diameter,
            emphasis: emphasis,
            externalScale: isCountdown ? 1.05 : 1,
            margin: 2,
            scale: scale
        )
    }

    private func tokenDiameter(
        entry: TapInEntry,
        layout: TapInGridResult,
        size: CGSize,
        scale: CGFloat
    ) -> CGFloat {
        guard model.tapInSnapshot.winner?.id == entry.id else { return layout.diameter }
        return TapInGridLayout.winnerDiameter(
            gridDiameter: layout.diameter,
            in: size,
            scale: scale
        )
    }

    private func tokenEmphasis(winner: Bool) -> BoardPieceEmphasis {
        switch model.tapInSnapshot.phase {
        case .revealed:
            winner ? .winner : .dimmed
        case .countdown:
            .resting
        case .collecting:
            .resting
        }
    }

}

@MainActor
public struct PinballModeView: View {
    @Bindable var model: ChooserAppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @AccessibilityFocusState private var resultIsFocused: Bool
    @State private var flickTracking: NativePinballGestureTracking?
    @State private var flickCoachStartedAt: Date?
    @State private var flickCoachTask: Task<Void, Never>?
    @State private var hasCoachedCurrentGroup = false

    public init(model: ChooserAppModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let tokenLayout = model.pinballSeatTokenLayout()
                ZStack {
                    if let partition = model.pinballPartition() {
                        PinballDividerCanvas(
                            partition: partition,
                            winnerSeatID: model.pinballPhase.winnerSeatID,
                            colorTheme: model.colorTheme
                        )
                    }

                    if case .running(let run) = model.pinballPhase {
                        NativePinballSpriteReplay(
                            run: run,
                            presentation: .running,
                            colorTheme: model.colorTheme,
                            bumperMarks: Dictionary(
                                uniqueKeysWithValues: model.pinballBumperContacts(for: run).map {
                                    (
                                        $0.vertexIndex,
                                        NativeReplayBumperMark(
                                            seatID: $0.seatID,
                                            center: $0.center,
                                            radius: $0.radius
                                        )
                                    )
                                }
                            ),
                            onImpact: { runID, impact in
                                model.handlePinballRenderedImpact(
                                    runID: runID,
                                    impact: impact
                                )
                            },
                            onEndpointCompression: { runID in
                                model.handlePinballRenderedEndpointCompression(
                                    runID: runID
                                )
                            },
                            onFinished: { runID in
                                model.handlePinballReplayFinished(runID: runID)
                            }
                        )
                            .id(
                                NativePinballReplayIdentity(
                                    runID: run.id,
                                    presentation: .running,
                                    colorThemeID: model.colorTheme.id
                                )
                            )
                            .zIndex(20)
                            .allowsHitTesting(false)
                    } else if case .revealing(let run, _, _) = model.pinballPhase {
                        NativePinballSpriteReplay(
                            run: run,
                            presentation: .finalStatic,
                            colorTheme: model.colorTheme
                        )
                            .id(
                                NativePinballReplayIdentity(
                                    runID: run.id,
                                    presentation: .finalStatic,
                                    colorThemeID: model.colorTheme.id
                                )
                            )
                            .zIndex(20)
                            .allowsHitTesting(false)
                    } else if case .revealed(let run) = model.pinballPhase {
                        NativePinballSpriteReplay(
                            run: run,
                            presentation: .finalStatic,
                            colorTheme: model.colorTheme
                        )
                            .id(
                                NativePinballReplayIdentity(
                                    runID: run.id,
                                    presentation: .finalStatic,
                                    colorThemeID: model.colorTheme.id
                                )
                            )
                            .zIndex(20)
                            .allowsHitTesting(false)
                    }

                    if isCollecting {
                        NativePinballGestureSurface(
                            accessibilityLabel: "Pinball seat area",
                            accessibilityHint: "Tap near a seat, or flick to launch after adding two seats.",
                            onAction: {
                                cancelFlickCoach()
                                model.handlePinballGesture($0, reduceMotion: reduceMotion)
                            },
                            onTrackingChanged: { tracking in
                                cancelFlickCoach()
                                flickTracking = model.pinballCanStart && tracking.isClearFlick
                                    ? tracking
                                    : nil
                            },
                            onTrackingEnded: { _ in
                                flickTracking = nil
                            },
                            onAccessibilityActivate: model.addPinballSeatForAccessibility
                        )
                        .accessibilityAction(named: Text("Launch pinball")) {
                            model.startPinball(reduceMotion: reduceMotion)
                        }
                        .accessibilityAction(named: Text("Shuffle colors")) {
                            _ = model.randomizeColorTheme()
                        }
                        .accessibilityValue("\(model.pinballSeats.count) seats")
                        .accessibilityAdjustableAction { direction in
                            switch direction {
                            case .increment:
                                model.configureAccessiblePinballSeats(
                                    count: min(12, max(2, model.pinballSeats.count + 1))
                                )
                            case .decrement:
                                model.configureAccessiblePinballSeats(
                                    count: max(2, model.pinballSeats.count - 1)
                                )
                            @unknown default:
                                break
                            }
                        }
                        .accessibilityIdentifier("pinball-stage")
                    }

                    if case .revealed = model.pinballPhase {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture(perform: model.dismissPinballResult)
                            .accessibilityHidden(true)
                    }

                    if isCollecting, let flickTracking {
                        PinballDirectManipulationPreview(
                            tracking: flickTracking,
                            playfieldSize: geometry.size,
                            colorTheme: model.colorTheme
                        )
                        .zIndex(30)
                        .allowsHitTesting(false)
                    }

                    // Only the settled layout may size a seat. Falling back to
                    // the raw preferred diameter was a third sizing path that
                    // bypassed the passage shrink entirely, so the drawn chit
                    // could be larger than the circle the ball collides with.
                    ForEach(tokenLayout == nil ? [] : model.pinballSeats) { seat in
                        let diameter = tokenLayout?.tokenDiameter ?? 0
                        let emphasis = pinballSeatEmphasis(seat)
                        NumberedChitView(
                            number: seat.id,
                            diameter: diameter,
                            style: .participant(
                                theme: model.colorTheme,
                                index: seat.id - 1
                            ),
                            emphasis: emphasis
                        )
                        .position(
                            pinballSeatPosition(
                                seat,
                                layout: tokenLayout,
                                in: geometry.size,
                                diameter: diameter,
                                emphasis: emphasis
                            )
                        )
                        .transition(
                            reduceMotion
                                ? .identity
                                : .scale(scale: 0.5).combined(with: .opacity)
                        )
                        .allowsHitTesting(false)
                    }
                    .allowsHitTesting(false)

                    if let flickCoachStartedAt, isCollecting {
                        PinballFlickCoach(
                            startDate: flickCoachStartedAt,
                            reduceMotion: reduceMotion,
                            color: model.colorTheme.pinballTailColor
                        )
                        .zIndex(40)
                        .allowsHitTesting(false)
                    }
                }
                .clipped()
                .onAppear { model.updatePinballPlayfield(size: geometry.size) }
                .onChange(of: geometry.size) { _, size in model.updatePinballPlayfield(size: size) }
                .animation(
                    reduceMotion ? .linear(duration: 0.01) : .smooth(duration: 0.26),
                    value: model.pinballSeats
                )
                .animation(
                    reduceMotion ? .linear(duration: 0.01) : .smooth(duration: 0.24),
                    value: model.pinballTravelOrigins
                )
            }

            pinballDock
        }
        .onChange(of: model.pinballPhase.winnerSeatID) { _, winner in
            if case .revealed = model.pinballPhase {
                resultIsFocused = winner != nil
            }
        }
        .onChange(of: model.pinballSeats.count) { oldCount, newCount in
            if newCount == 0 {
                cancelFlickCoach()
                hasCoachedCurrentGroup = false
            } else if oldCount < 2, newCount >= 2, !hasCoachedCurrentGroup {
                scheduleFlickCoach()
            }
        }
        .onChange(of: model.presentedOnboarding) { _, presented in
            // Card first, coach after — never both, and never lost.
            guard presented == nil,
                  isCollecting,
                  model.pinballSeats.count >= 2,
                  !hasCoachedCurrentGroup else { return }
            scheduleFlickCoach()
        }
        .onChange(of: isCollecting) { _, collecting in
            if !collecting { cancelFlickCoach() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { cancelFlickCoach() }
        }
        .onChange(of: model.mode) { _, mode in
            if mode != .pinball { cancelFlickCoach() }
        }
        .onDisappear(perform: cancelFlickCoach)
    }

    private var pinballDock: some View {
        ZStack(alignment: .top) {
            if !pinballTitle.isEmpty || pinballDockHasControls {
                VStack(spacing: 8) {
                    ChooserStatusDock(
                        title: pinballTitle,
                        detail: pinballDetail,
                        accessibilityTitle: pinballAccessibilityTitle,
                        accessibilityIdentifier: "pinball-status"
                    )
                    .padding(.horizontal, -16)
                    .padding(.bottom, -4)
                    .accessibilityFocused($resultIsFocused)

                    if isCollecting {
                        HStack(spacing: 9) { pinballCollectingButtons }
                    } else if case .revealed = model.pinballPhase {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 10) { pinballResultButtons }
                            VStack(spacing: 10) { pinballResultButtons }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, pinballDockHasControls ? 10 : 4)
            }
        }
        // Keep the playfield geometry identical while collecting, running,
        // and revealing. Otherwise hiding the buttons expands GeometryReader
        // and correctly trips the model's rotation-safety cancellation.
        .frame(height: verticalSizeClass == .compact ? 104 : 108, alignment: .top)
    }

    private var pinballDockHasControls: Bool {
        if isCollecting { return true }
        if case .revealed = model.pinballPhase { return true }
        return false
    }

    @ViewBuilder
    private var pinballCollectingButtons: some View {
        ChooserIconActionButton("Undo", systemImage: "arrow.uturn.backward", action: model.undoPinballSeat)
            .disabled(model.pinballSeats.isEmpty)
            .accessibilityIdentifier("pinball-undo")

        ChooserIconActionButton("Clear", systemImage: "xmark", role: .destructive, action: model.requestClearPinball)
            .disabled(model.pinballSeats.isEmpty)
            .accessibilityIdentifier("pinball-clear")

    }

    @ViewBuilder
    private var pinballResultButtons: some View {
        ChooserActionButton(
            "Try Again",
            systemImage: "arrow.clockwise",
            accessibilityLabel: "Try again with the same seats",
            isPrimary: true
        ) {
            model.playPinballAgain(reduceMotion: reduceMotion)
        }
        .accessibilityIdentifier("pinball-play-again")

        ChooserIconActionButton("New group", systemImage: "person.3", action: model.newPinballGroup)
            .accessibilityIdentifier("pinball-new-group")
    }

    private var isCollecting: Bool {
        if case .collecting = model.pinballPhase { return true }
        return false
    }

    private var winnerIsLit: Bool {
        switch model.pinballPhase {
        case .revealing(_, _, let isLit): isLit
        case .revealed: true
        default: false
        }
    }

    private func pinballSeatPosition(
        _ seat: NativePinballSeat,
        layout: PinballSeatTokenLayout?,
        in size: CGSize,
        diameter: CGFloat,
        emphasis: BoardPieceEmphasis
    ) -> CGPoint {
        // Only the brief tap-to-slot travel origin uses a rectangular clamp.
        // A settled multi-seat token uses the partition's jointly solved center
        // verbatim; clamping that point again can move it across a divider.
        if let travelOrigin = model.pinballTravelOrigins[seat.id] {
            return BoardPieceVisualMetrics.clampedCenter(
                travelOrigin,
                in: size,
                diameter: diameter,
                emphasis: emphasis,
                margin: 5
            )
        }
        if let settled = layout?.center(forSeatID: seat.id) {
            return settled
        }
        return BoardPieceVisualMetrics.clampedCenter(
            model.pinballPoint(for: seat),
            in: size,
            diameter: diameter,
            emphasis: emphasis,
            margin: 5
        )
    }

    private func pinballSeatEmphasis(_ seat: NativePinballSeat) -> BoardPieceEmphasis {
        if case .running = model.pinballPhase {
            return .receded
        }
        guard let winnerSeatID = model.pinballPhase.winnerSeatID else { return .resting }
        if seat.id == winnerSeatID {
            return winnerIsLit ? .winner : .resting
        }
        return .dimmed
    }

    private var pinballTitle: String {
        switch model.pinballPhase {
        case .collecting where model.pinballSeats.isEmpty:
            ""
        case .collecting where model.pinballSeats.count == 1:
            "1 seat"
        case .collecting:
            "\(model.pinballSeats.count) seats"
        case .running:
            ""
        case .revealing:
            ""
        case .revealed:
            ""
        }
    }

    private var pinballAccessibilityTitle: String {
        if case .revealed(let run) = model.pinballPhase {
            return "Seat \(run.result.winningSeatID) goes first."
        }
        return pinballTitle
    }

    private var pinballDetail: String {
        // The gesture surface, one-time wordless coach, and VoiceOver hint do
        // the teaching. Keep the live board quiet and game-piece focused.
        ""
    }

    private func scheduleFlickCoach() {
        // The introduction card is entry-scoped and this coach is group-scoped,
        // so they normally cannot co-occur — unless someone taps two seats
        // while the card is still up. Defer rather than overlap; the
        // `presentedOnboarding` observer below reschedules once it clears.
        guard model.presentedOnboarding == nil else { return }
        cancelFlickCoach()
        hasCoachedCurrentGroup = true
        flickCoachTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled, isCollecting, scenePhase == .active else { return }
                flickCoachStartedAt = Date()
                let visibility = reduceMotion
                    ? PinballFlickCoachTimeline.reducedMotionDuration
                    : PinballFlickCoachTimeline.totalDuration
                try await Task.sleep(for: .seconds(visibility))
                guard !Task.isCancelled else { return }
                flickCoachStartedAt = nil
                flickCoachTask = nil
            } catch {
                return
            }
        }
    }

    private func cancelFlickCoach() {
        flickCoachTask?.cancel()
        flickCoachTask = nil
        flickCoachStartedAt = nil
    }

}

struct PinballFlickCoachSample: Equatable, Sendable {
    let progress: CGFloat
    let opacity: CGFloat
}

struct PinballFlickCoachTimeline: Equatable, Sendable {
    static let travelDistance: CGFloat = 52
    static let passDuration: TimeInterval = 0.65
    static let pauseDuration: TimeInterval = 0.50
    static let totalDuration = passDuration * 2 + pauseDuration
    static let reducedMotionDuration: TimeInterval = 1.20

    let reduceMotion: Bool

    func sample(at elapsed: TimeInterval) -> PinballFlickCoachSample? {
        guard elapsed >= 0 else { return nil }
        if reduceMotion {
            guard elapsed <= Self.reducedMotionDuration else { return nil }
            return PinballFlickCoachSample(progress: 1, opacity: 0.78)
        }

        let localTime: TimeInterval
        if elapsed <= Self.passDuration {
            localTime = elapsed
        } else if elapsed < Self.passDuration + Self.pauseDuration {
            return nil
        } else if elapsed <= Self.totalDuration {
            localTime = elapsed - Self.passDuration - Self.pauseDuration
        } else {
            return nil
        }

        let normalized = CGFloat(min(1, max(0, localTime / Self.passDuration)))
        let progress = normalized * normalized * (3 - 2 * normalized)
        let fadeIn = min(1, CGFloat(localTime / 0.08))
        let fadeOut = min(1, CGFloat((Self.passDuration - localTime) / 0.15))
        return PinballFlickCoachSample(
            progress: progress,
            opacity: max(0, min(fadeIn, fadeOut))
        )
    }
}

private struct PinballFlickCoach: View {
    let startDate: Date
    let reduceMotion: Bool
    let color: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 120.0)) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                let timing = PinballFlickCoachTimeline(reduceMotion: reduceMotion)
                guard let sample = timing.sample(at: elapsed) else { return }

                let angle = -CGFloat.pi * 0.10
                let vector = CGVector(
                    dx: cos(angle) * PinballFlickCoachTimeline.travelDistance,
                    dy: sin(angle) * PinballFlickCoachTimeline.travelDistance
                )
                let start = CGPoint(
                    x: size.width / 2 - vector.dx / 2,
                    y: size.height / 2 - vector.dy / 2
                )
                let current = CGPoint(
                    x: start.x + vector.dx * sample.progress,
                    y: start.y + vector.dy * sample.progress
                )
                drawTaperedStreak(
                    in: &context,
                    from: start,
                    to: current,
                    color: color,
                    opacity: sample.opacity
                )

                let outer = Path(
                    ellipseIn: CGRect(
                        x: current.x - 11,
                        y: current.y - 11,
                        width: 22,
                        height: 22
                    )
                )
                context.fill(outer, with: .color(color.opacity(0.16 * sample.opacity)))
                context.stroke(
                    outer,
                    with: .color(color.opacity(0.88 * sample.opacity)),
                    lineWidth: 2.5
                )
                let center = Path(
                    ellipseIn: CGRect(
                        x: current.x - 3.5,
                        y: current.y - 3.5,
                        width: 7,
                        height: 7
                    )
                )
                context.fill(center, with: .color(color.opacity(0.92 * sample.opacity)))
            }
        }
        .accessibilityHidden(true)
    }

    private func drawTaperedStreak(
        in context: inout GraphicsContext,
        from start: CGPoint,
        to end: CGPoint,
        color: Color,
        opacity: CGFloat
    ) {
        let delta = CGVector(dx: end.x - start.x, dy: end.y - start.y)
        for index in 0..<4 {
            let lower = CGFloat(index) / 4
            let upper = CGFloat(index + 1) / 4
            var segment = Path()
            segment.move(to: CGPoint(
                x: start.x + delta.dx * lower,
                y: start.y + delta.dy * lower
            ))
            segment.addLine(to: CGPoint(
                x: start.x + delta.dx * upper,
                y: start.y + delta.dy * upper
            ))
            context.stroke(
                segment,
                with: .color(color.opacity(opacity * (0.20 + CGFloat(index) * 0.13))),
                style: StrokeStyle(
                    lineWidth: 1.2 + CGFloat(index) * 0.65,
                    lineCap: .round
                )
            )
        }
    }
}

/// The launch object is already in the player's hand before release. It appears
/// only after the gesture crosses the committed flick thresholds, follows the
/// physical finger without animation lag, and occupies the same collision-safe
/// point used as the analytic replay's first vertex.
enum PinballDirectManipulationGeometry {
    static func clampedBallCenter(
        for fingerPoint: CGPoint,
        in playfieldSize: CGSize,
        collisionInset: CGFloat? = nil
    ) -> CGPoint {
        let collisionInset = collisionInset
            ?? PinballBoardMetrics(playfieldSize: playfieldSize).collisionInset
                + PinballFlickLaunchPolicy.releaseInteriorClearance
        return CGPoint(
            x: min(
                max(fingerPoint.x, collisionInset),
                max(collisionInset, playfieldSize.width - collisionInset)
            ),
            y: min(
                max(fingerPoint.y, collisionInset),
                max(collisionInset, playfieldSize.height - collisionInset)
            )
        )
    }
}

private struct PinballDirectManipulationPreview: View {
    let tracking: NativePinballGestureTracking
    let playfieldSize: CGSize
    let colorTheme: ChooserColorTheme

    private var ballCenter: CGPoint {
        PinballDirectManipulationGeometry.clampedBallCenter(
            for: tracking.current,
            in: playfieldSize
        )
    }

    /// The ball in the player's hand must be the ball that launches.
    private var boardMetrics: PinballBoardMetrics {
        PinballBoardMetrics(playfieldSize: playfieldSize)
    }

    var body: some View {
        ZStack {
            Canvas { context, _ in
                drawDirectionTail(in: &context)
            }

            PhysicalPinballBallView(
                theme: colorTheme,
                diameter: boardMetrics.ballDiameter
            )
            .position(ballCenter)
        }
        .frame(width: playfieldSize.width, height: playfieldSize.height)
        .accessibilityHidden(true)
    }

    private func drawDirectionTail(in context: inout GraphicsContext) {
        let speed = hypot(tracking.velocity.dx, tracking.velocity.dy)
        guard speed > 0 else { return }
        let unit = CGVector(
            dx: tracking.velocity.dx / speed,
            dy: tracking.velocity.dy / speed
        )
        let scale = boardMetrics.scale
        let tailLength = min(72 * scale, max(28 * scale, tracking.payload.distance * 0.72))
        let ballRadius = boardMetrics.ballRadius
        let visibleEnd = CGPoint(
            x: ballCenter.x - unit.dx * ballRadius * 0.72,
            y: ballCenter.y - unit.dy * ballRadius * 0.72
        )
        let visibleStart = CGPoint(
            x: visibleEnd.x - unit.dx * tailLength,
            y: visibleEnd.y - unit.dy * tailLength
        )
        let delta = CGVector(
            dx: visibleEnd.x - visibleStart.x,
            dy: visibleEnd.y - visibleStart.y
        )

        // A tapered physical wake communicates the exact release vector without
        // adding a second arrow or a competing launch origin.
        for index in 0..<4 {
            let lower = CGFloat(index) / 4
            let upper = CGFloat(index + 1) / 4
            var segment = Path()
            segment.move(to: CGPoint(
                x: visibleStart.x + delta.dx * lower,
                y: visibleStart.y + delta.dy * lower
            ))
            segment.addLine(to: CGPoint(
                x: visibleStart.x + delta.dx * upper,
                y: visibleStart.y + delta.dy * upper
            ))
            context.stroke(
                segment,
                with: .color(colorTheme.pinballTailColor.opacity(
                    0.20 + Double(index) * 0.14
                )),
                style: StrokeStyle(
                    lineWidth: 1.4 + CGFloat(index) * 0.65,
                    lineCap: .round
                )
            )
        }
    }
}

struct PinballDividerRay: Equatable, Sendable {
    let start: CGPoint
    let end: CGPoint
}

enum PinballDividerGeometry {
    static func baseRays(for partition: PinballRadialPartition) -> [PinballDividerRay] {
        partition.regions.map {
            PinballDividerRay(start: partition.center, end: $0.startBoundaryPoint)
        }
    }

    static func winnerRays(
        for seatID: Int,
        in partition: PinballRadialPartition
    ) -> [PinballDividerRay] {
        guard let winner = partition.regions.first(where: { $0.seat.seatID == seatID }) else {
            return []
        }
        return [winner.startBoundaryPoint, winner.endBoundaryPoint].map {
            PinballDividerRay(start: partition.center, end: $0)
        }
    }
}

struct PinballDividerStrokeMetrics: Equatable, Sendable {
    let keylineWidth: CGFloat
    let primaryWidth: CGFloat
}

enum PinballDividerVisualMetrics {
    static func base(isDense: Bool) -> PinballDividerStrokeMetrics {
        PinballDividerStrokeMetrics(
            keylineWidth: isDense ? 4.0 : 4.6,
            primaryWidth: isDense ? 1.5 : 2.0
        )
    }

    static let winner = PinballDividerStrokeMetrics(
        keylineWidth: 5.6,
        primaryWidth: 2.8
    )
}

/// Exact equal-area ownership rays. The outer perimeter remains unframed; the
/// matte ink dividers stay visible so the resting place is unambiguous.
private struct PinballDividerCanvas: View {
    let partition: PinballRadialPartition
    let winnerSeatID: Int?
    let colorTheme: ChooserColorTheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        Canvas { context, _ in
            let isDense = partition.regions.count >= 9
            let metrics = PinballDividerVisualMetrics.base(isDense: isDense)
            let baseRays = PinballDividerGeometry.baseRays(for: partition)
            let contrastScale: CGFloat = colorSchemeContrast == .increased ? 1.28 : 1

            if let keylineColor = colorTheme.dividerSecondaryColor {
                for ray in baseRays {
                    strokeRay(
                        from: ray.start,
                        to: ray.end,
                        in: &context,
                        lineColor: keylineColor.opacity(isDense ? 0.92 : 1),
                        lineWidth: metrics.keylineWidth * contrastScale
                    )
                }
            }

            for ray in baseRays {
                strokeRay(
                    from: ray.start,
                    to: ray.end,
                    in: &context,
                    lineColor: colorTheme.dividerColor.opacity(
                        colorSchemeContrast == .increased ? 1 : (isDense ? 0.86 : 1)
                    ),
                    lineWidth: metrics.primaryWidth * contrastScale
                )
            }

            if let winnerSeatID {
                let color = colorTheme.participantColor(at: winnerSeatID - 1)
                let winnerRays = PinballDividerGeometry.winnerRays(
                    for: winnerSeatID,
                    in: partition
                )
                if let keylineColor = colorTheme.dividerSecondaryColor {
                    for ray in winnerRays {
                        strokeRay(
                            from: ray.start,
                            to: ray.end,
                            in: &context,
                            lineColor: keylineColor,
                            lineWidth: PinballDividerVisualMetrics.winner.keylineWidth * contrastScale
                        )
                    }
                }
                for ray in winnerRays {
                    strokeRay(
                        from: ray.start,
                        to: ray.end,
                        in: &context,
                        lineColor: color.opacity(colorSchemeContrast == .increased ? 1 : 0.92),
                        lineWidth: PinballDividerVisualMetrics.winner.primaryWidth * contrastScale,
                        dash: differentiateWithoutColor ? [8, 4] : []
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func strokeRay(
        from start: CGPoint,
        to end: CGPoint,
        in context: inout GraphicsContext,
        lineColor: Color,
        lineWidth: CGFloat,
        dash: [CGFloat] = []
    ) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(
            path,
            with: .color(lineColor),
            style: StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round,
                dash: dash
            )
        )
    }
}

private struct ChooserStatusDock: View {
    let title: String
    let detail: String
    var accessibilityTitle: String? = nil
    let accessibilityIdentifier: String
    @Environment(\.chooserVisualTheme) private var visualTheme

    var body: some View {
        Group {
            if title.isEmpty {
                Color.clear
                    .frame(height: 1)
            } else {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(visualTheme.informationPanelInkColor)
                    .multilineTextAlignment(.center)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 32)
                    .background(
                        visualTheme.informationPanelColor,
                        in: Capsule()
                    )
                    .overlay {
                        Capsule()
                            .stroke(visualTheme.separatorColor, lineWidth: 1)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .frame(height: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHidden(accessibilitySummary.isEmpty)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var accessibilitySummary: String {
        [accessibilityTitle ?? title, detail]
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }
}

/// A restrained physical landing layered on top of `BoardRingView`'s authored
/// 1.06 winner lift. The scale values here are multipliers: the last keyframe
/// returns to 1 so the ring finishes at the material view's canonical winner
/// presentation instead of leaving a second transform behind.
/// How large a Chooser ring draws, and how much room its reveal needs.
///
/// Extracted from the view so the no-collapse property can be tested directly:
/// the sizing and the clamp must agree about the winner's footprint, and when
/// they disagree `clampedCenter` degrades to stacking every ring on the exact
/// centre of the board.
enum ChooserRingSizing {
    /// Everything a ring can add to its own footprint after it is chosen — the
    /// anticipation rebound during the countdown and the landing rebound at
    /// reveal, whichever is larger. Any resting ring can become the winner, so
    /// this is reserved from the first frame rather than at reveal.
    static let externalScale = max(
        ChoiceAnticipationTimeline.chooser.maximumScale,
        ChooserWinnerLandingMetrics.maximumScale
    )

    static let margin = 8 + max(
        ChoiceAnticipationTimeline.chooser.maximumTranslation,
        ChooserWinnerLandingMetrics.maximumTranslation
    )

    /// The authored anchors scale with the board; the fractions do not. On a
    /// phone `boardScale` is 1 and the clamps bind exactly where they always
    /// have, so the whole expression is the shipping expression.
    ///
    /// `fittedDiameter` replaces a hand-tuned `max(96, shortEdge - 40)` tail.
    /// That tail was a guess at the same question and got it wrong on a short
    /// landscape playfield, where it returned a diameter whose winner footprint
    /// could not fit the height — precisely the case that collapses the clamp.
    static func diameter(in size: CGSize) -> CGFloat {
        let scale = BoardPieceVisualMetrics.boardScale(for: size)
        let shortEdge = min(size.width, size.height)
        let isLandscape = size.width > size.height
        let preferred = isLandscape
            ? min(158 * scale, max(144 * scale, shortEdge * 0.52))
            : min(176 * scale, max(158 * scale, shortEdge * 0.45))
        return BoardPieceVisualMetrics.fittedDiameter(
            preferred,
            in: size,
            emphasis: .winner,
            externalScale: externalScale,
            margin: margin,
            scale: scale
        )
    }
}

enum ChooserWinnerLandingMetrics {
    static let compressionScale: CGFloat = 0.94
    static let reboundScale: CGFloat = 1.055
    static let counterScale: CGFloat = 0.993

    static let compressionX: CGFloat = 1.5
    static let compressionY: CGFloat = 2.5
    static let reboundX: CGFloat = -4.5
    static let reboundY: CGFloat = -8
    static let counterX: CGFloat = 1.2
    static let counterY: CGFloat = -1.5

    static let compressionRotation = 0.45
    static let reboundRotation = -0.90
    static let counterRotation = 0.18

    static let maximumScale = reboundScale
    static let maximumTranslation = max(
        hypot(compressionX, compressionY),
        hypot(reboundX, reboundY),
        hypot(counterX, counterY)
    )

    static let compressionFraction = ChoiceAnticipationTimeline
        .chooser
        .winnerCompressionFraction
    static let reboundFraction = 0.22
    static let counterFraction = 0.29
    static let settleFraction = 0.39
}

private struct ChooserWinnerLandingValues {
    var scale: CGFloat = 1
    var x: CGFloat = 0
    var y: CGFloat = 0
    var rotationDegrees = 0.0
}

private struct ChooserWinnerLandingModifier: ViewModifier {
    let isActive: Bool
    let duration: TimeInterval
    let direction: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var landingSequence = 0

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(
                initialValue: ChooserWinnerLandingValues(),
                trigger: landingSequence
            ) { content, value in
                content
                    .scaleEffect(value.scale)
                    .offset(x: value.x, y: value.y)
                    .rotationEffect(.degrees(value.rotationDegrees))
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(
                        ChooserWinnerLandingMetrics.compressionScale,
                        duration: duration * ChooserWinnerLandingMetrics.compressionFraction
                    )
                    CubicKeyframe(
                        ChooserWinnerLandingMetrics.reboundScale,
                        duration: duration * ChooserWinnerLandingMetrics.reboundFraction
                    )
                    CubicKeyframe(
                        ChooserWinnerLandingMetrics.counterScale,
                        duration: duration * ChooserWinnerLandingMetrics.counterFraction
                    )
                    CubicKeyframe(
                        1,
                        duration: duration * ChooserWinnerLandingMetrics.settleFraction
                    )
                }
                KeyframeTrack(\.x) {
                    CubicKeyframe(
                        reduceMotion
                            ? 0
                            : direction * ChooserWinnerLandingMetrics.compressionX,
                        duration: duration * ChooserWinnerLandingMetrics.compressionFraction
                    )
                    CubicKeyframe(
                        reduceMotion
                            ? 0
                            : direction * ChooserWinnerLandingMetrics.reboundX,
                        duration: duration * ChooserWinnerLandingMetrics.reboundFraction
                    )
                    CubicKeyframe(
                        reduceMotion
                            ? 0
                            : direction * ChooserWinnerLandingMetrics.counterX,
                        duration: duration * ChooserWinnerLandingMetrics.counterFraction
                    )
                    CubicKeyframe(
                        0,
                        duration: duration * ChooserWinnerLandingMetrics.settleFraction
                    )
                }
                KeyframeTrack(\.y) {
                    CubicKeyframe(
                        reduceMotion ? 0 : ChooserWinnerLandingMetrics.compressionY,
                        duration: duration * ChooserWinnerLandingMetrics.compressionFraction
                    )
                    CubicKeyframe(
                        reduceMotion ? 0 : ChooserWinnerLandingMetrics.reboundY,
                        duration: duration * ChooserWinnerLandingMetrics.reboundFraction
                    )
                    CubicKeyframe(
                        reduceMotion ? 0 : ChooserWinnerLandingMetrics.counterY,
                        duration: duration * ChooserWinnerLandingMetrics.counterFraction
                    )
                    CubicKeyframe(
                        0,
                        duration: duration * ChooserWinnerLandingMetrics.settleFraction
                    )
                }
                KeyframeTrack(\.rotationDegrees) {
                    CubicKeyframe(
                        reduceMotion
                            ? 0
                            : direction * ChooserWinnerLandingMetrics.compressionRotation,
                        duration: duration * ChooserWinnerLandingMetrics.compressionFraction
                    )
                    CubicKeyframe(
                        reduceMotion
                            ? 0
                            : direction * ChooserWinnerLandingMetrics.reboundRotation,
                        duration: duration * ChooserWinnerLandingMetrics.reboundFraction
                    )
                    CubicKeyframe(
                        reduceMotion
                            ? 0
                            : direction * ChooserWinnerLandingMetrics.counterRotation,
                        duration: duration * ChooserWinnerLandingMetrics.counterFraction
                    )
                    CubicKeyframe(
                        0,
                        duration: duration * ChooserWinnerLandingMetrics.settleFraction
                    )
                }
            }
            .onAppear {
                if isActive {
                    landingSequence &+= 1
                }
            }
            .onChange(of: isActive) { _, active in
                if active {
                    landingSequence &+= 1
                }
            }
    }
}

private struct ChooserAnticipationKeyframes<Content: View>: View {
    let isActive: Bool
    let startDate: Date?
    @ViewBuilder let content: (TimeInterval) -> Content

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 120, paused: !isActive)) { timeline in
            ZStack {
                content(elapsed(at: timeline.date))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func elapsed(at date: Date) -> TimeInterval {
        guard isActive, let startDate else { return 0 }
        return max(0, date.timeIntervalSince(startDate))
    }
}

/// Tap In intentionally retains its Build 11 one-second contraction. Its
/// explicit Pick interaction has different pacing from simultaneous Chooser.
private struct AcceleratingChooserPulse<Content: View>: View {
    let isActive: Bool
    let startDate: Date?
    @ViewBuilder let content: (CGFloat) -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: !isActive || reduceMotion)) { timeline in
            ZStack {
                content(scale(at: timeline.date))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func scale(at date: Date) -> CGFloat {
        guard isActive, !reduceMotion, let startDate else { return 1 }
        let elapsed = min(1, max(0, date.timeIntervalSince(startDate)))
        let eased = elapsed * elapsed * (3 - 2 * elapsed)
        return 1 - 0.026 * eased
    }
}

@MainActor
private final class NativePinballSKView: SKView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        preferredFramesPerSecond = window?.windowScene?.screen.maximumFramesPerSecond ?? 60
    }
}

enum NativePinballReplayPresentation: Hashable {
    case running
    case finalStatic

    var isFinal: Bool { self != .running }
    var settlesAtEndpoint: Bool { self == .running }
    var dependsOnReduceMotion: Bool { settlesAtEndpoint }
}

/// Accessibility preferences the rendered replay depends on. A change to any
/// of them has to rebuild the scene, the same way a motion preference does.
private struct NativePinballReplayAppearanceFlags: Equatable {
    let reduceMotion: Bool
    let increasedContrast: Bool
    let reduceTransparency: Bool
    let differentiateWithoutColor: Bool
}

private struct NativePinballReplayIdentity: Hashable {
    let runID: UUID
    let presentation: NativePinballReplayPresentation
    let colorThemeID: String
}

@MainActor
private struct NativePinballSpriteReplay: UIViewRepresentable {
    let run: NativePinballRun
    let presentation: NativePinballReplayPresentation
    let colorTheme: ChooserColorTheme
    /// Seat rings the marcher recorded, keyed by polyline vertex index. The
    /// scene cannot derive these from the points alone.
    var bumperMarks: [Int: NativeReplayBumperMark] = [:]
    var onImpact: (_ runID: UUID, _ impact: NativeAnalyticReplayImpact) -> Void = { _, _ in }
    var onEndpointCompression: (_ runID: UUID) -> Void = { _ in }
    var onFinished: (_ runID: UUID) -> Void = { _ in }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    private var appearanceFlags: NativePinballReplayAppearanceFlags {
        NativePinballReplayAppearanceFlags(
            reduceMotion: reduceMotion,
            increasedContrast: colorSchemeContrast == .increased,
            reduceTransparency: reduceTransparency,
            differentiateWithoutColor: differentiateWithoutColor
        )
    }

    private var identity: NativePinballReplayIdentity {
        NativePinballReplayIdentity(
            runID: run.id,
            presentation: presentation,
            colorThemeID: colorTheme.id
        )
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SKView {
        context.coordinator.onImpact = onImpact
        context.coordinator.onEndpointCompression = onEndpointCompression
        context.coordinator.onFinished = onFinished
        let view = NativePinballSKView(frame: .zero)
        view.backgroundColor = .clear
        view.allowsTransparency = true
        view.ignoresSiblingOrder = true
        let scene = NativeAnalyticPolylineReplayScene(size: CGSize(width: 1, height: 1))
        scene.scaleMode = .resizeFill
        view.presentScene(scene)
        context.coordinator.scene = scene
        replay(in: scene, coordinator: context.coordinator)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        context.coordinator.onImpact = onImpact
        context.coordinator.onEndpointCompression = onEndpointCompression
        context.coordinator.onFinished = onFinished
        let identityChanged = context.coordinator.identity != identity
        let relevantMotionPreferenceChanged = presentation.dependsOnReduceMotion &&
            context.coordinator.reduceMotion != reduceMotion
        let appearanceChanged = context.coordinator.appearanceFlags != appearanceFlags
        context.coordinator.reduceMotion = reduceMotion
        context.coordinator.appearanceFlags = appearanceFlags
        guard identityChanged || relevantMotionPreferenceChanged || appearanceChanged else { return }
        if let scene = context.coordinator.scene {
            replay(in: scene, coordinator: context.coordinator)
        }
    }

    static func dismantleUIView(_ uiView: SKView, coordinator: Coordinator) {
        coordinator.scene?.cancelReplay()
        uiView.presentScene(nil)
    }

    private func replay(in scene: NativeAnalyticPolylineReplayScene, coordinator: Coordinator) {
        coordinator.identity = identity
        coordinator.reduceMotion = reduceMotion
        coordinator.appearanceFlags = appearanceFlags
        let isFinal = presentation.isFinal
        let motionColor = UIColor(colorTheme.pinballTailColor)
        let ballColor = UIColor(colorTheme.pinballColor)
        let ballEdgeColor = UIColor(colorTheme.pinballEdgeColor)
        let impactColor = UIColor(colorTheme.pinballImpactColor)
        let plan = NativeAnalyticReplayPlan(
            polyline: isFinal
                ? [run.result.finalPoint]
                : run.result.trajectory.points,
            duration: isFinal ? 0 : run.curve.duration,
            fairnessDeflectorVertexIndex: isFinal
                ? nil
                : run.result.fairnessDeflectorVertexIndex,
            bumperMarks: isFinal ? [:] : bumperMarks,
            regions: [],
            winnerFlashes: [],
            style: NativeReplayVisualStyle(
                backgroundColor: .clear,
                guideColor: .clear,
                trailColor: motionColor,
                cursorColor: ballColor,
                ballEdgeColor: ballEdgeColor,
                impactColor: impactColor,
                ballMaterial: colorTheme.pinballMaterial,
                trailWidth: isFinal ? 1.8 : 2.6,
                trailGlowWidth: 0,
                cursorRadius: 15,
                showsGuide: false,
                settlesAtEndpoint: presentation.settlesAtEndpoint && !reduceMotion,
                reducesMotion: reduceMotion,
                increasesContrast: colorSchemeContrast == .increased,
                reducesTransparency: reduceTransparency,
                differentiatesWithoutColor: differentiateWithoutColor
            )
        )
        scene.replay(
            plan,
            pointMapper: { point, size in CGPoint(x: point.x, y: size.height - point.y) },
            progressMapper: { normalizedTime in
                isFinal
                    ? 1
                    : run.curve.progress(at: normalizedTime * run.curve.duration)
            },
            speedMapper: { normalizedTime in
                isFinal
                    ? 0
                    : run.launchEnergy * Double(
                        run.curve.remainingSpeedFraction(
                            at: normalizedTime * run.curve.duration
                        )
                    )
            },
            callbacks: presentation == .running
                ? NativeAnalyticReplayCallbacks(
                    onImpact: { [weak coordinator] impact in
                        coordinator?.onImpact(run.id, impact)
                    },
                    onEndpointCompression: { [weak coordinator] in
                        coordinator?.onEndpointCompression(run.id)
                    },
                    onFinished: { [weak coordinator] in
                        coordinator?.onFinished(run.id)
                    }
                )
                : NativeAnalyticReplayCallbacks()
        )
    }

    final class Coordinator {
        var scene: NativeAnalyticPolylineReplayScene?
        var reduceMotion = false
        var appearanceFlags: NativePinballReplayAppearanceFlags?
        var identity: NativePinballReplayIdentity?
        var onImpact: (_ runID: UUID, _ impact: NativeAnalyticReplayImpact) -> Void = { _, _ in }
        var onEndpointCompression: (_ runID: UUID) -> Void = { _ in }
        var onFinished: (_ runID: UUID) -> Void = { _ in }
    }
}
