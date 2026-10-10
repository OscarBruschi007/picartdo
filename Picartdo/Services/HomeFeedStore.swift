import Foundation
import Observation

enum HomeLayoutBlock: String, CaseIterable, Hashable, Identifiable {
    case featured
    case artistOfTheWeek
    case articles
    case events
    case moreForYou

    var id: String { rawValue }
}

/// A fresh mix of Home content for each time the app is opened, so the
/// hero, stories, trending, and leftover listings aren't frozen on the
/// same four pieces.
@Observable
@MainActor
final class HomeFeedStore {

    private(set) var featured: Artwork
    private(set) var storyArtists: [Artist]
    private(set) var moreListings: [Artwork]
    private(set) var studioVideos: [ArtistPost]
    private(set) var articles: [HomeArticle]
    private(set) var cityEvents: [ArtEventItem]
    private(set) var layout: [HomeLayoutBlock]
    private(set) var artistOfTheWeek: ArtistOfTheWeekFeature

    private var lastRefresh = Date.distantPast
    private let lastFeaturedKey = "picartdo.home.lastFeaturedImages"
    private let lastLayoutKey = "picartdo.home.lastLayout"
    private let lastArtistOfTheWeekKey = "picartdo.home.lastArtistOfTheWeek"

    init() {
        featured = Artwork.samples[0]
        storyArtists = Self.storyCast
        moreListings = []
        studioVideos = ArtistPost.studioVideos
        articles = Array(HomeArticle.samples.prefix(4))
        cityEvents = Array(ArtEventItem.samples.prefix(3))
        layout = HomeLayoutBlock.allCases
        artistOfTheWeek = ArtistOfTheWeekFeature.current
        refresh()
    }

    /// New mix when returning to the app. Skips the double-fire at launch.
    func refreshIfNeeded(taste: TastePreferenceStore? = nil) {
        guard Date().timeIntervalSince(lastRefresh) > 4 else { return }
        refresh(taste: taste)
    }

    func refresh(taste: TastePreferenceStore? = nil) {
        let pool = Artwork.samples
        guard !pool.isEmpty else { return }

        var recent = UserDefaults.standard.stringArray(forKey: lastFeaturedKey) ?? []
        let avoid = Set(recent.suffix(3))
        let fresh = pool.filter { !avoid.contains($0.imageName) }
        featured = (fresh.isEmpty ? pool : fresh).randomElement() ?? pool[0]
        recent.append(featured.imageName)
        if recent.count > 8 { recent = Array(recent.suffix(8)) }
        UserDefaults.standard.set(recent, forKey: lastFeaturedKey)

        var rest = pool.filter { $0.imageName != featured.imageName }
        rest = weightedShuffle(rest, taste: taste)

        moreListings = rest
        studioVideos = ArtistPost.studioVideos.shuffled()
        storyArtists = Self.storyCast
        articles = Array(HomeArticle.samples.shuffled().prefix(4))
        cityEvents = Array(ArtEventItem.samples.shuffled().prefix(3))
        layout = shuffledLayout()
        artistOfTheWeek = pickArtistOfTheWeek()

        lastRefresh = Date()
        applyTaste(taste)
    }

    /// Artists with real story portraits. Oscar first; the rest shuffle.
    private static var storyCast: [Artist] {
        let names = ["James Okafor", "Mira Solano", "Nix Calder", "Kofi Mensah", "Hugo Kessler", "Camila Ruiz"]
        return [Artist.oscar] + names.compactMap(Artist.named).shuffled()
    }

    func applyTaste(_ taste: TastePreferenceStore?) {
        guard let taste, !taste.categoryScores.isEmpty else { return }
        moreListings = rankedByTaste(moreListings, taste: taste)
    }

    private func pickArtistOfTheWeek() -> ArtistOfTheWeekFeature {
        let pool = ArtistOfTheWeekFeature.roster
        guard !pool.isEmpty else { return ArtistOfTheWeekFeature.current }
        let last = UserDefaults.standard.string(forKey: lastArtistOfTheWeekKey)
        let fresh = pool.filter { $0.portraitImage != last }
        let pick = (fresh.isEmpty ? pool : fresh).randomElement() ?? pool[0]
        UserDefaults.standard.set(pick.portraitImage, forKey: lastArtistOfTheWeekKey)
        return pick
    }

    private func shuffledLayout() -> [HomeLayoutBlock] {
        var rest = HomeLayoutBlock.allCases.filter { $0 != .artistOfTheWeek }.shuffled()
        let last = UserDefaults.standard.stringArray(forKey: lastLayoutKey) ?? []
        if rest.map(\.rawValue) == last.filter({ $0 != HomeLayoutBlock.artistOfTheWeek.rawValue }),
           rest.count > 1 {
            rest.append(rest.removeFirst())
        }
        // Keep Artist of the Week high — first or second after stories, never the bottom.
        let slot = Int.random(in: 0...1)
        rest.insert(.artistOfTheWeek, at: min(slot, rest.count))
        UserDefaults.standard.set(rest.map(\.rawValue), forKey: lastLayoutKey)
        return rest
    }

    private func rankedByTaste(_ artworks: [Artwork], taste: TastePreferenceStore) -> [Artwork] {
        let scores = taste.categoryScores
        return artworks.enumerated()
            .sorted { a, b in
                let scoreA = scores[a.element.category] ?? 0
                let scoreB = scores[b.element.category] ?? 0
                if scoreA != scoreB { return scoreA > scoreB }
                return a.offset < b.offset
            }
            .map(\.element)
    }

    private func weightedShuffle(_ artworks: [Artwork], taste: TastePreferenceStore?) -> [Artwork] {
        let scores = taste?.categoryScores ?? [:]
        guard !scores.isEmpty else { return artworks.shuffled() }
        return artworks.shuffled().sorted { a, b in
            let scoreA = scores[a.category] ?? 0
            let scoreB = scores[b.category] ?? 0
            if scoreA != scoreB { return scoreA > scoreB }
            return a.likeCount > b.likeCount
        }
    }
}
