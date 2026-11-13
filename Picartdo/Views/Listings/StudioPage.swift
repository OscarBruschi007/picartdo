import SwiftUI

struct StudioDestination: Hashable {
    var artistName: String
    var serviceID: String
    var owned: Bool = false

    static var mine: StudioDestination {
        StudioDestination(artistName: "", serviceID: "", owned: true)
    }
}

private enum StudioTab: String, CaseIterable, Identifiable {
    case services = "Services"
    case portfolio = "Portfolio"
    case reviews = "Reviews"
    case about = "About"
    var id: String { rawValue }
}

private struct StudioOffer: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let priceLabel: String
    let delivery: String
}

private struct StudioReviewItem: Identifiable, Hashable {
    let id: String
    let author: String
    let text: String
}

private struct StudioPhoto: Identifiable, Hashable {
    let id: String
    let asset: String
    let jpeg: Data?
}

/// Public studio opened from a service card, or from My Studio.
struct StudioPage: View {
    let destination: StudioDestination

    @State private var store = StudioStore.shared
    @State private var tab: StudioTab = .services
    @State private var musing = false
    @State private var showRequest = false
    @State private var requestSent = false
    @State private var photo: StudioPhoto?

    private var profile: StudioContent {
        if destination.owned, let owned = store.studio {
            return StudioContent.from(owned: owned)
        }
        return StudioContent.sample(artistName: destination.artistName)
    }

    private var focusID: String {
        if destination.owned {
            return store.studio?.services.first?.id.uuidString ?? ""
        }
        return destination.serviceID
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        Picker("Studio", selection: $tab) {
                            ForEach(StudioTab.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)

                        tabBody(proxy: proxy)
                    }
                    .padding(.bottom, 24)
                }
            }
            requestBar
        }
        .background(Color.picardoBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showRequest) {
            if let artist = Artist.named(profile.artistName) {
                CommissionRequestView(artist: artist)
            }
        }
        .alert("Request sent", isPresented: $requestSent) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your request was sent to \(profile.name).")
        }
        .fullScreenCover(item: $photo) { item in
            StudioPhotoPage(photo: item)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            StudioStill(jpeg: profile.coverJPEG, asset: profile.coverAsset)
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipped()

            HStack(alignment: .center, spacing: 12) {
                StudioStill(jpeg: profile.avatarJPEG, asset: profile.avatarAsset)
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(Color.picardoText)
                        .lineLimit(1)
                    Text(profile.city)
                        .font(.subheadline)
                        .foregroundStyle(Color.picardoTextSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Button {
                    Haptics.tap()
                    musing.toggle()
                } label: {
                    Text(musing ? "Release Muse" : "Muse")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.picardoText, in: Capsule())
                        .foregroundStyle(Color.cardSurface)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(musing ? "Release Muse" : "Muse")
            }
            .padding(.horizontal, 16)

            Text(profile.bio)
                .font(.subheadline)
                .foregroundStyle(Color.picardoTextSecondary)
                .lineLimit(1)
                .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func tabBody(proxy: ScrollViewProxy) -> some View {
        switch tab {
        case .services:
            LazyVStack(spacing: 0) {
                ForEach(profile.services) { service in
                    serviceRow(service)
                        .id(service.id)
                        .background(service.id == focusID ? Color.picardoNeonRed.opacity(0.10) : Color.clear)
                }
            }
            .onAppear {
                guard profile.services.contains(where: { $0.id == focusID }) else { return }
                DispatchQueue.main.async {
                    proxy.scrollTo(focusID, anchor: .center)
                }
            }
        case .portfolio:
            let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(profile.portfolio) { item in
                    Button {
                        Haptics.tap()
                        photo = item
                    } label: {
                        StudioStill(jpeg: item.jpeg, asset: item.asset)
                            .frame(minHeight: 110)
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open photo")
                }
            }
        case .reviews:
            if profile.reviews.isEmpty {
                PicartdoEmptyState(icon: "text.bubble", title: "No reviews yet.")
                    .padding(.top, 12)
            } else {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(profile.reviews) { review in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(review.author)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.picardoText)
                            Text(review.text)
                                .font(.subheadline)
                                .foregroundStyle(Color.picardoTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                    }
                }
            }
        case .about:
            VStack(alignment: .leading, spacing: 14) {
                Text(profile.about)
                    .font(.body)
                    .foregroundStyle(Color.picardoText)
                labeled("Location", profile.city)
                labeled("Response time", profile.responseTime)
                labeled("Languages", profile.languages)
            }
            .padding(.horizontal, 16)
        }
    }

    private func serviceRow(_ service: StudioOffer) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(service.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.picardoText)
                    .lineLimit(1)
                Text(service.summary)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .lineLimit(2)
                Text(service.delivery)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.picardoTextSecondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 8) {
                Text(service.priceLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.picardoNeonRed)
                Button("Request") { ask() }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.picardoNeonRed, in: Capsule())
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.picardoTextSecondary)
            Text(value)
                .font(.body)
                .foregroundStyle(Color.picardoText)
        }
    }

    private var requestBar: some View {
        Button(action: ask) {
            Text("Request")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.picardoNeonRed, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(ServicesPressStyle())
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 108)
        .background(Color.picardoBackground)
    }

    private func ask() {
        Haptics.tap()
        if Artist.named(profile.artistName) != nil {
            showRequest = true
        } else {
            requestSent = true
        }
    }
}

private struct StudioPhotoPage: View {
    let photo: StudioPhoto
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            StudioStill(jpeg: photo.jpeg, asset: photo.asset)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.black.opacity(0.45), in: Circle())
            }
            .padding(20)
            .accessibilityLabel("Close")
        }
    }
}

struct StudioStill: View {
    var jpeg: Data?
    var asset: String

    var body: some View {
        if let jpeg, let image = UIImage(data: jpeg) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ArtworkImage(imageName: asset, contentMode: .fill, maxDimension: 900)
        }
    }
}

private struct StudioContent {
    var name: String
    var artistName: String
    var city: String
    var bio: String
    var about: String
    var coverAsset: String
    var coverJPEG: Data?
    var avatarAsset: String
    var avatarJPEG: Data?
    var responseTime: String
    var languages: String
    var services: [StudioOffer]
    var portfolio: [StudioPhoto]
    var reviews: [StudioReviewItem]

    static func from(owned: OwnedStudio) -> StudioContent {
        StudioContent(
            name: owned.name,
            artistName: owned.name,
            city: owned.city,
            bio: owned.bio,
            about: owned.bio,
            coverAsset: owned.coverAsset,
            coverJPEG: owned.coverJPEG,
            avatarAsset: owned.avatarAsset,
            avatarJPEG: owned.avatarJPEG,
            responseTime: "Within a day",
            languages: "English",
            services: owned.services.filter(\.isActive).map { service in
                StudioOffer(
                    id: service.id.uuidString,
                    title: service.title,
                    summary: service.summary.isEmpty ? service.type : service.summary,
                    priceLabel: service.priceLabel,
                    delivery: service.delivery
                )
            },
            portfolio: owned.services.map { service in
                StudioPhoto(id: service.id.uuidString, asset: service.coverAsset, jpeg: service.coverJPEG)
            },
            reviews: []
        )
    }

    static func sample(artistName: String) -> StudioContent {
        if artistName == "Jake Morrison" { return jake }
        if artistName == "Penny Brooks" { return penny }
        guard let artist = Artist.named(artistName) else {
            return StudioContent(
                name: artistName,
                artistName: artistName,
                city: "",
                bio: "",
                about: "",
                coverAsset: "art_01",
                coverJPEG: nil,
                avatarAsset: "art_01",
                avatarJPEG: nil,
                responseTime: "Within 2 days",
                languages: "English",
                services: [],
                portfolio: [],
                reviews: []
            )
        }
        let listings = ServiceCatalog.listings.filter { $0.artist.name == artist.name }
        let services = listings.map { listing in
            StudioOffer(
                id: listing.id,
                title: listing.title,
                summary: listing.serviceType,
                priceLabel: listing.priceLabel,
                delivery: listing.deliveryText
            )
        }
        let photos = artist.portfolioImages.enumerated().map { index, name in
            StudioPhoto(id: "\(artist.name)-\(index)", asset: name, jpeg: nil)
        }
        return StudioContent(
            name: "\(artist.name) Studio",
            artistName: artist.name,
            city: artist.location,
            bio: artist.tagline,
            about: artist.bio,
            coverAsset: artist.bannerImage,
            coverJPEG: nil,
            avatarAsset: artist.avatarImage,
            avatarJPEG: nil,
            responseTime: "Within 2 days",
            languages: "English",
            services: services,
            portfolio: photos,
            reviews: []
        )
    }

    private static let jake = StudioContent(
        name: "Jake Morrison Studio",
        artistName: "Jake Morrison",
        city: "Austin, US",
        bio: "Bold lines, classic flash. Traditional American tattoo.",
        about: "Bold lines, classic flash. Traditional American tattoo done right. Walk-ins some afternoons, custom work by request.",
        coverAsset: "tattoo_studio_02",
        coverJPEG: nil,
        avatarAsset: "tattoo_studio_02",
        avatarJPEG: nil,
        responseTime: "Within a day",
        languages: "English",
        services: [
            StudioOffer(id: "Tattoo Art|Jake Morrison", title: "American Traditional", summary: "Classic flash and custom traditional pieces.", priceLabel: "From $220", delivery: "2 hour session"),
            StudioOffer(id: "jake-sleeve", title: "Custom sleeve plan", summary: "A drawn plan before the first session.", priceLabel: "From $400", delivery: "2–4 weeks"),
            StudioOffer(id: "jake-flash", title: "Flash day", summary: "Pick a design from the wall and sit the same day.", priceLabel: "From $80", delivery: "1 hour")
        ],
        portfolio: [
            StudioPhoto(id: "jake-1", asset: "tattoo_studio_02", jpeg: nil),
            StudioPhoto(id: "jake-2", asset: "tattoo_studio_04", jpeg: nil),
            StudioPhoto(id: "jake-3", asset: "tattoo_studio_01", jpeg: nil)
        ],
        reviews: [
            StudioReviewItem(id: "jake-r1", author: "Maya", text: "Clean lines and a calm shop. The eagle healed perfectly."),
            StudioReviewItem(id: "jake-r2", author: "Chris", text: "Booked a flash day and was out in an hour. Exactly the drawing on the wall.")
        ]
    )

    private static let penny = StudioContent(
        name: "Penny Brooks Studio",
        artistName: "Penny Brooks",
        city: "Sydney, AU",
        bio: "Mess-friendly painting workshops for ages 4–12.",
        about: "Fun, mess-friendly painting workshops for ages 4–12. Every child leaves with something they made.",
        coverAsset: "art_02",
        coverJPEG: nil,
        avatarAsset: "art_05",
        avatarJPEG: nil,
        responseTime: "Within a day",
        languages: "English",
        services: [
            StudioOffer(id: "Kids Workshops|Penny Brooks", title: "Painting & Creative Play", summary: "A Saturday studio for ages 4–12.", priceLabel: "From $45", delivery: "2 hours"),
            StudioOffer(id: "penny-party", title: "Birthday studio", summary: "The same workshop, booked for one group.", priceLabel: "From $180", delivery: "2 hours")
        ],
        portfolio: [
            StudioPhoto(id: "penny-1", asset: "art_02", jpeg: nil),
            StudioPhoto(id: "penny-2", asset: "art_05", jpeg: nil),
            StudioPhoto(id: "penny-3", asset: "art_07", jpeg: nil)
        ],
        reviews: [
            StudioReviewItem(id: "penny-r1", author: "Aisha", text: "My daughter still has the painting on the fridge."),
            StudioReviewItem(id: "penny-r2", author: "Tom", text: "Calm, organized, and the kids actually finished a picture.")
        ]
    )
}
