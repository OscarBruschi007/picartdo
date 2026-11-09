import SwiftUI

// Home, built from one small system (see `HomeLayout`):
//   • Hero card: full width, 28pt radius, the art leads, text on a soft scrim.
//   • Tile: fixed ratio per shelf, 16pt radius, plain text underneath.
//   • Row: 10pt thumbnail and text, hairline dividers, no box around it.
// One header style, one margin, one gap between sections. Red is kept for Buy,
// unseen story rings and "See all"; everything else is ink on paper.

// MARK: - Zoom transitions

private struct HomeZoomNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    /// Set by Home so artwork opens with a zoom from wherever it was tapped.
    var homeZoomNamespace: Namespace.ID? {
        get { self[HomeZoomNamespaceKey.self] }
        set { self[HomeZoomNamespaceKey.self] = newValue }
    }
}

private struct HomeZoomSource: ViewModifier {
    let id: AnyHashable
    @Environment(\.homeZoomNamespace) private var namespace

    func body(content: Content) -> some View {
        if let namespace {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

extension View {
    /// Marks this view as where a zoom into the piece starts.
    func homeZoomSource(_ id: AnyHashable) -> some View {
        modifier(HomeZoomSource(id: id))
    }
}

// MARK: - Section header

/// The one header every Home section uses: a quiet title, a short "why", an optional "See all".
struct HomeSectionHeader<Accessory: View>: View {
    let title: String
    var reason: String? = nil
    @ViewBuilder var accessory: Accessory

    var body: some View {
        VStack(spacing: 2) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.picardoText)
                if let reason {
                    Text(reason)
                        .font(.subheadline)
                        .foregroundStyle(Color.picardoTextSecondary)
                        .lineLimit(2)
                }
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            accessory
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, HomeLayout.margin)
    }
}

extension HomeSectionHeader where Accessory == EmptyView {
    init(title: String, reason: String? = nil) {
        self.init(title: title, reason: reason) { EmptyView() }
    }
}

/// "See all ›", in the accent colour.
struct HomeSeeAll<Value: Hashable>: View {
    let value: Value

    var body: some View {
        NavigationLink(value: value) {
            HStack(spacing: 2) {
                Text("See all")
                Image(systemName: "chevron.right")
                    .imageScale(.small)
                    .fontWeight(.semibold)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.picardoNeonRed)
            .frame(minHeight: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shelf

/// A horizontal shelf that snaps to its tiles. At accessibility text sizes it
/// becomes a vertical list, so nothing gets squeezed.
struct HomeShelf<Content: View>: View {
    @ViewBuilder var content: Content
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 24) { content }
                .padding(.horizontal, HomeLayout.margin)
        } else {
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: HomeLayout.itemGap) { content }
                    .scrollTargetLayout()
            }
            .contentMargins(.horizontal, HomeLayout.margin, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }
}

// MARK: - Header

/// The top bar: Picasso on the left, the name centred with today's date beneath it,
/// messages on the right with an unread badge.
struct HomeHeader<Wordmark: View>: View {
    var unreadMessages: Int
    var onMessages: () -> Void
    @ViewBuilder var wordmark: Wordmark

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                wordmark
                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .accessibilityLabel(Date().formatted(date: .complete, time: .omitted))
            }

            HStack {
                PicassoButton(inline: true)
                Spacer()
                Button {
                    Haptics.tap()
                    onMessages()
                } label: {
                    Image(systemName: "paperplane")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(Color.picardoText)
                        .frame(width: 44, height: 44)
                        .overlay(alignment: .topTrailing) {
                            if unreadMessages > 0 {
                                Text("\(min(unreadMessages, 9))")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(minWidth: 18, minHeight: 18)
                                    .background(Circle().fill(Color.picardoNeonRed))
                                    .overlay(Circle().strokeBorder(Color.picardoBackground, lineWidth: 2))
                                    .offset(x: 2, y: 2)
                            }
                        }
                }
                .buttonStyle(PicardoPressStyle())
                .accessibilityLabel("Messages")
                .accessibilityValue(unreadMessages > 0 ? "\(unreadMessages) unread" : "")
            }
        }
        .padding(.horizontal, HomeLayout.margin - 4)
    }
}

// MARK: - Stories

/// Everyone the same size. Unseen stories get a thin accent ring, seen ones a hairline.
struct HomeStoriesRow: View {
    let artists: [Artist]
    let identity: ProfileIdentity
    var onAddStory: () -> Void

    @State private var openedStory: Artist?
    @State private var messageArtist: Artist?
    @State private var seen: Set<Artist.ID> = []

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: HomeLayout.itemGap) {
                Button {
                    Haptics.tap()
                    onAddStory()
                } label: {
                    yourStory
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add to your story")

                ForEach(artists) { artist in
                    Button {
                        Haptics.tap()
                        openedStory = artist
                    } label: {
                        HomeStoryAvatar(
                            name: artist.name.components(separatedBy: " ").first ?? artist.name,
                            ring: seen.contains(artist.id) ? .seen : .unseen
                        ) {
                            ArtworkImage(imageName: artist.avatarImage, contentMode: .fill, maxDimension: 240)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(artist.name)\u{2019}s story")
                    .accessibilityValue(seen.contains(artist.id) ? "Seen" : "New")
                    .contextMenu {
                        Button {
                            messageArtist = artist
                        } label: {
                            Label("Message", systemImage: "envelope")
                        }
                        NavigationLink(value: artist) {
                            Label("View profile", systemImage: "person")
                        }
                    }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, HomeLayout.margin, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .fullScreenCover(item: $openedStory) { artist in
            StoryViewer(story: artist.feedStory, artist: artist) {
                seen.insert(artist.id)
                openedStory = nil
            }
        }
        .messageComposer(artist: $messageArtist)
    }

    private var yourStory: some View {
        HomeStoryAvatar(name: "Your story", ring: .none) {
            if let custom = identity.avatarImage {
                Image(uiImage: custom).resizable().scaledToFill()
            } else {
                ArtworkImage(imageName: identity.avatarAsset, contentMode: .fill, maxDimension: 240)
            }
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.picardoBackground)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.picardoText))
                .overlay(Circle().strokeBorder(Color.picardoBackground, lineWidth: 2))
                .offset(x: -2, y: 50)
        }
    }
}

struct HomeStoryAvatar<Photo: View>: View {
    enum Ring { case unseen, seen, none }

    let name: String
    let ring: Ring
    @ViewBuilder var photo: Photo

    private static var size: CGFloat { 68 }

    var body: some View {
        VStack(spacing: 6) {
            photo
                .frame(width: Self.size, height: Self.size)
                .background(Color.picardoCard)
                .clipShape(Circle())
                .padding(4)
                .overlay {
                    switch ring {
                    case .unseen:
                        Circle().strokeBorder(
                            AngularGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.76, blue: 0.24),
                                    Color.picardoNeonRed,
                                    Color(red: 0.62, green: 0.18, blue: 0.62),
                                    Color.picardoNeonRed,
                                    Color(red: 0.98, green: 0.76, blue: 0.24),
                                ],
                                center: .center,
                                startAngle: .degrees(90),
                                endAngle: .degrees(450)
                            ),
                            lineWidth: 2.5
                        )
                    case .seen:   Circle().strokeBorder(Color.picardoBorder, lineWidth: 1)
                    case .none:   EmptyView()
                    }
                }

            Text(name)
                .font(.caption)
                .foregroundStyle(ring == .seen ? Color.picardoTextSecondary : Color.picardoText)
                .lineLimit(1)
        }
        .frame(width: Self.size + 8)
    }
}

// MARK: - Featured (the one big moment)

/// Up to five pieces, one per page. The art is shown whole on a soft wash of its
/// own colours, with the label and Buy on a scrim along the bottom.
struct HomeFeaturedCarousel: View {
    let artworks: [Artwork]
    var onBuy: (Artwork) -> Void

    @State private var current: Artwork.ID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var index: Int {
        artworks.firstIndex { $0.id == current } ?? 0
    }

    var body: some View {
        VStack(spacing: HomeLayout.itemGap) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: HomeLayout.itemGap) {
                    ForEach(artworks) { artwork in
                        HomeFeaturedCard(artwork: artwork, onBuy: { onBuy(artwork) })
                            .containerRelativeFrame(.horizontal)
                            .scrollTransition(axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(reduceMotion || phase.isIdentity ? 1 : 0.96)
                                    .opacity(phase.isIdentity ? 1 : 0.85)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, HomeLayout.margin, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $current)
            .scrollIndicators(.hidden)
            .onChange(of: current) { _, _ in Haptics.select() }

            if artworks.count > 1 {
                HStack(spacing: 6) {
                    ForEach(Array(artworks.enumerated()), id: \.element.id) { i, _ in
                        Capsule()
                            .fill(Color.picardoText.opacity(i == index ? 0.9 : 0.2))
                            .frame(width: i == index ? 16 : 6, height: 6)
                    }
                }
                .animation(PicardoMotion.quick, value: index)
                .accessibilityElement()
                .accessibilityLabel("Piece \(index + 1) of \(artworks.count)")
            }
        }
    }
}

private struct HomeFeaturedCard: View {
    let artwork: Artwork
    var onBuy: () -> Void

    @Environment(WishlistStore.self) private var wishlist
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: HomeLayout.heroRadius, style: .continuous)
    }

    var body: some View {
        let saved = wishlist.isLiked(artwork)
        VStack(alignment: .leading, spacing: 14) {
            NavigationLink(value: artwork) {
                Color.picardoCard
                    .overlay {
                        // A soft wash of the piece's own colours behind it.
                        ArtworkImage(artwork: artwork, contentMode: .fill, maxDimension: 300)
                            .blur(radius: 40)
                            .opacity(0.5)
                            .allowsHitTesting(false)
                    }
                    .overlay {
                        ArtworkImage(artwork: artwork, contentMode: .fit, maxDimension: 1600)
                            .shadow(color: .black.opacity(0.16), radius: 14, y: 8)
                            .padding(28)
                            .allowsHitTesting(false)
                    }
                    .aspectRatio(4.0 / 5.0, contentMode: .fit)
                    .clipShape(shape)
                    .contentShape(shape)
                    .homeZoomSource(artwork.id)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(artwork.title) by \(artwork.artistName), \(artwork.price.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
            .accessibilityHint("Opens the piece")

            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(artwork.title)
                        .font(.system(.title3, design: .serif).weight(.semibold))
                        .foregroundStyle(Color.picardoText)
                        .lineLimit(1)
                    Text("\(artwork.artistName) \u{00B7} \(artwork.price.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
                        .font(.subheadline)
                        .foregroundStyle(Color.picardoTextSecondary)
                        .lineLimit(1)
                }
                .accessibilityHidden(true)

                Spacer(minLength: 8)

                Button {
                    withAnimation(PicardoMotion.quick) { wishlist.toggle(artwork) }
                } label: {
                    Image(systemName: saved ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.picardoText)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PicardoPressStyle())
                .sensoryFeedback(.selection, trigger: saved)
                .accessibilityLabel(saved ? "Remove from saved" : "Save")

                if !artwork.isSold {
                    Button {
                        Haptics.tap()
                        onBuy()
                    } label: {
                        Text("Buy")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 22)
                            .frame(height: 44)
                            .background(Capsule().fill(Color.picardoNeonRed))
                    }
                    .buttonStyle(PicardoPressStyle())
                    .accessibilityLabel("Buy \(artwork.title)")
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Tile

/// A shelf or grid tile: the image at a fixed ratio, plain text underneath.
struct HomeArtworkTile: View {
    let artwork: Artwork
    var width: CGFloat? = nil
    var ratio: CGFloat = 3.0 / 4.0

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: HomeLayout.tileRadius, style: .continuous)
    }

    var body: some View {
        NavigationLink(value: artwork) {
            VStack(alignment: .leading, spacing: 8) {
                Color.picardoCard
                    .aspectRatio(ratio, contentMode: .fit)
                    .overlay {
                        ArtworkImage(artwork: artwork, contentMode: .fill, maxDimension: 600)
                            .allowsHitTesting(false)
                    }
                    .clipShape(shape)
                    .contentShape(shape)
                    .homeZoomSource(artwork.id)

                VStack(alignment: .leading, spacing: 1) {
                    Text(artwork.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.picardoText)
                        .lineLimit(1)
                    Text(artwork.artistName)
                        .font(.footnote)
                        .foregroundStyle(Color.picardoTextSecondary)
                        .lineLimit(1)
                    Text(artwork.isSold ? "Sold" : artwork.price.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(artwork.isSold ? Color.picardoTextSecondary : Color.picardoText)
                        .padding(.top, 2)
                }
            }
            .frame(width: width)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(artwork.title) by \(artwork.artistName), \(artwork.isSold ? "sold" : artwork.price.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
    }
}

// MARK: - Posts from people you follow

/// One post layout for everything: who, the media, the piece it shows, actions, caption.
struct HomePostCard: View {
    let post: ArtistPost
    var onNotForMe: () -> Void = {}

    @Environment(\.feedVideoEnabled) private var feedVideoEnabled
    @State private var isVisible = false
    @State private var liked = false
    @State private var saved = false
    @State private var showMessage = false

    private var mediaShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: HomeLayout.heroRadius, style: .continuous)
    }

    private var firstName: String {
        post.artist.name.components(separatedBy: " ").first ?? post.artist.name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            media
            if let listing = post.listing {
                shopTag(listing)
            }
            actions
            Text("\(Text(firstName).fontWeight(.semibold)) \(post.caption)")
                .font(.subheadline)
                .foregroundStyle(Color.picardoText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
        }
        .messageComposer(isPresented: $showMessage, artist: post.artist)
    }

    /// Who posted and when, centred over the media; the options menu sits on the right.
    private var header: some View {
        HStack(spacing: 8) {
            NavigationLink(value: post.artist) {
                HStack(spacing: 10) {
                    ArtworkImage(imageName: post.artist.avatarImage, contentMode: .fill, maxDimension: 120)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    Text(post.artist.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.picardoText)
                    if post.artist.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(Color.picardoText)
                            .accessibilityLabel("Verified")
                    }
                }
            }
            .buttonStyle(.plain)

            Text("\u{00B7} \(post.timeAgo)")
                .font(.subheadline)
                .foregroundStyle(Color.picardoTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 44)
        .overlay(alignment: .trailing) {
            Menu {
                Button {
                    showMessage = true
                } label: {
                    Label("Message \(firstName)", systemImage: "envelope")
                }
                Button(role: .destructive, action: onNotForMe) {
                    Label("Not for me", systemImage: "eye.slash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("More options")
        }
        .frame(minHeight: 44)
    }

    private var media: some View {
        Color.picardoCard
            .aspectRatio(4.0 / 5.0, contentMode: .fit)
            .overlay {
                if post.isVideo {
                    LoopingPostVideo(
                        resourceName: post.videoName ?? post.imageName,
                        fallbackImageName: post.imageName,
                        fill: true
                    )
                    // Only the post that's mostly on screen plays.
                    .environment(\.feedVideoEnabled, feedVideoEnabled && isVisible)
                } else {
                    ArtworkImage(imageName: post.imageName, contentMode: .fill, maxDimension: 1400)
                }
            }
            .clipShape(mediaShape)
            .onScrollVisibilityChange(threshold: 0.75) { isVisible = $0 }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(post.isVideo ? "Video by \(post.artist.name)" : "Photo by \(post.artist.name)")
    }

    private func shopTag(_ listing: Artwork) -> some View {
        NavigationLink(value: listing) {
            HStack(spacing: 12) {
                ArtworkImage(artwork: listing, contentMode: .fill, maxDimension: 160)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: HomeLayout.thumbRadius, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text(listing.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.picardoText)
                        .lineLimit(1)
                    Text(listing.isSold ? "Sold" : "Available")
                        .font(.footnote)
                        .foregroundStyle(Color.picardoTextSecondary)
                }
                Spacer(minLength: 8)
                if !listing.isSold {
                    Text(listing.price, format: .currency(code: "USD").precision(.fractionLength(0)))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.picardoText)
                }
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.picardoTextSecondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(listing.title), \(listing.isSold ? "sold" : listing.price.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
        .accessibilityHint("Opens the listing")
    }

    /// Like, comments, message and save, centred under the media.
    private var actions: some View {
        HStack(spacing: 28) {
            Button {
                liked.toggle()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: liked ? "heart.fill" : "heart")
                        .contentTransition(.symbolEffect(.replace))
                    Text(count(post.likes + (liked ? 1 : 0)))
                        .contentTransition(.numericText())
                }
            }
            .sensoryFeedback(.selection, trigger: liked)
            .accessibilityLabel(liked ? "Unlike" : "Like")
            .accessibilityValue("\(post.likes + (liked ? 1 : 0)) likes")

            HStack(spacing: 5) {
                Image(systemName: "bubble.right")
                Text(count(post.comments))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(post.comments) comments")

            Button {
                showMessage = true
            } label: {
                Image(systemName: "paperplane")
            }
            .accessibilityLabel("Message \(firstName)")

            Button {
                saved.toggle()
            } label: {
                Image(systemName: saved ? "bookmark.fill" : "bookmark")
                    .contentTransition(.symbolEffect(.replace))
            }
            .sensoryFeedback(.selection, trigger: saved)
            .accessibilityLabel(saved ? "Remove from saved" : "Save")
        }
        .font(.body.weight(.medium))
        .foregroundStyle(Color.picardoText)
        .buttonStyle(.plain)
        .frame(minHeight: 32)
        .frame(maxWidth: .infinity)
    }

    private func count(_ n: Int) -> String {
        n >= 1000 ? String(format: "%.1fk", Double(n) / 1000) : "\(n)"
    }
}

// MARK: - Studio visit

/// The editorial moment: this week's artist, in their space, in their words.
struct HomeStudioVisit: View {
    let feature: ArtistOfTheWeekFeature

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: HomeLayout.heroRadius, style: .continuous)
    }

    var body: some View {
        if let artist = feature.artist {
            VStack(alignment: .leading, spacing: HomeLayout.headerGap) {
                HomeSectionHeader(title: "Studio visit", reason: "This week\u{2019}s artist, in their own space")

                NavigationLink(value: artist) {
                    Color.picardoCard
                        .aspectRatio(4.0 / 5.0, contentMode: .fit)
                        .overlay {
                            ArtworkImage(imageName: feature.portraitImage, contentMode: .fill, maxDimension: 1600)
                                .allowsHitTesting(false)
                        }
                        .overlay(alignment: .bottom) {
                            LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                                .frame(height: 260)
                                .allowsHitTesting(false)
                        }
                        .overlay(alignment: .bottomLeading) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Artist of the week")
                                    .font(.caption.weight(.semibold))
                                    .textCase(.uppercase)
                                    .kerning(0.6)
                                    .foregroundStyle(.white.opacity(0.8))
                                Text(artist.name)
                                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text("\u{201C}\(feature.blurb)\u{201D}")
                                    .font(.system(.body, design: .serif).italic())
                                    .foregroundStyle(.white.opacity(0.92))
                                    .lineLimit(3)
                                HStack(spacing: 4) {
                                    Text("Visit the studio")
                                    Image(systemName: "chevron.right").imageScale(.small)
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.top, 4)
                            }
                            .padding(20)
                        }
                        .clipShape(shape)
                        .contentShape(shape)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, HomeLayout.margin)
                .accessibilityLabel("Studio visit: \(artist.name). \(feature.blurb)")
                .accessibilityHint("Opens their studio")
            }
        }
    }
}

// MARK: - Events

struct HomeEventsShelf: View {
    let events: [ArtEventItem]
    let city: String

    var body: some View {
        if !events.isEmpty {
            VStack(alignment: .leading, spacing: HomeLayout.headerGap) {
                HomeSectionHeader(title: "This week near you", reason: "Exhibitions, talks and live events in \(city)") {
                    HomeSeeAll(value: CityEventsList())
                }
                HomeShelf {
                    ForEach(events) { event in
                        NavigationLink(value: event) {
                            HomeEventTile(event: event)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct HomeEventTile: View {
    let event: ArtEventItem

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: HomeLayout.tileRadius, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.picardoCard
                .aspectRatio(16.0 / 10.0, contentMode: .fit)
                .overlay {
                    ArtworkImage(imageName: event.imageName, contentMode: .fill, maxDimension: 700)
                        .allowsHitTesting(false)
                }
                .overlay(alignment: .topLeading) {
                    Text("\(event.month) \(event.day)")
                        .font(.caption2.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(Color.picardoText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.picardoBackground))
                        .padding(10)
                }
                .clipShape(shape)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.picardoText)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                Text("\(event.type) \u{00B7} \(event.isFree ? "Free" : event.priceLabel)")
                    .font(.footnote)
                    .foregroundStyle(Color.picardoTextSecondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 260)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - News

/// The one part of Home set like a news app: a masthead with the name and today's date,
/// a lead story card with more stories inside it, then single story cards.
struct HomeReadingList: View {
    let articles: [HomeArticle]

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: HomeLayout.tileRadius + 4, style: .continuous)
    }

    var body: some View {
        if let lead = articles.first {
            VStack(spacing: HomeLayout.headerGap) {
                masthead

                VStack(spacing: HomeLayout.itemGap) {
                    leadCard(lead, more: Array(articles.dropFirst().prefix(2)))
                    ForEach(articles.dropFirst(3).prefix(2)) { article in
                        NavigationLink(value: article) {
                            storyCard(article)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, HomeLayout.margin)
            }
        }
    }

    private var masthead: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Picartdo")
                    .font(.system(.title, design: .serif).weight(.black))
                Text("News")
                    .font(.title.weight(.bold))
            }
            .foregroundStyle(Color.picardoText)
            Text(Date().formatted(.dateTime.month(.wide).day()))
                .font(.title.weight(.bold))
                .foregroundStyle(Color.picardoTextSecondary)
            HomeSeeAll(value: HomeArticlesList())
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .padding(.horizontal, HomeLayout.margin)
    }

    private func source(_ article: HomeArticle) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "building.columns.fill")
                .font(.footnote)
            Text(article.kicker)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
        }
        .foregroundStyle(Color.picardoText)
    }

    private func byline(_ article: HomeArticle) -> some View {
        Text("\(article.author) \u{00B7} \(article.readTime) read")
            .font(.footnote)
            .foregroundStyle(Color.picardoTextSecondary)
            .lineLimit(1)
    }

    /// Top story: a big headline, then "More stories" listed inside the same card.
    private func leadCard(_ lead: HomeArticle, more: [HomeArticle]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink(value: lead) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Top Story")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .kerning(0.6)
                        .foregroundStyle(Color.picardoNeonRed)
                    source(lead)
                    Text(lead.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.picardoText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    byline(lead)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !more.isEmpty {
                Divider().padding(.horizontal, 16)
                Text("More Stories")
                    .font(.headline)
                    .foregroundStyle(Color.picardoText)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                ForEach(Array(more.enumerated()), id: \.element.id) { i, article in
                    if i > 0 { Divider().padding(.leading, 16 + 28) }
                    NavigationLink(value: article) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "building.columns.fill")
                                .font(.footnote)
                                .foregroundStyle(Color.picardoText)
                                .frame(width: 18, height: 20)
                            Text(article.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.picardoText)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 4)
            }
        }
        .background(Color.picardoCard)
        .clipShape(cardShape)
    }

    private func storyCard(_ article: HomeArticle) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            source(article)
            Text(article.title)
                .font(.headline)
                .foregroundStyle(Color.picardoText)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
            byline(article)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.picardoCard)
        .clipShape(cardShape)
        .contentShape(cardShape)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Discover more

/// The open-ended part of Home: a two-column grid of everything not shown above.
struct HomeDiscoverGrid: View {
    let artworks: [Artwork]

    private let columns = [
        GridItem(.flexible(), spacing: HomeLayout.itemGap, alignment: .top),
        GridItem(.flexible(), spacing: HomeLayout.itemGap, alignment: .top),
    ]

    var body: some View {
        if !artworks.isEmpty {
            VStack(alignment: .leading, spacing: HomeLayout.headerGap) {
                HomeSectionHeader(title: "Discover more", reason: "New work from living artists")
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(artworks) { artwork in
                        HomeArtworkTile(artwork: artwork, ratio: 4.0 / 5.0)
                    }
                }
                .padding(.horizontal, HomeLayout.margin)
            }
        }
    }
}

// MARK: - Legacy radii

/// Still used by the full events guide and the older post card outside Home's new layout.
enum GalleryRadius {
    static let large: CGFloat = 24
    static let small: CGFloat = 12
}
