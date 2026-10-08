import Foundation
import Observation

/// What a new user likes, learned by play instead of a form. No account,
/// no signup wall — just a fast swipe pass that feeds straight back into
/// what Home shows first. The data collection *is* the first taste of
/// the product, not a gate in front of it.
@Observable
@MainActor
final class TastePreferenceStore {

    private(set) var hasCompletedTastePass: Bool = false
    private(set) var categoryScores: [ArtCategory: Int] = [:]

    private let completedKey = "picartdo.taste.completed"
    private let scoresKey = "picartdo.taste.scores"

    init() {
        load()
    }

    func recordSwipe(category: ArtCategory, liked: Bool) {
        categoryScores[category, default: 0] += liked ? 2 : -1
        save()
    }

    func completeTastePass() {
        hasCompletedTastePass = true
        save()
    }

    /// For anyone who wants to redo it — from a settings screen later, say.
    func reset() {
        hasCompletedTastePass = false
        categoryScores = [:]
        save()
    }

    private func load() {
        hasCompletedTastePass = UserDefaults.standard.bool(forKey: completedKey)
        if let raw = UserDefaults.standard.dictionary(forKey: scoresKey) as? [String: Int] {
            var scores: [ArtCategory: Int] = [:]
            for (key, value) in raw {
                if let category = ArtCategory(rawValue: key) { scores[category] = value }
            }
            categoryScores = scores
        }
    }

    private func save() {
        UserDefaults.standard.set(hasCompletedTastePass, forKey: completedKey)
        let raw = Dictionary(uniqueKeysWithValues: categoryScores.map { ($0.key.rawValue, $0.value) })
        UserDefaults.standard.set(raw, forKey: scoresKey)
    }
}
