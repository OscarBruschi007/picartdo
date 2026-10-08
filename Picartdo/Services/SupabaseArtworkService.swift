import Foundation

struct SupabaseArtworkService: ArtworkServiceProtocol {
    private let client = SupabaseClient.shared
    private let fallback = MockArtworkService()

    func fetchArtworks(query: ArtworkQuery, page: Int, pageSize: Int) async throws -> ArtworkPage {
        guard AppConfig.isBackendConfigured else {
            return try await fallback.fetchArtworks(query: query, page: page, pageSize: pageSize)
        }

        do {
            let response: FeedResponse = try await client.invokeFunction(
                "feed-scoring",
                body: query.asBackendPayload(page: page, pageSize: pageSize),
                type: FeedResponse.self
            )
            let items = response.items.map { $0.toArtwork() }
            if items.isEmpty && page == 0 {
                return try await fallback.fetchArtworks(query: query, page: page, pageSize: pageSize)
            }
            return ArtworkPage(items: items, hasMore: response.hasMore)
        } catch {
            return try await fallback.fetchArtworks(query: query, page: page, pageSize: pageSize)
        }
    }

    func count(matching query: ArtworkQuery) async -> Int {
        guard AppConfig.isBackendConfigured else {
            return await fallback.count(matching: query)
        }
        do {
            let response: FeedResponse = try await client.invokeFunction(
                "feed-scoring",
                body: query.asBackendPayload(page: 0, pageSize: 1),
                type: FeedResponse.self
            )
            return response.total
        } catch {
            return await fallback.count(matching: query)
        }
    }
}

nonisolated private struct FeedResponse: Decodable, Sendable {
    let items: [ListingRow]
    let total: Int
    let hasMore: Bool
}

nonisolated struct ListingRow: Decodable, Sendable {
    let id: UUID
    let title: String
    let description: String?
    let price: Double
    let category: String?
    let medium: String?
    let dimensions: String?
    let images: [String]?
    let status: String?
    let saveCount: Int?
    let likeCount: Int?
    let createdAt: Date?
    let artistId: UUID
    let users: ListingArtist?

    func toArtwork() -> Artwork {
        Artwork(
            id: id,
            title: title,
            artistName: users?.fullName ?? "Artist",
            artistID: artistId,
            description: description ?? "",
            medium: medium ?? "",
            dimensions: dimensions ?? "",
            price: price,
            imageName: "photo",
            imageURLs: images ?? [],
            category: ArtCategory(rawValue: category ?? "") ?? .painting,
            isSold: status == "sold",
            likeCount: saveCount ?? likeCount ?? 0,
            createdAt: createdAt ?? Date()
        )
    }
}

nonisolated struct ListingArtist: Decodable, Sendable {
    let fullName: String?
    let verified: Bool?
    let stripeIdentityVerified: Bool?
}

private extension ArtworkQuery {
    func asBackendPayload(page: Int, pageSize: Int) -> [String: Any] {
        var payload: [String: Any] = [
            "page": page,
            "page_size": pageSize,
            "include_sold": filters.includeSold,
        ]
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty { payload["search"] = text }
        if let browseCategory = browseCategory, let medium = browseCategory.linkedArtCategory {
            payload["category"] = medium.rawValue
        } else if let browseCategory = browseCategory, !browseCategory.searchKeywordsForBackend.isEmpty {
            payload["search"] = browseCategory.searchKeywordsForBackend.first
        }
        if filters.priceBand != .any {
            payload["price_min"] = filters.priceBand.range.lowerBound
            let upper = filters.priceBand.range.upperBound
            if upper != Double.greatestFiniteMagnitude {
                payload["price_max"] = upper
            }
        }
        switch filters.sort {
        case .newest: payload["sort"] = "newest"
        case .popular: payload["sort"] = "popular"
        case .priceLow: payload["sort"] = "price_low"
        case .priceHigh: payload["sort"] = "price_high"
        default: break
        }
        return payload
    }
}
