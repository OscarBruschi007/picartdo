import Foundation
import Observation

/// Which side of the canvas someone stands on.
enum PicartdoRole: String, CaseIterable, Identifiable {
    case collector, artist, both
    var id: String { rawValue }

    var makesArt: Bool { self != .collector }
    var collectsArt: Bool { self != .artist }
}

/// What an artist wants Picartdo to do for them.
enum ArtistGoal: String, CaseIterable, Identifiable {
    case sellOriginals, sellPrints, commissions, services, audience
    var id: String { rawValue }

    var title: String {
        switch self {
        case .sellOriginals: "Sell my originals"
        case .sellPrints:    "Sell prints & editions"
        case .commissions:   "Take commissions"
        case .services:      "Offer my services"
        case .audience:      "Grow my audience"
        }
    }

    var detail: String {
        switch self {
        case .sellOriginals: "One of one. Straight from the easel to a wall."
        case .sellPrints:    "Let more people live with your work."
        case .commissions:   "Collectors ask, you create."
        case .services:      "Tattoos, murals, classes, restoration."
        case .audience:      "Be seen by people who actually look."
        }
    }

    var icon: String {
        switch self {
        case .sellOriginals: "paintpalette"
        case .sellPrints:    "square.on.square"
        case .commissions:   "envelope.open"
        case .services:      "wand.and.stars"
        case .audience:      "eye"
        }
    }
}

/// How much a collector is ready to spend on a first piece.
enum CollectorBudget: String, CaseIterable, Identifiable {
    case under500, upTo2000, statement, browsing
    var id: String { rawValue }

    var price: String {
        switch self {
        case .under500:  "Under $500"
        case .upTo2000:  "$500 – $2,000"
        case .statement: "$2,000+"
        case .browsing:  "Just looking"
        }
    }

    var detail: String {
        switch self {
        case .under500:  "Small walls, big beginnings."
        case .upTo2000:  "The serious first piece."
        case .statement: "Statement work. The room bends around it."
        case .browsing:  "Let me wander the halls first."
        }
    }
}

/// Who a new user is and what they love, learned in the opening minute,
/// no account needed. Feeds straight back into what Home shows first.
@Observable
@MainActor
final class TastePreferenceStore {

    private(set) var hasCompletedTastePass: Bool = false
    private(set) var categoryScores: [ArtCategory: Int] = [:]

    private(set) var role: PicartdoRole?
    private(set) var favoriteMediums: Set<ArtCategory> = []
    private(set) var artistGoals: Set<ArtistGoal> = []
    private(set) var budget: CollectorBudget?
    private(set) var artistName: String = ""

    private let completedKey = "picartdo.taste.completed"
    private let scoresKey = "picartdo.taste.scores"
    private let roleKey = "picartdo.onboarding.role"
    private let mediumsKey = "picartdo.onboarding.mediums"
    private let goalsKey = "picartdo.onboarding.goals"
    private let budgetKey = "picartdo.onboarding.budget"
    private let artistNameKey = "picartdo.onboarding.artistName"

    init() {
        load()
        #if DEBUG
        // Launch with --reset-onboarding to see the first-open flow again.
        if ProcessInfo.processInfo.arguments.contains("--reset-onboarding") {
            reset()
        }
        #endif
    }

    func recordSwipe(category: ArtCategory, liked: Bool) {
        categoryScores[category, default: 0] += liked ? 2 : -1
        save()
    }

    func completeTastePass() {
        hasCompletedTastePass = true
        save()
    }

    /// Finishes the opening: remembers who they are and tunes Home to the mediums they picked.
    func completeOnboarding(
        role: PicartdoRole,
        mediums: Set<ArtCategory>,
        goals: Set<ArtistGoal>,
        budget: CollectorBudget?,
        artistName: String
    ) {
        self.role = role
        favoriteMediums = mediums
        artistGoals = role.makesArt ? goals : []
        self.budget = role.collectsArt ? budget : nil
        self.artistName = role.makesArt ? artistName.trimmingCharacters(in: .whitespacesAndNewlines) : ""
        for medium in mediums {
            categoryScores[medium, default: 0] += 3
        }
        hasCompletedTastePass = true
        save()
    }

    /// For anyone who wants to redo it — from a settings screen later, say.
    func reset() {
        hasCompletedTastePass = false
        categoryScores = [:]
        role = nil
        favoriteMediums = []
        artistGoals = []
        budget = nil
        artistName = ""
        save()
    }

    private func load() {
        let defaults = UserDefaults.standard
        hasCompletedTastePass = defaults.bool(forKey: completedKey)
        if let raw = defaults.dictionary(forKey: scoresKey) as? [String: Int] {
            var scores: [ArtCategory: Int] = [:]
            for (key, value) in raw {
                if let category = ArtCategory(rawValue: key) { scores[category] = value }
            }
            categoryScores = scores
        }
        role = defaults.string(forKey: roleKey).flatMap(PicartdoRole.init(rawValue:))
        favoriteMediums = Set((defaults.stringArray(forKey: mediumsKey) ?? []).compactMap(ArtCategory.init(rawValue:)))
        artistGoals = Set((defaults.stringArray(forKey: goalsKey) ?? []).compactMap(ArtistGoal.init(rawValue:)))
        budget = defaults.string(forKey: budgetKey).flatMap(CollectorBudget.init(rawValue:))
        artistName = defaults.string(forKey: artistNameKey) ?? ""
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(hasCompletedTastePass, forKey: completedKey)
        let raw = Dictionary(uniqueKeysWithValues: categoryScores.map { ($0.key.rawValue, $0.value) })
        defaults.set(raw, forKey: scoresKey)
        defaults.set(role?.rawValue, forKey: roleKey)
        defaults.set(favoriteMediums.map(\.rawValue), forKey: mediumsKey)
        defaults.set(artistGoals.map(\.rawValue), forKey: goalsKey)
        defaults.set(budget?.rawValue, forKey: budgetKey)
        defaults.set(artistName, forKey: artistNameKey)
    }
}
