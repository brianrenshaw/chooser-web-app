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
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack {
                    NativeTouchSurface(
                        accessibilityLabel: "Together touch area",
                        accessibilityHint: "Place two or more fingers here at the same time.",
                        onBegan: model.togetherTouchBegan,
                        onMoved: model.togetherTouchMoved,
                        onEnded: { model.togetherTouchEnded($0, cancelled: false) },
                        onCancelled: { model.togetherTouchEnded($0, cancelled: true) }
                    )
                    .accessibilityIdentifier("together-stage")

                    ForEach(sortedVisuals, id: \.id) { visual in
                        let isWinner = model.togetherSnapshot.winner == visual.id
                        AcceleratingChooserPulse(
                            isActive: isCountdown,
                            startDate: model.countdownStartedAt
                        ) {
                            NativeNeonRingView(
                                diameter: ringDiameter(in: geometry.size),
                                lineWidth: 5,
                                palette: .hue(visual.hue),
                                emphasis: ringEmphasis(isWinner: isWinner),
                                accessibilityLabel: isWinner ? "Winning finger" : "Finger"
                            )
                        }
                        .position(visual.location)
                        .transition(
                            reduceMotion
                                ? .identity
                                : .scale(scale: 0.7).combined(with: .opacity)
                        )
                    }
                    .allowsHitTesting(false)
                }
                .clipped()
                .animation(
                    reduceMotion ? .linear(duration: 0.01) : .spring(duration: 0.32, bounce: 0.34),
                    value: model.togetherSnapshot.phase
                )
            }

            ChooserStatusDock(
                title: statusTitle,
                detail: statusDetail,
                accessibilityIdentifier: "together-status"
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

    private var statusTitle: String {
        switch model.togetherSnapshot.phase {
        case .idle where model.togetherSnapshot.participantTouchIDs.count == 1:
            "One finger down"
        case .idle:
            "Touch and hold together"
        case .settling:
            "Hold still…"
        case .countdown:
            "Choosing…"
        case .revealed:
            "This finger goes first."
        }
    }

    private var statusDetail: String {
        switch model.togetherSnapshot.phase {
        case .idle where model.togetherSnapshot.participantTouchIDs.count == 1:
            "Add at least one more."
        case .idle:
            "Each person uses one finger."
        case .settling:
            "\(model.togetherSnapshot.participantTouchIDs.count) fingers are in."
        case .countdown:
            "The glow is speeding up."
        case .revealed:
            "Lift, then touch again for a new choice."
        }
    }

    private func ringDiameter(in size: CGSize) -> CGFloat {
        min(140, max(96, min(size.width, size.height) * 0.36))
    }

    private func ringEmphasis(isWinner: Bool) -> NativeNeonEmphasis {
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

    public init(model: ChooserAppModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let layout = TapInGridLayout.make(
                    count: model.tapInSnapshot.entries.count,
                    in: geometry.size
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
                    .accessibilityIdentifier("tap-in-stage")

                    ForEach(Array(model.tapInSnapshot.entries.enumerated()), id: \.element.id) { index, entry in
                        let winner = model.tapInSnapshot.winner?.id == entry.id
                        AcceleratingChooserPulse(
                            isActive: isCountdown,
                            startDate: model.countdownStartedAt
                        ) {
                            NativeNeonTokenView(
                                number: entry.number,
                                diameter: tokenDiameter(entry: entry, layout: layout),
                                palette: .hue(goldenAngleHue(entry.number - 1)),
                                emphasis: tokenEmphasis(winner: winner)
                            )
                        }
                        .position(tokenPosition(entry: entry, index: index, layout: layout, size: geometry.size))
                        .zIndex(winner ? 5 : 1)
                        .transition(
                            reduceMotion
                                ? .identity
                                : .scale(scale: 0.62).combined(with: .opacity)
                        )
                    }

                    ForEach(model.tapInPending.values.sorted { $0.touchID < $1.touchID }, id: \.touchID) { pending in
                        NativeNeonTokenView(
                            number: pending.number,
                            diameter: min(112, layout.diameter),
                            palette: .hue(pending.hue),
                            emphasis: .pulsing(period: 0.8)
                        )
                        .position(pending.location)
                        .transition(
                            reduceMotion
                                ? .identity
                                : .scale(scale: 0.7).combined(with: .opacity)
                        )
                    }
                }
                .clipped()
                .allowsHitTesting(isCollecting)
                .animation(
                    reduceMotion ? .linear(duration: 0.01) : .spring(duration: 0.38, bounce: 0.30),
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
        VStack(spacing: 12) {
            ChooserStatusDock(
                title: tapInTitle,
                detail: tapInDetail,
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
            } else {
                Grid(horizontalSpacing: 10) {
                    GridRow {
                        tapInUndoButton
                        tapInClearButton
                        tapInPickButton
                            .gridCellColumns(2)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(.black.opacity(0.94))
    }

    private var tapInUndoButton: some View {
        ChooserActionButton("Undo", systemImage: "arrow.uturn.backward", action: model.undoTapIn)
            .disabled(model.tapInSnapshot.entries.isEmpty || !isCollecting)
            .accessibilityIdentifier("tap-in-undo")
    }

    private var tapInClearButton: some View {
        ChooserActionButton("Clear", systemImage: "xmark", role: .destructive, action: model.requestClearTapIn)
            .disabled(model.tapInSnapshot.entries.isEmpty || !isCollecting)
            .accessibilityIdentifier("tap-in-clear")
    }

    private var tapInPickButton: some View {
        ChooserActionButton(
            isCountdown ? "Choosing…" : "Pick from \(model.tapInSnapshot.entries.count)",
            systemImage: "sparkles",
            isPrimary: true,
            action: model.pickTapIn
        )
        .disabled(!model.tapInCanPick)
        .accessibilityIdentifier("tap-in-pick")
    }

    @ViewBuilder
    private var tapInResultButtons: some View {
        ChooserActionButton("Pick again", systemImage: "arrow.clockwise", isPrimary: true, action: model.pickTapInAgain)
            .accessibilityIdentifier("tap-in-pick-again")
        ChooserActionButton("New group", systemImage: "person.3", action: model.newTapInGroup)
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
            "Each player taps once."
        case .collecting:
            "\(model.tapInSnapshot.entries.count) \(model.tapInSnapshot.entries.count == 1 ? "player" : "players") in"
        case .countdown:
            "Choosing…"
        case .revealed(let winner):
            "Player \(winner.number) goes first."
        }
    }

    private var tapInDetail: String {
        switch model.tapInSnapshot.phase {
        case .collecting where model.tapInSnapshot.entries.isEmpty:
            "Pass the iPhone around."
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
        size: CGSize
    ) -> CGPoint {
        if case .revealed(let winner) = model.tapInSnapshot.phase, winner.id == entry.id {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
        if let origin = model.tapInTravelOrigins[entry.id] {
            return origin
        }
        return layout.positions.indices.contains(index) ? layout.positions[index] : .zero
    }

    private func tokenDiameter(entry: TapInEntry, layout: TapInGridResult) -> CGFloat {
        if model.tapInSnapshot.winner?.id == entry.id { return 140 }
        return layout.diameter
    }

    private func tokenEmphasis(winner: Bool) -> NativeNeonEmphasis {
        switch model.tapInSnapshot.phase {
        case .revealed:
            winner ? .winner : .dimmed
        case .countdown:
            .resting
        case .collecting:
            .resting
        }
    }

    private func goldenAngleHue(_ index: Int) -> Double {
        (Double(index) * 137.508).truncatingRemainder(dividingBy: 360)
    }
}

@MainActor
public struct PinballModeView: View {
    @Bindable var model: ChooserAppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var resultIsFocused: Bool

    public init(model: ChooserAppModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack {
                    if let partition = model.pinballPartition() {
                        PinballRegionsCanvas(
                            partition: partition,
                            winnerSeatID: model.pinballPhase.winnerSeatID,
                            winnerIsLit: winnerIsLit
                        )
                    }

                    if case .running(let run) = model.pinballPhase {
                        NativePinballSpriteReplay(run: run, partition: model.pinballPartition())
                    } else if case .revealing(let run, _, _) = model.pinballPhase {
                        NativePinballSpriteReplay(run: run, partition: model.pinballPartition(), showCompletedPath: true)
                    } else if case .revealed(let run) = model.pinballPhase {
                        NativePinballSpriteReplay(run: run, partition: model.pinballPartition(), showCompletedPath: true)
                    }

                    if isCollecting {
                        NativeTouchSurface(
                            accessibilityLabel: "Pinball seat area",
                            accessibilityHint: "Tap the screen nearest each person's seat.",
                            onBegan: { _ in },
                            onEnded: { model.addPinballSeat(at: $0.location) },
                            onCancelled: { _ in },
                            onAccessibilityActivate: model.addPinballSeatForAccessibility
                        )
                        .accessibilityIdentifier("pinball-stage")
                    }

                    ForEach(model.pinballSeats) { seat in
                        NativeNeonTokenView(
                            number: seat.id,
                            diameter: pinballSeatDiameter(seat),
                            palette: .hue(goldenAngleHue(seat.id - 1)),
                            emphasis: pinballSeatEmphasis(seat)
                        )
                        .position(model.pinballPoint(for: seat))
                        .transition(
                            reduceMotion
                                ? .identity
                                : .scale(scale: 0.5).combined(with: .opacity)
                        )
                    }
                    .allowsHitTesting(false)
                }
                .clipped()
                .onAppear { model.updatePinballPlayfield(size: geometry.size) }
                .onChange(of: geometry.size) { _, size in model.updatePinballPlayfield(size: size) }
                .animation(
                    reduceMotion ? .linear(duration: 0.01) : .spring(duration: 0.36, bounce: 0.3),
                    value: model.pinballSeats
                )
            }

            pinballDock
        }
        .onChange(of: model.pinballPhase.winnerSeatID) { _, winner in
            if case .revealed = model.pinballPhase {
                resultIsFocused = winner != nil
            }
        }
    }

    private var pinballDock: some View {
        VStack(spacing: 12) {
            ChooserStatusDock(
                title: pinballTitle,
                detail: pinballDetail,
                accessibilityIdentifier: "pinball-status"
            )
            .padding(.horizontal, -16)
            .padding(.bottom, -4)
            .accessibilityFocused($resultIsFocused)

            ZStack {
                HStack(spacing: 9) { pinballCollectingButtons }
                .opacity(isCollecting ? 1 : 0)
                .accessibilityHidden(!isCollecting)
                .allowsHitTesting(isCollecting)

                if case .revealed = model.pinballPhase {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) { pinballResultButtons }
                        VStack(spacing: 10) { pinballResultButtons }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(.black.opacity(0.94))
    }

    @ViewBuilder
    private var pinballCollectingButtons: some View {
        ChooserActionButton("Undo", systemImage: "arrow.uturn.backward", action: model.undoPinballSeat)
            .disabled(model.pinballSeats.isEmpty)
            .accessibilityIdentifier("pinball-undo")

        Menu {
            ForEach(2...12, id: \.self) { count in
                Button("\(count) seats") {
                    model.configureAccessiblePinballSeats(count: count)
                }
            }
        } label: {
            ChooserAdaptiveLabel("Seats", systemImage: "person.2")
        }
        .buttonStyle(ChooserCapsuleButtonStyle())
        .accessibilityLabel("Set an accessible seat count")
        .accessibilityIdentifier("pinball-seat-count")

        ChooserActionButton("Clear", systemImage: "xmark", role: .destructive, action: model.requestClearPinball)
            .disabled(model.pinballSeats.isEmpty)
            .accessibilityIdentifier("pinball-clear")

        ChooserActionButton("Start", systemImage: "play.fill", isPrimary: true) {
            model.startPinball(reduceMotion: reduceMotion)
        }
        .disabled(!model.pinballCanStart)
        .accessibilityIdentifier("pinball-start")
    }

    @ViewBuilder
    private var pinballResultButtons: some View {
        ChooserActionButton("Play again", systemImage: "arrow.clockwise", isPrimary: true) {
            model.playPinballAgain(reduceMotion: reduceMotion)
        }
        .accessibilityIdentifier("pinball-play-again")

        ChooserActionButton("New group", systemImage: "person.3", action: model.newPinballGroup)
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

    private func pinballSeatDiameter(_ seat: NativePinballSeat) -> CGFloat {
        model.pinballPhase.winnerSeatID == seat.id ? 64 : 54
    }

    private func pinballSeatEmphasis(_ seat: NativePinballSeat) -> NativeNeonEmphasis {
        guard let winnerSeatID = model.pinballPhase.winnerSeatID else { return .resting }
        if seat.id == winnerSeatID {
            return winnerIsLit ? .winner : .resting
        }
        return .dimmed
    }

    private var pinballTitle: String {
        switch model.pinballPhase {
        case .collecting where model.pinballSeats.isEmpty:
            "Tap near each seat."
        case .collecting:
            "\(model.pinballSeats.count) \(model.pinballSeats.count == 1 ? "seat" : "seats") in"
        case .running:
            "Pinball!"
        case .revealing:
            "We have a winner…"
        case .revealed(let run):
            "Seat \(run.result.winningSeatID) goes first."
        }
    }

    private var pinballDetail: String {
        switch model.pinballPhase {
        case .collecting where model.pinballSeats.count < 2:
            "Place the iPhone flat. Add at least two seats."
        case .collecting:
            "Equal areas give every seat the same odds."
        case .running:
            "The final resting place decides."
        case .revealing:
            "Watch the glowing region."
        case .revealed:
            "Play again keeps the same seating."
        }
    }

    private func goldenAngleHue(_ index: Int) -> Double {
        (Double(index) * 137.508).truncatingRemainder(dividingBy: 360)
    }
}

private struct ChooserStatusDock: View {
    let title: String
    let detail: String
    let accessibilityIdentifier: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .contentTransition(.numericText())
            Text(detail)
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.58))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private struct ChooserActionButton: View {
    let title: String
    let systemImage: String
    let role: ButtonRole?
    let isPrimary: Bool
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String,
        role: ButtonRole? = nil,
        isPrimary: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.isPrimary = isPrimary
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            ChooserAdaptiveLabel(title, systemImage: systemImage)
        }
        .accessibilityLabel(title)
        .buttonStyle(ChooserCapsuleButtonStyle(isPrimary: isPrimary, isDestructive: role == .destructive))
    }
}

private struct ChooserAdaptiveLabel: View {
    let title: String
    let systemImage: String

    init(_ title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            Label(title, systemImage: systemImage)
                .fixedSize(horizontal: true, vertical: false)
            Text(title)
                .fixedSize(horizontal: true, vertical: false)
            Image(systemName: systemImage)
        }
        .font(.system(.body, design: .rounded, weight: .bold))
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .frame(maxWidth: .infinity, minHeight: 44)
    }
}

private struct ChooserCapsuleButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var isPrimary = false
    var isDestructive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .foregroundStyle(foreground)
            .background(background(configuration: configuration), in: Capsule())
            .overlay {
                Capsule().stroke(border, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(isEnabled ? 1 : 0.38)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foreground: Color {
        if isPrimary { return .black }
        if isDestructive { return .red.opacity(0.92) }
        return .white.opacity(0.9)
    }

    private func background(configuration: Configuration) -> Color {
        if isPrimary { return .cyan.opacity(configuration.isPressed ? 0.72 : 0.94) }
        if isDestructive { return .red.opacity(configuration.isPressed ? 0.18 : 0.10) }
        return .white.opacity(configuration.isPressed ? 0.14 : 0.08)
    }

    private var border: Color {
        if isPrimary { return .white.opacity(0.34) }
        if isDestructive { return .red.opacity(0.34) }
        return .white.opacity(0.14)
    }
}

private struct AcceleratingChooserPulse<Content: View>: View {
    let isActive: Bool
    let startDate: Date?
    @ViewBuilder let content: () -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: !isActive || reduceMotion)) { timeline in
            content()
                .scaleEffect(scale(at: timeline.date))
        }
    }

    private func scale(at date: Date) -> CGFloat {
        guard isActive, !reduceMotion, let startDate else { return 1 }
        let elapsed = min(1, max(0, date.timeIntervalSince(startDate)))
        let cycles = 1.25 * elapsed + 3.0 * elapsed * elapsed
        let wave = (sin(cycles * 2 * .pi - .pi / 2) + 1) / 2
        return 0.96 + 0.09 * wave
    }
}

private struct PinballRegionsCanvas: View {
    let partition: PinballRadialPartition
    let winnerSeatID: Int?
    let winnerIsLit: Bool

    var body: some View {
        Canvas { context, _ in
            for region in partition.regions {
                let polygon = pinballRegionPolygon(region, partition: partition)
                guard let first = polygon.first else { continue }
                var path = Path()
                path.move(to: first)
                polygon.dropFirst().forEach { path.addLine(to: $0) }
                path.closeSubpath()
                let hue = goldenAngleHue(region.seat.seatID - 1) / 360
                let isWinner = winnerSeatID == region.seat.seatID
                context.fill(
                    path,
                    with: .color(Color(hue: hue, saturation: 0.84, brightness: 1).opacity(isWinner && winnerIsLit ? 0.38 : 0.10))
                )
                context.stroke(
                    path,
                    with: .color(Color(hue: hue, saturation: 0.84, brightness: 1).opacity(isWinner && winnerIsLit ? 0.9 : 0.34)),
                    style: StrokeStyle(lineWidth: isWinner && winnerIsLit ? 3 : 1.2, lineJoin: .round)
                )
            }
        }
        .allowsHitTesting(false)
    }
}

@MainActor
private struct NativePinballSpriteReplay: UIViewRepresentable {
    let run: NativePinballRun
    let partition: PinballRadialPartition?
    var showCompletedPath = false

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: .zero)
        view.backgroundColor = .clear
        view.allowsTransparency = true
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
        let scene = NativeAnalyticPolylineReplayScene(size: CGSize(width: 1, height: 1))
        scene.scaleMode = .resizeFill
        view.presentScene(scene)
        context.coordinator.scene = scene
        replay(in: scene, coordinator: context.coordinator)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        guard context.coordinator.runID != run.id else { return }
        if let scene = context.coordinator.scene {
            replay(in: scene, coordinator: context.coordinator)
        }
    }

    static func dismantleUIView(_ uiView: SKView, coordinator: Coordinator) {
        coordinator.scene?.cancelReplay()
        uiView.presentScene(nil)
    }

    private func replay(in scene: NativeAnalyticPolylineReplayScene, coordinator: Coordinator) {
        coordinator.runID = run.id
        let regions = (partition?.regions ?? []).map { region in
            let hue = goldenAngleHue(region.seat.seatID - 1) / 360
            return NativeReplayRegion(
                id: "seat-\(region.seat.seatID)",
                polygon: pinballRegionPolygon(region, partition: partition!),
                fillColor: UIColor(hue: hue, saturation: 0.84, brightness: 1, alpha: 0.08),
                strokeColor: UIColor(hue: hue, saturation: 0.84, brightness: 1, alpha: 0.28)
            )
        }
        let plan = NativeAnalyticReplayPlan(
            polyline: run.result.trajectory.points,
            duration: showCompletedPath ? 0 : run.curve.duration,
            regions: regions,
            style: NativeReplayVisualStyle(
                backgroundColor: .clear,
                guideColor: UIColor.white.withAlphaComponent(0.06),
                trailColor: .systemCyan,
                cursorColor: .white,
                trailWidth: 3.5,
                trailGlowWidth: 13,
                cursorRadius: 7,
                showsGuide: false
            )
        )
        scene.replay(
            plan,
            pointMapper: { point, size in CGPoint(x: point.x, y: size.height - point.y) },
            progressMapper: { normalizedTime in
                run.curve.progress(at: normalizedTime * run.curve.duration)
            }
        )
    }

    final class Coordinator {
        var scene: NativeAnalyticPolylineReplayScene?
        var runID: UUID?
    }
}

private func pinballRegionPolygon(
    _ region: PinballRadialRegion,
    partition: PinballRadialPartition
) -> [CGPoint] {
    var end = region.endPhase
    if end <= region.startPhase { end += 1 }
    let corners: [(CGFloat, CGPoint)] = [
        (0.125, CGPoint(x: partition.bounds.maxX, y: partition.bounds.maxY)),
        (0.375, CGPoint(x: partition.bounds.minX, y: partition.bounds.maxY)),
        (0.625, CGPoint(x: partition.bounds.minX, y: partition.bounds.minY)),
        (0.875, CGPoint(x: partition.bounds.maxX, y: partition.bounds.minY)),
        (1.125, CGPoint(x: partition.bounds.maxX, y: partition.bounds.maxY)),
        (1.375, CGPoint(x: partition.bounds.minX, y: partition.bounds.maxY)),
        (1.625, CGPoint(x: partition.bounds.minX, y: partition.bounds.minY)),
        (1.875, CGPoint(x: partition.bounds.maxX, y: partition.bounds.minY))
    ]
    let includedCorners = corners
        .filter { $0.0 > region.startPhase + 1e-8 && $0.0 < end - 1e-8 }
        .map(\.1)
    return [partition.center, region.startBoundaryPoint] + includedCorners + [region.endBoundaryPoint]
}

private func goldenAngleHue(_ index: Int) -> Double {
    (Double(index) * 137.508).truncatingRemainder(dividingBy: 360)
}
