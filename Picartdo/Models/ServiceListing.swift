import Foundation

/// One bookable service on the Services tab, built from the existing artist roster.
/// Review counts stay at zero: artist ratings belong to profiles, not these listings.
struct ServiceListing: Identifiable, Hashable {
    let artist: Artist
    let category: ServiceCategory
    let serviceType: String
    let priceLabel: String
    let priceAmount: Int
    let deliveryText: String
    let availabilityText: String
    let isAvailableNow: Bool
    /// Service reviews. Sample listings stay at zero so cards say "New".
    let reviewCount: Int
    let rating: Double
    /// A specific photo for this card. Nil uses the category studio photo.
    let coverOverride: String?
    /// A specific card title. Nil uses the artist's tagline.
    let titleOverride: String?

    var isNearby: Bool {
        !artist.location.localizedCaseInsensitiveContains("remote")
    }

    var id: String {
        if let coverOverride {
            return "\(category.rawValue)|\(artist.name)|\(coverOverride)"
        }
        return "\(category.rawValue)|\(artist.name)"
    }

    /// Tagline with the category name taken out, so a wallpaper is not titled "Wallpaper".
    var title: String {
        if let titleOverride, titleOverride.count >= 3 { return titleOverride }
        return Self.serviceTitle(artist.tagline, category: category)
    }

    static func serviceTitle(_ tagline: String, category: ServiceCategory) -> String {
        var result = tagline
        for token in category.titleTokens {
            result = result.replacingOccurrences(of: token, with: " ", options: [.caseInsensitive, .diacriticInsensitive])
        }
        result = result.replacingOccurrences(of: "·", with: " ")
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        let trimmed = result.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.init(charactersIn: "&,/-–—")))
        return trimmed.count >= 3 ? trimmed : tagline
    }

    var coverImageName: String {
        coverOverride ?? ServiceGallery.coverPhoto(for: artist, in: category)
    }

    init(
        artist: Artist,
        category: ServiceCategory,
        priceOverride: Int? = nil,
        availableOverride: Bool? = nil,
        coverOverride: String? = nil,
        titleOverride: String? = nil
    ) {
        self.artist = artist
        self.category = category
        self.coverOverride = coverOverride
        self.titleOverride = titleOverride
        let seed = artist.name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        switch category {
        case .classes:
            serviceType = "Class"
            deliveryText = "90 min"
        case .kidsWorkshop:
            serviceType = "Workshop"
            deliveryText = "2 hours"
        default:
            serviceType = seed.isMultiple(of: 2) ? "Commission" : "In person studio"
            let turnarounds = ["5 days", "1–2 weeks", "2–4 weeks", "4–6 weeks"]
            deliveryText = turnarounds[seed % turnarounds.count]
        }
        if let priceOverride {
            priceAmount = priceOverride
            priceLabel = "From $\(priceOverride)"
        } else {
            priceLabel = Self.priceLabel(from: artist.startingPrice)
            priceAmount = Self.amount(from: artist.startingPrice)
        }
        let available = availableOverride ?? artist.availableForCommissions
        isAvailableNow = available
        reviewCount = 0
        rating = 0
        if available {
            availabilityText = "Available now"
        } else {
            let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            availabilityText = "Next open \(months[seed % months.count]) \(1 + seed % 27)"
        }
    }

    /// "From $350". Leaves a price that already starts with "From" alone.
    static func priceLabel(from startingPrice: String) -> String {
        let trimmed = startingPrice.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("from") { return trimmed }
        return "From \(trimmed)"
    }

    static func amount(from startingPrice: String) -> Int {
        let digits = startingPrice.filter(\.isNumber)
        return Int(digits) ?? 0
    }
}

enum ServiceCatalog {
    /// Artists who match an offered category. Art Exhibitions is a category
    /// tile, not a list of invented services.
    static let listings: [ServiceListing] = ServiceCategory.offered
        .filter { $0 != .liveEvent }
        .flatMap { category in
            Artist.all
                .filter { category.matches($0) }
                .map { ServiceListing(artist: $0, category: category) }
        }

    /// Category screen only. Tops each category up to at least six different
    /// artists, and makes sure two of them are under $100. Review counts stay at 0.
    /// Wall Murals uses the mural photo set, one card per picture.
    static func browseListings(in category: ServiceCategory) -> [ServiceListing] {
        if category == .mural { return muralShow }
        var result = listings.filter { $0.category == category }
        var used = Set(result.map(\.artist.name))
        if result.count < 6 {
            for artist in Artist.all where !used.contains(artist.name) {
                result.append(ServiceListing(artist: artist, category: category))
                used.insert(artist.name)
                if result.count >= 6 { break }
            }
        }
        let cheapCount = result.filter { $0.priceAmount < 100 }.count
        if cheapCount < 2 {
            let prices = [65, 90]
            var added = 0
            let needed = 2 - cheapCount
            for artist in Artist.all.reversed() where !used.contains(artist.name) {
                result.append(ServiceListing(artist: artist, category: category, priceOverride: prices[added]))
                used.insert(artist.name)
                added += 1
                if added == needed { break }
            }
            if added < needed {
                var n = added
                for index in result.indices.reversed() where result[index].priceAmount >= 100 {
                    result[index] = ServiceListing(
                        artist: result[index].artist,
                        category: category,
                        priceOverride: prices[n % prices.count]
                    )
                    n += 1
                    if n >= 2 { break }
                }
            }
        }
        return result
    }

    /// The mural photos, one bookable card each. Same pictures as Home.
    /// Two smaller jobs stay under $100. Nobody gets a made-up rating.
    private static let muralWorks: [(asset: String, title: String, artist: String, price: Int?)] = [
        ("mural_01", "Blue Line Figure", "Pedro Silva", nil),
        ("mural_02", "New Wall, From Scratch", "Naomi Williams", nil),
        ("mural_03", "Peony Portrait", "Pedro Silva", nil),
        ("mural_04", "Monstera Room", "Naomi Williams", nil),
        ("mural_05", "Coral Circle", "Pedro Silva", nil),
        ("mural_06", "Orange Field", "Pedro Silva", 90),
        ("mural_07", "White Silhouette", "Naomi Williams", 65),
        ("mural_08", "Art School Wall", "Kenji Nakamura", nil),
        ("mural_09", "Neon Room", "Zara Ahmed", nil),
        ("mural_10", "Finished Portrait Wall", "Kenji Nakamura", nil),
        ("mural_11", "Arched Passage", "Zara Ahmed", nil),
        ("mural_12", "Column and Waves", "Zara Ahmed", nil),
        ("mural_13", "Violet Room", "Zara Ahmed", nil),
        ("mural_14", "Magenta Profile", "Kenji Nakamura", nil),
        ("mural_15", "Arch Mirror", "Zara Ahmed", nil),
    ]

    private static var muralShow: [ServiceListing] {
        muralWorks.compactMap { work in
            guard let artist = Artist.named(work.artist) else { return nil }
            return ServiceListing(
                artist: artist,
                category: .mural,
                priceOverride: work.price,
                coverOverride: work.asset,
                titleOverride: work.title
            )
        }
    }
}

enum ServiceSearchHit: Identifiable, Hashable {
    case listing(ServiceListing)
    case category(ServiceCategory)

    var id: String {
        switch self {
        case .listing(let listing): return listing.id
        case .category(let category): return "category|\(category.id)"
        }
    }

    var category: ServiceCategory {
        switch self {
        case .listing(let listing): return listing.category
        case .category(let category): return category
        }
    }

    /// Listings whose title, artist, style, or category match, plus a category
    /// row when the query names a category that has no listing hit (exhibitions).
    static func matching(_ rawQuery: String) -> [ServiceSearchHit] {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return [] }

        let listings = ServiceCatalog.listings.filter { listing in
            listing.title.lowercased().contains(query)
                || listing.artist.name.lowercased().contains(query)
                || listing.category.tileTitle.lowercased().contains(query)
                || listing.category.rawValue.lowercased().contains(query)
                || listing.artist.tagline.lowercased().contains(query)
                || listing.artist.specialties.contains { $0.lowercased().contains(query) }
        }
        var hits = listings.map { ServiceSearchHit.listing($0) }
        let covered = Set(listings.map(\.category))
        for category in ServiceCategory.offered where !covered.contains(category) {
            let blob = "\(category.tileTitle) \(category.rawValue) \(category.introLine)".lowercased()
            if blob.contains(query) {
                hits.append(.category(category))
            }
        }
        return hits
    }
}
