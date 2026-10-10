import SwiftUI

// MARK: - Shared profile page
//
// One layout for every profile: your own Profile tab and every artist's page.
// Add a new profile feature HERE, never in ProfileView or ArtistStoreView, so
// both get it. The wrappers only supply who the person is and what the
// header buttons do (Edit and Messages on your own profile, Contact on others).

struct ProfilePageConfig {
    var person: ProfileGalleryPerson
    var personal: Bool
    var primaryTitle: String
    var onPrimary: () -> Void
    var secondaryTitle: String
    var onSecondary: () -> Void
    var stories: [ArtistStory]
    var artworks: [Artwork]
    var reviews: [ArtistReview]
    /// Name the person posts thoughts under; the Thoughts sheet shows only theirs.
    var thoughtsAuthor: String
    /// Profile-specific links, shown after Thoughts and Reviews (for example "Book").
    var extraLinks: [(String, () -> Void)] = []
    var footer: String
}

struct ProfilePageBody: View {
    let config: ProfilePageConfig

    @State private var mediaTab: ProfileMediaTab = .posts
    @Namespace private var profileTabs
    @State private var listingFeed: ListingFeedLaunch?
    @State private var buyArtwork: Artwork?
    @State private var messageArtwork: Artwork?
    @State private var activeStory: ArtistStory?
    @State private var showReviews = false
    @State private var openedPost: ProfilePostLaunch?

    var body: some View {
        ZStack {
            PicartdoBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ProfileGalleryHeader(
                        person: config.person,
                        personal: config.personal,
                        primaryTitle: config.primaryTitle,
                        onPrimary: config.onPrimary,
                        secondaryTitle: config.secondaryTitle,
                        onSecondary: config.onSecondary,
                        onReviews: { showReviews = true }
                    )
                    .padding(.bottom, 10)

                    ProfileTabBar(tab: $mediaTab, namespace: profileTabs)
                        .padding(.bottom, 1)

                    if mediaTab == .selling {
                        ProfileListingStack(
                            items: listingItems,
                            onOpen: { artwork in
                                Haptics.tap()
                                listingFeed = ListingFeedLaunch(id: artwork.id, items: listingItems)
                            },
                            onBuy: { buyArtwork = $0 },
                            allowsMessage: !config.personal
                        )
                        .padding(.bottom, 8)
                    } else {
                        MediaGrid(
                            items: imageGridItems,
                            emptyTitle: "No images yet",
                            emptyDetail: "Posts and photos will land here.",
                            onSelect: { item in
                                Haptics.tap()
                                if let post = profilePosts.first(where: { $0.imageName == item.imageName }) {
                                    openedPost = ProfilePostLaunch(post: post)
                                } else {
                                    listingFeed = ListingFeedLaunch(id: item.id, items: listingItems)
                                }
                            },
                            onMessage: config.personal ? nil : { item in
                                Haptics.tap()
                                messageArtwork = listingItems.first { $0.id == item.id }
                            }
                        )
                        .padding(.bottom, 8)
                    }

                    Color.clear.frame(height: 48)
                }
            }
        }
        .sheet(isPresented: $showReviews) {
            ProfileReviewsSheet(reviews: config.reviews)
        }
        .fullScreenCover(item: $buyArtwork) { artwork in
            BuyConfirmationSheet(artwork: artwork)
                .presentationBackground(Color.picardoBackground)
        }
        .fullScreenCover(item: $listingFeed) { launch in
            ProfileListingFeedView(launch: launch, allowsMessage: !config.personal)
        }
        .fullScreenCover(item: $openedPost) { launch in
            ProfilePostDetailView(post: launch.post, personal: config.personal)
                .presentationBackground(Color.picardoBackground)
        }
        .fullScreenCover(item: $activeStory) { story in
            StoryViewer(
                story: story,
                artist: config.personal ? nil : Artist.named(config.person.name)
            ) { activeStory = nil }
        }
        .messageComposer(artwork: $messageArtwork)
    }

    private var listingItems: [Artwork] {
        let all = config.artworks.filter { !$0.imageName.isEmpty }
        return mediaTab == .selling ? all.filter { !$0.isSold } : all
    }

    private var profilePosts: [ArtistPost] {
        let listingNames = Set(config.artworks.map(\.imageName))
        return ArtistPost.samples.filter {
            $0.artist.name == config.person.name && !$0.isVideo && !listingNames.contains($0.imageName)
        }
    }

    private var imageGridItems: [MediaGridItem] {
        let posts = profilePosts.map {
            MediaGridItem(id: $0.id, imageName: $0.imageName, title: $0.caption)
        }
        return posts + listingItems.map(\.mediaGridItem)
    }
}

struct ProfilePostLaunch: Identifiable {
    let post: ArtistPost
    var id: String { post.imageName }
}

private struct ProfilePostComment: Identifiable {
    let id = UUID()
    let name: String
    let text: String
    let timeAgo: String
}

/// Studio / social post — not a listing. Stars, comments, share. No price or Buy.
struct ProfilePostDetailView: View {
    let post: ArtistPost
    var personal: Bool = false
    @Environment(\.dismiss) private var dismiss

    @State private var starred = false
    @State private var saved = false
    @State private var commentDraft = ""
    @State private var comments: [ProfilePostComment] = []
    @FocusState private var commentFocused: Bool

    private var starRating: Double {
        let total = Double(post.likes + post.comments + comments.count + (starred ? 1 : 0))
        let raw = (log10(total + 1) / log10(5000)) * 5.0
        let clamped = min(5.0, max(1.0, raw))
        return (clamped * 2).rounded() / 2
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        ArtworkImage(imageName: post.imageName, contentMode: .fit, maxDimension: 1600)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        HStack(spacing: 10) {
                            ArtworkImage(imageName: post.artist.avatarImage, contentMode: .fill, maxDimension: 200)
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 1) {
                                Text(post.artist.name)
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Post · \(post.timeAgo)")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)

                        Text(post.caption)
                            .font(.system(size: 16))
                            .padding(.horizontal, 16)

                        HStack(spacing: 22) {
                            Button {
                                Haptics.tap()
                                starred.toggle()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: starred ? "star.fill" : "star")
                                        .foregroundStyle(starred ? Color.picardoGold : .primary)
                                    Text(String(format: "%.1f", starRating))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(starred ? Color.picardoGold : .primary)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Rate, \(String(format: "%.1f", starRating)) stars")

                            Button {
                                commentFocused = true
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "bubble.right")
                                    Text("\(post.comments + comments.count)")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundStyle(.primary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Comments")

                            ShareLink(item: "Check out this post by \(post.artist.name) on Picartdo") {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.primary)
                            }
                            .accessibilityLabel("Share")

                            Spacer()

                            Button {
                                withAnimation { saved.toggle() }
                            } label: {
                                Image(systemName: saved ? "bookmark.fill" : "bookmark")
                                    .foregroundStyle(saved ? Color.picardoGold : .primary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(saved ? "Remove from collection" : "Save")
                        }
                        .font(.system(size: 20))
                        .padding(.horizontal, 16)

                        Rectangle()
                            .fill(Color.picardoDivider)
                            .frame(height: 0.5)
                            .padding(.horizontal, 16)

                        Text("Comments")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)

                        ForEach(comments) { item in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(Color.picardoCard)
                                    .frame(width: 28, height: 28)
                                    .overlay {
                                        Text(String(item.name.prefix(1)))
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(item.name)
                                            .font(.system(size: 13, weight: .semibold))
                                        Text(item.timeAgo)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(item.text)
                                        .font(.system(size: 14))
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 20)
                }

                HStack(spacing: 10) {
                    TextField("Add a comment…", text: $commentDraft, axis: .vertical)
                        .lineLimit(1...3)
                        .focused($commentFocused)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.picardoCard, in: Capsule())
                    Button {
                        let text = commentDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        comments.append(ProfilePostComment(name: "You", text: text, timeAgo: "now"))
                        commentDraft = ""
                        Haptics.tap()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.secondary.opacity(0.4)
                                : Color.picardoNeonRed)
                    }
                    .disabled(commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Post comment")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(PicartdoBackground().ignoresSafeArea())
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            if comments.isEmpty {
                comments = [
                    ProfilePostComment(name: "Camila Ruiz", text: "The colour against that sky.", timeAgo: "40m"),
                    ProfilePostComment(name: "Hugo Kessler", text: "Studio light is doing the work.", timeAgo: "1h"),
                ]
            }
        }
    }
}

// MARK: - Sheets shared by every profile

struct ProfileReviewsSheet: View {
    let reviews: [ArtistReview]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if reviews.isEmpty {
                    Text("No customer reviews yet.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                } else {
                    VStack(spacing: 10) {
                        ForEach(reviews) { review in
                            ReviewCard(review: review)
                        }
                    }
                    .padding(16)
                    .padding(.top, 8)
                }
            }
            .background(Color.picardoBackground)
            .navigationTitle("Customer reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ProfileThoughtsSheet: View {
    let author: String
    let canCompose: Bool

    @Environment(ThreadPostStore.self) private var threads
    @Environment(\.dismiss) private var dismiss
    @State private var showCompose = false

    private var posts: [ThreadPost] {
        threads.roots.filter { $0.authorName == author }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if posts.isEmpty {
                    Text("No thoughts yet.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(posts) { post in
                            ThreadRow(
                                post: post,
                                replies: threads.replies(to: post.id),
                                onLike: { threads.toggleLike(post.id) },
                                onRepost: { threads.repost(post.id) },
                                onShare: {}
                            )
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
            .background(Color.picardoBackground)
            .navigationTitle("Thoughts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                if canCompose {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Haptics.tap()
                            showCompose = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                        .accessibilityLabel("Write a thought")
                    }
                }
            }
            .sheet(isPresented: $showCompose) { ComposeThreadSheet() }
        }
    }
}

struct ComposeThreadSheet: View {
    @Environment(ThreadPostStore.self) private var threads
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            TextField("What’s on the studio table?", text: $text, axis: .vertical)
                .font(.system(size: 17))
                .lineLimit(6...12)
                .padding()
                .navigationTitle("New thought")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Post") {
                            threads.add(ThreadPost(
                                authorName: Artist.oscar.name,
                                handle: "oscarbruschi",
                                avatarImage: Artist.oscar.avatarImage,
                                text: text.trimmingCharacters(in: .whitespacesAndNewlines)
                            ))
                            Haptics.success()
                            dismiss()
                        }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Highlights for any artist

extension Artist {
    /// Home story ring — a short set of studio photos for Instagram-style viewing.
    var feedStory: ArtistStory {
        let photos = storePhotos.isEmpty ? [avatarImage, bannerImage].filter { !$0.isEmpty } : Array(storePhotos.prefix(4))
        let cover = avatarImage.isEmpty ? (photos.first ?? bannerImage) : avatarImage
        return ArtistStory(
            id: "\(id.uuidString)-feed",
            title: firstName,
            coverImage: cover,
            frames: photos.isEmpty ? [cover] : photos
        )
    }

    /// Studio / Process / Shows / Sold highlight bubbles, built from the artist's photos.
    var highlightStories: [ArtistStory] {
        let titles = ["Studio", "Process", "Shows", "Sold"]
        let photos = storePhotos.isEmpty ? [avatarImage] : storePhotos
        return titles.enumerated().map { index, title in
            // Artists with few photos reuse them, so no bubble shows a blank placeholder.
            let cover = photos[index % photos.count]
            let frames = (0..<min(3, photos.count)).map { photos[(index + $0) % photos.count] }
            return ArtistStory(
                id: "\(id.uuidString)-\(title)",
                title: title,
                coverImage: cover,
                frames: frames.isEmpty ? [cover] : frames
            )
        }
    }
}
