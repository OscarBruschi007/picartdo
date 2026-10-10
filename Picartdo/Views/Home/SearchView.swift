import SwiftUI

// MARK: - Filter Model

struct ArtFilter {
    var colors:     Set<String> = []
    var shapes:     Set<String> = []
    var sizes:      Set<String> = []
    var dimensions: Set<String> = []
    var mediums:    Set<String> = []
    var priceRange: ClosedRange<Double> = 0...5000

    var isActive: Bool {
        !colors.isEmpty || !shapes.isEmpty || !sizes.isEmpty ||
        !dimensions.isEmpty || !mediums.isEmpty ||
        priceRange != 0...5000
    }

    var activeCount: Int {
        (colors.isEmpty     ? 0 : 1) + (shapes.isEmpty    ? 0 : 1) +
        (sizes.isEmpty      ? 0 : 1) + (dimensions.isEmpty ? 0 : 1) +
        (mediums.isEmpty    ? 0 : 1) + (priceRange == 0...5000 ? 0 : 1)
    }
}

// MARK: - Explore Data Models (all backed by real art assets)

struct ArtServiceItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let artistName: String
    let priceFrom: Double
    let rating: Double
    let reviewCount: Int
    let icon: String
    let imageName: String

    static let samples: [ArtServiceItem] = [
        ArtServiceItem(title: "Custom Portrait",  artistName: "Maya Chen",      priceFrom: 450,  rating: 4.9, reviewCount: 38, icon: "person.fill.viewfinder", imageName: "art_12"),
        ArtServiceItem(title: "Mural Design",     artistName: "Oscar Bruschi",  priceFrom: 1200, rating: 5.0, reviewCount: 12, icon: "building.2.fill",        imageName: "art_15"),
        ArtServiceItem(title: "Tattoo Flash",     artistName: "Leo Vega",       priceFrom: 200,  rating: 4.8, reviewCount: 67, icon: "pencil.tip",             imageName: "art_09"),
        ArtServiceItem(title: "Fine Art Framing", artistName: "Studio Noire",   priceFrom: 180,  rating: 4.7, reviewCount: 44, icon: "photo.artframe",         imageName: "art_22"),
        ArtServiceItem(title: "Live Painting",    artistName: "Rina Sato",      priceFrom: 800,  rating: 4.9, reviewCount: 21, icon: "paintbrush.pointed.fill",imageName: "art_19"),
        ArtServiceItem(title: "Digital Art",      artistName: "Dev Patel",      priceFrom: 300,  rating: 4.6, reviewCount: 53, icon: "laptopcomputer",         imageName: "art_05"),
        ArtServiceItem(title: "Art Photography",  artistName: "Sofia Park",     priceFrom: 550,  rating: 5.0, reviewCount: 29, icon: "camera.fill",            imageName: "art_07"),
        ArtServiceItem(title: "Restoration",      artistName: "Marcel Blanc",   priceFrom: 950,  rating: 4.8, reviewCount: 16, icon: "sparkles",               imageName: "art_11"),
        ArtServiceItem(title: "Sculpture Commission", artistName: "Mira Solano", priceFrom: 1400, rating: 4.9, reviewCount: 28, icon: "cube.fill",             imageName: "tagged_david"),
    ]
}

struct ArtEventItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let venue: String
    let city: String
    let month: String
    let day: Int
    let type: String
    let imageName: String
    let isOnline: Bool
    let distance: String
    let hoursUntil: Int?

    static let samples: [ArtEventItem] = [
        ArtEventItem(title: "Faces of the City", venue: "Cooper Cole", city: "Toronto, ON", month: "OCT", day: 11, type: "Exhibition", imageName: "red_dress_portrait", isOnline: false, distance: "1.4 mi", hoursUntil: nil),
        ArtEventItem(title: "Sculpture After Dark", venue: "MoCA Toronto", city: "Toronto, ON", month: "OCT", day: 17, type: "Opening", imageName: "tagged_david", isOnline: false, distance: "2.0 mi", hoursUntil: nil),
        ArtEventItem(title: "Colour Field Hang", venue: "Art Gallery of Ontario", city: "Toronto, ON", month: "OCT", day: 22, type: "Exhibition", imageName: "color_field", isOnline: false, distance: "1.1 mi", hoursUntil: nil),
        ArtEventItem(title: "Live Painting Night", venue: "The Drake Hotel", city: "Toronto, ON", month: "NOV", day: 1, type: "Live Painting", imageName: "electric_face", isOnline: false, distance: "0.8 mi", hoursUntil: nil),
        ArtEventItem(title: "Paper & People", venue: "Daniel Faria Gallery", city: "Toronto, ON", month: "NOV", day: 8, type: "Gallery Opening", imageName: "people_collage", isOnline: false, distance: "1.6 mi", hoursUntil: nil),
        ArtEventItem(title: "Studio Open House", venue: "Picartdo Studio", city: "Toronto, ON", month: "NOV", day: 14, type: "Open Studio", imageName: "circle_worlds", isOnline: false, distance: "2.4 mi", hoursUntil: nil),
    ]
}

struct ArtPlaceItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: String
    let city: String
    let imageName: String
    let isOpenNow: Bool
    let closeTime: String
    let distance: String

    static let samples: [ArtPlaceItem] = [
        ArtPlaceItem(name: "MoMA",                type: "Museum",        city: "New York, NY",    imageName: "art_09", isOpenNow: true,  closeTime: "Closes at 5:30 PM", distance: "1.8 mi"),
        ArtPlaceItem(name: "Gagosian Gallery",    type: "Gallery",       city: "New York, NY",    imageName: "art_22", isOpenNow: true,  closeTime: "Closes at 6 PM",    distance: "2.4 mi"),
        ArtPlaceItem(name: "Wynwood Walls",       type: "Gallery",       city: "Miami, FL",       imageName: "art_01", isOpenNow: false, closeTime: "Opens at 10 AM",    distance: "1,250 mi"),
        ArtPlaceItem(name: "The Broad",           type: "Museum",        city: "Los Angeles, CA", imageName: "art_12", isOpenNow: true,  closeTime: "Closes at 8 PM",    distance: "2,800 mi"),
        ArtPlaceItem(name: "Sotheby's",           type: "Auction House", city: "New York, NY",    imageName: "art_07", isOpenNow: true,  closeTime: "Closes at 5 PM",    distance: "3.1 mi"),
        ArtPlaceItem(name: "Oscar Bruschi Studio",type: "Artist Studio", city: "New York, NY",    imageName: "art_08", isOpenNow: false, closeTime: "By Appointment",    distance: "4.7 mi"),
    ]
}

// MARK: - Explore Tab Enum

enum ExploreTab: String, CaseIterable {
    case all      = "All"
    case art      = "Art"
    case artists  = "Artists"
    case services = "Services"
    case events   = "Events"
    case places   = "Places"

    var icon: String {
        switch self {
        case .all:      return "square.grid.2x2"
        case .art:      return "paintpalette"
        case .artists:  return "person.2"
        case .services: return "briefcase"
        case .events:   return "calendar"
        case .places:   return "mappin"
        }
    }
}

// MARK: - SearchView — Airbnb-style Explore

struct SearchView: View {
    @State private var query       = ""
    @State private var isSearching = false
    @State private var showFilter  = false
    @State private var filter      = ArtFilter()
    @State private var activeTab: ExploreTab = .all
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                if !isSearching {
                    categoryStrip
                    Rectangle().fill(Color(.systemGray5)).frame(height: 0.5)
                }

                if isSearching {
                    SearchResultsGrid(query: query, filter: filter)
                } else {
                    tabContent
                }
            }
            .background(Color.picardoBackground)
            .navigationBarHidden(true)
            .sheet(isPresented: $showFilter) { FilterSheetView(filter: $filter) }
            .navigationDestination(for: Artwork.self) { artwork in
                ArtworkDetailView(artwork: artwork)
            }
            .navigationDestination(for: Artist.self) { artist in
                ArtistStoreView(artist: artist)
            }
        }
    }

    // MARK: Search bar — quiet, integrated
    private var searchBar: some View {
        HStack(spacing: 0) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.picardoText)
                .padding(.leading, 16).padding(.trailing, 10)

            VStack(alignment: .leading, spacing: 1) {
                if query.isEmpty && !focused {
                    Text("Search artists, works, styles")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.picardoText)
                    Text("Instant · Visual · Curated")
                        .font(PicardoType.meta(9))
                        .kerning(0.8)
                        .foregroundStyle(Color.picardoTextSecondary)
                } else {
                    TextField("", text: $query,
                              prompt: Text("Artists, art, styles…")
                                  .foregroundStyle(Color.picardoTextSecondary).font(.system(size: 15)))
                        .foregroundStyle(Color.picardoText).tint(Color.picardoAccent).font(.system(size: 15, weight: .medium))
                        .focused($focused).submitLabel(.search).autocorrectionDisabled()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { focused = true }
            .onChange(of: query) { _, v in
                withAnimation(PicardoMotion.quick) {
                    isSearching = !v.trimmingCharacters(in: .whitespaces).isEmpty
                }
            }

            Spacer(minLength: 8)

            if !query.isEmpty {
                Button { query = ""; isSearching = false; focused = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.picardoTextSecondary).font(.system(size: 16))
                }
                .padding(.trailing, 10)
            }

            Button { showFilter = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.picardoText)
                        .frame(width: 34, height: 34)
                    if filter.activeCount > 0 {
                        Circle().fill(Color.picardoAccent).frame(width: 8, height: 8)
                            .offset(x: 2, y: -2)
                    }
                }
            }
            .padding(.trailing, 8)
        }
        .frame(height: 54)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.picardoSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(focused ? Color.picardoAccent.opacity(0.45) : Color.picardoBorder, lineWidth: 1)
                )
        )
        .animation(PicardoMotion.quick, value: focused)
    }

    // MARK: Category strip — icon above label, underline on selection
    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(ExploreTab.allCases, id: \.self) { tab in
                    let active = activeTab == tab
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { activeTab = tab }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 19, weight: active ? .semibold : .regular))
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: active ? .semibold : .regular))
                        }
                        .foregroundStyle(active ? .black : Color.gray)
                        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 10)
                        .overlay(alignment: .bottom) {
                            if active { Rectangle().fill(Color.black).frame(height: 2) }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
        }
    }

    // MARK: Tab content router
    @ViewBuilder
    private var tabContent: some View {
        switch activeTab {
        case .all:      AllTabContent()
        case .art:      ArtTabContent(filter: filter)
        case .artists:  ArtistsTabContent()
        case .services: ServicesTabContent()
        case .events:   EventsTabContent()
        case .places:   PlacesTabContent()
        }
    }
}

// MARK: - Airbnb-style Listing Card (shared across every tab)

struct ListingCard: View {
    let images: [String]
    var badge: String? = nil
    let title: String
    var verified: Bool = false
    let subtitle: String
    var subtitle2: String? = nil
    var rating: Double? = nil
    var reviewCount: Int? = nil
    let priceLabel: String
    var priceSuffix: String? = nil
    var listedArtwork: Artwork? = nil

    @State private var isSaved = false

    // Airbnb's actual card: no card box, no shadow, no border — just an
    // image with rounded corners sitting flush on the white page, and two
    // lines of text below it.
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Photo (true square, matching Airbnb's grid photos) ─────
            // GeometryReader gives us the card's actual width so we can force
            // a hard height == width square and avoid aspectRatio's letterboxing
            // with TabView (which was leaving a gray margin around the photo).
            listingArtworkLink {
            GeometryReader { geo in
                ArtworkImage(
                    imageName: images.first ?? "",
                    contentMode: .fill,
                    maxDimension: 900
                )
                .frame(width: geo.size.width, height: geo.size.width)
                .overlay {
                    VStack {
                        HStack {
                            if let badge {
                                Text(badge)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .picardoGlass(in: Capsule(), interactive: true)
                            }
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isSaved.toggle() }
                            } label: {
                                Image(systemName: isSaved ? "heart.fill" : "heart")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(isSaved ? Color.picardoGold : .primary)
                                    .frame(width: 36, height: 36)
                            }
                            .picardoGlass(in: Circle(), interactive: true)
                        }
                        Spacer()
                    }
                    .padding(12)
                }
                .picardoGlassMedia(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
            .aspectRatio(1, contentMode: .fit)
            }

            // ── Info — matches Airbnb's exact stacked-line order:
            // rating alone (top-right), title, subtitle(s), then bold price last.
            VStack(alignment: .leading, spacing: 2) {
                if let rating {
                    HStack {
                        Spacer()
                        Text("★ \(String(format: "%.1f", rating))")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }

                listingArtworkLink {
                    HStack(spacing: 4) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                        if verified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.picardoSupport)
                        }
                    }
                }

                if listedArtwork != nil {
                    ArtistNameLink(
                        name: subtitle,
                        font: .system(size: 14),
                        color: Color(.secondaryLabel)
                    )
                } else {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(.secondaryLabel))
                        .lineLimit(1)
                }

                if let subtitle2 {
                    Text(subtitle2)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(.secondaryLabel))
                        .lineLimit(1)
                }

                (Text(priceLabel).font(.system(size: 14, weight: .semibold)).foregroundStyle(.black)
                 + Text(priceSuffix != nil ? " \(priceSuffix!)" : "").font(.system(size: 14)).foregroundStyle(Color(.secondaryLabel)))
                    .padding(.top, 2)
                    .lineLimit(1)
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func listingArtworkLink<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if let listedArtwork {
            NavigationLink(value: listedArtwork, label: content)
                .buttonStyle(.plain)
        } else {
            content()
        }
    }
}

// MARK: - ListingCard convenience initializers (map every data model onto one card style)

extension ListingCard {
    init(artist: Artist) {
        self.init(
            images: artist.portfolioImages.isEmpty ? [artist.bannerImage] : Array(artist.portfolioImages.prefix(5)),
            badge: artist.availableForCommissions ? "Open for commissions" : nil,
            title: artist.name,
            verified: artist.verified,
            subtitle: artist.location,
            subtitle2: artist.tagline,
            rating: artist.rating,
            reviewCount: artist.reviewCount,
            priceLabel: "From \(artist.startingPrice)"
        )
    }

    init(artwork: Artwork) {
        self.init(
            images: [artwork.imageName],
            badge: artwork.isSold ? "Sold" : nil,
            title: artwork.title,
            verified: false,
            subtitle: artwork.artistName,
            subtitle2: artwork.medium,
            rating: nil,
            reviewCount: nil,
            priceLabel: artwork.price.formatted(.currency(code: "USD").precision(.fractionLength(0))),
            listedArtwork: artwork
        )
    }

    init(service: ArtServiceItem) {
        self.init(
            images: [service.imageName],
            badge: nil,
            title: service.title,
            verified: false,
            subtitle: service.artistName,
            subtitle2: nil,
            rating: service.rating,
            reviewCount: service.reviewCount,
            priceLabel: "From $\(Int(service.priceFrom))"
        )
    }

    init(event: ArtEventItem) {
        self.init(
            images: [event.imageName],
            badge: event.type,
            title: event.title,
            verified: false,
            subtitle: event.venue,
            subtitle2: event.city,
            rating: nil,
            reviewCount: nil,
            priceLabel: "\(event.month) \(event.day)",
            priceSuffix: event.isOnline ? "Online" : event.distance
        )
    }

    init(place: ArtPlaceItem) {
        self.init(
            images: [place.imageName],
            badge: place.isOpenNow ? "Open now" : nil,
            title: place.name,
            verified: false,
            subtitle: place.type,
            subtitle2: place.city,
            rating: nil,
            reviewCount: nil,
            priceLabel: place.distance,
            priceSuffix: place.isOpenNow ? nil : place.closeTime
        )
    }
}

// MARK: - ALL Tab

private struct AllTabContent: View {
    private let recent = ["Circle Worlds", "Oscar Bruschi", "Black & White", "Mandala"]
    private let trendingStyles = ["Abstract", "Ink", "Minimal", "Organic", "Digital"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 14) {
                    PicardoEyebrow(text: "Recent")
                    FlowRecentRow(items: recent)
                }

                VStack(alignment: .leading, spacing: 14) {
                    PicardoSectionHeader(title: "Trending Styles", eyebrow: "Discover")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(trendingStyles, id: \.self) { style in
                                Text(style.uppercased())
                                    .font(PicardoType.meta(10))
                                    .kerning(1)
                                    .foregroundStyle(Color.picardoText)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .overlay(Rectangle().strokeBorder(Color.picardoBorder, lineWidth: 1))
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    PicardoSectionHeader(title: "Trending Artists", eyebrow: "In focus")
                    ForEach(Artist.all.prefix(6)) { artist in
                        NavigationLink(value: artist) {
                            HStack(spacing: 14) {
                                ArtworkImage(imageName: artist.avatarImage, contentMode: .fill, maxDimension: 160)
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(artist.name)
                                        .font(PicardoType.body(15))
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.picardoText)
                                    Text(artist.tagline)
                                        .font(PicardoType.meta(9))
                                        .kerning(0.6)
                                        .foregroundStyle(Color.picardoTextSecondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(PicardoPressStyle())
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    PicardoSectionHeader(title: "Visual Suggestions", eyebrow: "Look")
                    let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                    LazyVGrid(columns: cols, spacing: 12) {
                        ForEach(Artwork.samples.prefix(6)) { art in
                            NavigationLink(value: art) {
                                ArtworkImage(artwork: art, contentMode: .fill)
                                    .frame(height: 160)
                                    .picardoGlassMedia(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                            }
                            .buttonStyle(PicardoPressStyle())
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 110)
        }
    }
}

private struct FlowRecentRow: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items, id: \.self) { item in
                HStack(spacing: 10) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.picardoTextSecondary)
                    Text(item)
                        .font(PicardoType.body(14))
                        .foregroundStyle(Color.picardoText)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - ART Tab

private struct ArtTabContent: View {
    let filter: ArtFilter
    @State private var selectedCategory: ArtCategory? = nil

    private let categories: [(String, ArtCategory?)] = [
        ("All", nil), ("Painting", .painting), ("Drawing", .drawing),
        ("Mixed", .mixedMedia), ("Photo", .photography), ("Digital", .digital), ("Sculpture", .sculpture)
    ]

    private var artworks: [Artwork] {
        var pool = Artwork.samples
        if let c = selectedCategory { pool = pool.filter { $0.category == c } }
        if filter.isActive {
            if !filter.mediums.isEmpty {
                pool = pool.filter { a in filter.mediums.contains { a.medium.lowercased().contains($0.lowercased()) } }
            }
            pool = pool.filter { filter.priceRange.contains($0.price) }
        }
        return pool
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.0) { label, cat in
                        let active = selectedCategory == cat
                        Button {
                            withAnimation(PicardoMotion.quick) { selectedCategory = cat }
                        } label: {
                            Text(label).font(.system(size: 13, weight: active ? .semibold : .medium))
                                .foregroundStyle(active ? .white : .black)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(active ? Color.black : Color(.systemGray6), in: Capsule())
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 28) {
                    ForEach(artworks) { artwork in
                        ListingCard(artwork: artwork)
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 110)
            }
        }
    }
}

// MARK: - ARTISTS Tab

private struct ArtistsTabContent: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 28) {
                ForEach(Artist.all.prefix(20)) { artist in
                    NavigationLink(value: artist) { ListingCard(artist: artist) }
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 110)
        }
    }
}

// MARK: - SERVICES Tab

private struct ServicesTabContent: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 28) {
                ForEach(ArtServiceItem.samples) { svc in
                    ListingCard(service: svc)
                }
            }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 110)
        }
    }
}

// MARK: - EVENTS Tab

private struct EventsTabContent: View {
    let events = ArtEventItem.samples
    let eventTypes = ["All", "Exhibition", "Opening", "Gallery Opening", "Live Painting", "Open Studio"]
    @State private var selectedType = "All"

    private var filtered: [ArtEventItem] {
        selectedType == "All" ? events : events.filter { $0.type == selectedType }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(eventTypes, id: \.self) { type in
                        let active = selectedType == type
                        Button { withAnimation { selectedType = type } } label: {
                            Text(type).font(.system(size: 13, weight: active ? .semibold : .medium))
                                .foregroundStyle(active ? .white : .black)
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(active ? Color.black : Color(.systemGray6), in: Capsule())
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 28) {
                    ForEach(filtered) { evt in ListingCard(event: evt) }
                }
                .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 110)
            }
        }
    }
}

// MARK: - PLACES Tab

private struct PlacesTabContent: View {
    let places = ArtPlaceItem.samples

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 28) {
                ForEach(places) { place in ListingCard(place: place) }
            }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 110)
        }
    }
}

// MARK: - Filter Section Header

struct FilterSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 13)).foregroundStyle(Color.picardoGold)
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(.black)
            }
            content()
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout<Item: Hashable, ItemView: View>: View {
    let items: [Item]
    @ViewBuilder let itemView: (Item) -> ItemView
    var body: some View { _FlowHStack(items: items, content: itemView) }
}

struct _FlowHStack<Item: Hashable, ItemView: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> ItemView
    var body: some View {
        GeometryReader { geo in self.generateContent(in: geo) }
            .frame(height: estimatedHeight)
    }
    private var estimatedHeight: CGFloat { CGFloat(Int(ceil(Double(items.count) / 3.0))) * 44 }
    private func generateContent(in geo: GeometryProxy) -> some View {
        var currentX: CGFloat = 0; var currentY: CGFloat = 0
        let spacing: CGFloat = 8; let rowHeight: CGFloat = 38
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item).fixedSize()
                    .alignmentGuide(.leading) { d in
                        if currentX + d.width > geo.size.width { currentX = 0; currentY += rowHeight + spacing }
                        let result = -currentX
                        if item == items.last { currentX = 0; currentY = 0 } else { currentX += d.width + spacing }
                        return result
                    }
                    .alignmentGuide(.top) { _ in -currentY }
            }
        }
    }
}

// MARK: - Filter Sheet

struct FilterSheetView: View {
    @Binding var filter: ArtFilter
    @Environment(\.dismiss) private var dismiss

    private let colorOptions: [(name: String, swatch: Color)] = [
        ("Red",    .red),   ("Orange", .orange), ("Yellow", Color(red:1,green:0.85,blue:0)),
        ("Green",  .green), ("Blue",   .blue),   ("Purple", .purple),
        ("Pink",   .pink),  ("Brown",  .brown),  ("Black",  Color(white:0.15)),
        ("White",  Color(white:0.9)), ("Gold",   Color.picardoGold),
    ]
    private let shapeOptions  = ["Abstract", "Portrait", "Landscape", "Geometric", "Circular", "Figurative", "Organic", "Minimalist"]
    private let sizeOptions   = ["Small", "Medium", "Large", "Extra Large"]
    private let dimOptions    = ["Square", "Vertical", "Horizontal", "Panoramic"]
    private let mediumOptions = ["Acrylic", "Oil", "Watercolor", "Ink", "Digital", "Mixed Media", "Pencil", "Spray"]
    @State private var priceMax: Double = 5000

    var body: some View {
        ZStack {
            Color.picardoBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color(.systemGray4)).frame(width: 36, height: 4).padding(.top, 12).padding(.bottom, 20)
                HStack {
                    Text("Filter").font(.system(size: 20, weight: .bold)).foregroundStyle(.black)
                    Spacer()
                    if filter.isActive {
                        Button { withAnimation { filter = ArtFilter(); priceMax = 5000 } } label: {
                            Text("Reset").font(.system(size: 14, weight: .medium)).foregroundStyle(Color.picardoGold)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 20)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        FilterSection(title: "Color", icon: "paintpalette.fill") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 12) {
                                ForEach(colorOptions, id: \.name) { c in
                                    let active = filter.colors.contains(c.name)
                                    Button {
                                        withAnimation(.spring(response: 0.25)) {
                                            if active { filter.colors.remove(c.name) } else { filter.colors.insert(c.name) }
                                        }
                                    } label: {
                                        VStack(spacing: 5) {
                                            Circle().fill(c.swatch).frame(width: 36, height: 36)
                                                .overlay(Circle().stroke(active ? Color.picardoGold : Color.black.opacity(0.12), lineWidth: active ? 2.5 : 1))
                                                .scaleEffect(active ? 1.1 : 1.0)
                                            Text(c.name).font(.system(size: 9)).foregroundStyle(active ? Color.picardoGold : Color.gray)
                                        }
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                        FilterSection(title: "Style", icon: "square.on.circle.fill") {
                            FlowLayout(items: shapeOptions) { shape in
                                let active = filter.shapes.contains(shape)
                                Button {
                                    withAnimation(.spring(response: 0.25)) {
                                        if active { filter.shapes.remove(shape) } else { filter.shapes.insert(shape) }
                                    }
                                } label: {
                                    Text(shape).font(.system(size: 13, weight: active ? .semibold : .regular))
                                        .foregroundStyle(active ? .white : .black.opacity(0.8))
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(active ? Color.black : Color(.systemGray6), in: Capsule())
                                }.buttonStyle(.plain)
                            }
                        }
                        FilterSection(title: "Size", icon: "arrow.up.left.and.arrow.down.right") {
                            HStack(spacing: 10) {
                                ForEach(sizeOptions, id: \.self) { size in
                                    let active = filter.sizes.contains(size)
                                    Button {
                                        withAnimation(.spring(response: 0.25)) {
                                            if active { filter.sizes.remove(size) } else { filter.sizes.insert(size) }
                                        }
                                    } label: {
                                        VStack(spacing: 6) {
                                            let sz: CGFloat = size == "Small" ? 20 : size == "Medium" ? 28 : size == "Large" ? 36 : 44
                                            RoundedRectangle(cornerRadius: 4).fill(active ? Color.picardoGold : Color(.systemGray5)).frame(width: sz, height: sz)
                                            Text(size).font(.system(size: 11, weight: active ? .semibold : .regular)).foregroundStyle(active ? Color.picardoGold : Color.gray)
                                        }
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(active ? Color.picardoGold.opacity(0.10) : Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(active ? Color.picardoGold.opacity(0.5) : Color.clear, lineWidth: 1))
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                        FilterSection(title: "Orientation", icon: "rectangle.on.rectangle.fill") {
                            HStack(spacing: 10) {
                                ForEach(dimOptions, id: \.self) { dim in
                                    let active = filter.dimensions.contains(dim)
                                    Button {
                                        withAnimation(.spring(response: 0.25)) {
                                            if active { filter.dimensions.remove(dim) } else { filter.dimensions.insert(dim) }
                                        }
                                    } label: {
                                        VStack(spacing: 6) {
                                            let w: CGFloat = dim == "Vertical" ? 20 : dim == "Horizontal" ? 40 : dim == "Panoramic" ? 52 : 30
                                            let h: CGFloat = dim == "Vertical" ? 36 : dim == "Horizontal" ? 22 : dim == "Panoramic" ? 18 : 30
                                            RoundedRectangle(cornerRadius: 3).fill(active ? Color.picardoGold : Color(.systemGray5)).frame(width: w, height: h)
                                            Text(dim).font(.system(size: 10, weight: active ? .semibold : .regular)).foregroundStyle(active ? Color.picardoGold : Color.gray)
                                        }
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(active ? Color.picardoGold.opacity(0.10) : Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(active ? Color.picardoGold.opacity(0.5) : Color.clear, lineWidth: 1))
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                        FilterSection(title: "Medium", icon: "paintbrush.pointed.fill") {
                            FlowLayout(items: mediumOptions) { med in
                                let active = filter.mediums.contains(med)
                                Button {
                                    withAnimation(.spring(response: 0.25)) {
                                        if active { filter.mediums.remove(med) } else { filter.mediums.insert(med) }
                                    }
                                } label: {
                                    Text(med).font(.system(size: 13, weight: active ? .semibold : .regular))
                                        .foregroundStyle(active ? .white : .black.opacity(0.8))
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(active ? Color.black : Color(.systemGray6), in: Capsule())
                                }.buttonStyle(.plain)
                            }
                        }
                        FilterSection(title: "Max Price: $\(Int(priceMax))", icon: "dollarsign.circle.fill") {
                            VStack(spacing: 8) {
                                Slider(value: $priceMax, in: 100...5000, step: 100).tint(Color.picardoGold)
                                    .onChange(of: priceMax) { _, v in filter.priceRange = 0...v }
                                HStack {
                                    Text("$100").font(.system(size: 11)).foregroundStyle(Color.gray)
                                    Spacer()
                                    Text("$5,000").font(.system(size: 11)).foregroundStyle(Color.gray)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 32)
                }
                Button { dismiss() } label: {
                    HStack {
                        Text("Show Results").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                        if filter.isActive {
                            Text("· \(filter.activeCount) filter\(filter.activeCount == 1 ? "" : "s")")
                                .font(.system(size: 14, weight: .medium)).foregroundStyle(.white.opacity(0.75))
                        }
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 20).padding(.bottom, 32)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onAppear { priceMax = filter.priceRange.upperBound }
    }
}

// MARK: - Search Results Grid (as-you-type)

struct SearchResultsGrid: View {
    let query: String
    let filter: ArtFilter
    private let gap: CGFloat = 4

    private var results: [Artwork] {
        var pool = Artwork.samples
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        if !q.isEmpty {
            pool = pool.filter {
                $0.title.lowercased().contains(q) || $0.artistName.lowercased().contains(q) ||
                $0.category.rawValue.lowercased().contains(q) || $0.medium.lowercased().contains(q)
            }
        }
        if !filter.mediums.isEmpty {
            pool = pool.filter { artwork in filter.mediums.contains { m in artwork.medium.lowercased().contains(m.lowercased()) } }
        }
        pool = pool.filter { filter.priceRange.contains($0.price) }
        return pool
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if results.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "magnifyingglass").font(.system(size: 44)).foregroundStyle(Color(.systemGray4))
                    Text("No results").font(.system(size: 15)).foregroundStyle(Color.gray)
                }
                .frame(maxWidth: .infinity).padding(.top, 80)
            } else {
                HStack {
                    Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.gray)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 6)
                let size = (UIScreen.main.bounds.width - gap * 2) / 3
                LazyVGrid(columns: [GridItem(.fixed(size), spacing: gap), GridItem(.fixed(size), spacing: gap), GridItem(.fixed(size), spacing: gap)], spacing: gap) {
                    ForEach(results) { artwork in
                        NavigationLink(value: artwork) {
                            ZStack(alignment: .bottomLeading) {
                                ArtworkImage(artwork: artwork, contentMode: .fill)
                                    .frame(width: size, height: size)
                                    .clipped()
                                LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .bottom, endPoint: .center)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(artwork.title).font(.system(size: 10, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                                    Text(artwork.price, format: .currency(code: "USD").precision(.fractionLength(0)))
                                        .font(.system(size: 9, weight: .bold)).foregroundStyle(.white.opacity(0.9))
                                }
                                .padding(6)
                            }
                            .frame(width: size, height: size)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview { SearchView() }
