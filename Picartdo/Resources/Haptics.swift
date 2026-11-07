import UIKit

/// One haptic grammar for the whole app:
/// - `select`: picking an option
/// - `tap` / `soft`: a press
/// - `rigid`: a firm step in a sequence (e.g. Face ID begins)
/// - `success`: something completed (purchase, ticket, publish, sent)
/// - `warning`: about to do something destructive
/// - `error`: something failed
/// Generators are kept and re-prepared, so feedback lands without latency.
enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let softGen = UIImpactFeedbackGenerator(style: .soft)
    private static let rigidGen = UIImpactFeedbackGenerator(style: .rigid)
    private static let selection = UISelectionFeedbackGenerator()
    private static let notification = UINotificationFeedbackGenerator()

    static func tap() {
        light.impactOccurred()
        light.prepare()
    }

    static func select() {
        selection.selectionChanged()
        selection.prepare()
    }

    static func soft() {
        softGen.impactOccurred()
        softGen.prepare()
    }

    static func rigid() {
        rigidGen.impactOccurred()
        rigidGen.prepare()
    }

    static func success() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    static func warning() {
        notification.notificationOccurred(.warning)
        notification.prepare()
    }

    static func error() {
        notification.notificationOccurred(.error)
        notification.prepare()
    }
}
