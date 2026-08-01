import Foundation

enum AIDifficulty: String, CaseIterable, Identifiable {
    case easy, normal, hard

    var id: String { rawValue }
    var requiresPro: Bool { self == .hard }
    var titleKey: String {
        switch self {
        case .easy: return "difficulty.easy"
        case .normal: return "difficulty.normal"
        case .hard: return "difficulty.hard"
        }
    }
}

/// Chooses a move among `GameModel.legalMoves(for:roll:)`'s output for the
/// current AI player. Scoring terms, per spec:
/// - heavy weight for capturing an opponent token
/// - weight for how far a move advances a token (closer-to-goal favored)
/// - weight for getting a token out of the yard
/// - (Hard only) penalty if the resulting cell is within exact capture range
///   (1...6 cells behind) of an opponent token on the shared track next roll
///
/// Easy: mostly random, light bias toward leaving the yard/capturing.
/// Normal: greedy on the positive weights only (captures + progress + yard).
/// Hard: full weighted scoring including the exposure-avoidance term.
enum AIEngine {
    static func chooseMove(_ moves: [PendingMove], players: [Player], currentPlayerIndex: Int,
                            difficulty: AIDifficulty) -> PendingMove {
        precondition(!moves.isEmpty, "chooseMove requires at least one legal move")
        switch difficulty {
        case .easy:
            return easyChoice(moves)
        case .normal:
            return bestByScore(moves, players: players, currentPlayerIndex: currentPlayerIndex,
                                includeExposurePenalty: false)
        case .hard:
            return bestByScore(moves, players: players, currentPlayerIndex: currentPlayerIndex,
                                includeExposurePenalty: true)
        }
    }

    private static func easyChoice(_ moves: [PendingMove]) -> PendingMove {
        let weighted: [(PendingMove, Double)] = moves.map { move in
            var w = 1.0
            if move.isCapture { w += 1.5 }
            if move.leavesYard { w += 1.0 }
            return (move, w)
        }
        let total = weighted.reduce(0.0) { $0 + $1.1 }
        var r = Double.random(in: 0..<total)
        for (move, w) in weighted {
            if r < w { return move }
            r -= w
        }
        return moves[moves.count - 1]
    }

    private static func bestByScore(_ moves: [PendingMove], players: [Player], currentPlayerIndex: Int,
                                     includeExposurePenalty: Bool) -> PendingMove {
        var bestMove = moves[0]
        var bestScore = -Double.infinity
        for move in moves {
            let s = score(for: move, players: players, currentPlayerIndex: currentPlayerIndex,
                          includeExposurePenalty: includeExposurePenalty)
            if s > bestScore {
                bestScore = s
                bestMove = move
            }
        }
        return bestMove
    }

    private static func score(for move: PendingMove, players: [Player], currentPlayerIndex: Int,
                               includeExposurePenalty: Bool) -> Double {
        var score = 0.0
        if move.isCapture { score += 100.0 * Double(move.captures.count) }
        score += Double(move.toPosition) * 2.0 // progress; further along the path scores higher
        if move.reachesGoal { score += 60.0 }
        if move.leavesYard { score += 20.0 }

        if includeExposurePenalty {
            let color = players[currentPlayerIndex].color
            if move.toPosition <= Board.sharedSteps,
               let global = Board.globalIndex(color: color, pathPosition: move.toPosition),
               !Board.isSafe(globalIndex: global),
               isExposed(atGlobal: global, players: players, movingPlayerIndex: currentPlayerIndex) {
                score -= 40.0
            }
        }
        return score
    }

    /// True if some opponent token already on the shared track sits 1...6
    /// cells behind `global` — i.e. a single die roll next turn could land
    /// exactly there and capture us.
    private static func isExposed(atGlobal global: Int, players: [Player], movingPlayerIndex: Int) -> Bool {
        for (pi, p) in players.enumerated() where pi != movingPlayerIndex {
            for t in p.tokens where t.isOnSharedTrack {
                guard let tGlobal = t.globalIndex else { continue }
                let diff = ((global - tGlobal) % Board.trackLength + Board.trackLength) % Board.trackLength
                if (1...6).contains(diff) { return true }
            }
        }
        return false
    }
}
