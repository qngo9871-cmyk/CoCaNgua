import Foundation

struct Player: Identifiable, Equatable {
    let id: Int // seat index 0...3, matches color.seatIndex
    let color: PlayerColor
    var isHuman: Bool
    var tokens: [Token]
    /// Display name — resolved once at match setup. Never "You" unless this
    /// really is the sole human in solo mode (see GameModel.startMatch), so
    /// "%@'s turn"-style strings stay grammatically safe wherever this name
    /// is substituted.
    var name: String

    var allFinished: Bool { tokens.allSatisfy { $0.isFinished } }

    static func fresh(color: PlayerColor, isHuman: Bool, name: String) -> Player {
        Player(id: color.seatIndex, color: color, isHuman: isHuman,
               tokens: (0..<4).map { Token(id: $0, color: color) }, name: name)
    }
}
