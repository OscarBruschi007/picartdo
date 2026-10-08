import SwiftUI

// MARK: - Explore Design Tokens

enum ExploreTokens {
    static let cardCornerRadius: CGFloat = 20
    static let sheetCornerRadius: CGFloat = 20
    static let screenPadding: CGFloat = 16
    static let categoryCardHeight: CGFloat = 168

    static let springBounce = Animation.spring(response: 0.3, dampingFraction: 0.5)
    static let snappy = Animation.snappy(duration: 0.25)
}

// MARK: - Sort Options

enum ExploreSort: String, CaseIterable, Identifiable, Hashable {
    case recommended = "Recommended"
    case newest      = "Newest first"
    case popular     = "Most loved"
    case priceLow    = "Price: low to high"
    case priceHigh   = "Price: high to low"

    var id: String { rawValue }
}

// MARK: - Price Bands

enum PriceBand: String, CaseIterable, Identifiable, Hashable {
    case any      = "Any price"
    case under500 = "Under $500"
    case midLow   = "$500 – $1,000"
    case midHigh  = "$1,000 – $2,000"
    case over2k   = "$2,000+"

    var id: String { rawValue }

    var range: ClosedRange<Double> {
        switch self {
        case .any:      return 0...Double.greatestFiniteMagnitude
        case .under500: return 0...500
        case .midLow:   return 500...1000
        case .midHigh:  return 1000...2000
        case .over2k:   return 2000...Double.greatestFiniteMagnitude
        }
    }
}

// MARK: - Filter Criteria

struct ExploreFilterCriteria: Hashable {
    var priceBand: PriceBand = .any
    var sort: ExploreSort = .recommended
    var includeSold = true

    var activeCount: Int {
        var count = 0
        if priceBand != .any { count += 1 }
        if sort != .recommended { count += 1 }
        if !includeSold { count += 1 }
        return count
    }
}

// MARK: - Explore categories
// Top lanes from Saatchi Art, Artsy, Artfinder, 1stDibs + highest art-search subjects.

enum ExploreBrowseCategory: String, CaseIterable, Identifiable, Hashable {
    case paintings   = "Paintings"
    case photography = "Photography"
    case sculpture   = "Sculpture"
    case prints      = "Prints"
    case abstract    = "Abstract"
    case landscapes  = "Landscapes"
    case portraits   = "Portraits"
    case drawings    = "Drawings"

    var id: String { rawValue }

    /// Curated grid — medium (Saatchi/Artsy/1stDibs) + subject (Artfinder/UGallery search terms).
    static let heroCategories: [ExploreBrowseCategory] = allCases

    /// Add matching assets to Xcode when ready, e.g. `ExploreAbstract`.
    var imageAssetName: String {
        "Explore" + rawValue.replacingOccurrences(of: " ", with: "")
    }

    var placeholderImageName: String {
        switch self {
        case .paintings:   return "red_dress_portrait"
        case .photography: return "art_05"
        case .sculpture:   return "tagged_david"
        case .prints:      return "art_04"
        case .abstract:    return "art_20"
        case .landscapes:  return "art_15"
        case .portraits:   return "red_dress_portrait"
        case .drawings:    return "art_09"
        }
    }

    var iconName: String {
        switch self {
        case .paintings:   return "paintbrush.pointed.fill"
        case .photography: return "camera.fill"
        case .sculpture:   return "cube.fill"
        case .prints:      return "square.stack.fill"
        case .abstract:    return "sparkles"
        case .landscapes:  return "mountain.2.fill"
        case .portraits:   return "person.crop.rectangle.fill"
        case .drawings:    return "scribble.variable"
        }
    }

    /// One fill per lane so the Explore grid is readable without photos.
    var tileColor: Color {
        switch self {
        case .paintings:   return Color(red: 0.86, green: 0.22, blue: 0.24) // cadmium
        case .photography: return Color(red: 0.16, green: 0.34, blue: 0.52) // navy
        case .sculpture:   return Color(red: 0.62, green: 0.44, blue: 0.28) // bronze
        case .prints:      return Color(red: 0.18, green: 0.42, blue: 0.40) // teal
        case .abstract:    return Color(red: 0.52, green: 0.22, blue: 0.58) // violet
        case .landscapes:  return Color(red: 0.26, green: 0.50, blue: 0.34) // moss
        case .portraits:   return Color(red: 0.78, green: 0.36, blue: 0.42) // rose
        case .drawings:    return Color(red: 0.28, green: 0.26, blue: 0.24) // charcoal
        }
    }

    var marketplaceHint: String {
        switch self {
        case .paintings:   return "Saatchi · Artfinder"
        case .photography: return "Saatchi · Artsy"
        case .sculpture:   return "1stDibs · Saatchi"
        case .prints:      return "Saatchi · Artsy"
        case .abstract:    return "Artfinder · Artsy"
        case .landscapes:  return "Artfinder · UGallery"
        case .portraits:   return "Saatchi · Artfinder"
        case .drawings:    return "Saatchi · 1stDibs"
        }
    }

    var linkedArtCategory: ArtCategory? {
        switch self {
        case .paintings:   return .painting
        case .photography: return .photography
        case .sculpture:   return .sculpture
        case .prints:      return .printmaking
        case .drawings:    return .drawing
        case .abstract, .landscapes, .portraits: return nil
        }
    }

    private var searchKeywords: [String] {
        switch self {
        case .abstract:
            return ["abstract", "expression", "geometric", "mandala", "non-representational", "chaos"]
        case .landscapes:
            return ["landscape", "cityscape", "seascape", "horizon", "plein air", "mountain", "coast"]
        case .portraits:
            return ["portrait", "figurative", "silhouette", "figure", "face", "people"]
        default:
            return []
        }
    }

    var searchKeywordsForBackend: [String] { searchKeywords }

    func filter(_ list: [Artwork]) -> [Artwork] {
        if let medium = linkedArtCategory {
            return list.filter { $0.category == medium }
        }
        return list.filter { $0.matchesExploreKeywords(searchKeywords) }
    }
}

// MARK: - Query

struct ArtworkQuery: Hashable {
    var searchText: String = ""
    var browseCategory: ExploreBrowseCategory? = nil
    var filters = ExploreFilterCriteria()
}

// MARK: - Artwork Convenience

extension Artwork {
    var exploreImageNames: [String] { [imageName] }
    var isPopular: Bool { likeCount >= 200 }

    func matchesExploreKeywords(_ keywords: [String]) -> Bool {
        let blob = "\(title) \(description) \(medium)".lowercased()
        return keywords.contains { blob.contains($0) }
    }
}
