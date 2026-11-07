import SwiftUI

// Home as a gallery visit: today's date and city, one piece to stop for, then rooms
// (your wall, a studio visit, what's on, reading, the studios' feed). Art is shown
// whole, never cropped, and big enough to look at.

// MARK: - Date line

/// "FRIDAY, NOVEMBER 6 · TORONTO": the visit happens somewhere, today.
struct HomeDateLine: View {
    private var city: String {
        let location = ProfileIdentity.load().location
        let first = location.split(separator: ",").first.map { String($0).trimmingCharacters(in: .whitespaces) }
        return (first?.isEmpty == false ? first! : "Toronto")
    }

    var body: some View {
        Text("\(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased()) \u{00B7} \(city.uppercased())")
            .font(PicardoType.meta(10))
            .kerning(1.4)
            .foregroundStyle(Color.picardoTextSecondary)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("\(Date().formatted(date: .complete, time: .omitted)), \(city)")
    }
}

// MARK: - Section header

/// One header for every room: a serif title and a single line saying why it's here.
struct GallerySectionHeader<Accessory: View>: View {
    let title: String
    let reason: String
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 27, weight: .bold, design: .serif))
                    .tracking(-0.3)
                    .foregroundStyle(Color.picardoText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(reason)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            accessory
        }
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
    }
}

extension GallerySectionHeader where Accessory == EmptyView {
    init(title: String, reason: String) {
        self.init(title: title, reason: reason) { EmptyView() }
    }
}

/// "See all ›" for a header.
struct GallerySeeAll<Value: Hashable>: View {
    let value: Value
    var body: some View {
        NavigationLink(value: value) {
            HStack(spacing: 3) {
                Text("See all")
                Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.picardoText)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tonight's piece

/// The first thing you see: one artwork, whole and large, on a soft wash of its own
/// colours, with a museum wall label. Swipe for the next.
struct TonightsPieceHero: View {
    let artworks: [Artwork]
    var onBuy: (Artwork) -> Void

    @Environment(WishlistStore.self) private var wishlist
    @State private var index = 0

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("TONIGHT\u{2019}S PIECE")
                    .font(PicardoType.meta(10))
                    .kerning(1.4)
                    .foregroundStyle(Color.picardoTextSecondary)
                Spacer()
                if artworks.count > 1 {
                    Text("\(index + 1) / \(artworks.count)")
                        .font(PicardoType.meta(10))
                        .foregroundStyle(Color.picardoTextSecondary)
                        .contentTransition(.numericText())
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 20)

            TabView(selection: $index) {
                ForEach(Array(artworks.enumerated()), id: \.element.id) { i, artwork in
                    page(artwork)
                        .padding(.horizontal, 16)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 580)
            .onChange(of: index) { _, _ in Haptics.select() }
        }
    }

    private func page(_ artwork: Artwork) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink(value: artwork) {
                GalleryArtworkTile(artwork: artwork, inset: 30, maxDimension: 1600)
                    .frame(maxWidth: .infinity)
                    .frame(height: 470)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(artwork.title) by \(artwork.artistName)")
            .accessibilityHint("Opens the piece")

            wallLabel(artwork)
                .padding(.top, 14)
                .padding(.horizontal, 4)
        }
    }

    private func specLine(_ artwork: Artwork) -> String {
        [artwork.medium, artwork.dimensions]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " \u{00B7} ")
    }

    private func wallLabel(_ artwork: Artwork) -> some View {
        let saved = wishlist.isLiked(artwork)
        return HStack(alignment: .center, spacing: 12) {
            // Set like a museum wall label: who, what, made of, how big, how much.
            VStack(alignment: .leading, spacing: 3) {
                Text(artwork.artistName)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Color.picardoText)
                Text(artwork.title)
                    .font(.system(size: 21, weight: .semibold, design: .serif).italic())
                    .foregroundStyle(Color.picardoText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if !specLine(artwork).isEmpty {
                    Text(specLine(artwork))
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.picardoTextSecondary)
                        .lineLimit(1)
                }
                Text(artwork.price, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(Color.picardoText)
                    .padding(.top, 3)
            }
            Spacer(minLength: 8)
            Button {
                withAnimation(PicardoMotion.quick) { wishlist.toggle(artwork) }
            } label: {
                Image(systemName: saved ? "heart.fill" : "heart")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(saved ? Color.picardoNeonRed : Color.picardoText)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 44, height: 44)
                    .background(Color.picardoCard, in: Circle())
                    .overlay(Circle().strokeBorder(Color.picardoBorder, lineWidth: 0.5))
            }
            .buttonStyle(PicardoPressStyle())
            .accessibilityLabel(saved ? "Remove from saved" : "Save")

            if !artwork.isSold {
                Button {
                    Haptics.tap()
                    onBuy(artwork)
                } label: {
                    Text("Buy")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .frame(height: 44)
                        .background(Color.picardoNeonRed, in: Capsule())
                }
                .buttonStyle(PicardoPressStyle())
                .accessibilityLabel("Buy \(artwork.title)")
            }
        }
    }
}

// MARK: - Studio visit

/// Artist of the Week as a short magazine feature: who, a line in their voice,
/// three works, and a door into the studio.
struct StudioVisitSection: View {
    let feature: ArtistOfTheWeekFeature

    private var works: [Artwork] {
        guard let artist = feature.artist else { return [] }
        return Array(Artwork.samples.filter { $0.artistName == artist.name }.prefix(3))
    }

    var body: some View {
        if let artist = feature.artist {
            VStack(alignment: .leading, spacing: 16) {
                GallerySectionHeader(
                    title: "Studio visit",
                    reason: "This week\u{2019}s artist, in their own space"
                )

                NavigationLink(value: artist) {
                    ZStack(alignment: .bottomLeading) {
                        Color.picardoCard
                            .frame(maxWidth: .infinity)
                            .frame(height: 420)
                            .overlay {
                                ArtworkImage(imageName: feature.portraitImage, contentMode: .fill, maxDimension: 1600)
                                    .allowsHitTesting(false)
                            }
                            .clipped()
                        LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .center, endPoint: .bottom)
                            .allowsHitTesting(false)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ARTIST OF THE WEEK")
                                .font(PicardoType.meta(9))
                                .kerning(1.4)
                                .foregroundStyle(.white.opacity(0.85))
                            Text(artist.name)
                                .font(.system(size: 30, weight: .black, design: .serif))
                                .foregroundStyle(.white)
                            Text("\u{201C}\(feature.blurb)\u{201D}")
                                .font(.system(size: 15, design: .serif).italic())
                                .foregroundStyle(.white.opacity(0.92))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(20)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: GalleryRadius.large, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: GalleryRadius.large, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .accessibilityLabel("Artist of the week: \(artist.name). \(feature.blurb)")
                .accessibilityHint("Opens their studio")

                // Always a matching row of three, or nothing, never one stretched tile.
                if works.count >= 3 {
                    HStack(spacing: 10) {
                        ForEach(works) { work in
                            NavigationLink(value: work) {
                                GalleryArtworkTile(artwork: work, radius: GalleryRadius.small, inset: 9, maxDimension: 500)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 118)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(work.title) by \(work.artistName)")
                        }
                    }
                    .padding(.horizontal, 16)
                }

                NavigationLink(value: artist) {
                    HStack(spacing: 6) {
                        Text("Visit \(artist.name.split(separator: " ").first.map(String.init) ?? artist.name)\u{2019}s studio")
                        Image(systemName: "arrow.right").font(.system(size: 13, weight: .semibold))
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.picardoText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.picardoCard, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.picardoBorder, lineWidth: 1))
                }
                .buttonStyle(PicardoPressStyle())
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Feed card

/// A listing in the studios' feed: the whole piece at its own proportions, edge to
/// edge, with a wall label underneath. No mat, no grey box.
struct GalleryFeedCard: View {
    let artwork: Artwork
    let isSaved: Bool
    let onSave: () -> Void
    let onBuy: () -> Void


    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(value: artwork) {
                GalleryArtworkTile(artwork: artwork)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(4.0 / 5.0, contentMode: .fit)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(artwork.title) by \(artwork.artistName)")

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(artwork.artistName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.picardoText)
                    Text(artwork.title)
                        .font(.system(size: 18, weight: .semibold, design: .serif).italic())
                        .foregroundStyle(Color.picardoText)
                        .lineLimit(2)
                    Text(artwork.price, format: .currency(code: "USD").precision(.fractionLength(0)))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.picardoText)
                        .padding(.top, 2)
                }
                Spacer(minLength: 8)
                Button(action: onSave) {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(isSaved ? Color.picardoNeonRed : Color.picardoText)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSaved ? "Remove from saved" : "Save")
                if !artwork.isSold {
                    Button {
                        Haptics.tap()
                        onBuy()
                    } label: {
                        Text("Buy")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 38)
                            .background(Color.picardoNeonRed, in: Capsule())
                    }
                    .buttonStyle(PicardoPressStyle())
                    .accessibilityLabel("Buy \(artwork.title)")
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Reading

/// Articles as a quiet reading list, not another carousel.
struct ReadingList: View {
    let articles: [HomeArticle]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(articles.prefix(3).enumerated()), id: \.element.id) { i, article in
                NavigationLink(value: article) {
                    HStack(alignment: .top, spacing: 14) {
                        Text(String(format: "%02d", i + 1))
                            .font(.system(size: 22, weight: .black, design: .serif))
                            .foregroundStyle(Color.picardoTextSecondary.opacity(0.6))
                            .frame(width: 34, alignment: .leading)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(article.title)
                                .font(.system(size: 17, weight: .bold, design: .serif))
                                .foregroundStyle(Color.picardoText)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(article.author) \u{00B7} \(article.readTime)")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.picardoTextSecondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.picardoTextSecondary)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if i < min(articles.count, 3) - 1 {
                    Divider().padding(.leading, 48)
                }
            }
        }
        .padding(.horizontal, 16)
        .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: GalleryRadius.large, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: GalleryRadius.large, style: .continuous).strokeBorder(Color.picardoBorder, lineWidth: 0.5))
        .padding(.horizontal, 16)
    }
}

// MARK: - One way to show art

/// The single rule for artwork on Home: every piece hangs on the same wall (same
/// colour, same margin, same soft shadow), whole and never cropped. Pieces
/// photographed with a mat and pieces without one then read as one collection.
enum GalleryRadius {
    /// Heroes, features, feed tiles, videos, list cards.
    static let large: CGFloat = 24
    /// Thumbnails and small tiles.
    static let small: CGFloat = 12
}

struct GalleryArtworkTile: View {
    let artwork: Artwork
    var radius: CGFloat = GalleryRadius.large
    /// Space between the piece and the edge of the wall.
    var inset: CGFloat = 26
    var maxDimension: CGFloat = 1400

    var body: some View {
        Color.picardoCard
            .overlay {
                ArtworkImage(artwork: artwork, contentMode: .fit, maxDimension: maxDimension)
                    .shadow(color: .black.opacity(0.18), radius: inset * 0.4, y: inset * 0.25)
                    .padding(inset)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.picardoBorder, lineWidth: 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}
