import SwiftUI

struct FeedView: View {
    @State private var selectedFilter: String = "All"
    @State private var selectedArtwork: Artwork? = nil
    @State private var likedIDs: Set<Int> = []
    @State private var searchText = ""

    let filters = ["All", "Painting", "Drawing", "Mixed Media"]

    var filteredArtworks: [Artwork] {
        let base: [Artwork]
        if selectedFilter == "All" {
            base = Artwork.all
        } else {
            base = Artwork.all.filter { $0.category == selectedFilter }
        }
        if searchText.isEmpty { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // ── Hero ──────────────────────────────────────
                    HeroSection(featured: Artwork.featured, onTap: { selectedArtwork = Artwork.featured })

                    VStack(spacing: 32) {

                        // ── Just Dropped ──────────────────────────
                        ArtworkRowSection(
                            eyebrow: "New Arrivals",
                            title: "Just Dropped",
                            subtitle: "Fresh from the studio",
                            artworks: Artwork.justDropped,
                            likedIDs: $likedIDs,
                            onTap: { selectedArtwork = $0 }
                        )

                        Divider().padding(.horizontal)

                        // ── Trending ──────────────────────────────
                        ArtworkRowSection(
                            eyebrow: "What's Hot",
                            title: "Trending Now",
                            subtitle: "Most coveted pieces this week",
                            artworks: Artwork.trending,
                            likedIDs: $likedIDs,
                            onTap: { selectedArtwork = $0 },
                            showRank: true
                        )

                        Divider().padding(.horizontal)

                        // ── All Works ─────────────────────────────
                        AllWorksSection(
                            filters: filters,
                            selectedFilter: $selectedFilter,
                            artworks: filteredArtworks,
                            likedIDs: $likedIDs,
                            onTap: { selectedArtwork = $0 }
                        )
                    }
                    .padding(.vertical, 32)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Search artworks…")
            .sheet(item: $selectedArtwork) { artwork in
                ArtworkDetailView(artwork: artwork, likedIDs: $likedIDs)
            }
        }
    }
}

// MARK: - Hero Section

struct HeroSection: View {
    let featured: Artwork
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            Image(featured.imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 520)
                .clipped()

            // Gradient scrim
            LinearGradient(
                colors: [.black.opacity(0.8), .black.opacity(0.2), .clear],
                startPoint: .bottom,
                endPoint: .top
            )

            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Featured drop pill
                Label("Featured Drop", systemImage: "circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.picardoGold)
                    .labelStyle(PillLabelStyle())

                Text(featured.title)
                    .font(.system(size: 40, weight: .heavy, design: .default))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(featured.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Button("Buy Now") { onTap() }
                        .buttonStyle(GoldButtonStyle())

                    Text(featured.priceFormatted)
                        .font(.title3.bold())
                        .foregroundStyle(.picardoGold)
                }
                .padding(.top, 4)

                // Stats row
                HStack(spacing: 0) {
                    StatBadge(number: "26", label: "Artworks")
                    StatBadge(number: "1", label: "Artist")
                    StatBadge(number: "389", label: "Top Likes")
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .frame(height: 520)
    }
}

// MARK: - Artwork Row Section

struct ArtworkRowSection: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let artworks: [Artwork]
    @Binding var likedIDs: Set<Int>
    let onTap: (Artwork) -> Void
    var showRank: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(eyebrow)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.picardoGold)
                        .tracking(2)
                        .textCase(.uppercase)
                    Text(title)
                        .font(.title2.bold())
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("View All →") {}
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.picardoGold)
            }
            .padding(.horizontal)

            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(artworks.enumerated()), id: \.element.id) { index, artwork in
                        ArtworkCard(
                            artwork: artwork,
                            rank: showRank ? index + 1 : nil,
                            isLiked: likedIDs.contains(artwork.id),
                            onTap: { onTap(artwork) },
                            onLike: { toggleLike(artwork.id) }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
    }

    private func toggleLike(_ id: Int) {
        if likedIDs.contains(id) { likedIDs.remove(id) }
        else { likedIDs.insert(id) }
    }
}

// MARK: - All Works Section

struct AllWorksSection: View {
    let filters: [String]
    @Binding var selectedFilter: String
    let artworks: [Artwork]
    @Binding var likedIDs: Set<Int>
    let onTap: (Artwork) -> Void

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("The Collection")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.picardoGold)
                        .tracking(2)
                        .textCase(.uppercase)
                    Text("All Works")
                        .font(.title2.bold())
                    Text("\(artworks.count) available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)

            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filters, id: \.self) { filter in
                        FilterPill(label: filter, isSelected: selectedFilter == filter) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Grid
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(artworks) { artwork in
                    ArtworkGridCard(
                        artwork: artwork,
                        isLiked: likedIDs.contains(artwork.id),
                        onTap: { onTap(artwork) },
                        onLike: {
                            if likedIDs.contains(artwork.id) { likedIDs.remove(artwork.id) }
                            else { likedIDs.insert(artwork.id) }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Artwork Card (horizontal scroll)

struct ArtworkCard: View {
    let artwork: Artwork
    let rank: Int?
    let isLiked: Bool
    let onTap: () -> Void
    let onLike: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    Image(artwork.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 180, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if let rank {
                        Text("#\(rank)")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.picardoGold)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .padding(8)
                    }

                    if artwork.sold {
                        Text("SOLD")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(8)
                    }

                    // Verified badge
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.picardoGold)
                        Text("Verified")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(8)
                }

                Text(artwork.category.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1)

                Text(artwork.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("Oscar Bruschi")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(artwork.priceFormatted)
                        .font(.subheadline.weight(.heavy))
                    Spacer()
                    Button(action: onLike) {
                        Label("\(artwork.likes + (isLiked ? 1 : 0))", systemImage: isLiked ? "heart.fill" : "heart")
                            .font(.caption)
                            .foregroundStyle(isLiked ? .red : .secondary)
                    }
                }
            }
            .frame(width: 180)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Artwork Grid Card

struct ArtworkGridCard: View {
    let artwork: Artwork
    let isLiked: Bool
    let onTap: () -> Void
    let onLike: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    Image(artwork.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()

                    if artwork.sold {
                        Text("SOLD")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .padding(8)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        Text(artwork.title)
                            .font(.subheadline.weight(.bold))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(artwork.priceFormatted)
                            .font(.subheadline.weight(.heavy))
                            .lineLimit(1)
                    }
                    HStack {
                        Text("Oscar Bruschi")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(action: onLike) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.caption)
                                .foregroundStyle(isLiked ? .red : .secondary)
                        }

                        Text(artwork.category.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.tertiary)
                            .tracking(0.5)
                    }
                }
                .padding(12)
            }
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reusable Components

struct StatBadge: View {
    let number: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(number)
                .font(.headline.weight(.heavy))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(0.5)
        }
        .padding(.horizontal, 16)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(.white.opacity(0.18))
                .frame(width: 0.5)
        }
    }
}

struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.primary : Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.picardoGold)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct PillLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            configuration.icon
                .font(.system(size: 6))
            configuration.title
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Color.picardoGold.opacity(0.18))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.picardoGold.opacity(0.4), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    FeedView()
}
