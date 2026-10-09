import SwiftUI

struct MediaGridItem: Identifiable, Hashable {
    let id: UUID
    let imageName: String
    var price: Double? = nil
    var isSold: Bool = false
    var isVideo: Bool = false
    var viewsLabel: String? = nil
    var title: String = ""
}

struct MediaGrid: View {
    let items: [MediaGridItem]
    var portraitTiles: Bool = false
    var emptyTitle: String
    var emptyDetail: String
    var onSelect: (MediaGridItem) -> Void
    var onMessage: ((MediaGridItem) -> Void)? = nil

    private let spacing: CGFloat = 12
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        if items.isEmpty {
            ProfileEmptyState(title: emptyTitle, detail: emptyDetail)
                .padding(.top, 48)
        } else {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(items) { item in
                    Button { onSelect(item) } label: {
                        tile(item)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibility(for: item))
                    .contextMenu {
                        if let onMessage {
                            Button {
                                onMessage(item)
                            } label: {
                                Label("Message", systemImage: "envelope")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
    }

    private func tile(_ item: MediaGridItem) -> some View {
        VStack(spacing: 0) {
            Color.picardoPolaroidMat
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    ArtworkImage(imageName: item.imageName, contentMode: .fit, maxDimension: 700)
                        .padding(5)
                        .background(Color.picardoPostFrame)
                }
                .overlay(alignment: .topLeading) {
                    if item.isVideo {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(.black.opacity(0.5), in: Circle())
                            .padding(8)
                    }
                }
                .clipped()

            Color.picardoPolaroidMat
                .frame(height: 22)
        }
        .padding(.horizontal, 6)
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background(Color.picardoPolaroidMat)
        .overlay(
            Rectangle()
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 5, y: 3)
    }

    private func accessibility(for item: MediaGridItem) -> String {
        var parts = [item.title.isEmpty ? "Artwork" : item.title]
        if item.isVideo { parts.append("Video") }
        return parts.joined(separator: ", ")
    }
}

struct ProfileEmptyState: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.picardoText)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(Color.picardoTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .accessibilityElement(children: .combine)
    }
}

extension Artwork {
    var mediaGridItem: MediaGridItem {
        MediaGridItem(
            id: id,
            imageName: imageName,
            title: title
        )
    }
}

struct ListingFeedLaunch: Identifiable {
    let id: UUID
    let items: [Artwork]
}

struct ProfileListingStack: View {
    let items: [Artwork]
    var onOpen: (Artwork) -> Void
    var onBuy: ((Artwork) -> Void)? = nil
    var allowsMessage: Bool = true

    @Environment(WishlistStore.self) private var wishlist

    var body: some View {
        if items.isEmpty {
            ProfileEmptyState(
                title: "No listings yet",
                detail: "Listings you put up for sale will land here."
            )
            .padding(.top, 48)
        } else {
            LazyVStack(spacing: 28) {
                ForEach(items) { artwork in
                    FeaturedHeroCard(
                        artwork: artwork,
                        isSaved: wishlist.isLiked(artwork),
                        onSave: { wishlist.toggle(artwork) },
                        onBuy: artwork.isSold ? nil : { onBuy?(artwork) },
                        onOpen: { onOpen(artwork) },
                        eyebrow: artwork.isSold ? "SOLD" : artwork.category.rawValue.uppercased(),
                        allowsMessage: allowsMessage
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }
}

struct ProfileListingFeedView: View {
    let launch: ListingFeedLaunch
    var allowsMessage: Bool = true
    @Environment(\.dismiss) private var dismiss
    @Environment(WishlistStore.self) private var wishlist
    @State private var buyArtwork: Artwork?
    @State private var openedArtwork: Artwork?

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 28) {
                        ForEach(launch.items) { artwork in
                            FeaturedHeroCard(
                                artwork: artwork,
                                isSaved: wishlist.isLiked(artwork),
                                onSave: { wishlist.toggle(artwork) },
                                onBuy: artwork.isSold ? nil : { buyArtwork = artwork },
                                onOpen: {
                                    Haptics.tap()
                                    openedArtwork = artwork
                                },
                                eyebrow: artwork.isSold ? "SOLD" : artwork.category.rawValue.uppercased(),
                                allowsMessage: allowsMessage
                            )
                            .id(artwork.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .padding(.bottom, 40)
                }
                .onAppear {
                    proxy.scrollTo(launch.id, anchor: .top)
                }
            }
            .background { PicartdoBackground().ignoresSafeArea() }
            .navigationTitle("Listings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: $buyArtwork) { artwork in
                BuyConfirmationSheet(artwork: artwork)
            }
            .navigationDestination(item: $openedArtwork) { artwork in
                ArtworkDetailView(artwork: artwork)
            }
        }
    }
}
