import SwiftUI

/// Renders the 52-cell square track, the 4 private home stretches, the 4
/// yards, and every token — and handles tap-to-move on any token that has a
/// legal `PendingMove` this turn (destinations are highlighted with a ring).
struct BoardView: View {
    @ObservedObject var game: GameModel

    private let trackCellSize: CGFloat = 16
    private let tokenSize: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.05, green: 0.14, blue: 0.09))

                trackCells(size: size)
                homeStretchCells(size: size)
                centerHub(size: size)
                ForEach(PlayerColor.allCases) { color in
                    yardBox(for: color, size: size)
                }
                tokensLayer(size: size)
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    // MARK: - Track

    private func trackCells(size: CGFloat) -> some View {
        ForEach(0..<Board.trackLength, id: \.self) { i in
            let p = Board.trackPoint(for: i, size: size)
            let entryColor = PlayerColor.allCases.first { $0.entryGlobalIndex == i }
            ZStack {
                Circle()
                    .fill(entryColor?.uiColor.opacity(0.35)
                          ?? (Board.isSafe(globalIndex: i) ? Color.yellow.opacity(0.28) : Color.white.opacity(0.10)))
                if Board.isSafe(globalIndex: i) {
                    Image(systemName: "star.fill").font(.system(size: 7)).foregroundStyle(.yellow.opacity(0.9))
                }
            }
            .frame(width: trackCellSize, height: trackCellSize)
            .position(p)
        }
    }

    private func homeStretchCells(size: CGFloat) -> some View {
        ForEach(PlayerColor.allCases) { color in
            ForEach(Array(Board.homeStretchPoints(for: color, size: size).enumerated()), id: \.offset) { _, p in
                Circle()
                    .fill(color.uiColor.opacity(0.28))
                    .frame(width: trackCellSize, height: trackCellSize)
                    .position(p)
            }
        }
    }

    private func centerHub(size: CGFloat) -> some View {
        Circle()
            .fill(RadialGradient(colors: [Color.yellow.opacity(0.35), .clear],
                                  center: .center, startRadius: 2, endRadius: size * 0.12))
            .frame(width: size * 0.22, height: size * 0.22)
            .overlay(Text("🏁").font(.system(size: size * 0.08)))
            .position(x: size / 2, y: size / 2)
    }

    // MARK: - Yards

    private func yardBox(for color: PlayerColor, size: CGFloat) -> some View {
        let anchor = Board.yardAnchor(for: color, size: size)
        let boxSize = size * 0.20
        return RoundedRectangle(cornerRadius: 14)
            .fill(color.uiColor.opacity(0.16))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.uiColor.opacity(0.5), lineWidth: 2))
            .frame(width: boxSize, height: boxSize)
            .position(anchor)
    }

    private func yardSlotPoint(color: PlayerColor, slot: Int, size: CGFloat) -> CGPoint {
        let anchor = Board.yardAnchor(for: color, size: size)
        let spacing = size * 0.10
        let dx: CGFloat = slot % 2 == 0 ? -spacing / 2 : spacing / 2
        let dy: CGFloat = slot < 2 ? -spacing / 2 : spacing / 2
        return CGPoint(x: anchor.x + dx, y: anchor.y + dy)
    }

    // MARK: - Tokens

    private func tokensLayer(size: CGFloat) -> some View {
        ZStack {
            ForEach(game.players) { player in
                ForEach(player.tokens) { token in
                    tokenView(player: player, token: token, size: size)
                }
            }
        }
    }

    private func tokenView(player: Player, token: Token, size: CGFloat) -> some View {
        let point: CGPoint = token.isInYard
            ? yardSlotPoint(color: player.color, slot: token.id, size: size)
            : (Board.point(color: player.color, pathPosition: token.pathPosition, size: size) ?? .zero)

        let move = (player.id == game.currentPlayerIndex && game.phase == .awaitingMove)
            ? game.pendingMoves.first(where: { $0.tokenID == token.id })
            : nil

        return Circle()
            .fill(player.color.uiColor)
            .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 1.5))
            .overlay(
                Group {
                    if move != nil {
                        Circle().stroke(Color.white, lineWidth: 3).scaleEffect(1.4)
                    }
                }
            )
            .frame(width: tokenSize, height: tokenSize)
            .position(point)
            .opacity(token.isFinished ? 0.4 : 1.0)
            .contentShape(Circle().size(width: 30, height: 30))
            .onTapGesture {
                if let move { game.applyMove(move) }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: token.pathPosition)
    }
}

#Preview {
    let game = GameModel()
    game.startMatch(humanCount: 1, aiDifficulty: .normal)
    return BoardView(game: game).aspectRatio(1, contentMode: .fit).padding()
}
