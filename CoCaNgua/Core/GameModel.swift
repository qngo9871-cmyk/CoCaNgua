import Foundation

enum GameOutcome: Equatable {
    case ongoing
    case win(PlayerColor)
}

enum TurnPhase: Equatable {
    case awaitingRoll
    case awaitingMove
}

struct CapturedToken: Equatable {
    let playerIndex: Int
    let tokenID: Int
}

/// One legal move for the current roll: move `tokenID` from `fromPosition`
/// to `toPosition` (both own-path positions, see `Token.pathPosition`).
struct PendingMove: Identifiable, Equatable {
    let tokenID: Int
    let fromPosition: Int
    let toPosition: Int
    let leavesYard: Bool
    let captures: [CapturedToken]
    var id: Int { tokenID }
    var isCapture: Bool { !captures.isEmpty }
    var reachesGoal: Bool { toPosition == Board.goalPathPosition }
}

/// What just happened, for the UI to describe live via L() — never stores
/// pre-localized strings, so a mid-game language switch never goes stale.
enum GameEvent: Equatable {
    case rolledSix(player: Int)
    case threeSixesForfeit(player: Int)
    case noLegalMove(player: Int)
    case captured(by: Int, victims: [Int])
    case reachedGoal(player: Int)
}

/// Drives one match of Cờ Cá Ngựa: turn order, dice, legal-move enumeration,
/// captures, and win detection. iOS 16 target, so ObservableObject/@Published
/// rather than the Observation macro (matches the house pattern).
final class GameModel: ObservableObject {
    @Published private(set) var players: [Player] = []
    @Published private(set) var currentPlayerIndex: Int = 0
    @Published private(set) var phase: TurnPhase = .awaitingRoll
    @Published private(set) var diceValue: Int = 1
    @Published private(set) var pendingMoves: [PendingMove] = []
    @Published private(set) var outcome: GameOutcome = .ongoing
    @Published private(set) var lastEvent: GameEvent?

    private(set) var humanCount: Int = 1
    private(set) var aiDifficulty: AIDifficulty = .normal
    private var consecutiveSixes: Int = 0

    var currentPlayer: Player { players[currentPlayerIndex] }
    var isHumanTurn: Bool { currentPlayer.isHuman }

    /// True only when there is exactly one human and it's their turn — the
    /// only situation where "You" is a grammatically safe substitution.
    var isSoloHumanTurn: Bool { humanCount == 1 && currentPlayer.isHuman }

    func startMatch(humanCount: Int, aiDifficulty: AIDifficulty) {
        self.humanCount = max(1, min(4, humanCount))
        self.aiDifficulty = aiDifficulty
        players = PlayerColor.allCases.enumerated().map { index, color in
            let isHuman = index < self.humanCount
            let name: String
            if isHuman {
                name = self.humanCount == 1 ? L("player.you") : String(format: L("player.local"), index + 1)
            } else {
                name = L(color.nameKey)
            }
            return Player.fresh(color: color, isHuman: isHuman, name: name)
        }
        currentPlayerIndex = 0
        phase = .awaitingRoll
        diceValue = 1
        pendingMoves = []
        outcome = .ongoing
        lastEvent = nil
        consecutiveSixes = 0
    }

    // MARK: - Rolling

    func rollDie() {
        guard phase == .awaitingRoll, outcome == .ongoing else { return }
        let value = Int.random(in: 1...6)
        diceValue = value

        if value == 6 {
            consecutiveSixes += 1
            if consecutiveSixes == 3 {
                lastEvent = .threeSixesForfeit(player: currentPlayerIndex)
                advanceToNextPlayer()
                return
            }
        }

        let moves = legalMoves(for: currentPlayerIndex, roll: value)
        if moves.isEmpty {
            lastEvent = .noLegalMove(player: currentPlayerIndex)
            if value == 6 {
                // Still earn the extra roll even though nothing could move.
                phase = .awaitingRoll
            } else {
                consecutiveSixes = 0
                advanceToNextPlayer()
            }
            return
        }

        if value == 6 {
            lastEvent = .rolledSix(player: currentPlayerIndex)
        }
        pendingMoves = moves
        phase = .awaitingMove
    }

    /// Every legal move for `playerIndex` given `roll`: a token in the yard
    /// may only leave on exactly 6; a token on the board moves forward by
    /// `roll` unless that would overshoot its goal cell, in which case that
    /// token simply has no legal move this turn.
    func legalMoves(for playerIndex: Int, roll: Int) -> [PendingMove] {
        let player = players[playerIndex]
        var moves: [PendingMove] = []
        for token in player.tokens {
            if token.isInYard {
                guard roll == 6 else { continue }
                let to = 1
                let captures = capturesAt(color: player.color, pathPosition: to, movingPlayerIndex: playerIndex)
                moves.append(PendingMove(tokenID: token.id, fromPosition: 0, toPosition: to,
                                          leavesYard: true, captures: captures))
            } else if !token.isFinished {
                let to = token.pathPosition + roll
                guard to <= Board.goalPathPosition else { continue }
                let captures = capturesAt(color: player.color, pathPosition: to, movingPlayerIndex: playerIndex)
                moves.append(PendingMove(tokenID: token.id, fromPosition: token.pathPosition, toPosition: to,
                                          leavesYard: false, captures: captures))
            }
        }
        return moves
    }

    /// Opponent tokens that would be captured by landing `color` on `pathPosition`.
    /// Only the shared track can ever hold a capture — the private home
    /// stretch and yard are never shared with other colors. Safe cells never
    /// trigger a capture; a player's own tokens are never captured by this.
    private func capturesAt(color: PlayerColor, pathPosition: Int, movingPlayerIndex: Int) -> [CapturedToken] {
        guard pathPosition <= Board.sharedSteps,
              let global = Board.globalIndex(color: color, pathPosition: pathPosition),
              !Board.isSafe(globalIndex: global) else { return [] }

        var captured: [CapturedToken] = []
        for (pi, p) in players.enumerated() where pi != movingPlayerIndex {
            for t in p.tokens where !t.isInYard && !t.isFinished {
                if t.globalIndex == global {
                    captured.append(CapturedToken(playerIndex: pi, tokenID: t.id))
                }
            }
        }
        return captured
    }

    // MARK: - Moving

    func applyMove(_ move: PendingMove) {
        guard phase == .awaitingMove, pendingMoves.contains(move) else { return }

        var mover = players[currentPlayerIndex]
        guard let idx = mover.tokens.firstIndex(where: { $0.id == move.tokenID }) else { return }
        mover.tokens[idx].pathPosition = move.toPosition
        players[currentPlayerIndex] = mover

        for cap in move.captures {
            if let ci = players[cap.playerIndex].tokens.firstIndex(where: { $0.id == cap.tokenID }) {
                players[cap.playerIndex].tokens[ci].pathPosition = 0
            }
        }

        pendingMoves = []

        if move.isCapture {
            lastEvent = .captured(by: currentPlayerIndex, victims: move.captures.map { $0.playerIndex })
        } else if move.reachesGoal {
            lastEvent = .reachedGoal(player: currentPlayerIndex)
        }

        if players[currentPlayerIndex].allFinished {
            outcome = .win(players[currentPlayerIndex].color)
            phase = .awaitingRoll
            return
        }

        if diceValue == 6 {
            phase = .awaitingRoll // same player rolls again
        } else {
            consecutiveSixes = 0
            advanceToNextPlayer()
        }
    }

    private func advanceToNextPlayer() {
        consecutiveSixes = 0
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        phase = .awaitingRoll
        pendingMoves = []
    }

    #if DEBUG
    /// Deterministic states for App Store screenshot capture, keyed by CN_CAPTURE.
    func captureSetup(_ scenario: String) {
        startMatch(humanCount: 1, aiDifficulty: .normal)
        switch scenario {
        case "midgame":
            players[0].tokens[0].pathPosition = 18
            players[0].tokens[1].pathPosition = 0
            players[0].tokens[2].pathPosition = 45
            players[0].tokens[3].pathPosition = 0
            players[1].tokens[0].pathPosition = 31
            players[1].tokens[1].pathPosition = 5
            players[2].tokens[0].pathPosition = 55
            players[3].tokens[0].pathPosition = 9
            diceValue = 4
            phase = .awaitingRoll
        case "nearwin":
            players[0].tokens[0].pathPosition = 57
            players[0].tokens[1].pathPosition = 57
            players[0].tokens[2].pathPosition = 57
            players[0].tokens[3].pathPosition = 54
            diceValue = 3
            pendingMoves = legalMoves(for: 0, roll: 3)
            phase = .awaitingMove
        default:
            break
        }
    }
    #endif
}
