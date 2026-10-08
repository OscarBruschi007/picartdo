import Foundation

// MARK: - Page Result

struct ArtworkPage: Sendable {
    let items: [Artwork]
    let hasMore: Bool
}

// MARK: - Service Protocol
// Swap MockArtworkService for a real API client without touching any view.

protocol ArtworkServiceProtocol: Sendable {
    func fetchArtworks(query: ArtworkQuery, page: Int, pageSize: Int) async throws -> ArtworkPage
    func count(matching query: ArtworkQuery) async -> Int
}

// MARK: - Mock Service

struct MockArtworkService: ArtworkServiceProtocol {

    /// Simulated network latency in nanoseconds.
    var latency: UInt64 = 450_000_000

    // MARK: Catalog (2 "waves" of the sample data → ~52 items for pagination)

    static let catalog: [Artwork] = {
        var items: [Artwork] = []
        let now = Date()
        let priceMultipliers: [Double] = [1.0, 0.85]
        let suffixes = ["", " — Study"]

        for wave in 0..<2 {
            for (offset, base) in Artwork.samples.enumerated() {
                items.append(
                    Artwork(
                        title: base.title + suffixes[wave],
                        artistName: base.artistName,
                        description: base.description,
                        medium: base.medium,
                        dimensions: base.dimensions,
                        price: (base.price * priceMultipliers[wave]).rounded(),
                        imageName: base.imageName,
                        category: base.category,
                        isSold: wave == 1 && offset % 5 == 0,
                        likeCount: max(5, base.likeCount - wave * 23),
                        createdAt: now.addingTimeInterval(-Double(wave * 30 + offset) * 3600)
                    )
                )
            }
        }
        return items
    }()

    // MARK: Fetch

    func fetchArtworks(query: ArtworkQuery, page: Int, pageSize: Int) async throws -> ArtworkPage {
        try await Task.sleep(nanoseconds: latency)
        try Task.checkCancellation()

        let all = Self.apply(query, to: Self.catalog)
        let start = page * pageSize
        guard start < all.count else { return ArtworkPage(items: [], hasMore: false) }

        let end = min(start + pageSize, all.count)
        return ArtworkPage(items: Array(all[start..<end]), hasMore: end < all.count)
    }

    func count(matching query: ArtworkQuery) async -> Int {
        Self.apply(query, to: Self.catalog).count
    }

    // MARK: Filtering + Sorting (one pipeline, mirrors what a backend would do)

    static func apply(_ query: ArtworkQuery, to list: [Artwork]) -> [Artwork] {
        var result = list

        if let browseCategory = query.browseCategory {
            result = browseCategory.filter(result)
        }

        let text = query.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(text)
                    || $0.artistName.localizedCaseInsensitiveContains(text)
                    || $0.medium.localizedCaseInsensitiveContains(text)
            }
        }

        if query.filters.priceBand != .any {
            let range = query.filters.priceBand.range
            result = result.filter { range.contains($0.price) }
        }

        if !query.filters.includeSold {
            result = result.filter { !$0.isSold }
        }

        switch query.filters.sort {
        case .recommended: break
        case .newest:      result.sort { $0.createdAt > $1.createdAt }
        case .popular:     result.sort { $0.likeCount > $1.likeCount }
        case .priceLow:    result.sort { $0.price < $1.price }
        case .priceHigh:   result.sort { $0.price > $1.price }
        }

        return result
    }
}
