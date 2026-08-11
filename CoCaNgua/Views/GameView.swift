import SwiftUI

struct GameView: View {
    @ObservedObject var game: GameModel
    @Environment(\.dismiss) private var dismiss

    @State private var isAIThinking = false
    @State private var showHowToPlay = false
    @State private var showQuitConfirm = false
    @State private var eventBanner: String?
    @State private var eventBannerWorkItem: DispatchWorkItem?

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            playerBadges

            Text(statusText)
                .font(.subheadline.bold())
                .frame(minHeight: 20)

            if let eventBanner {
                Text(eventBanner)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }

            BoardView(game: game)
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 8)

            DieView(value: game.diceValue, isRollable: canRoll) {
                Haptics.diceRolled()
                game.rollDie()
            }

            if game.phase == .awaitingMove, game.currentPlayer.isHuman {
                movePicker
            }

            Button(role: .destructive) { showQuitConfirm = true } label: {
                Text(L("game.quit"))
            }
            .buttonStyle(.bordered)
            .padding(.top, 4)

            Spacer(minLength: 0)
        }
        .padding(.vertical)
        .navigationTitle(L("home.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showHowToPlay = true } label: {
                    Image(systemName: "questionmark.circle")
                }
            }
        }
        .sheet(isPresented: $showHowToPlay) {
            OnboardingView(onFinished: { showHowToPlay = false })
        }
        .confirmationDialog(L("game.quitConfirm"), isPresented: $showQuitConfirm, titleVisibility: .visible) {
            Button(L("game.quit"), role: .destructive) { dismiss() }
            Button(L("game.cancel"), role: .cancel) {}
        }
        .onAppear { maybeTriggerAI() }
        .onChange(of: game.currentPlayerIndex) { _ in maybeTriggerAI() }
        .onChange(of: game.phase) { _ in maybeTriggerAI() }
        .onChange(of: game.lastEvent) { event in showEventBanner(event) }
        .onChange(of: game.outcome) { outcome in
            if outcome != .ongoing { Haptics.matchWon() }
        }
        .alert(outcomeTitle, isPresented: .constant(game.outcome != .ongoing)) {
            Button(L("game.newGame")) { game.startMatch(humanCount: game.humanCount, aiDifficulty: game.aiDifficulty) }
            Button(L("game.done")) { dismiss() }
        } message: {
            Text(statusText)
        }
        #if DEBUG
        .onAppear {
            if let capture = ProcessInfo.processInfo.environment["CN_CAPTURE"], capture != "home" {
                game.captureSetup(capture)
            }
        }
        #endif
    }

    // MARK: - Header

    private var playerBadges: some View {
        HStack(spacing: 14) {
            ForEach(game.players) { player in
                VStack(spacing: 3) {
                    Circle()
                        .fill(player.color.uiColor)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle().stroke(Color.primary, lineWidth: player.id == game.currentPlayerIndex ? 2 : 0)
                                .frame(width: 20, height: 20)
                        )
                    Text("\(player.tokens.filter { $0.isFinished }.count)/4")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var movePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(game.pendingMoves) { move in
                    Button {
                        game.applyMove(move)
                    } label: {
                        HStack(spacing: 4) {
                            Text("🐴\(move.tokenID + 1)")
                            if move.isCapture { Image(systemName: "bolt.fill") }
                            if move.reachesGoal { Image(systemName: "flag.checkered") }
                        }
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12).padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(move.isCapture ? .red : (game.currentPlayer.color.uiColor))
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Status text (grammar-safe: "%@" is only ever substituted with a
    // name that isn't "You" — see Player.name and GameModel.isSoloHumanTurn).

    private var statusText: String {
        switch game.outcome {
        case .win(let color):
            guard let winner = game.players.first(where: { $0.color == color }) else { return "" }
            if game.humanCount == 1 && winner.isHuman { return L("game.youWin") }
            return String(format: L("game.win"), winner.name)
        case .ongoing:
            if isAIThinking {
                return String(format: L("game.aiThinking"), game.currentPlayer.name)
            }
            switch game.phase {
            case .awaitingRoll:
                return game.isSoloHumanTurn ? L("game.yourTurn") : String(format: L("game.playerTurnRoll"), game.currentPlayer.name)
            case .awaitingMove:
                return game.isSoloHumanTurn ? L("game.yourTurnMove") : String(format: L("game.playerTurnMove"), game.currentPlayer.name)
            }
        }
    }

    private var outcomeTitle: String {
        game.outcome == .ongoing ? "" : L("game.matchOver")
    }

    private func eventText(_ event: GameEvent) -> String? {
        switch event {
        case .rolledSix:
            return L("event.rolledSix")
        case .threeSixesForfeit:
            return L("event.threeSixes")
        case .noLegalMove:
            return L("event.noMove")
        case .captured(let by, let victims):
            let capturer = game.players[by]
            let isSoloYou = game.humanCount == 1 && capturer.isHuman
            if victims.count == 1 {
                let victimName = game.players[victims[0]].name
                return isSoloYou
                    ? String(format: L("event.capturedYou"), victimName)
                    : String(format: L("event.captured"), capturer.name, victimName)
            }
            return isSoloYou
                ? String(format: L("event.capturedPluralYou"), victims.count)
                : String(format: L("event.capturedPlural"), capturer.name, victims.count)
        case .reachedGoal(let player):
            let mover = game.players[player]
            let isSoloYou = game.humanCount == 1 && mover.isHuman
            return isSoloYou ? L("event.reachedGoalYou") : String(format: L("event.reachedGoal"), mover.name)
        }
    }

    private func showEventBanner(_ event: GameEvent?) {
        guard let event, let text = eventText(event) else { return }
        switch event {
        case .captured: Haptics.capture()
        case .reachedGoal: Haptics.reachedGoal()
        default: break
        }
        eventBannerWorkItem?.cancel()
        withAnimation { eventBanner = text }
        let work = DispatchWorkItem { withAnimation { eventBanner = nil } }
        eventBannerWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: work)
    }

    // MARK: - Turn driving

    private var canRoll: Bool {
        game.outcome == .ongoing && game.phase == .awaitingRoll && game.currentPlayer.isHuman
    }

    private func maybeTriggerAI() {
        guard game.outcome == .ongoing, !game.currentPlayer.isHuman else { isAIThinking = false; return }
        isAIThinking = true
        let playerIndexAtSchedule = game.currentPlayerIndex
        let phaseAtSchedule = game.phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            guard game.outcome == .ongoing,
                  game.currentPlayerIndex == playerIndexAtSchedule,
                  game.phase == phaseAtSchedule,
                  !game.currentPlayer.isHuman else {
                isAIThinking = false
                return
            }
            switch game.phase {
            case .awaitingRoll:
                game.rollDie()
            case .awaitingMove:
                let move = AIEngine.chooseMove(game.pendingMoves, players: game.players,
                                                currentPlayerIndex: game.currentPlayerIndex,
                                                difficulty: game.aiDifficulty)
                game.applyMove(move)
            }
            isAIThinking = false
            maybeTriggerAI()
        }
    }
}

#Preview {
    let game = GameModel()
    game.startMatch(humanCount: 1, aiDifficulty: .normal)
    return NavigationStack { GameView(game: game) }
}
