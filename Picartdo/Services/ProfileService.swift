import Foundation

enum ProfileService {
    private static let client = SupabaseClient.shared

    nonisolated struct ProfileUpdate: Encodable, Sendable {
        let fullName: String?
        let tagline: String?
        let bio: String?
    }

    static func updateProfile(fullName: String, tagline: String, bio: String) async throws {
        guard let userID = try await client.fetchCurrentUser()?.id else {
            throw SupabaseError.unauthorized
        }
        try await client.patch(
            table: "users",
            query: [URLQueryItem(name: "id", value: "eq.\(userID.uuidString)")],
            body: ProfileUpdate(fullName: fullName, tagline: tagline, bio: bio)
        )
    }

    static func fetchListings(for artistID: UUID) async throws -> [Artwork] {
        let rows = try await ListingService.fetchArtistListings(artistID: artistID)
        return rows.map { $0.toArtwork() }
    }
}
