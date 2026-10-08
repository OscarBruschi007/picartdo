import SwiftUI

// MARK: - Profile Tab

enum ArtistListingTab: String, CaseIterable {
    case selling = "Selling"
    case sold    = "Sold"
}

// MARK: - Marketplace Profile Data

struct ArtistMarketplaceProfile {
    let bannerImage: String
    let avatarImage: String
    let name: String
    let verified: Bool
    let location: String
    let rating: Double
    let revenue: String
    let piecesSold: Int
    let responseTime: String
    let authenticated: Bool
    let returnPolicy: String

    static let oscar = ArtistMarketplaceProfile(
        bannerImage: "art_01",
        avatarImage: "art_08",
        name: "Oscar Bruschi",
        verified: true,
        location: "Toronto, ON",
        rating: 4.8,
        revenue: "$14K",
        piecesSold: 12,
        responseTime: "<1hr",
        authenticated: true,
        returnPolicy: "14-day returns"
    )

    /// Two-letter monogram from the name (e.g. "Oscar Bruschi" → "OB").
    var initials: String {
        let letters = name.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }
        return letters.isEmpty ? "?" : letters.joined().uppercased()
    }

    /// Follower count for social proof (static for now; real value once Firebase lands).
    var followers: String { "1.4k" }

    init(
        bannerImage: String, avatarImage: String, name: String,
        verified: Bool, location: String, rating: Double,
        revenue: String, piecesSold: Int, responseTime: String,
        authenticated: Bool, returnPolicy: String
    ) {
        self.bannerImage  = bannerImage;  self.avatarImage = avatarImage
        self.name         = name;         self.verified    = verified
        self.location     = location;     self.rating      = rating
        self.revenue      = revenue;      self.piecesSold  = piecesSold
        self.responseTime = responseTime; self.authenticated = authenticated
        self.returnPolicy = returnPolicy
    }

    init(artist: Artist, featuredBanner: String? = nil) {
        bannerImage   = featuredBanner ?? artist.bannerImage
        avatarImage   = artist.avatarImage
        name          = artist.name
        verified      = artist.verified
        location      = artist.location
        rating        = artist.rating
        revenue       = artist.sales
        piecesSold    = Int(artist.sales.filter(\.isNumber)) ?? max(artist.reviewCount / 2, 1)
        responseTime  = "<1hr"
        authenticated = artist.verified
        returnPolicy  = "14-day returns"
    }
}

// MARK: - Clean Profile Header (no banner, centered identity)

struct ArtistProfileBanner: View {
    let profile: ArtistMarketplaceProfile

    var body: some View {
        VStack(spacing: 16) {
            Image(profile.avatarImage)
                .resizable()
                .scaledToFill()
                .frame(width: 130, height: 130)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Color.picardoGold, lineWidth: 3))
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text(profile.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.primary)
                    if profile.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.picardoSupport)
                    }
                }
                Text(profile.location)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background { PicartdoBackground() }
    }
}

// MARK: - Combined Stats + Trust + CTA

struct MarketplaceStatsBar: View {
    let profile: ArtistMarketplaceProfile

    var body: some View {
        VStack(spacing: 12) {
            // Stats row
            HStack(spacing: 0) {
                statCell(profile.revenue, "Revenue")
                divider
                statCell("\(profile.piecesSold)", "Sold")
                divider
                statCell(String(format: "%.1f★", profile.rating), "Rating")
            }

            // Trust row
            HStack(spacing: 16) {
                trustItem(icon: "checkmark.shield.fill", text: "Authenticated")
                trustItem(icon: "shippingbox.fill",      text: "Ships Worldwide")
                trustItem(icon: "bolt.fill",             text: "\(profile.responseTime) response")
            }
            .padding(.horizontal, 18)
        }
        .padding(.vertical, 16)
        .background(Color.picardoBackground)
    }

    private var divider: some View {
        Rectangle().fill(Color.picardoDivider).frame(width: 0.5, height: 28)
    }

    private func statCell(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .kerning(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private func trustItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(Color.picardoGold)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Trust Strip (empty stub — merged into StatsBar)
struct ArtistTrustStrip: View {
    let profile: ArtistMarketplaceProfile
    var body: some View { EmptyView() }
}

// MARK: - Commission Button

struct ArtistCommissionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Commission a piece")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 13)
                .background(Color.picardoGold, in: Capsule())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.picardoBackground)
    }
}

// MARK: - Gold Pill Tab Switcher

struct ArtistListingTabSwitcher: View {
    @Binding var tab: ArtistListingTab

    var body: some View {
        HStack {
            Spacer()
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray6))

                GeometryReader { geo in
                    let w = geo.size.width / CGFloat(ArtistListingTab.allCases.count)
                    Capsule()
                        .fill(Color.picardoGold)
                        .frame(width: w - 6, height: geo.size.height - 6)
                        .offset(x: CGFloat(ArtistListingTab.allCases.firstIndex(of: tab) ?? 0) * w + 3, y: 3)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: tab)
                }

                HStack(spacing: 0) {
                    ForEach(ArtistListingTab.allCases, id: \.self) { item in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { tab = item }
                        } label: {
                            Text(item.rawValue.uppercased())
                                .font(.system(size: 12, weight: .bold))
                                .kerning(1.2)
                                .foregroundStyle(tab == item ? .white : Color(.secondaryLabel))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(width: 200, height: 38)
            Spacer()
        }
        .padding(.vertical, 12)
        .background(Color.picardoBackground)
        Divider()
    }
}

// MARK: - Listing Card (image + info below, no white bleed)

struct ArtistListingCard: View {
    let artwork: Artwork
    let width: CGFloat

    var body: some View {
        ArtworkCard(artwork: artwork, variant: .compact, compactWidth: width)
    }
}

// MARK: - Listing Grid

struct ArtistListingGrid: View {
    let items: [Artwork]
    let emptyMessage: String

    private let gap: CGFloat = 14
    private var cardWidth: CGFloat {
        (UIScreen.main.bounds.width - gap * 3) / 2
    }

    var body: some View {
        if items.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 36))
                    .foregroundStyle(.tertiary)
                Text(emptyMessage)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 48)
            .padding(.bottom, 40)
        } else {
            LazyVGrid(
                columns: [
                    GridItem(.fixed(cardWidth), spacing: gap),
                    GridItem(.fixed(cardWidth), spacing: gap),
                ],
                spacing: 18
            ) {
                ForEach(items) { artwork in
                    NavigationLink(value: artwork) {
                        ArtistListingCard(artwork: artwork, width: cardWidth)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, gap)
            .padding(.top, 16)
            .padding(.bottom, 36)
        }
    }
}

// MARK: - Full Profile Header Stack

struct ArtistProfileHeaderStack: View {
    let profile: ArtistMarketplaceProfile
    @Binding var tab: ArtistListingTab
    let onCommission: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ArtistProfileBanner(profile: profile)
            Divider()
            MarketplaceStatsBar(profile: profile)
            Divider()
            ArtistCommissionButton(action: onCommission)
            ArtistListingTabSwitcher(tab: $tab)
        }
    }
}
