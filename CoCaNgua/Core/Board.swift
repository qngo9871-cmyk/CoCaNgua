import Foundation
import SwiftUI

/// The 4 colors, in fixed seating order. Seat order determines each color's
/// entry point on the shared track (13 cells apart) — see `entryGlobalIndex`.
enum PlayerColor: String, CaseIterable, Identifiable, Codable {
    case red, green, yellow, blue

    var id: String { rawValue }

    var seatIndex: Int { PlayerColor.allCases.firstIndex(of: self)! }

    /// This color's entry cell on the shared 52-cell outer track (global
    /// index 0...51). Colors sit exactly 13 cells apart, one per side of the
    /// square loop.
    var entryGlobalIndex: Int { seatIndex * 13 }

    var uiColor: Color {
        switch self {
        case .red: return Color(red: 0.85, green: 0.18, blue: 0.18)
        case .green: return Color(red: 0.16, green: 0.62, blue: 0.30)
        case .yellow: return Color(red: 0.93, green: 0.73, blue: 0.10)
        case .blue: return Color(red: 0.15, green: 0.42, blue: 0.85)
        }
    }

    var nameKey: String {
        switch self {
        case .red: return "player.color.red"
        case .green: return "player.color.green"
        case .yellow: return "player.color.yellow"
        case .blue: return "player.color.blue"
        }
    }
}

/// Static geometry/ruleset constants for the shared track and each color's
/// private home stretch. Numeric layout only — no view code here.
///
/// Ruleset (do not "correct" this against a different Ludo variant — this is
/// the deliberately chosen, internally-consistent house ruleset, see CLAUDE.md):
/// - 52-cell shared outer track, a square loop, 13 cells per side.
/// - Each color also gets a private 6-cell home stretch leading to its goal.
/// - A token's own-path position: 0 = in yard; 1...51 = on the shared track
///   (mapped to a global cell via `globalIndex(color:pathPosition:)`);
///   52...57 = in the private home stretch; 57 = the goal cell (finished).
///   57 = 51 (one full lap back to just before your own entry) + 6 (the
///   home stretch) — a token must roll the exact number of pips to land on
///   57, overshoot is illegal for that token.
/// - Safe cells: each color's entry cell (4) + 4 star cells, one placed 8
///   cells past each entry — 8 safe cells total, evenly distributed. Tokens
///   on a safe cell can never be captured; multiple colors may share one.
enum Board {
    static let trackLength = 52
    static let homeStretchLength = 6
    /// Forward steps needed to complete the shared-track lap (52 cells, but
    /// the entry cell is step 1, so 51 more steps returns you to just before
    /// your own entry) before entering the home stretch.
    static let sharedSteps = trackLength - 1 // 51
    /// The final home-stretch cell — reaching this exact path position wins
    /// that token. 51 (lap) + 6 (home stretch) = 57.
    static let goalPathPosition = sharedSteps + homeStretchLength // 57

    /// 4 entry cells + 4 star cells = 8 safe cells total.
    static let safeGlobalIndices: Set<Int> = {
        var set = Set<Int>()
        for color in PlayerColor.allCases {
            set.insert(color.entryGlobalIndex)
            set.insert((color.entryGlobalIndex + 8) % trackLength)
        }
        return set
    }()

    static func isSafe(globalIndex: Int) -> Bool { safeGlobalIndices.contains(globalIndex) }

    /// Maps a token's own-path position (1...51) to a global cell index
    /// (0...51) on the shared track. Returns nil once the token has turned
    /// into its private home stretch (position > sharedSteps).
    static func globalIndex(color: PlayerColor, pathPosition: Int) -> Int? {
        guard (1...sharedSteps).contains(pathPosition) else { return nil }
        return (color.entryGlobalIndex + pathPosition - 1) % trackLength
    }

    // MARK: - Rendering geometry (pure layout data, used only by BoardView)

    /// 52 evenly-spaced points around the perimeter of a `size`x`size` square,
    /// 13 per side, walked clockwise starting at the top-left corner. This is
    /// purely a rendering convenience — game logic never touches CGPoint.
    static func trackPoint(for globalIndex: Int, size: CGFloat) -> CGPoint {
        let sideIndex = globalIndex / 13
        let posInSide = CGFloat(globalIndex % 13)
        let t = posInSide / 13.0
        switch sideIndex {
        case 0: return CGPoint(x: t * size, y: 0)
        case 1: return CGPoint(x: size, y: t * size)
        case 2: return CGPoint(x: size - t * size, y: size)
        default: return CGPoint(x: 0, y: size - t * size)
        }
    }

    /// 6 rendering points for a color's private home stretch, running from
    /// just inside its entry corner straight to the board center.
    static func homeStretchPoints(for color: PlayerColor, size: CGFloat) -> [CGPoint] {
        let center = CGPoint(x: size / 2, y: size / 2)
        let entry = trackPoint(for: color.entryGlobalIndex, size: size)
        let incomingIndex = (color.entryGlobalIndex + sharedSteps) % trackLength
        let incoming = trackPoint(for: incomingIndex, size: size)
        let outerAnchor = CGPoint(x: (incoming.x + entry.x) / 2, y: (incoming.y + entry.y) / 2)
        // Keep the whole lane in the inner 32%...96% band of the way from the
        // corner to center — the corner-adjacent stretch would otherwise sit
        // visually on top of that color's yard box (see yardAnchor/yardBox).
        let tStart: CGFloat = 0.55
        let tEnd: CGFloat = 0.97
        return (0..<homeStretchLength).map { i in
            let frac = CGFloat(i) / CGFloat(homeStretchLength - 1)
            let t = tStart + (tEnd - tStart) * frac
            return CGPoint(x: outerAnchor.x + (center.x - outerAnchor.x) * t,
                            y: outerAnchor.y + (center.y - outerAnchor.y) * t)
        }
    }

    /// A rendering point for the private home stretch OR the shared track,
    /// given a token's own-path position (1...57). Returns nil for yard (0).
    static func point(color: PlayerColor, pathPosition: Int, size: CGFloat) -> CGPoint? {
        if pathPosition == 0 { return nil }
        if pathPosition <= sharedSteps {
            guard let g = globalIndex(color: color, pathPosition: pathPosition) else { return nil }
            return trackPoint(for: g, size: size)
        }
        let stretchIndex = pathPosition - sharedSteps - 1 // 0...5
        let pts = homeStretchPoints(for: color, size: size)
        guard pts.indices.contains(stretchIndex) else { return nil }
        return pts[stretchIndex]
    }

    /// Corner anchor point for a color's yard box (outside the ring, in the
    /// quadrant beyond its entry corner).
    static func yardAnchor(for color: PlayerColor, size: CGFloat) -> CGPoint {
        switch color.seatIndex {
        case 0: return CGPoint(x: size * 0.13, y: size * 0.13) // top-left
        case 1: return CGPoint(x: size * 0.87, y: size * 0.13) // top-right
        case 2: return CGPoint(x: size * 0.87, y: size * 0.87) // bottom-right
        default: return CGPoint(x: size * 0.13, y: size * 0.87) // bottom-left
        }
    }
}
