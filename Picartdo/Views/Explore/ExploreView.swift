import SwiftUI

// MARK: - Explore — Instagram search + photo grid

private enum ExploreSearchLane: String, CaseIterable, Identifiable {
    case top = "Top"
    case accounts = "Accounts"
    case tags = "Tags"
    var id: String { rawValue }
}

struct ExploreView: View {

    @State private var query = ""
    @State private var lane: ExploreSearchLane = .top
    @State private var discoverArt: [Artwork] = Artwork.samples.shuffled()
    @State private var following: Set<String> = []
    @FocusState private var searchFocused: Bool

    private var catalog: [Artist] { [Artist.oscar] + Artist.all }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var showSearch: Bool { searchFocused || !trimmedQuery.isEmpty }

    private var matchedAccounts: [Artist] {
        guard !trimmedQuery.isEmpty else { return Array(catalog.prefix(16)) }
        let q = trimmedQuery.lowercased().replacingOccurrences(of: "@", with: "")
        return catalog.filter {
            $0.name.lowercased().contains(q)
            || $0.username.contains(q)
            || $0.storeName.lowercased().contains(q)
            || $0.tagline.lowercased().contains(q)
        }
    }

    private var matchedTags: [String] {
        let tags = Array(Set(
            catalog.flatMap(\.specialties) + ArtCategory.allCases.map(\.rawValue)
        )).sorted()
        guard !trimmedQuery.isEmpty else { return tags }
        let q = trimmedQuery.lowercased()
        return tags.filter { $0.lowercased().contains(q) }
    }

    private var matchedArt: [Artwork] {
        guard !trimmedQuery.isEmpty else { return discoverArt }
        let q = trimmedQuery.lowercased()
        return discoverArt.filter {
            $0.title.lowercased().contains(q)
            || $0.artistName.lowercased().contains(q)
            || $0.category.rawValue.lowercased().contains(q)
        }
    }

    private let grid = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                    if showSearch {
                        if !trimmedQuery.isEmpty { lanePicker }
                        searchPane
                    } else {
                        exploreGrid
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Artwork.self) { ArtworkDetailView(artwork: $0) }
            .navigationDestination(for: Artist.self) { artist in
                ArtistStoreView(artist: artist)
                    .picardoPushedScreen()
            }
        }
    }

    // MARK: Search bar — Instagram

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("Search", text: $query)
                    .font(.system(size: 16))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($searchFocused)
                    .submitLabel(.search)
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            if showSearch {
                Button("Cancel") {
                    query = ""
                    lane = .top
                    searchFocused = false
                }
                .font(.system(size: 16))
                .foregroundStyle(.primary)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .animation(.easeInOut(duration: 0.2), value: showSearch)
    }

    private var lanePicker: some View {
        HStack(spacing: 0) {
            ForEach(ExploreSearchLane.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { lane = item }
                } label: {
                    VStack(spacing: 8) {
                        Text(item.rawValue)
                            .font(.system(size: 15, weight: lane == item ? .semibold : .regular))
                            .foregroundStyle(lane == item ? .primary : .secondary)
                        Rectangle()
                            .fill(lane == item ? Color.primary : Color.clear)
                            .frame(height: 1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(.separator)).frame(height: 0.5)
        }
    }

    // MARK: Explore grid — Instagram 3-up

    private var exploreGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: grid, spacing: 1) {
                ForEach(Array(discoverArt.enumerated()), id: \.element.id) { index, artwork in
                    NavigationLink(value: artwork) {
                        Color(.systemGray5)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                ArtworkImage(artwork: artwork, contentMode: .fill, maxDimension: 700)
                            }
                            .clipped()
                            .overlay(alignment: .topTrailing) {
                                if reelTile(index) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.45), radius: 3)
                                        .padding(7)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 48)
        }
    }

    /// Every 10th tile reads as a Reel — taller, like Instagram Explore.
    private func reelTile(_ index: Int) -> Bool {
        index % 10 == 2 || index % 10 == 5
    }

    // MARK: Search pane

    @ViewBuilder
    private var searchPane: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                if trimmedQuery.isEmpty {
                    Text("Suggested")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 6)
                    accountRows(matchedAccounts)
                } else {
                    switch lane {
                    case .top:
                        accountRows(Array(matchedAccounts.prefix(8)))
                        photoHits
                    case .accounts:
                        accountRows(matchedAccounts)
                    case .tags:
                        tagRows
                    }
                }
            }
            .padding(.bottom, 48)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private func accountRows(_ artists: [Artist]) -> some View {
        Group {
            if artists.isEmpty {
                Text("No results found")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else {
                ForEach(Array(artists), id: \.username) { person in
                    InstagramAccountRow(
                        artist: person,
                        isFollowing: following.contains(person.name)
                    ) {
                        if following.contains(person.name) {
                            following.remove(person.name)
                        } else {
                            following.insert(person.name)
                        }
                    }
                }
            }
        }
    }

    private var photoHits: some View {
        LazyVGrid(columns: grid, spacing: 1) {
            ForEach(Array(matchedArt.prefix(18))) { artwork in
                NavigationLink(value: artwork) {
                    Color(.systemGray5)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            ArtworkImage(artwork: artwork, contentMode: .fill, maxDimension: 700)
                        }
                        .clipped()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }

    private var tagRows: some View {
        Group {
            if matchedTags.isEmpty {
                Text("No tags found")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else {
                ForEach(matchedTags, id: \.self) { tag in
                    HStack(spacing: 12) {
                        Image(systemName: "number")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 48, height: 48)
                            .background(Color(.systemGray6), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tag)
                                .font(.system(size: 15, weight: .semibold))
                            Text("Tag")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}


private struct InstagramAccountRow: View {
    let artist: Artist
    let isFollowing: Bool
    let onFollow: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(value: artist) {
                HStack(spacing: 12) {
                    ArtworkImage(imageName: artist.avatarImage, contentMode: .fill, maxDimension: 160)
                        .frame(width: 54, height: 54)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(artist.username)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.primary)
                            if artist.verified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.picardoSupport)
                            }
                        }
                        Text(artist.name)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text(artist.availableForCommissions ? "\(artist.storeName) · \(artist.followers)" : artist.followers)
                            .font(.system(size: 13))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.easeInOut(duration: 0.15), onFollow)
            } label: {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isFollowing ? Color.primary : Color.white)
                    .frame(width: 90, height: 32)
                    .background(
                        isFollowing
                            ? Color(.systemGray5)
                            : Color(red: 0.00, green: 0.584, blue: 0.965),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Category feed (marketplace lane)

struct ExploreCategoryFeedView: View {
    let category: ExploreBrowseCategory
    @Environment(WishlistStore.self) private var wishlist

    private var artworks: [Artwork] {
        category.filter(Artwork.samples)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ZStack {
            PicartdoBackground()
                .ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(artworks) { artwork in
                        NavigationLink(value: artwork) {
                            GoatGridCard(
                                artwork: artwork,
                                isSaved: wishlist.isLiked(artwork)
                            ) {
                                wishlist.toggle(artwork)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .picardoPushedScreen()
    }
}

// MARK: - Category card

struct ExploreCategoryHeroButton: View {
    let category: ExploreBrowseCategory
    var height: CGFloat = ExploreTokens.categoryCardHeight

    private var mediaShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
    }

    var body: some View {
        ArtworkImage(imageName: category.placeholderImageName, contentMode: .fill, maxDimension: 900)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Text(category.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .picardoGlass(in: Capsule(), interactive: true)
                }
                .padding(12)
            }
            .picardoGlassMedia(in: mediaShape)
            .accessibilityLabel("\(category.rawValue), \(category.marketplaceHint)")
    }
}

// MARK: - Masonry layout (category feeds + search)

struct PinterestMasonryGrid<Content: View>: View {
    let items: [Artwork]
    var spacing: CGFloat = 10
    @ViewBuilder let content: (Artwork) -> Content

    private var columns: [[Artwork]] {
        var left: [Artwork] = []
        var right: [Artwork] = []
        var leftH: CGFloat = 0
        var rightH: CGFloat = 0
        for art in items {
            let h = PinterestPinMetrics.estimatedHeight(for: art)
            if leftH <= rightH {
                left.append(art)
                leftH += h + spacing
            } else {
                right.append(art)
                rightH += h + spacing
            }
        }
        return [left, right]
    }

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<2, id: \.self) { column in
                LazyVStack(spacing: spacing) {
                    ForEach(columns[column]) { item in
                        content(item)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }
}

enum PinterestPinMetrics {
    static func aspectRatio(for artwork: Artwork) -> CGFloat {
        let size = ArtworkImageCache.shared.pixelSize(for: artwork)
        guard size.width > 0 else { return 1.0 }
        let raw = size.height / size.width
        return min(max(raw, 0.75), 1.45)
    }

    static func estimatedHeight(for artwork: Artwork) -> CGFloat {
        let columnWidth: CGFloat = 180
        return columnWidth * aspectRatio(for: artwork) + 44
    }
}

struct PinterestPinCard: View {
    let artwork: Artwork
    @Environment(WishlistStore.self) private var wishlist

    var body: some View {
        ArtworkCard(
            artwork: artwork,
            variant: .pinterest,
            isSaved: wishlist.isLiked(artwork),
            onSave: {
                withAnimation(ExploreTokens.springBounce) {
                    wishlist.toggle(artwork)
                }
            }
        )
    }
}

typealias ExploreArtCard = PinterestPinCard

struct ExploreArtworkImage: View {
    let name: String

    var body: some View {
        ArtworkImage(imageName: name, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ExploreSkeletonCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(white: 0.92))
            .frame(height: 200)
            .exploreShimmering()
            .accessibilityHidden(true)
    }
}

struct ExploreShimmerModifier: ViewModifier {
    @State private var animate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.35), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .rotationEffect(.degrees(10))
                    .offset(x: animate ? 500 : -500)
                }
            }
            .clipped()
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
    }
}

extension View {
    func exploreShimmering() -> some View { modifier(ExploreShimmerModifier()) }
}

struct ExploreCategoryBar: View {
    @Binding var selected: ArtCategory?
    let namespace: Namespace.ID

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(nil, "All")
                ForEach(ArtCategory.allCases) { category in
                    chip(category, category.rawValue)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private func chip(_ category: ArtCategory?, _ label: String) -> some View {
        let isSelected = selected == category
        return Button {
            withAnimation(ExploreTokens.snappy) { selected = category }
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(isSelected ? Color.picardoGold : Color.picardoCard))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExploreView()
        .environment(WishlistStore())
}
