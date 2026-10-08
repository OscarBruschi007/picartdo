import Foundation
import Observation

@Observable
@MainActor
final class WishlistStore {

    private(set) var likedIDs: Set<UUID> = []
    private let defaultsKey = "picartdo.wishlist.likedIDs"
    private let client = SupabaseClient.shared

    init() {
        load()
    }

    func isLiked(_ artwork: Artwork) -> Bool {
        likedIDs.contains(artwork.id)
    }

    func toggle(_ artwork: Artwork) {
        let wasLiked = likedIDs.contains(artwork.id)
        if wasLiked {
            likedIDs.remove(artwork.id)
        } else {
            likedIDs.insert(artwork.id)
        }
        save()
        Task { await syncToggle(artwork: artwork, save: !wasLiked) }
    }

    func hydrateFromServer() async {
        guard AppConfig.isBackendConfigured, await client.isAuthenticated else { return }
        do {
            nonisolated struct SaveRow: Decodable, Sendable { let listingId: UUID }
            let rows: [SaveRow] = try await client.select(
                table: "saves",
                query: [URLQueryItem(name: "select", value: "listing_id")],
                type: [SaveRow].self
            )
            likedIDs = Set(rows.map(\.listingId))
            save()
        } catch {
            // keep local cache
        }
    }

    private func syncToggle(artwork: Artwork, save: Bool) async {
        guard AppConfig.isBackendConfigured, await client.isAuthenticated else { return }
        guard let userID = try? await client.fetchCurrentUser()?.id else { return }
        do {
            if save {
                nonisolated struct SaveInsert: Codable, Sendable {
                    let userId: UUID
                    let listingId: UUID
                }
                _ = try await client.insert(
                    table: "saves",
                    row: SaveInsert(userId: userID, listingId: artwork.id),
                    returning: SaveInsert.self
                )
            } else {
                try await client.delete(
                    table: "saves",
                    query: [URLQueryItem(name: "listing_id", value: "eq.\(artwork.id.uuidString)")]
                )
            }
        } catch {
            // revert on failure
            if save {
                likedIDs.remove(artwork.id)
            } else {
                likedIDs.insert(artwork.id)
            }
            self.save()
        }
    }

    private func load() {
        guard let strings = UserDefaults.standard.stringArray(forKey: defaultsKey) else { return }
        likedIDs = Set(strings.compactMap(UUID.init(uuidString:)))
    }

    private func save() {
        UserDefaults.standard.set(likedIDs.map(\.uuidString), forKey: defaultsKey)
    }
}
