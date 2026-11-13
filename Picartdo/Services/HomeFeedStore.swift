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

        moreListings = pinMurals(rest)
        studioVideos = ArtistPost.studioVideos.shuffled()
        storyArtists = Self.storyCast
        articles = Array(HomeArticle.samples.shuffled().prefix(4))
        cityEvents = Self.homeEventPicks()
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
        moreListings = pinMurals(rankedByTaste(moreListings, taste: taste))
    }

    /// The mural photos stay at the front of Home, ahead of the rest of the mix.
    private func pinMurals(_ artworks: [Artwork]) -> [Artwork] {
        let murals = artworks.filter { $0.imageName.hasPrefix("mural_") }
        let others = artworks.filter { !$0.imageName.hasPrefix("mural_") }
        return murals + others
    }

    /// The artist of the month: the same all month, rotating through the featured
    /// artists who have enough work listed to fill the grid.
    private func pickArtistOfTheWeek() -> ArtistOfTheWeekFeature {
        let pool = ArtistOfTheWeekFeature.roster.filter { feature in
            guard let artist = feature.artist else { return false }
            return Artwork.samples.filter { $0.artistName == artist.name }.count >= 3
        }
        guard !pool.isEmpty else { return ArtistOfTheWeekFeature.current }
        let month = Calendar.current.component(.month, from: Date())
        let year = Calendar.current.component(.year, from: Date())
        return pool[(year * 12 + month) % pool.count]
    }

    /// What Home's Exhibitions & Events card shows: the next two events coming up,
    /// then one exhibition on view now (a different one each launch).
    private static func homeEventPicks() -> [ArtEventItem] {
        let today = Calendar.current.startOfDay(for: Date())
        let upcoming = ArtEventItem.events
            .filter { ($0.startDate ?? .distantPast) >= today }
            .sorted { ($0.startDate ?? .distantPast) < ($1.startDate ?? .distantPast) }
        let onNow = ArtEventItem.exhibitions.filter(\.isOnNow).shuffled()
        let picks = Array(upcoming.prefix(2)) + Array(onNow.prefix(1))
        // Fall back to anything if the programme has run out.
        guard picks.count < 3 else { return picks }
        var filled = picks
        for item in ArtEventItem.samples where filled.count < 3 && !filled.contains(item) {
            filled.append(item)
        }
        return filled
    }

    /// Shuffles the middle of Home for variety, with three fixed rules:
    /// Artist of the Week stays high, Exhibitions & Events is always within the first
    /// three sections, and the endless "More for you" feed is always last, so nothing
    /// ever ends up buried beneath it.
    private func shuffledLayout() -> [HomeLayoutBlock] {
        let pinned: Set<HomeLayoutBlock> = [.artistOfTheWeek, .events, .moreForYou]
        var rest = HomeLayoutBlock.allCases.filter { !pinned.contains($0) }.shuffled()
        let last = UserDefaults.standard.stringArray(forKey: lastLayoutKey) ?? []
        if rest.map(\.rawValue) == last.filter({ !pinned.map(\.rawValue).contains($0) }),
           rest.count > 1 {
            rest.append(rest.removeFirst())
        }
        // Keep Artist of the Week high — first or second after stories, never the bottom.
        rest.insert(.artistOfTheWeek, at: min(Int.random(in: 0...1), rest.count))
        // Exhibitions & Events always shows near the top: second or third.
        rest.insert(.events, at: min(Int.random(in: 1...2), rest.count))
        rest.append(.moreForYou)
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
