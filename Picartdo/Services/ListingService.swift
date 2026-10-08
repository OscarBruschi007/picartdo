import Foundation
import UIKit

enum ListingService {
    private static let client = SupabaseClient.shared

    nonisolated struct CreateListingPayload: Encodable, Sendable {
        let artistId: UUID
        let title: String
        let description: String
        let listingType: String
        let price: Double
        let category: String
        let medium: String
        let dimensions: String
        let images: [String]
        let status: String
    }

    static func createListing(
        title: String,
        description: String,
        price: Double,
        category: ArtCategory,
        medium: String,
        dimensions: String,
        images: [UIImage],
        artistID: UUID
    ) async throws -> ListingRow {
        var imageURLs: [String] = []
        for (index, image) in images.enumerated() {
            guard let data = image.jpegData(compressionQuality: 0.85) else { continue }
            let path = "\(artistID.uuidString)/\(UUID().uuidString)_\(index).jpg"
            let url = try await client.uploadFile(
                bucket: "listing-images",
                path: path,
                data: data,
                contentType: "image/jpeg"
            )
            imageURLs.append(url)
        }

        let payload = CreateListingPayload(
            artistId: artistID,
            title: title,
            description: description,
            listingType: "product",
            price: price,
            category: category.rawValue,
            medium: medium,
            dimensions: dimensions,
            images: imageURLs,
            status: "active"
        )

        let row = try await client.insert(table: "listings", row: payload, returning: ListingRow.self)

        // Index the new listing for Picasso's meaning-based search. Best effort: the
        // backfill run of embed-listings picks up anything that fails here.
        let listingID = row.id.uuidString
        Task {
            _ = try? await SupabaseClient.shared.invokeFunction("embed-listings", body: ["listing_id": listingID])
        }
        return row
    }

    static func fetchArtistListings(artistID: UUID) async throws -> [ListingRow] {
        try await client.select(
            table: "listings",
            query: [
                URLQueryItem(name: "artist_id", value: "eq.\(artistID.uuidString)"),
                URLQueryItem(name: "order", value: "created_at.desc"),
            ],
            type: [ListingRow].self
        )
    }
}
