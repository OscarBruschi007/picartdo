import Foundation
import Observation

struct ThreadPost: Identifiable, Hashable {
    var id: UUID = UUID()
    var authorName: String
    var handle: String
    var avatarImage: String
    var text: String
    var createdAt: Date = Date()
    var artworkImageName: String? = nil
    var replyCount: Int = 0
    var repostCount: Int = 0
    var likeCount: Int = 0
    var liked: Bool = false
    var parentID: UUID? = nil

    var timeAgo: String {
        let seconds = Date().timeIntervalSince(createdAt)
        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m" }
        if seconds < 86_400 { return "\(Int(seconds / 3600))h" }
        if seconds < 604_800 { return "\(Int(seconds / 86_400))d" }
        return createdAt.formatted(.dateTime.month(.abbreviated).day())
    }
}

@Observable
@MainActor
final class ThreadPostStore {
    var posts: [ThreadPost] = ThreadPost.seed

    var roots: [ThreadPost] { posts.filter { $0.parentID == nil } }

    func replies(to id: UUID) -> [ThreadPost] {
        posts.filter { $0.parentID == id }
    }

    func add(_ post: ThreadPost) {
        posts.insert(post, at: 0)
    }

    func toggleLike(_ id: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return }
        posts[index].liked.toggle()
        posts[index].likeCount += posts[index].liked ? 1 : -1
    }

    func repost(_ id: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return }
        posts[index].repostCount += 1
    }
}

extension ThreadPost {
    static var seed: [ThreadPost] {
        let oscar = Artist.oscar
        let handle = "oscarbruschi"
        let root1 = UUID()
        let root2 = UUID()
        return [
            ThreadPost(
                id: root1,
                authorName: oscar.name,
                handle: handle,
                avatarImage: oscar.avatarImage,
                text: "The new mandala is a language, not a pattern. Pink, ink, and a little chaos — that’s the week in the studio.",
                createdAt: Date().addingTimeInterval(-3600 * 5),
                artworkImageName: "art_01",
                replyCount: 2,
                repostCount: 14,
                likeCount: 86
            ),
            ThreadPost(
                authorName: "Elena Rossi",
                handle: "elenawater",
                avatarImage: "avatar_01",
                text: "This sits so well next to the long canvas. The centre holds.",
                createdAt: Date().addingTimeInterval(-3600 * 4),
                replyCount: 0,
                likeCount: 12,
                parentID: root1
            ),
            ThreadPost(
                authorName: oscar.name,
                handle: handle,
                avatarImage: oscar.avatarImage,
                text: "That’s the idea — a still point the rest of the room can orbit.",
                createdAt: Date().addingTimeInterval(-3600 * 3),
                replyCount: 0,
                likeCount: 9,
                parentID: root1
            ),
            ThreadPost(
                id: root2,
                authorName: oscar.name,
                handle: handle,
                avatarImage: oscar.avatarImage,
                text: "Studio note: commissions from $620, worldwide. If you want a piece that feels like a private language, write me.",
                createdAt: Date().addingTimeInterval(-3600 * 26),
                replyCount: 1,
                repostCount: 6,
                likeCount: 41
            ),
            ThreadPost(
                authorName: "Maya Chen",
                handle: "mayainink",
                avatarImage: "avatar_02",
                text: "Booked. Miami light in December.",
                createdAt: Date().addingTimeInterval(-3600 * 20),
                likeCount: 4,
                parentID: root2
            ),
            ThreadPost(
                authorName: oscar.name,
                handle: handle,
                avatarImage: oscar.avatarImage,
                text: "Pen & ink labyrinth took three weeks. Every panel is a door.",
                createdAt: Date().addingTimeInterval(-3600 * 48),
                artworkImageName: "art_02",
                replyCount: 0,
                repostCount: 21,
                likeCount: 133
            ),
        ]
    }
}
