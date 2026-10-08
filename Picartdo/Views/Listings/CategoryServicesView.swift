import SwiftUI

// MARK: - Service Home
//
// One home per service (Tattoo, Murals, Ceramics…). Tapping a Services
// category lands here. Every category uses the same store layout
// (ServiceStoreHomeView); only the copy, artists and photos change.
// Photo slots are documented in ServiceStoreHome.swift.

struct CategoryServicesView: View {
    let category: ServiceCategory

    var body: some View {
        ServiceStoreHomeView(category: category)
            .background { PicartdoBackground().ignoresSafeArea() }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Featured artist profile card

struct ServiceFeaturedArtistCard: View {
    let artist: Artist
    let isSaved: Bool
    let onSave: () -> Void

    private var mediaShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ArtworkImage(imageName: artist.serviceCoverName, contentMode: .fill, maxDimension: 900)
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .overlay {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer(minLength: 0)
                            Button(action: onSave) {
                                Image(systemName: isSaved ? "heart.fill" : "heart")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(isSaved ? Color.picardoNeonRed : .primary)
                                    .frame(width: 36, height: 36)
                            }
                            .buttonStyle(.plain)
                            .picardoGlass(in: Circle(), interactive: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                }
                .picardoGlassMedia(in: mediaShape)

            HStack(alignment: .top, spacing: 12) {
                ArtworkImage(imageName: artist.avatarImage, contentMode: .fill)
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(artist.name)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        if artist.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.picardoSupport)
                        }
                    }
                    Text(artist.tagline)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    HStack(spacing: 10) {
                        Label(String(format: "%.2f", artist.rating), systemImage: "star.fill")
                        Label(artist.location, systemImage: "mappin")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            HStack {
                Text("from \(artist.startingPrice)")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("View studio")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.picardoNeonRed)
            }
        }
    }
}

// MARK: - Airbnb Section

struct AirbnbSection: View {
    let title: String
    let subtitle: String?
    let artists: [Artist]
    @Binding var savedArtists: Set<UUID>
    var seeAllTitle: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.primary)
                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                NavigationLink(value: ServiceArtistList(
                    title: seeAllTitle.isEmpty ? title : seeAllTitle,
                    artists: artists
                )) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(artists) { artist in
                        NavigationLink(value: artist) {
                            AirbnbListingCard(
                                artist: artist,
                                isSaved: savedArtists.contains(artist.id),
                                onSave: {
                                    if savedArtists.contains(artist.id) {
                                        savedArtists.remove(artist.id)
                                    } else {
                                        savedArtists.insert(artist.id)
                                    }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }
}

struct ServiceArtistList: Hashable {
    let title: String
    let artists: [Artist]
}

struct ServiceArtistListView: View {
    let title: String
    let artists: [Artist]
    @State private var savedArtists: Set<UUID> = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 22) {
                ForEach(artists) { artist in
                    NavigationLink(value: artist) {
                        AirbnbListingCard(
                            artist: artist,
                            isSaved: savedArtists.contains(artist.id),
                            onSave: {
                                if savedArtists.contains(artist.id) {
                                    savedArtists.remove(artist.id)
                                } else {
                                    savedArtists.insert(artist.id)
                                }
                            }
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background { PicartdoBackground().ignoresSafeArea() }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .picardoPushedScreen()
    }
}

// MARK: - Airbnb Listing Card

struct AirbnbListingCard: View {
    let artist: Artist
    let isSaved: Bool
    let onSave: () -> Void

    private var mediaShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ArtworkImage(imageName: artist.storePhotos.first ?? artist.serviceCoverName, contentMode: .fill, maxDimension: 600)
                .frame(width: 200, height: 160)
                .overlay {
                    VStack(spacing: 0) {
                        HStack(spacing: 8) {
                            if artist.rating >= 4.8 {
                                Text("Guest favorite")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .picardoGlass(in: Capsule(), interactive: true)
                            }
                            Spacer(minLength: 0)
                            Button(action: onSave) {
                                Image(systemName: isSaved ? "heart.fill" : "heart")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(isSaved ? Color.picardoNeonRed : .primary)
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(.plain)
                            .picardoGlass(in: Circle(), interactive: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                }
                .picardoGlassMedia(in: mediaShape)

            VStack(alignment: .leading, spacing: 2) {

                HStack {
                    Text(artist.storeName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                        Text(String(format: "%.2f", artist.rating))
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.primary)
                }

                Text(artist.hostedByLine)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(artist.location)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                HStack(spacing: 0) {
                    Text("from ")
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                    Text(artist.startingPrice)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    if artist.availableForCommissions {
                        Text(" · Available")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 2)
            }
            .frame(width: 200, alignment: .leading)
        }
    }
}

// MARK: - Airbnb Filter Pill

struct AirbnbFilterPill: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? Color(.systemBackground) : Color.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.primary : Color(.systemGray6), in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.trailing, 6)
    }
}

// MARK: - Backward-compat stubs

struct PinterestGrid: View {
    let images: [String]
    private func height(at index: Int) -> CGFloat {
        let h: [CGFloat] = [160,220,140,200,180,240,150,210]
        return h[index % h.count]
    }
    var body: some View {
        let left  = images.enumerated().filter { $0.offset % 2 == 0 }.map(\.element)
        let right = images.enumerated().filter { $0.offset % 2 == 1 }.map(\.element)
        HStack(alignment: .top, spacing: 8) {
            LazyVStack(spacing: 8) {
                ForEach(Array(left.enumerated()),  id: \.offset) { i,img in PinterestCell(imageName: img, height: height(at: i*2)) }
            }
            LazyVStack(spacing: 8) {
                ForEach(Array(right.enumerated()), id: \.offset) { i,img in PinterestCell(imageName: img, height: height(at: i*2+1)) }
            }
        }
    }
}

struct PinterestCell: View {
    let imageName: String; let height: CGFloat
    var body: some View {
        ArtworkImage(imageName: imageName, contentMode: .fill)
            .frame(height: height)
            .picardoGlassMedia(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

struct ArtistStoreCard: View {
    let artist: Artist
    private var mediaShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ArtworkImage(imageName: artist.bannerImage, contentMode: .fill, maxDimension: 400)
                .frame(width: 150, height: 110)
                .picardoGlassMedia(in: mediaShape)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    ArtworkImage(imageName: artist.avatarImage, contentMode: .fill)
                        .frame(width: 36, height: 36).clipShape(Circle())
                    Spacer()
                    if artist.availableForCommissions {
                        Text("OPEN").font(.system(size: 7, weight: .black)).tracking(1)
                            .foregroundStyle(.white).padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.green, in: Capsule())
                    }
                }
                Text(artist.name).font(.system(size: 12, weight: .bold)).lineLimit(1)
                HStack(spacing: 3) {
                    Image(systemName: "star.fill").font(.system(size: 9)).foregroundStyle(.yellow)
                    Text(String(format: "%.1f", artist.rating)).font(.system(size: 10, weight: .semibold))
                    Text("(\(artist.reviewCount))").font(.system(size: 10)).foregroundStyle(.secondary)
                }
                Text("from \(artist.startingPrice)").font(.system(size: 11, weight: .bold)).foregroundStyle(Color.picardoNeonRed)
            }
        }
        .frame(width: 150)
    }
}

struct SectionLabel: View {
    let text: String
    var body: some View { Text(text).font(.system(size: 18, weight: .bold)).foregroundStyle(.primary) }
}

struct MiniArtistCard: View {
    let artist: Artist
    var body: some View { ArtistStoreCard(artist: artist) }
}

// MARK: - Filter Pill (old, kept for compat)
struct FilterPill: View {
    let label: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color(.systemBackground) : Color.primary)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(isSelected ? Color.primary : Color(.systemGray6), in: Capsule())
        }.buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CategoryServicesView(category: .tattoo)
            .navigationDestination(for: ServiceArtistList.self) { list in
                ServiceArtistListView(title: list.title, artists: list.artists)
            }
            .navigationDestination(for: Artist.self) { artist in
                ArtistStoreView(artist: artist)
            }
    }
}
