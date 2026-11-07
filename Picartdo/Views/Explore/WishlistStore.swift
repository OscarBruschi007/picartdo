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

    /// Saves or unsaves a piece. Every change says what happened, and removing
    /// one can be undone for a few seconds.
    func toggle(_ artwork: Artwork, announce: Bool = true) {
        let wasLiked = likedIDs.contains(artwork.id)
        if wasLiked {
            likedIDs.remove(artwork.id)
        } else {
            likedIDs.insert(artwork.id)
        }
        save()
        Task { await syncToggle(artwork: artwork, save: !wasLiked) }

        guard announce else { return }
        if wasLiked {
            Haptics.tap()
            PicartdoToast.show(
                "Removed \u{201C}\(artwork.title)\u{201D} from your saved pieces",
                icon: "heart.slash",
                action: .undo { [weak self] in
                    guard let self, !self.isLiked(artwork) else { return }
                    self.toggle(artwork, announce: false)
                }
            )
        } else {
            Haptics.soft()
            PicartdoToast.show("Saved \u{201C}\(artwork.title)\u{201D}", icon: "heart.fill")
        }
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
            // Roll back, and say so: a silent revert looks like a broken button.
            if save {
                likedIDs.remove(artwork.id)
            } else {
                likedIDs.insert(artwork.id)
            }
            self.save()
            PicartdoToast.show(
                save ? "Couldn't save that piece. Check your connection." : "Couldn't remove that piece. Check your connection.",
                icon: "wifi.exclamationmark",
                tone: .error,
                action: PicartdoToast.Action(title: "Retry") { [weak self] in self?.toggle(artwork) }
            )
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
