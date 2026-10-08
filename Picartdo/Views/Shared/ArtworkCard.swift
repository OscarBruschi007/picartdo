import SwiftUI

/// One listing card. Screens pick a variant; chrome (image, title, price,
/// save, category, radius) lives here so it cannot drift screen to screen.
struct ArtworkCard: View {
    enum Variant {
        case grid
        case featured
        case pinterest
        case compact
        case listRow
        case collectionWork
    }

    let artwork: Artwork
    var variant: Variant = .grid
    var isSaved: Bool = false
    var onSave: (() -> Void)? = nil
    var onBuy: (() -> Void)? = nil
    var rank: Int = 1
    var compactWidth: CGFloat = 160
    /// Featured eyebrow. Home passes `nil` so it stays “FEATURED DROP”.
    var eyebrow: String? = nil
    /// When set, image and title open this way (sheet/cover). Otherwise they
    /// push `Artwork` on the current `NavigationStack`.
    var onOpenArtwork: (() -> Void)? = nil

    var body: some View {
        switch variant {
        case .grid:           gridBody
        case .featured:       featuredBody
        case .pinterest:      pinterestBody
        case .compact:        compactBody
        case .listRow:        listRowBody
        case .collectionWork: collectionWorkBody
        }
    }

    // MARK: Shared chrome

    @ViewBuilder
    private func polaroidImage(height: CGFloat, inner: CGFloat, outer: CGFloat) -> some View {
        ZStack {
            Color.picardoPolaroidMat
            ArtworkImage(artwork: artwork, contentMode: .fit)
                .padding(inner)
                .background(Color.picardoPostFrame)
                .padding(outer)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }

    @ViewBuilder
    private func saveButton(size: CGFloat, filled: Bool = false) -> some View {
        if let onSave {
            Button(action: onSave) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: size, weight: .medium))
                    .foregroundStyle(isSaved ? Color.picardoGold : (filled ? Color(white: 0.4) : Color(.secondaryLabel)))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func artworkLink<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if let onOpenArtwork {
            Button(action: onOpenArtwork, label: content)
                .buttonStyle(.plain)
        } else {
            NavigationLink(value: artwork, label: content)
                .buttonStyle(.plain)
        }
    }

    private var categoryTag: some View {
        Text(artwork.category.rawValue.uppercased())
            .font(.system(size: 10, weight: .bold))
            .kerning(1.2)
            .foregroundStyle(Color.picardoGold)
    }

    private var priceText: some View {
        Text(artwork.price, format: .currency(code: "USD").precision(.fractionLength(0)))
    }

    private var soldBadge: some View {
        Text("SOLD")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.65), in: Capsule())
    }

    // MARK: .grid — Polaroid 2-up (Home / Explore / Feed)

    private var gridBody: some View {
        VStack(spacing: 0) {
            polaroidImage(height: 168, inner: 12, outer: 10)
                .clipped()

            VStack(alignment: .center, spacing: 4) {
                categoryTag

                Text(artwork.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                ZStack {
                    priceText
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.picardoNeonRed)

                    HStack {
                        Spacer()
                        saveButton(size: 14, filled: true)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity)
            .background(Color.picardoPostFrame)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: .featured — Home hero

    private var featuredBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            artworkLink {
                polaroidImage(height: 340, inner: 18, outer: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    artworkLink {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(eyebrow ?? "FEATURED DROP")
                                .font(.system(size: 11, weight: .bold))
                                .kerning(1.6)
                                .foregroundStyle(Color.picardoEraAccent)

                            Text(artwork.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                    }

                    ArtistNameLink(
                        name: artwork.artistName,
                        prefix: "by ",
                        font: .system(size: 14),
                        color: Color(white: 0.45)
                    )
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 8) {
                    priceText
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 10) {
                        Button(action: { onSave?() }) {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(isSaved ? Color.picardoGold : Color(white: 0.35))
                        }
                        .buttonStyle(.plain)

                        if !artwork.isSold {
                            Button {
                                onBuy?()
                            } label: {
                                Text("BUY")
                                    .font(.system(size: 13, weight: .bold))
                                    .kerning(0.6)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.picardoNeonRed, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 14)
        }
    }

    // MARK: .pinterest — masonry pin

    private var pinterestBody: some View {
        let ratio = PinterestPinMetrics.aspectRatio(for: artwork)
        return VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(white: 0.96))
                    .overlay {
                        ArtworkImage(artwork: artwork, contentMode: .fit)
                            .padding(8)
                    }
                    .aspectRatio(ratio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if artwork.isSold {
                    soldBadge
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(10)
                }

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onSave?()
                } label: {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isSaved ? .red : .primary)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 2) {
                artworkLink {
                    Text(artwork.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                ArtistNameLink(
                    name: artwork.artistName,
                    font: .system(size: 11),
                    color: Color.secondary
                )
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: .compact — artist profile listings

    private var compactBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                ArtworkImage(artwork: artwork, contentMode: .fill)
                    .frame(width: compactWidth, height: compactWidth * 1.1)
                    .clipped()

                if artwork.isSold {
                    Text("SOLD")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.7), in: Capsule())
                        .padding(8)
                }
            }
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 12, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 12
            ))

            VStack(alignment: .center, spacing: 4) {
                Text(artwork.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                priceText
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.picardoNeonRed)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(width: compactWidth, alignment: .center)
            .background(Color.picardoCard)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 12,
                bottomTrailingRadius: 12, topTrailingRadius: 0
            ))
        }
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }

    // MARK: .listRow — Home trending

    private var listRowBody: some View {
        HStack(spacing: 14) {
            Text("#\(rank)")
                .font(.system(size: rank == 1 ? 16 : 13, weight: .black))
                .foregroundStyle(rank == 1 ? Color.picardoGold : Color(.tertiaryLabel))
                .frame(width: 28, alignment: .center)

            artworkLink {
                ArtworkImage(artwork: artwork, contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 3) {
                artworkLink {
                    Text(artwork.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                HStack(spacing: 6) {
                    ArtistNameLink(
                        name: artwork.artistName,
                        font: .system(size: 12),
                        color: Color.secondary
                    )
                    Text("·")
                        .foregroundStyle(Color(.tertiaryLabel))
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Text("\(artwork.likeCount)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                priceText
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Button(action: { onSave?() }) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 13))
                            .foregroundStyle(isSaved ? Color.picardoGold : Color(.secondaryLabel))
                    }
                    .buttonStyle(.plain)

                    if !artwork.isSold {
                        Button { onBuy?() } label: {
                            Text("BUY")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.picardoNeonRed, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: .collectionWork — exhibition tile

    private var collectionWorkBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            artworkLink {
                ZStack {
                    Color.picardoSurface
                    ArtworkImage(artwork: artwork, contentMode: .fit)
                        .padding(10)
                }
                .frame(height: 180)
                .picardoCard(radius: 18)
            }

            artworkLink {
                Text(artwork.title)
                    .font(PicardoType.body(13))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.picardoText)
                    .lineLimit(2)
            }

            ArtistNameLink(
                name: artwork.artistName,
                font: PicardoType.meta(9),
                color: Color.picardoTextSecondary,
                kerning: 0.8
            )
        }
    }
}

/// Tappable listing artist name → `ArtistStoreView` via `NavigationLink(value:)`.
struct ArtistNameLink: View {
    let name: String
    var prefix: String = ""
    var font: Font = .system(size: 14)
    var color: Color = Color(white: 0.45)
    var kerning: CGFloat = 0
    var italic: Bool = false
    var lineLimit: Int? = 1

    var body: some View {
        Group {
            if let artist = Artist.named(name) {
                NavigationLink(value: artist) { label }
                    .buttonStyle(.plain)
            } else {
                label
            }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(name)
        .accessibilityHint("Opens artist profile")
    }

    private var label: some View {
        text
            .foregroundStyle(color)
            .kerning(kerning)
            .lineLimit(lineLimit)
            .contentShape(Rectangle())
    }

    private var text: Text {
        let base = Text(prefix + name).font(font)
        return italic ? base.italic() : base
    }
}
