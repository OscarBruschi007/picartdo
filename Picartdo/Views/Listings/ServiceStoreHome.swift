import SwiftUI

// MARK: - Service store home
//
// One layout for every service category: a compact header, search and filters,
// then a vertical list of service cards. Only the copy and the photos change.
//
// Photo slots — drop images into Assets.xcassets with these names and they
// appear automatically, no code changes needed. `{slug}` is the category's
// asset prefix (tattoo, mural, ceramics, digitalArt…; see `ServiceCategory.assetSlug`):
//   {slug}_hero            hero image (already in the catalog for every category)
//   {slug}_hero.mp4        optional looping hero video in Resources/
//   {slug}_studio_01…09    studio and work photos; store cards use these first
// Until those exist, cards fall back to each artist's portfolio photos.

/// Studio photos for a service category, by asset-name convention.
enum ServiceGallery {
    private static let cacheLock = NSLock()
    private static var studioCache: [String: [String]] = [:]
    private static var heroCache: [String: String] = [:]

    /// The photo a store card leads with: a category studio photo when one exists,
    /// otherwise the artist's own cover.
    static func coverPhoto(for artist: Artist, in category: ServiceCategory) -> String {
        if category == .wallpaper {
            // Wallpaper studios show wallpapers, never other artwork.
            let pack = WallpaperPack.waves.images
            let seed = artist.name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
            return pack[seed % pack.count]
        }
        return studioPhoto(for: artist, in: category) ?? artist.storePhotos.first ?? artist.serviceCoverName
    }

    /// Hero still: `{slug}_studio_01` when present, otherwise `{slug}_hero`.
    /// The asset lookup is cached so scrolling does not call `UIImage(named:)` per card.
    static func heroPhoto(for category: ServiceCategory) -> String {
        let key = category.id
        cacheLock.lock()
        if let cached = heroCache[key] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        let resolved: String
        if category == .wallpaper {
            resolved = "wave_rainbow"
        } else {
            let studio = "\(category.assetSlug)_studio_01"
            resolved = UIImage(named: studio) != nil ? studio : category.heroImageName
        }
        cacheLock.lock()
        heroCache[key] = resolved
        cacheLock.unlock()
        return resolved
    }

    /// A studio photo for this artist among `{slug}_studio_02…09`, the same one on every launch.
    static func studioPhoto(for artist: Artist, in category: ServiceCategory) -> String? {
        if category == .tattoo { return tattooPhotos[artist.name] ?? "tattoo_studio_04" }
        let available = cachedStudioPhotos(slug: category.assetSlug)
        guard !available.isEmpty else { return nil }
        // Deterministic pick: `hashValue` changes between launches.
        let seed = artist.name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return available[seed % available.count]
    }

    /// Resolves which studio assets exist once per category, not once per row.
    private static func cachedStudioPhotos(slug: String) -> [String] {
        cacheLock.lock()
        if let cached = studioCache[slug] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        let available = (2...9)
            .map { String(format: "%@_studio_%02d", slug, $0) }
            .filter { UIImage(named: $0) != nil }
        cacheLock.lock()
        studioCache[slug] = available
        cacheLock.unlock()
        return available
    }

    /// Hand-picked tattoo studio photos per artist.
    private static let tattooPhotos: [String: String] = [
        "Raf Torres": "tattoo_studio_03",
        "Jake Morrison": "tattoo_studio_02",
        "Kim Soo-Yeon": "tattoo_studio_06",
        "Nadia Petrov": "tattoo_studio_07",
        "Tomas Bauer": "tattoo_studio_05",
        "Aiko Yamamoto": "tattoo_studio_08",
    ]
}

extension ServiceCategory {
    /// Asset-name prefix for this category's photos, e.g. `mural` for `mural_hero`.
    var assetSlug: String {
        heroImageName.hasSuffix("_hero") ? String(heroImageName.dropLast(5)) : heroImageName
    }

    /// What a business in this category is called on its store home.
    var storeNoun: String {
        switch self {
        case .tattoo:                        return "stores"
        case .classes, .kidsWorkshop:        return "workshops"
        case .liveEvent:                     return "venues"
        default:                             return "studios"
        }
    }

    /// Hero title, e.g. "Tattoo stores", "Mural studios".
    var storeTitle: String {
        switch self {
        case .tattoo:          return "Tattoo stores"
        case .digitalArt:      return "Digital art studios"
        case .mural:           return "Mural studios"
        case .wallpaper:       return "Wallpaper studios"
        case .fashion:         return "Wearable art studios"
        case .paintingService: return "Painting studios"
        case .liveEvent:       return "Exhibitions & events"
        case .classes:         return "Art workshops"
        case .sculpture:       return "Sculpture studios"
        case .ceramics:        return "Ceramics studios"
        case .kidsWorkshop:    return "Kids workshops"
        case .restoration:     return "Restoration studios"
        }
    }

    /// One line under the hero title.
    var storeTagline: String {
        switch self {
        case .tattoo:          return "Studios you can book for custom ink."
        case .digitalArt:      return "Illustrators and designers taking commissions."
        case .mural:           return "Artists who paint walls, rooms and whole buildings."
        case .wallpaper:       return "Pattern designers for rooms, quiet or loud."
        case .fashion:         return "Garments and textiles made to order."
        case .paintingService: return "Commission a portrait, landscape or interior."
        case .liveEvent:       return "What's on in Toronto, with tickets in one tap."
        case .classes:         return "Sit down, pick up a brush, take something home."
        case .sculpture:       return "Bronze, stone, wood and clay, made to commission."
        case .ceramics:        return "Working kilns for vessels, tiles and tableware."
        case .kidsWorkshop:    return "Rooms where kids make something they keep."
        case .restoration:     return "Conservators for paintings, paper and frames."
        }
    }
}


// MARK: - Motion
//
// One spring for the Services flow. Nothing here runs longer than 0.4s.
// Reduce Motion falls back to a short fade.

enum ServicesMotion {
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.85)

    static func animation(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.2) : spring
    }
}

enum ServiceDeliveryFilter: String, CaseIterable, Identifiable {
    case any = "Any"
    case underWeek = "Under a week"
    case oneToTwo = "1–2 weeks"
    case twoToFour = "2–4 weeks"
    case fourToSix = "4–6 weeks"
    case session = "By session"

    var id: String { rawValue }

    func matches(_ deliveryText: String) -> Bool {
        switch self {
        case .any:
            return true
        case .underWeek:
            return deliveryText.localizedCaseInsensitiveContains("day")
        case .oneToTwo:
            return deliveryText == "1–2 weeks"
        case .twoToFour:
            return deliveryText == "2–4 weeks"
        case .fourToSix:
            return deliveryText == "4–6 weeks"
        case .session:
            let text = deliveryText.lowercased()
            return text.contains("min") || text.contains("hour")
        }
    }
}

/// A service category's home: compact header, filters, and a vertical list of services.
struct ServiceStoreHomeView: View {
    let category: ServiceCategory

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var searchText = ""
    @State private var chip = ServiceListChip.all
    @State private var saved: Set<String> = []
    @State private var isLoading = true
    @State private var showFilters = false
    @State private var appliedMin: Double = 0
    @State private var appliedMax: Double = 1_000_000
    @State private var appliedType = "Any"
    @State private var appliedDelivery = ServiceDeliveryFilter.any

    private let tabBarClearance: CGFloat = 120

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var categoryListings: [ServiceListing] {
        ServiceCatalog.browseListings(in: category)
    }

    /// Chips other than All, and search, replace the shelves with one grid.
    private var showsGrid: Bool {
        chip != .all || !trimmedQuery.isEmpty
    }

    private var shelves: [ServiceShelf] {
        let pool = filtered
        let rows: [(String, [ServiceListing])] = [
            ("New on Picartdo", pool.filter { $0.reviewCount == 0 }),
            ("Available now", pool.filter(\.isAvailableNow)),
            ("Near you", pool.filter(\.isNearby)),
            ("Under $100", pool.filter { $0.priceAmount < 100 })
        ]
        return rows.compactMap { title, items in
            items.isEmpty ? nil : ServiceShelf(title: title, listings: items)
        }
    }

    private var priceBounds: ClosedRange<Double> {
        let prices = categoryListings.map { Double($0.priceAmount) }
        guard let low = prices.min(), let high = prices.max() else { return 0...1 }
        if high <= low { return low...(low + 1) }
        return low...high
    }

    private var serviceTypes: [String] {
        Array(Set(categoryListings.map(\.serviceType))).sorted()
    }

    private var filtersAreNarrowed: Bool {
        let bounds = priceBounds
        let minMoved = appliedMin > bounds.lowerBound + 0.5
        let maxMoved = appliedMax < bounds.upperBound - 0.5 && appliedMax < 999_999
        return minMoved || maxMoved || appliedType != "Any" || appliedDelivery != .any
    }

    private var filtered: [ServiceListing] {
        let query = trimmedQuery.lowercased()
        return categoryListings.filter { listing in
            if !query.isEmpty {
                let hit = listing.title.lowercased().contains(query)
                    || listing.artist.name.lowercased().contains(query)
                    || listing.artist.location.lowercased().contains(query)
                    || listing.serviceType.lowercased().contains(query)
                    || listing.artist.specialties.contains { $0.lowercased().contains(query) }
                if !hit { return false }
            }
            switch chip {
            case .all:
                break
            case .nearby:
                if !listing.isNearby { return false }
            case .top:
                if listing.reviewCount == 0 || listing.rating < 4.8 { return false }
            case .available:
                if !listing.isAvailableNow { return false }
            }
            if Double(listing.priceAmount) < appliedMin - 0.5 { return false }
            if Double(listing.priceAmount) > appliedMax + 0.5 { return false }
            if appliedType != "Any", listing.serviceType != appliedType { return false }
            if !appliedDelivery.matches(listing.deliveryText) { return false }
            return true
        }
    }

    private var resultKey: String {
        filtered.map(\.id).joined(separator: "|")
    }

    var body: some View {
        GeometryReader { geo in
            let cardWidth = max(120, (geo.size.width - 88) / 2)
            ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header

                if category == .liveEvent {
                    ExhibitionsServiceSection()
                        .padding(.top, 8)
                        .padding(.bottom, tabBarClearance)
                } else {
                    searchAndFilters
                        .padding(.top, 14)

                    Group {
                        if isLoading {
                            skeleton(cardWidth: cardWidth)
                                .padding(.top, 18)
                                .transition(.opacity)
                        } else {
                            loadedList(cardWidth: cardWidth)
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeOut(duration: reduceMotion ? 0.2 : 0.25), value: isLoading)
                    .padding(.bottom, tabBarClearance)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.picardoBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showFilters) {
            ServiceFiltersSheet(
                priceBounds: priceBounds,
                serviceTypes: serviceTypes,
                minPrice: $appliedMin,
                maxPrice: $appliedMax,
                type: $appliedType,
                delivery: $appliedDelivery
            )
        }
        .navigationDestination(for: StudioDestination.self) { destination in
            StudioPage(destination: destination)
        }
        .navigationDestination(for: ServiceShelf.self) { shelf in
            ServiceShelfGrid(shelf: shelf, saved: $saved)
        }
        .task(id: category.id) {
            guard category != .liveEvent else {
                isLoading = false
                return
            }
            isLoading = true
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            isLoading = false
        }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                Haptics.tap()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.picardoText)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 2) {
                Text(category.tileTitle)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color.picardoText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(category.storeTagline)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: 120, alignment: .leading)
    }

    private var searchAndFilters: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search services, artists, styles", text: $searchText)
                    .font(.system(size: 15))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(Color(.systemBackground), in: Capsule())
            .shadow(color: .black.opacity(0.10), radius: 6, y: 2)
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ServiceListChip.allCases) { item in
                        Button {
                            Haptics.select()
                            withAnimation(ServicesMotion.animation(reduceMotion: reduceMotion)) {
                                chip = item
                            }
                        } label: {
                            Text(item.rawValue)
                                .font(.system(size: 13, weight: chip == item ? .semibold : .regular))
                                .foregroundStyle(chip == item ? Color(.systemBackground) : Color.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(chip == item ? Color.primary : Color(.systemGray6), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    Button {
                        Haptics.tap()
                        showFilters = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 12, weight: .medium))
                            Text("Filters")
                                .font(.system(size: 13, weight: filtersAreNarrowed ? .semibold : .regular))
                        }
                        .foregroundStyle(filtersAreNarrowed ? Color(.systemBackground) : Color.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(filtersAreNarrowed ? Color.primary : Color(.systemGray6), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Filters")
                }
                .padding(.horizontal, 16)
                .animation(ServicesMotion.animation(reduceMotion: reduceMotion), value: chip)
                .animation(ServicesMotion.animation(reduceMotion: reduceMotion), value: filtersAreNarrowed)
            }
        }
    }

    @ViewBuilder
    private func loadedList(cardWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            if category == .wallpaper {
                WallpaperPackSection(pack: .waves)
            }

            if categoryListings.isEmpty {
                PicartdoEmptyState(
                    icon: "paintbrush.pointed",
                    title: "No services here yet.",
                    message: "Be the first to offer one."
                )
                .padding(.top, 24)
            } else if filtered.isEmpty {
                PicartdoEmptyState(
                    icon: "magnifyingglass",
                    title: trimmedQuery.isEmpty ? "No matches" : "No matches for \u{201C}\(trimmedQuery)\u{201D}",
                    message: "Try another search or filter."
                )
                .padding(.top, 24)
            } else if showsGrid {
                ServiceCardGrid(listings: filtered, saved: $saved, onToggle: toggle)
                    .padding(.top, 8)
                    .animation(ServicesMotion.animation(reduceMotion: reduceMotion), value: resultKey)
            } else {
                ForEach(shelves) { shelf in
                    shelfRow(shelf, cardWidth: cardWidth)
                }
            }
        }
    }

    private func shelfRow(_ shelf: ServiceShelf, cardWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Text(shelf.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.picardoText)
                    .lineLimit(1)
                Spacer(minLength: 8)
                NavigationLink(value: shelf) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.picardoText)
                        .frame(width: 36, height: 36)
                        .background(Color.picardoCard, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("See all \(shelf.title)")
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(shelf.listings) { listing in
                        ServiceListingCard(
                            listing: listing,
                            isSaved: saved.contains(listing.id),
                            onSave: { toggle(listing.id) }
                        )
                        .frame(width: cardWidth)
                        .scrollTransition(.animated(ServicesMotion.animation(reduceMotion: reduceMotion)), axis: .horizontal) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0.35)
                                .offset(x: (reduceMotion || phase.isIdentity) ? 0 : 12)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func skeleton(cardWidth: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.picardoCardMid)
                            .frame(width: cardWidth, height: cardWidth)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.picardoCardMid)
                            .frame(width: cardWidth * 0.8, height: 14)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.picardoCardMid)
                            .frame(width: cardWidth * 0.55, height: 12)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .accessibilityLabel("Loading services")
    }

    private func toggle(_ id: String) {
        if saved.contains(id) { saved.remove(id) } else { saved.insert(id) }
    }
}

private enum ServiceListChip: String, CaseIterable, Identifiable {
    case all = "All"
    case nearby = "Nearby"
    case top = "Top rated"
    case available = "Available now"
    var id: String { rawValue }
}

private struct ServiceFiltersSheet: View {
    let priceBounds: ClosedRange<Double>
    let serviceTypes: [String]
    @Binding var minPrice: Double
    @Binding var maxPrice: Double
    @Binding var type: String
    @Binding var delivery: ServiceDeliveryFilter

    @Environment(\.dismiss) private var dismiss
    @State private var draftMin: Double
    @State private var draftMax: Double
    @State private var draftType: String
    @State private var draftDelivery: ServiceDeliveryFilter

    init(
        priceBounds: ClosedRange<Double>,
        serviceTypes: [String],
        minPrice: Binding<Double>,
        maxPrice: Binding<Double>,
        type: Binding<String>,
        delivery: Binding<ServiceDeliveryFilter>
    ) {
        self.priceBounds = priceBounds
        self.serviceTypes = serviceTypes
        _minPrice = minPrice
        _maxPrice = maxPrice
        _type = type
        _delivery = delivery
        let lower = priceBounds.lowerBound
        let upper = priceBounds.upperBound
        let startingMin = min(max(minPrice.wrappedValue, lower), upper)
        let startingMax = maxPrice.wrappedValue >= 999_999
            ? upper
            : min(max(maxPrice.wrappedValue, lower), upper)
        _draftMin = State(initialValue: min(startingMin, startingMax))
        _draftMax = State(initialValue: max(startingMin, startingMax))
        _draftType = State(initialValue: type.wrappedValue)
        _draftDelivery = State(initialValue: delivery.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Price range") {
                    Text("From $\(Int(draftMin.rounded()))")
                        .foregroundStyle(Color.picardoNeonRed)
                    Slider(value: $draftMin, in: priceBounds)
                        .onChange(of: draftMin) { _, newValue in
                            if newValue > draftMax { draftMax = newValue }
                        }
                    Text("Up to $\(Int(draftMax.rounded()))")
                        .foregroundStyle(Color.picardoNeonRed)
                    Slider(value: $draftMax, in: priceBounds)
                        .onChange(of: draftMax) { _, newValue in
                            if newValue < draftMin { draftMin = newValue }
                        }
                }
                Section("Service type") {
                    Picker("Service type", selection: $draftType) {
                        Text("Any").tag("Any")
                        ForEach(serviceTypes, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }
                Section("Delivery time") {
                    Picker("Delivery time", selection: $draftDelivery) {
                        ForEach(ServiceDeliveryFilter.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        draftMin = priceBounds.lowerBound
                        draftMax = priceBounds.upperBound
                        draftType = "Any"
                        draftDelivery = .any
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        minPrice = draftMin
                        maxPrice = draftMax
                        type = draftType
                        delivery = draftDelivery
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

struct ServiceShelf: Hashable, Identifiable {
    let title: String
    let listings: [ServiceListing]
    var id: String { title }
}

struct ServiceListingCard: View {
    let listing: ServiceListing
    let isSaved: Bool
    let onSave: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var mediaShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
    }

    private var destination: StudioDestination {
        StudioDestination(artistName: listing.artist.name, serviceID: listing.id)
    }

    /// Available now wins. New only when the service has no reviews and is not available.
    private var badge: String? {
        if listing.isAvailableNow { return "Available now" }
        if listing.reviewCount == 0 { return "New" }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                NavigationLink(value: destination) {
                    cover
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.tap()
                    onSave()
                } label: {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSaved ? Color.picardoNeonRed : .white)
                        .frame(width: 32, height: 32)
                        .modifier(HeartBounce(isSaved: isSaved, reduceMotion: reduceMotion))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSaved ? "Remove from saved" : "Save")
                .background(.black.opacity(0.28), in: Circle())
                .padding(8)
            }

            NavigationLink(value: destination) {
                details
            }
            .buttonStyle(.plain)
        }
    }

    private var cover: some View {
        Color.picardoCardMid
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    ArtworkImage(imageName: listing.coverImageName, contentMode: .fill, maxDimension: 700)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
            }
            .overlay(alignment: .topLeading) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white, in: Capsule())
                        .padding(8)
                }
            }
            .clipShape(mediaShape)
            .contentShape(mediaShape)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(listing.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.picardoText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Text(listing.priceLabel)
                    .foregroundStyle(Color.picardoNeonRed)
                    .fontWeight(.semibold)
                Text("·")
                Text(listing.artist.name)
                if listing.reviewCount > 0 {
                    Text("·")
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                    Text(String(format: "%.1f", listing.rating))
                }
            }
            .font(.system(size: 13))
            .foregroundStyle(Color.picardoTextSecondary)
            .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}

struct ServiceCardGrid: View {
    let listings: [ServiceListing]
    @Binding var saved: Set<String>
    let onToggle: (String) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(listings) { listing in
                ServiceListingCard(
                    listing: listing,
                    isSaved: saved.contains(listing.id),
                    onSave: { onToggle(listing.id) }
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

struct ServiceShelfGrid: View {
    let shelf: ServiceShelf
    @Binding var saved: Set<String>

    private func toggle(_ id: String) {
        if saved.contains(id) { saved.remove(id) } else { saved.insert(id) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            ServiceCardGrid(listings: shelf.listings, saved: $saved, onToggle: toggle)
                .padding(.top, 12)
                .padding(.bottom, 120)
        }
        .background(Color.picardoBackground.ignoresSafeArea())
        .navigationTitle(shelf.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(false)
        .picardoPushedScreen()
    }
}
private struct HeartBounce: ViewModifier {
    let isSaved: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.symbolEffect(.bounce, options: .speed(2), value: isSaved)
        }
    }
}
