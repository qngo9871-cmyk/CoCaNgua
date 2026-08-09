import UIKit

/// Small, tasteful haptic touches for key game moments — dice rolls, captures,
/// reaching the goal, and winning. Added in the 2026-08-09 pre-resubmission
/// polish pass; none of this touches game logic, purely tactile feedback.
/// Generators are cached (not recreated per call) per Apple's guidance for
/// lowest latency.
enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let notification = UINotificationFeedbackGenerator()

    /// Die roll landed — a light tap, regardless of the value.
    static func diceRolled() {
        light.prepare()
        light.impactOccurred()
    }

    /// A capture just happened (either side) — a sharper, more eventful tap
    /// than a plain move, without going all the way to a system "error" buzz.
    static func capture() {
        rigid.prepare()
        rigid.impactOccurred()
    }

    /// One horse reached its goal cell.
    static func reachedGoal() {
        notification.prepare()
        notification.notificationOccurred(.success)
    }

    /// The match just ended.
    static func matchWon() {
        notification.prepare()
        notification.notificationOccurred(.success)
    }
}
