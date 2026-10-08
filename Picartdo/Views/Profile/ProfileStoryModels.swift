import Foundation

struct ArtistStory: Identifiable, Hashable {
    let id: String
    let title: String
    let coverImage: String
    let frames: [String]

    static let samples: [ArtistStory] = [
        ArtistStory(id: "studio", title: "Studio", coverImage: "art_01", frames: ["art_01", "art_05", "art_03"]),
        ArtistStory(id: "process", title: "Process", coverImage: "art_02", frames: ["art_02", "art_06", "art_07"]),
        ArtistStory(id: "shows", title: "Shows", coverImage: "art_08", frames: ["art_08", "art_04", "art_01"]),
        ArtistStory(id: "sold", title: "Sold", coverImage: "art_05", frames: ["art_05", "art_03", "art_08"]),
    ]
}

struct ProfileReview: Identifiable, Hashable {
    let id: UUID
    let buyerName: String
    let rating: Int
    let quote: String
    let date: String

    var initial: String { String(buyerName.prefix(1)) }

    static let samples: [ProfileReview] = [
        ProfileReview(id: UUID(), buyerName: "Alex T.", rating: 5,
                      quote: "The mandala arrived like a private language. I look at it every morning.",
                      date: "Jun 2025"),
        ProfileReview(id: UUID(), buyerName: "Maria L.", rating: 5,
                      quote: "Oscar was clear, kind, and the piece exceeded what I hoped for.",
                      date: "May 2025"),
        ProfileReview(id: UUID(), buyerName: "James R.", rating: 4,
                      quote: "Beautiful work, packed with care. It holds the whole wall.",
                      date: "Apr 2025"),
        ProfileReview(id: UUID(), buyerName: "Priya N.", rating: 5,
                      quote: "Commission felt easy. He listened, then made something I couldn’t have described.",
                      date: "Mar 2025"),
    ]
}
