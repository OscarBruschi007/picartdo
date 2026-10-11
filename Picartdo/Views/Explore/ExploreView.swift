import SwiftUI

// MARK: - Explore — Instagram search + photo grid

private enum ExploreSearchLane: String, CaseIterable, Identifiable {
    case top = "Top"
    case accounts = "Accounts"
    case art = "Art"
    case services = "Services"
    case categories = "Categories"
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

    private func hits(_ q: String, _ parts: String...) -> Bool {
        parts.joined(separator: " ").lowercased().contains(q)
    }

    private var matchedAccounts: [Artist] {
        guard !trimmedQuery.isEmpty else { return Array(catalog.prefix(16)) }
        let q = trimmedQuery.lowercased().replacingOccurrences(of: "@", with: "")
        return catalog.filter {
            hits(q, $0.name, $0.username, $0.storeName, $0.tagline, $0.bio, $0.location)
                || $0.specialties.contains { $0.lowercased().contains(q) }
        }
    }

    private var matchedArt: [Artwork] {
        let pool = Artwork.samples
        guard !trimmedQuery.isEmpty else { return Array(discoverArt.prefix(18)) }
        let q = trimmedQuery.lowercased()
        return pool.filter {
            hits(q, $0.title, $0.artistName, $0.category.rawValue, $0.medium, $0.description, $0.dimensions)
        }
    }

    private var matchedServices: [ServiceCategory] {
        let q = trimmedQuery.lowercased()
        let pool = ServiceCategory.allCases
        guard !q.isEmpty else { return Array(pool.prefix(8)) }
        return pool.filter {
            hits(q, $0.rawValue, $0.introLine)
                || $0.matchKeys.contains { key in key.contains(q) || q.contains(key) }
        }
    }

    private var matchedServiceListings: [Service] {
        let q = trimmedQuery.lowercased()
        guard !q.isEmpty else { return [] }
        return Service.samples.filter {
            hits(q, $0.title, $0.providerName, $0.description, $0.category.rawValue, $0.priceDisplay)
                || $0.tags.contains { $0.lowercased().contains(q) }
        }
    }

    private var matchedServiceOffers: [ArtServiceItem] {
        let q = trimmedQuery.lowercased()
        guard !q.isEmpty else { return [] }
        return ArtServiceItem.samples.filter {
            hits(q, $0.title, $0.artistName)
        }
    }

    private var matchedCategories: [ExploreBrowseCategory] {
        let q = trimmedQuery.lowercased()
        let pool = ExploreBrowseCategory.allCases
        guard !q.isEmpty else { return pool }
        return pool.filter {
            hits(q, $0.rawValue, $0.marketplaceHint)
                || $0.linkedArtCategory?.rawValue.lowercased().contains(q) == true
        }
    }

    private var matchedArtCategories: [ArtCategory] {
        let q = trimmedQuery.lowercased()
        guard !q.isEmpty else { return [] }
        let covered = Set(ExploreBrowseCategory.allCases.compactMap(\.linkedArtCategory))
        return ArtCategory.allCases.filter {
            !covered.contains($0) && hits(q, $0.rawValue)
        }
    }

    private var matchedEvents: [ArtEventItem] {
        let q = trimmedQuery.lowercased()
        guard !q.isEmpty else { return [] }
        return ArtEventItem.samples.filter {
            hits(q, $0.title, $0.venue, $0.city, $0.type)
        }
    }

    private var matchedPlaces: [ArtPlaceItem] {
        let q = trimmedQuery.lowercased()
        guard !q.isEmpty else { return [] }
        return ArtPlaceItem.samples.filter {
            hits(q, $0.name, $0.type, $0.city)
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
            }
            .navigationDestination(for: ServiceCategory.self) { category in
                CategoryServicesView(category: category)
                    .picardoPushedScreen()
            }
            .navigationDestination(for: ExploreBrowseCategory.self) { category in
                ExploreCategoryFeedView(category: category)
            }
            .navigationDestination(for: ArtEventItem.self) { event in
                CityEventDetailView(event: event)
                    .picardoPushedScreen()
            }
            .navigationDestination(for: ArtCategory.self) { category in
                ExploreArtCategoryFeedView(category: category)
            }
            .navigationDestination(for: Service.self) { listing in
                CategoryServicesView(category: listing.category)
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
                TextField("Search art, artists, services, categories", text: $query)
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
        ScrollView(.horizontal, showsIndicators: false) {
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
                        .padding(.horizontal, 14)
                    }
                    .buttonStyle(.plain)
                }
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
                    sectionTitle("Suggested")
                    accountRows(matchedAccounts)
                } else {
                    switch lane {
                    case .top:
                        topHits
                    case .accounts:
                        accountRows(matchedAccounts)
                    case .art:
                        if matchedArt.isEmpty { emptyLine("No art found") } else { photoHits }
                    case .services:
                        serviceRows(matchedServices)
                        serviceListingRows
                        serviceOfferRows
                    case .categories:
                        categoryRows(matchedCategories)
                        artCategoryRows
                    }
                }
            }
            .padding(.bottom, 48)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    @ViewBuilder
    private var topHits: some View {
        let empty = matchedCategories.isEmpty
            && matchedArtCategories.isEmpty
            && matchedServices.isEmpty
            && matchedServiceListings.isEmpty
            && matchedServiceOffers.isEmpty
            && matchedAccounts.isEmpty
            && matchedArt.isEmpty
            && matchedEvents.isEmpty
            && matchedPlaces.isEmpty
        if empty {
            emptyLine("No results found")
        } else {
            if !matchedCategories.isEmpty || !matchedArtCategories.isEmpty {
                sectionTitle("Categories")
                categoryRows(matchedCategories)
                artCategoryRows
            }
            if !matchedServices.isEmpty || !matchedServiceListings.isEmpty || !matchedServiceOffers.isEmpty {
                sectionTitle("Services")
                serviceRows(matchedServices)
                serviceListingRows
                serviceOfferRows
            }
            if !matchedAccounts.isEmpty {
                sectionTitle("Artists")
                accountRows(Array(matchedAccounts.prefix(8)))
            }
            if !matchedArt.isEmpty {
                sectionTitle("Art")
                photoHits
            }
            if !matchedEvents.isEmpty {
                sectionTitle("Events")
                eventRows
            }
            if !matchedPlaces.isEmpty {
                sectionTitle("Places")
                placeRows
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)
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

    private func categoryRows(_ categories: [ExploreBrowseCategory]) -> some View {
        Group {
            if categories.isEmpty && matchedArtCategories.isEmpty {
                emptyLine("No categories found")
            } else {
                ForEach(categories) { category in
                    NavigationLink(value: category) {
                        searchKindRow(
                            icon: category.iconName,
                            title: category.rawValue,
                            detail: "Category"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func serviceRows(_ services: [ServiceCategory]) -> some View {
        Group {
            if services.isEmpty && matchedServiceListings.isEmpty && matchedServiceOffers.isEmpty {
                emptyLine("No services found")
            } else {
                ForEach(services) { service in
                    NavigationLink(value: service) {
                        searchKindRow(
                            icon: service.iconName,
                            title: service.rawValue,
                            detail: "Service"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var serviceListingRows: some View {
        ForEach(matchedServiceListings) { listing in
            NavigationLink(value: listing) {
                searchKindRow(
                    icon: listing.imageName,
                    title: listing.title,
                    detail: "\(listing.providerName) · \(listing.priceDisplay)"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var serviceOfferRows: some View {
        ForEach(matchedServiceOffers) { offer in
            NavigationLink(value: serviceCategory(for: offer)) {
                searchKindRow(
                    icon: offer.icon,
                    title: offer.title,
                    detail: "\(offer.artistName) · From $\(Int(offer.priceFrom))"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func serviceCategory(for offer: ArtServiceItem) -> ServiceCategory {
        let t = offer.title.lowercased()
        if t.contains("tattoo") { return .tattoo }
        if t.contains("mural") { return .mural }
        if t.contains("digital") { return .digitalArt }
        if t.contains("restoration") { return .restoration }
        if t.contains("sculpture") { return .sculpture }
        if t.contains("live") { return .liveEvent }
        if t.contains("photo") { return .paintingService }
        return .paintingService
    }

    private var artCategoryRows: some View {
        ForEach(matchedArtCategories) { category in
            NavigationLink(value: category) {
                searchKindRow(
                    icon: category.iconName,
                    title: category.rawValue,
                    detail: "Category"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var eventRows: some View {
        ForEach(matchedEvents) { event in
            NavigationLink(value: event) {
                searchKindRow(
                    icon: "calendar",
                    title: event.title,
                    detail: "\(event.type) · \(event.venue)"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var placeRows: some View {
        ForEach(matchedPlaces) { place in
            searchKindRow(
                icon: "mappin",
                title: place.name,
                detail: "\(place.type) · \(place.city)"
            )
        }
    }

    private func searchKindRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
                .background(Color(.systemGray6), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func emptyLine(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
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

struct ExploreArtCategoryFeedView: View {
    let category: ArtCategory
    @Environment(WishlistStore.self) private var wishlist

    private var artworks: [Artwork] {
        Artwork.samples.filter { $0.category == category }
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
    /// Polaroid well is square, plus the white lip and caption.
    static func aspectRatio(for artwork: Artwork) -> CGFloat {
        _ = artwork
        return 1
    }

    static func estimatedHeight(for artwork: Artwork) -> CGFloat {
        _ = artwork
        let columnWidth: CGFloat = 180
        return columnWidth + 26 + 44
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
