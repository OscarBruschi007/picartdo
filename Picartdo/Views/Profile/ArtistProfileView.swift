import SwiftUI

// MARK: - Artist Review Model

struct ArtistReview: Identifiable {
    let id = UUID()
    let reviewerName: String
    let rating: Int
    let comment: String
    let date: String
    let artworkTitle: String
}

extension ArtistReview {
    static func samples(for artist: Artist) -> [ArtistReview] {
        let sets: [String: [ArtistReview]] = [
            "Elena Rossi": [
                ArtistReview(reviewerName: "Sarah K.", rating: 5,
                             comment: "Elena captured exactly what I envisioned. The watercolor portrait is breathtaking — she even included small details I mentioned offhand.",
                             date: "May 2025", artworkTitle: "Custom Portrait"),
                ArtistReview(reviewerName: "David M.", rating: 5,
                             comment: "Fast communication, delivered ahead of schedule. The piece is now the centrepiece of our living room.",
                             date: "Apr 2025", artworkTitle: "Family Watercolor"),
                ArtistReview(reviewerName: "Priya N.", rating: 4,
                             comment: "Wonderful work. Requested a small revision and she handled it graciously.",
                             date: "Mar 2025", artworkTitle: "Abstract Landscape"),
            ],
            "Lucía Vega": [
                ArtistReview(reviewerName: "Carlos R.", rating: 5,
                             comment: "Lucía transformed our event hall with a live mural that left guests speechless. Pure talent.",
                             date: "Jun 2025", artworkTitle: "Live Mural Commission"),
                ArtistReview(reviewerName: "Mia T.", rating: 5,
                             comment: "Commissioned a large canvas for our office lobby. She nailed the brand palette perfectly.",
                             date: "May 2025", artworkTitle: "Corporate Canvas"),
                ArtistReview(reviewerName: "Jordan P.", rating: 5,
                             comment: "The boldness of her work is unmatched. Every inch of the piece commands attention.",
                             date: "Apr 2025", artworkTitle: "Abstract 48×36"),
            ],
            "Yuki Tanaka": [
                ArtistReview(reviewerName: "Lena W.", rating: 5,
                             comment: "Super fast, professional, and the character design was beyond what I imagined. 100% will commission again.",
                             date: "Jun 2025", artworkTitle: "Character Commission"),
                ArtistReview(reviewerName: "Ryan S.", rating: 5,
                             comment: "Yuki created our brand mascot in 3 days. Incredible eye for detail and colour.",
                             date: "May 2025", artworkTitle: "Brand Mascot"),
                ArtistReview(reviewerName: "Hana Y.", rating: 4,
                             comment: "Really pleased with the result. Communication was clear and revisions were handled quickly.",
                             date: "Apr 2025", artworkTitle: "Portrait Illustration"),
            ],
        ]
        if let specific = sets[artist.name] { return specific }
        return [
            ArtistReview(reviewerName: "Alex T.", rating: 5,
                         comment: "Absolutely stunning. \(artist.name) brought my vision to life with skill and care. Will commission again without hesitation.",
                         date: "Jun 2025", artworkTitle: "Custom Commission"),
            ArtistReview(reviewerName: "Maria L.", rating: 5,
                         comment: "Professional, communicative, and incredibly talented. The final piece exceeded all expectations.",
                         date: "May 2025", artworkTitle: "Portrait Commission"),
            ArtistReview(reviewerName: "James R.", rating: 4,
                         comment: "Great experience overall. The artwork is beautiful and arrived well packaged.",
                         date: "Apr 2025", artworkTitle: "Mixed Media Piece"),
        ]
    }
}

// MARK: - Artist Profile View

struct ArtistProfileView: View {
    let artist: Artist

    var body: some View {
        ArtistStoreView(artist: artist)
    }
}

// MARK: - Profile Stat Pill

struct ProfileStatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.primary)
            Text(label.uppercased())
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

// MARK: - Review Card

struct ReviewCard: View {
    let review: ArtistReview

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // Avatar placeholder (initials)
                Text(String(review.reviewerName.prefix(1)))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.picardoGold)
                    .frame(width: 36, height: 36)
                    .background(Color.picardoGold.opacity(0.15), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(review.reviewerName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    HStack(spacing: 3) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < review.rating ? "star.fill" : "star")
                                .font(.system(size: 9))
                                .foregroundStyle(i < review.rating ? Color.picardoGold : Color(.systemGray4))
                        }
                        Text("· \(review.date)")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
            }

            Text(review.comment)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            Text("For: \(review.artworkTitle)")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.picardoBorder, lineWidth: 0.5)
        )
    }
}

#Preview {
    NavigationStack {
        ArtistProfileView(artist: Artist.all[0])
            .navigationDestination(for: Artwork.self) { ArtworkDetailView(artwork: $0) }
    }
}

// MARK: - Artist store / public profile
//
// Same gallery chrome as the Profile tab — identity, highlights, feed.

struct ArtistStoreView: View {
    let artist: Artist

    @Environment(WishlistStore.self) private var wishlist
    @State private var mediaTab: ProfileMediaTab = .posts
    @Namespace private var profileTabs
    @State private var isFollowing = false
    @State private var showCommission = false
    @State private var showReviews = false
    @State private var showMessages = false
    @State private var listingFeed: ListingFeedLaunch?
    @State private var buyArtwork: Artwork?
    @State private var activeStory: ArtistStory?

    var body: some View {
        ZStack {
            PicartdoBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ProfileGalleryHeader(
                        person: person,
                        primaryTitle: isFollowing ? "FOLLOWING" : "FOLLOW",
                        onPrimary: {
                            withAnimation(PicardoMotion.quick) {
                                isFollowing.toggle()
                            }
                        },
                        secondaryTitle: "MESSAGE",
                        onSecondary: { showMessages = true }
                    )
                    .padding(.bottom, 10)

                    ProfileHighlightsRow(stories: highlightStories) { story in
                        activeStory = story
                    }
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
                            onBuy: { buyArtwork = $0 }
                        )
                        .padding(.bottom, 8)
                    } else {
                        MediaGrid(
                            items: feedItems.map(\.mediaGridItem),
                            emptyTitle: "No images yet",
                            emptyDetail: "Posts and photos will land here."
                        ) { item in
                            Haptics.tap()
                            listingFeed = ListingFeedLaunch(id: item.id, items: feedItems)
                        }
                        .padding(.bottom, 8)
                    }

                    ProfileMoreLinks(items: moreLinks)
                        .padding(.top, 36)

                    Text("On PICARDO · \(artist.location)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                        .padding(.bottom, 40)

                    Color.clear.frame(height: 24)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .picardoPushedScreen()
        .navigationDestination(for: Artist.self) { next in
            ArtistStoreView(artist: next)
                .picardoPushedScreen()
        }
        .navigationDestination(isPresented: $showMessages) {
            ArtistChatView(artist: artist)
        }
        .sheet(isPresented: $showCommission) {
            NavigationStack { CommissionRequestView(artist: artist) }
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showReviews) {
            ArtistReviewsSheet(artist: artist)
        }
        .sheet(item: $buyArtwork) { artwork in
            BuyConfirmationSheet(artwork: artwork)
        }
        .fullScreenCover(item: $listingFeed) { launch in
            ProfileListingFeedView(launch: launch)
        }
        .fullScreenCover(item: $activeStory) { story in
            StoryViewer(story: story) { activeStory = nil }
        }
    }

    private var person: ProfileGalleryPerson {
        let handle = artist.name.lowercased().replacingOccurrences(of: " ", with: "")
        let bio = artist.bio.trimmingCharacters(in: .whitespacesAndNewlines)
        let shortBio = bio.count > 80 ? artist.tagline : (bio.isEmpty ? artist.tagline : bio)
        return ProfileGalleryPerson(
            name: artist.name,
            handle: handle,
            location: artist.location,
            bio: shortBio,
            avatarAsset: artist.avatarImage,
            coverAsset: artist.bannerImage,
            verified: artist.verified,
            followers: artist.followers,
            following: artist.followingCount,
            rating: artist.rating
        )
    }

    private var highlightStories: [ArtistStory] {
        let titles = ["Studio", "Process", "Shows", "Sold"]
        let photos = artist.storePhotos
        return titles.enumerated().map { index, title in
            let cover = photos.indices.contains(index) ? photos[index] : artist.avatarImage
            let start = min(index, max(photos.count - 1, 0))
            let frames = Array(photos.dropFirst(start).prefix(3))
            return ArtistStory(
                id: "\(artist.id.uuidString)-\(title)",
                title: title,
                coverImage: cover,
                frames: frames.isEmpty ? [cover] : frames
            )
        }
    }

    private var artistArtworks: [Artwork] {
        let matched = Artwork.samples.filter { $0.artistName == artist.name && !$0.imageName.isEmpty }
        if !matched.isEmpty { return matched }
        let price = Double(artist.startingPrice.filter(\.isNumber)) ?? 500
        return artist.portfolioImages.enumerated().map { index, imageName in
            Artwork(
                title: "Work \(index + 1)",
                artistName: artist.name,
                artistID: artist.id,
                price: price,
                imageName: imageName,
                isSold: index % 4 == 0
            )
        }
    }

    private var feedItems: [Artwork] {
        switch mediaTab {
        case .selling:
            return artistArtworks.filter { !$0.isSold }
        default:
            return artistArtworks
        }
    }

    private var moreLinks: [(String, () -> Void)] {
        var items: [(String, () -> Void)] = [("Reviews", { showReviews = true })]
        if artist.availableForCommissions {
            items.append(("Book", { showCommission = true }))
        }
        return items
    }
}

private struct ArtistReviewsSheet: View {
    let artist: Artist
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(ArtistReview.samples(for: artist)) { review in
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

