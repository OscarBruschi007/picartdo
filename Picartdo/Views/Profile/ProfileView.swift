import SwiftUI

/// Profile tab: Home chrome — identity, highlight bubbles, featured-drop feed.
struct ProfileView: View {
    var hideTabBar: Binding<Bool> = .constant(false)

    @Environment(SessionStore.self) private var session
    @Environment(WishlistStore.self) private var wishlist
    @Environment(MarketplaceStore.self) private var marketplace

    @State private var identity = ProfileIdentity.load()
    @State private var mediaTab: ProfileMediaTab = .posts
    @Namespace private var profileTabs
    @State private var showEdit = false
    @State private var showSettings = false
    @State private var showMessages = ProcessInfo.processInfo.arguments.contains("--open-messages")
    @State private var showAllThoughts = false
    @State private var showReviews = false
    @State private var listingFeed: ListingFeedLaunch?
    @State private var buyArtwork: Artwork?
    @State private var activeStory: ArtistStory?

    var body: some View {
        NavigationStack {
            ZStack {
                PicartdoBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ProfileGalleryHeader(
                            person: ProfileGalleryPerson(
                                name: identity.name,
                                handle: identity.handle,
                                location: identity.location,
                                bio: identity.bio,
                                avatarAsset: Artist.oscar.avatarImage,
                                coverAsset: Artist.oscar.bannerImage,
                                customAvatar: identity.avatarImage,
                                verified: true,
                                followers: Artist.oscar.followers,
                                following: Artist.oscar.followingCount,
                                rating: Artist.oscar.rating
                            ),
                            personal: true,
                            primaryTitle: "EDIT PROFILE",
                            onPrimary: { showEdit = true },
                            secondaryTitle: "MESSAGE",
                            onSecondary: { showMessages = true }
                        )
                        .padding(.bottom, 10)

                        ProfileHighlightsRow(stories: ArtistStory.samples) { story in
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
                                items: gridItems,
                                emptyTitle: "No images yet",
                                emptyDetail: "Posts and photos will land here."
                            ) { item in
                                Haptics.tap()
                                listingFeed = ListingFeedLaunch(id: item.id, items: feedItems)
                            }
                            .padding(.bottom, 8)
                        }

                        ProfileMoreLinks(items: [
                            ("Thoughts", { showAllThoughts = true }),
                            ("Reviews", { showReviews = true }),
                        ])
                        .padding(.top, 36)

                        Text("Joined PICARDO in \(String(identity.sinceYear))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 16)
                            .padding(.bottom, 40)

                        Color.clear.frame(height: 24)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Artist.self) { artist in
                ArtistStoreView(artist: artist)
                    .picardoPushedScreen()
            }
            .overlay(alignment: .topTrailing) {
                if !showMessages {
                    Button {
                        Haptics.tap()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.45), radius: 6, y: 1)
                            .padding(12)
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 16)
                    .accessibilityLabel("Settings")
                }
            }
            .task {
                if showMessages { hideTabBar.wrappedValue = true }
                identity = ProfileIdentity.load()
                if !ProfileIdentity.hasSaved {
                    if let name = session.profile?.fullName, !name.isEmpty { identity.name = name }
                    if let line = session.profile?.tagline, !line.isEmpty { identity.tagline = line }
                    if let about = session.profile?.bio, !about.isEmpty { identity.bio = about }
                    if let place = session.profile?.location, !place.isEmpty { identity.location = place }
                    identity.migratingStaleCopy()
                }
                await marketplace.load(for: session.profile?.id)
            }
            .navigationDestination(isPresented: $showMessages) {
                DirectMessagesView()
            }
            .onChange(of: showMessages) { _, presented in
                hideTabBar.wrappedValue = presented
            }
            .sheet(isPresented: $showEdit) { EditProfileSheet(identity: $identity) }
            .sheet(isPresented: $showSettings) { ProfileSettingsSheet() }
            .sheet(isPresented: $showAllThoughts) { AllThoughtsSheet() }
            .sheet(isPresented: $showReviews) { ProfileReviewsSheet() }
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
    }

    private var feedItems: [Artwork] {
        let all = marketplace.listings.filter { !$0.imageName.isEmpty }
        switch mediaTab {
        case .selling:
            return marketplace.forSale.filter { !$0.imageName.isEmpty }
        default:
            return all
        }
    }

    private var gridItems: [MediaGridItem] {
        feedItems.map(\.mediaGridItem)
    }
}

// MARK: - Sheets

private struct ProfileReviewsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                ReviewsStrip(reviews: ProfileReview.samples)
                    .padding(.top, 12)
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

private struct ComposeThreadSheet: View {
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

private struct AllThoughtsSheet: View {
    @Environment(ThreadPostStore.self) private var threads
    @Environment(\.dismiss) private var dismiss
    @State private var showCompose = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(threads.roots) { post in
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
            .background(Color.picardoBackground)
            .navigationTitle("Thoughts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
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
            .sheet(isPresented: $showCompose) { ComposeThreadSheet() }
        }
    }
}

#Preview("Profile") {
    ProfileView()
        .environment(SessionStore())
        .environment(WishlistStore())
        .environment(MarketplaceStore())
        .environment(ThreadPostStore())
}
