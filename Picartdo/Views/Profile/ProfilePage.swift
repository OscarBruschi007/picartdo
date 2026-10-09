import SwiftUI

// MARK: - Shared profile page
//
// One layout for every profile: your own Profile tab and every artist's page.
// Add a new profile feature HERE, never in ProfileView or ArtistStoreView, so
// both get it. The wrappers only supply who the person is and what the two
// header buttons do (Edit/Message for you, Muse/Message for other artists).

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
    @State private var showThoughts = false
    @State private var showReviews = false

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
                        onSecondary: config.onSecondary
                    )
                    .padding(.bottom, 10)

                    ProfileTabBar(tab: $mediaTab, namespace: profileTabs)
                        .padding(.bottom, 1)

                    if mediaTab == .selling {
                        ProfileListingStack(
                            items: feedItems,
                            onOpen: { artwork in
                                Haptics.tap()
                                listingFeed = ListingFeedLaunch(id: artwork.id, items: feedItems)
                            },
                            onBuy: { buyArtwork = $0 },
                            allowsMessage: !config.personal
                        )
                        .padding(.bottom, 8)
                    } else {
                        MediaGrid(
                            items: feedItems.map(\.mediaGridItem),
                            emptyTitle: "No images yet",
                            emptyDetail: "Posts and photos will land here.",
                            onSelect: { item in
                                Haptics.tap()
                                listingFeed = ListingFeedLaunch(id: item.id, items: feedItems)
                            },
                            onMessage: config.personal ? nil : { item in
                                Haptics.tap()
                                messageArtwork = feedItems.first { $0.id == item.id }
                            }
                        )
                        .padding(.bottom, 8)
                    }

                    ProfileMoreLinks(items: [
                        ("Thoughts", { showThoughts = true }),
                        ("Reviews", { showReviews = true }),
                    ] + config.extraLinks)
                    .padding(.top, 36)

                    Text(config.footer)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                        .padding(.bottom, 40)

                    Color.clear.frame(height: 24)
                }
            }
        }
        .sheet(isPresented: $showThoughts) {
            ProfileThoughtsSheet(author: config.thoughtsAuthor, canCompose: config.personal)
        }
        .sheet(isPresented: $showReviews) {
            ProfileReviewsSheet(reviews: config.reviews)
        }
        .sheet(item: $buyArtwork) { artwork in
            BuyConfirmationSheet(artwork: artwork)
        }
        .fullScreenCover(item: $listingFeed) { launch in
            ProfileListingFeedView(launch: launch, allowsMessage: !config.personal)
        }
        .fullScreenCover(item: $activeStory) { story in
            StoryViewer(
                story: story,
                artist: config.personal ? nil : Artist.named(config.person.name)
            ) { activeStory = nil }
        }
        .messageComposer(artwork: $messageArtwork)
    }

    private var feedItems: [Artwork] {
        let all = config.artworks.filter { !$0.imageName.isEmpty }
        return mediaTab == .selling ? all.filter { !$0.isSold } : all
    }
}

// MARK: - Sheets shared by every profile

struct ProfileReviewsSheet: View {
    let reviews: [ArtistReview]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(reviews) { review in
                        ReviewCard(review: review)
                    }
                }
                .padding(16)
                .padding(.top, 8)
            }
            .background(Color.picardoBackground)
            .navigationTitle("Reviews")
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
