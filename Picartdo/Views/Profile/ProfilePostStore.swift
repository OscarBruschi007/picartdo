import Foundation
import SwiftUI
import UIKit

struct ProfilePost: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var text: String
    var assetImageName: String?
    var storedImageName: String?
    var storedVideoName: String?
    var isVideo: Bool = false
    var isListing: Bool = false
    var listingPrice: Double?
    var qualityStars: Int = 3
    var likeCount: Int = 0
    var createdAt: Date = Date()

    var timeAgo: String {
        let seconds = Date().timeIntervalSince(createdAt)
        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m" }
        if seconds < 86_400 { return "\(Int(seconds / 3600))h" }
        return "\(Int(seconds / 86_400))d"
    }

    var hasMedia: Bool {
        assetImageName != nil || storedImageName != nil || storedVideoName != nil
    }
}

@MainActor
@Observable
final class ProfilePostStore {
    var posts: [ProfilePost] = []
    private let url: URL
    private let mediaDir: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        url = docs.appendingPathComponent("profile-posts.json")
        mediaDir = docs.appendingPathComponent("profile-post-media", isDirectory: true)
        try? FileManager.default.createDirectory(at: mediaDir, withIntermediateDirectories: true)
        if let data = try? Data(contentsOf: url),
           let saved = try? JSONDecoder().decode([ProfilePost].self, from: data),
           !saved.isEmpty {
            posts = saved
        } else {
            posts = ProfilePost.seed
        }
        if !posts.contains(where: { $0.assetImageName == "oscar_studio" }) {
            posts.insert(
                ProfilePost(
                    text: "At the canvas. Colour going down by the window.",
                    assetImageName: "oscar_studio",
                    likeCount: 842,
                    createdAt: Date()
                ),
                at: 0
            )
            persist()
        }
    }

    func add(_ post: ProfilePost) {
        posts.insert(post, at: 0)
        persist()
    }

    func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.86) else { return nil }
        let name = UUID().uuidString + ".jpg"
        do {
            try data.write(to: mediaDir.appendingPathComponent(name), options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    func saveVideo(from source: URL) -> String? {
        let name = UUID().uuidString + "." + source.pathExtension
        let dest = mediaDir.appendingPathComponent(name)
        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: source, to: dest)
            return name
        } catch {
            return nil
        }
    }

    func imageURL(_ name: String) -> URL {
        mediaDir.appendingPathComponent(name)
    }

    func videoURL(_ name: String) -> URL {
        mediaDir.appendingPathComponent(name)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(posts) {
            try? data.write(to: url, options: .atomic)
        }
    }
}

extension ProfilePost {
    static var seed: [ProfilePost] {
        let oscarPosts = ArtistPost.samples.filter { $0.artist.name == Artist.oscar.name }
        return oscarPosts.enumerated().map { index, post in
            let art = Artwork.samples.first { $0.imageName == post.imageName }
            return ProfilePost(
                text: post.caption,
                assetImageName: post.imageName,
                isVideo: post.isVideo,
                isListing: index == 1,
                listingPrice: index == 1 ? art?.price : nil,
                qualityStars: art?.qualityStars ?? 4,
                likeCount: post.likes,
                createdAt: Date().addingTimeInterval(-Double(index + 1) * 3600 * 3)
            )
        }
    }
}
