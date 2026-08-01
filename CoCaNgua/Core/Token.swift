import Foundation

/// One ngựa (horse). `pathPosition` is relative to its own color's path:
/// 0 = in the home yard; 1...51 = on the shared track; 52...57 = in the
/// private home stretch, with 57 being the goal (finished).
struct Token: Identifiable, Equatable {
    let id: Int // 0...3 within its color
    let color: PlayerColor
    var pathPosition: Int = 0

    var isInYard: Bool { pathPosition == 0 }
    var isFinished: Bool { pathPosition == Board.goalPathPosition }
    var isOnSharedTrack: Bool { (1...Board.sharedSteps).contains(pathPosition) }
    var isInHomeStretch: Bool { pathPosition > Board.sharedSteps && pathPosition < Board.goalPathPosition }

    /// The global shared-track cell this token occupies, or nil if it's in
    /// the yard, in its private home stretch, or already finished.
    var globalIndex: Int? { Board.globalIndex(color: color, pathPosition: pathPosition) }
}
