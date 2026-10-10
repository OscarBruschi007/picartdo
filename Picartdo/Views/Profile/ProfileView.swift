import SwiftUI

/// Profile tab: Home chrome — identity, highlight bubbles, featured-drop feed.
struct ProfileView: View {
    var hideTabBar: Binding<Bool> = .constant(false)

    @Environment(SessionStore.self) private var session
    @Environment(MarketplaceStore.self) private var marketplace

    @State private var identity = ProfileIdentity.load()
    @State private var showEdit = false
    @State private var showSettings = false
    @State private var showMessages = ProcessInfo.processInfo.arguments.contains("--open-messages")

    var body: some View {
        NavigationStack {
            ProfilePageBody(config: ProfilePageConfig(
                person: ProfileGalleryPerson(
                    name: identity.name,
                    handle: identity.handle,
                    location: identity.location,
                    bio: identity.bio,
                    avatarAsset: Artist.oscar.avatarImage,
                    coverAsset: Artist.oscar.bannerImage,
                    customAvatar: identity.avatarImage,
                    customCover: identity.coverImage,
                    verified: true,
                    followers: Artist.oscar.followers,
                    following: "111",
                    rating: Artist.oscar.rating,
                    reviewCount: Artist.oscar.reviewCount
                ),
                personal: true,
                primaryTitle: "EDIT PROFILE",
                onPrimary: { showEdit = true },
                secondaryTitle: "MESSAGE",
                onSecondary: { showMessages = true },
                stories: ArtistStory.samples,
                artworks: marketplace.listings,
                reviews: ArtistReview.samples(for: .oscar),
                thoughtsAuthor: Artist.oscar.name,
                footer: "Joined Picartdo in \(String(identity.sinceYear))"
            ))
            .navigationBarHidden(true)
            .navigationDestination(for: Artist.self) { artist in
                ArtistStoreView(artist: artist)
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
            .onChange(of: showMessages) { _, presented in
                hideTabBar.wrappedValue = presented
            }
            .fullScreenCover(isPresented: $showMessages) {
                DirectMessagesView(isPresented: $showMessages)
                    .presentationBackground(.clear)
            }
            .fullScreenCover(isPresented: $showEdit, onDismiss: {
                identity = ProfileIdentity.load()
            }) {
                EditProfileSheet(identity: $identity, isPresented: $showEdit)
                    .presentationBackground(.clear)
            }
            .fullScreenCover(isPresented: $showSettings, onDismiss: {
                identity = ProfileIdentity.load()
            }) {
                ProfileSettingsSheet()
                    .presentationBackground(.clear)
            }
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
