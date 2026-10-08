import Foundation
import Observation

/// Listings, videos, and highlights for the signed-in artist's shop.
@Observable
@MainActor
final class MarketplaceStore {
    var listings: [Artwork] = Artwork.samples.filter { $0.artistName == Artist.oscar.name }
    var videos: [ProfileVideoItem] = ProfileVideoItem.samples
    var highlights: [ProfileHighlight] = ProfileHighlight.samples

    var forSale: [Artwork] { listings.filter { !$0.isSold && !$0.imageName.isEmpty } }
    var sold: [Artwork] { listings.filter(\.isSold) }
    var collection: [Artwork] { sold.isEmpty ? Array(listings.prefix(9)) : sold }

    func load(for artistID: UUID?) async {
        guard let artistID else {
            seedSoldFlags()
            return
        }
        if let fetched = try? await ProfileService.fetchListings(for: artistID), !fetched.isEmpty {
            listings = fetched
        } else {
            seedSoldFlags()
        }
    }

    private func seedSoldFlags() {
        listings = Artwork.samples
            .filter { $0.artistName == Artist.oscar.name }
            .enumerated()
            .map { index, art in
                var copy = art
                if index == 3 || index == 7 || index == 11 { copy.isSold = true }
                return copy
            }
    }
}

struct ProfileVideoItem: Identifiable, Hashable {
    let id: UUID
    let imageName: String
    let title: String
    let views: Int

    var viewsLabel: String {
        if views >= 1000 { return String(format: "%.1fk", Double(views) / 1000) }
        return "\(views)"
    }

    static let samples: [ProfileVideoItem] = [
        .init(id: UUID(), imageName: "art_05", title: "Orange border process", views: 12_400),
        .init(id: UUID(), imageName: "art_01", title: "Green crosses studio", views: 8_900),
        .init(id: UUID(), imageName: "art_02", title: "Ink labyrinth studio", views: 6_210),
        .init(id: UUID(), imageName: "art_08", title: "Blue moon close-up", views: 4_180),
        .init(id: UUID(), imageName: "art_03", title: "Violet frame", views: 3_040),
        .init(id: UUID(), imageName: "art_07", title: "Eyes & waves", views: 2_760),
    ]
}

struct ProfileHighlight: Identifiable, Hashable {
    let id: String
    let title: String
    let imageName: String

    static let samples: [ProfileHighlight] = [
        .init(id: "studio", title: "Studio", imageName: "art_01"),
        .init(id: "wynwood", title: "Wynwood", imageName: "art_05"),
        .init(id: "ink", title: "Ink", imageName: "art_02"),
        .init(id: "solo", title: "Solo '25", imageName: "art_08"),
        .init(id: "collectors", title: "Collectors", imageName: "art_03"),
        .init(id: "miami", title: "Toronto", imageName: "art_04"),
    ]
}
