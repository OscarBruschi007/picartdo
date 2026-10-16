import SwiftUI

// MARK: - Service store home
//
// One layout for every service category (Tattoo, Murals, Ceramics…): a hero,
// search and filters, a nearby row, then the full store feed. Only the copy
// and the photos change per category.
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
    static func heroPhoto(for category: ServiceCategory) -> String {
        if category == .wallpaper { return "wave_rainbow" }
        let studio = "\(category.assetSlug)_studio_01"
        return UIImage(named: studio) != nil ? studio : category.heroImageName
    }

    /// A studio photo for this artist among `{slug}_studio_02…09`, the same one on every launch.
    static func studioPhoto(for artist: Artist, in category: ServiceCategory) -> String? {
        if category == .tattoo { return tattooPhotos[artist.name] ?? "tattoo_studio_04" }
        let available = (2...9)
            .map { String(format: "%@_studio_%02d", category.assetSlug, $0) }
            .filter { UIImage(named: $0) != nil }
        guard !available.isEmpty else { return nil }
        // Deterministic pick: `hashValue` changes between launches.
        let seed = artist.name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return available[seed % available.count]
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
        case .liveEvent:       return "Exhibitions & venues"
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
        case .tattoo:          return "Studios you can book — like a stay, for ink."
        case .digitalArt:      return "Illustrators and designers taking commissions."
        case .mural:           return "Artists who paint walls, rooms and whole buildings."
        case .wallpaper:       return "Pattern designers for rooms, quiet or loud."
        case .fashion:         return "Garments and textiles made to order."
        case .paintingService: return "Commission a portrait, landscape or interior."
        case .liveEvent:       return "Shows, live painting and nights around the work."
        case .classes:         return "Sit down, pick up a brush, take something home."
        case .sculpture:       return "Bronze, stone, wood and clay, made to commission."
        case .ceramics:        return "Working kilns for vessels, tiles and tableware."
        case .kidsWorkshop:    return "Rooms where kids make something they keep."
        case .restoration:     return "Conservators for paintings, paper and frames."
        }
    }
}

/// A service category's home — an Airbnb-style store feed.
struct ServiceStoreHomeView: View {
    let category: ServiceCategory

    @State private var searchText = ""
    @State private var filter = StoreFilter.all
    @State private var saved: Set<UUID> = []
    @State private var pageWidth: CGFloat = 390

    private enum StoreFilter: String, CaseIterable {
        case all, nearby, top, open

        func label(noun: String) -> String {
            switch self {
            case .all:    return noun.prefix(1).uppercased() + noun.dropFirst()
            case .nearby: return "Nearby"
            case .top:    return "Top rated"
            case .open:   return "Available"
            }
        }

        var icon: String {
            switch self {
            case .all:    return "storefront"
            case .nearby: return "mappin"
            case .top:    return "star.fill"
            case .open:   return "checkmark.seal.fill"
            }
        }
    }

    /// Artists in this category. Until a category has its own profiles, show the
    /// wider roster so the page is never empty.
    private var members: [Artist] {
        let matched = Artist.all.filter { category.matches($0) }
        return matched.isEmpty ? Array(Artist.all.prefix(8)) : matched
    }

    private var roster: [Artist] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let searched = q.isEmpty ? members : members.filter {
            $0.storeName.lowercased().contains(q)
            || $0.name.lowercased().contains(q)
            || $0.location.lowercased().contains(q)
            || $0.tagline.lowercased().contains(q)
            || $0.specialties.contains { $0.lowercased().contains(q) }
        }
        switch filter {
        case .all:     return searched
        case .nearby:  return searched.filter { !$0.location.lowercased().contains("remote") }
        case .top:     return searched.filter { $0.rating >= 4.8 }.sorted { $0.rating > $1.rating }
        case .open:    return searched.filter(\.availableForCommissions)
        }
    }

    private var nearbyStores: [Artist] {
        roster.filter { !$0.location.lowercased().contains("remote") }
    }

    var body: some View {
        storePage
    }

    private var storePage: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                hero

                searchAndFilters
                    .padding(.top, 16)
                    .padding(.bottom, 22)

                if category == .wallpaper {
                    WallpaperPackSection(pack: .waves)
                        .padding(.bottom, 28)
                }

                if filter == .all, !nearbyStores.isEmpty {
                    nearbyRow
                        .padding(.bottom, 28)
                }

                storeFeed
                    .padding(.bottom, 56)
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { pageWidth = $0 }
        .background(Color.picardoBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var heroShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
    }

    private var hero: some View {
        Color.clear
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .overlay {
                LoopingHeroVideo(
                    resourceName: category.heroImageName,
                    fallbackImageName: ServiceGallery.heroPhoto(for: category)
                )
            }
            .overlay {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    VStack(spacing: 4) {
                        Text(category.storeTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text(category.storeTagline)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .picardoGlass(in: RoundedRectangle(cornerRadius: 22, style: .continuous), interactive: true)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
            }
            .picardoGlassMedia(in: heroShape)
            .padding(.horizontal, 16)
            .padding(.top, 8)
    }

    private var searchAndFilters: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search \(category.storeNoun), cities, styles", text: $searchText)
                    .font(.system(size: 15))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(Color(.systemBackground), in: Capsule())
            .shadow(color: .black.opacity(0.10), radius: 6, y: 2)
            .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(StoreFilter.allCases, id: \.self) { item in
                        AirbnbFilterPill(
                            icon: item.icon,
                            label: item.label(noun: category.storeNoun),
                            isSelected: filter == item
                        ) { filter = item }
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    private var nearbyRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(category.storeNoun.prefix(1).uppercased() + category.storeNoun.dropFirst()) nearby")
                    .font(.system(size: 19, weight: .bold))
                Text("Open to visit · in person")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(nearbyStores) { artist in
                        NavigationLink(value: artist) {
                            AirbnbStoreListingCard(
                                artist: artist,
                                photo: ServiceGallery.coverPhoto(for: artist, in: category),
                                cardWidth: 280,
                                isSaved: saved.contains(artist.id),
                                onSave: { toggle(artist.id) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    private var storeFeed: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(filter == .all ? "Top rated \(category.storeNoun)" : filter.label(noun: category.storeNoun))
                .font(.system(size: 19, weight: .bold))
                .padding(.horizontal, 18)

            if roster.isEmpty {
                Text("No \(category.storeNoun) found")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
            } else {
                LazyVStack(spacing: 22) {
                    ForEach(roster) { artist in
                        NavigationLink(value: artist) {
                            AirbnbStoreListingCard(
                                artist: artist,
                                photo: ServiceGallery.coverPhoto(for: artist, in: category),
                                cardWidth: max(pageWidth - 36, 0),
                                isSaved: saved.contains(artist.id),
                                onSave: { toggle(artist.id) }
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 18)
                    }
                }
            }
        }
    }

    private func toggle(_ id: UUID) {
        if saved.contains(id) { saved.remove(id) } else { saved.insert(id) }
    }
}

/// Store listing photo — liquid glass, no Instagram card corners.
struct AirbnbStoreListingCard: View {
    let artist: Artist
    var photo: String? = nil
    var cardWidth: CGFloat
    let isSaved: Bool
    let onSave: () -> Void

    private var mediaShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ArtworkImage(
                imageName: photo ?? artist.storePhotos.first ?? artist.serviceCoverName,
                contentMode: .fill,
                maxDimension: 900
            )
            .frame(width: cardWidth, height: cardWidth)
            .overlay {
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        if artist.rating >= 4.8 {
                            Text("Guest favorite")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .picardoGlass(in: Capsule(), interactive: true)
                        }
                        Spacer(minLength: 0)
                        Button(action: onSave) {
                            Image(systemName: isSaved ? "heart.fill" : "heart")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(isSaved ? Color.picardoNeonRed : .primary)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isSaved ? "Remove from saved" : "Save")
                        .picardoGlass(in: Circle(), interactive: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
            }
            .picardoGlassMedia(in: mediaShape)

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(artist.storeName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(artist.hostedByLine)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(artist.location)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Text("\(Text("From \(artist.startingPrice)").fontWeight(.semibold))\(artist.availableForCommissions ? " · Available" : "")")
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .padding(.top, 2)
                }
                Spacer(minLength: 8)
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                    Text(String(format: "%.2f", artist.rating))
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.primary)
            }
            .frame(width: cardWidth, alignment: .leading)
        }
    }
}
