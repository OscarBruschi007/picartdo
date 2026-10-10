import SwiftUI


// MARK: - Artist Post Model

struct ArtistPost: Identifiable {
    let id = UUID()
    let artist: Artist
    let imageName: String
    let caption: String
    let likes: Int
    let comments: Int
    let timeAgo: String
    let isVideo: Bool
    var views: Int = 0
    /// Video length, shown on the video badge.
    var duration: String? = nil
    /// The listing this post shows, when the piece is for sale. Rendered as a shop tag.
    var listing: Artwork? = nil
    /// Bundle resource for autoplaying video posts (`studio_cubes.mp4` → `studio_cubes`).
    var videoName: String? = nil

    /// Stable across launches, used to remember posts marked "Not for Me".
    var feedKey: String { "\(artist.name)|\(imageName)|\(caption.prefix(32))" }
}

extension ArtistPost {
    private static func listing(_ imageName: String) -> Artwork? {
        Artwork.samples.first { $0.imageName == imageName }
    }

    private static func post(
        _ imageName: String,
        caption: String,
        likes: Int,
        comments: Int,
        timeAgo: String
    ) -> ArtistPost {
        ArtistPost(
            artist: Artist.oscar,
            imageName: imageName,
            caption: caption,
            likes: likes,
            comments: comments,
            timeAgo: timeAgo,
            isVideo: false,
            listing: listing(imageName)
        )
    }

    /// One post per unique work — never a close-up of a piece already listed.
    static let samples: [ArtistPost] = [
        ArtistPost(
            artist: Artist.oscar,
            imageName: "oscar_studio",
            caption: "At the canvas. Colour going down by the window.",
            likes: 842,
            comments: 36,
            timeAgo: "1h",
            isVideo: false
        ),
        post("circle_worlds", caption: "Twenty living worlds on one canvas.", likes: 1567, comments: 74, timeAgo: "2h"),
        post("cross_garden", caption: "Green field of crosses around a dotted inner world.", likes: 742, comments: 31, timeAgo: "4h"),
        post("orange_scallops", caption: "Orange scallops, black bodies, a watching moon in the corner.", likes: 1204, comments: 57, timeAgo: "6h"),
        post("crossroads", caption: "The whole page is one creature. Ink, no color.", likes: 618, comments: 22, timeAgo: "9h"),
        post("blue_moon", caption: "Blue moon. The quiet one.", likes: 980, comments: 44, timeAgo: "12h"),
        post("red_compass", caption: "Four quarters around one dotted face.", likes: 865, comments: 38, timeAgo: "1d"),
        post("violet_window", caption: "Purple rings holding a small universe.", likes: 533, comments: 19, timeAgo: "1d"),
        post("chorus", caption: "Faces stacked in the red and blue noise.", likes: 702, comments: 26, timeAgo: "2d"),
        post("night_watch", caption: "Eyes in the black. This one took nights.", likes: 548, comments: 20, timeAgo: "3d"),
        post("ink_garden", caption: "Loose lines until the forms show up.", likes: 411, comments: 15, timeAgo: "4d"),
    ]

    static let studioVideos: [ArtistPost] = [
        video("studio_cubes", artist: "Kai Moreau", caption: "Impossible architecture, one plane at a time.", likes: 2140, comments: 86, timeAgo: "32m", views: 18_400),
        video("studio_frame", artist: "Ellis Ward", caption: "Framing the work. This one needed a black box.", likes: 980, comments: 41, timeAgo: "1h", views: 9_120),
        video("studio_switching", artist: "Noah Pell", caption: "Switching. Green first, then the rest of the field.", likes: 1670, comments: 63, timeAgo: "2h", views: 14_800),
        video("studio_books", artist: "Wren Solis", caption: "The books quietly shaping my art.", likes: 2410, comments: 94, timeAgo: "3h", views: 22_600),
        video("studio_hang", artist: "Mateo Ruiz", caption: "Four squares. The fifth one finds the centre.", likes: 1320, comments: 52, timeAgo: "5h", views: 11_050),
        video("studio_stretch", artist: "Silas Kane", caption: "Stretching colour until it holds.", likes: 1880, comments: 71, timeAgo: "8h", views: 16_300),
        video("studio_carry", artist: "Samir Cole", caption: "Walking the piece into the light.", likes: 2750, comments: 112, timeAgo: "12h", views: 31_200),
    ]

    /// Lengths of the bundled studio videos, shown on each post's badge.
    private static let durations: [String: String] = [
        "studio_switching": "0:28", "studio_frame": "0:22", "studio_books": "0:37",
        "studio_carry": "0:17", "studio_stretch": "0:15", "studio_cubes": "0:16", "studio_hang": "0:20",
    ]

    private static func video(
        _ name: String,
        artist: String,
        caption: String,
        likes: Int,
        comments: Int,
        timeAgo: String,
        views: Int
    ) -> ArtistPost {
        ArtistPost(
            artist: Artist.named(artist) ?? .oscar,
            imageName: name,
            caption: caption,
            likes: likes,
            comments: comments,
            timeAgo: timeAgo,
            isVideo: true,
            views: views,
            duration: durations[name] ?? "",
            videoName: name
        )
    }
}

// MARK: - Artist of the Week
// Fill `current` when the portrait is ready: set `artist` and `portraitImage`.

struct ArtistOfTheWeekFeature {
    var artist: Artist?
    var portraitImage: String
    var blurb: String

    static let roster: [ArtistOfTheWeekFeature] = [
        ArtistOfTheWeekFeature(
            artist: Artist.oscar,
            portraitImage: "oscar_studio",
            blurb: "At the canvas. Colour by the window."
        ),
        ArtistOfTheWeekFeature(
            artist: Artist.named("Hugo Kessler"),
            portraitImage: "artist_of_the_week",
            blurb: "Four figures on a red ground. This week's studio."
        ),
        ArtistOfTheWeekFeature(
            artist: Artist.named("Nix Calder"),
            portraitImage: "third_eye_seat",
            blurb: "Neon diagrams of the body. This week's studio."
        ),
    ].compactMap { feature in
        feature.artist == nil ? nil : feature
    }

    static let current = roster.first ?? ArtistOfTheWeekFeature(
        artist: Artist.oscar,
        portraitImage: "oscar_studio",
        blurb: "At the canvas. Colour by the window."
    )
}

// MARK: - Home articles
// Append to `samples` when copy is ready. Empty means Home shows placeholders.

struct HomeArticle: Identifiable, Hashable {
    let id: UUID
    var title: String
    var kicker: String
    var imageName: String
    var author: String
    var readTime: String
    var body: String

    init(
        id: UUID = UUID(),
        title: String,
        kicker: String = "Essay",
        imageName: String = "",
        author: String = "Picartdo",
        readTime: String = "4 min",
        body: String = ""
    ) {
        self.id = id
        self.title = title
        self.kicker = kicker
        self.imageName = imageName
        self.author = author
        self.readTime = readTime
        self.body = body
    }

    static let samples: [HomeArticle] = [
        HomeArticle(
            title: "Holding Place: The Work of Alaskan Artist Sonya Kelliher-Combs",
            kicker: "National Gallery",
            author: "Julie Decker",
            readTime: "5 min",
            body: """
Sonya Kelliher-Combs builds work from walrus stomach, hair, quills, and polymer — materials that remember hunting camps, women’s labor, and the land around Sitŋasuaq (Nome). The surfaces look like skin: stitched, guarded, sometimes wounded.

Her series Secrets and Idiot Strings hold private grief and public history. Credible names Alaska villages marked by abuse, asking who gets believed. When she installs cultural belongings from museum stores, she asks who decided those objects were artifacts, and who they still belong to.

From the National Gallery of Art.
"""
        ),
        HomeArticle(
            title: "Piliāmoʻo Creates Archives of Erasure and Currents of Return",
            kicker: "National Gallery",
            author: "Josh Tengan",
            readTime: "10 min",
            body: """
Mark Hamasaki and Kapulani Landgraf photograph as Piliāmoʻo — “to cling as a lizard” in ʻŌlelo Hawaiʻi. Their first series watched Interstate H-3 cut through sacred sites on Oʻahu, treating the freeway as loss, not progress.

Later they documented Waiāhole farmers reopening irrigation channels so kalo could drink cold water again. Those pictures entered a landmark water-rights case. In Kailua they built a book of residents, chants, and black-and-white views that refuse the postcard of paradise.

From the National Gallery of Art.
"""
        ),
        HomeArticle(
            title: "There Will Be Light",
            kicker: "National Gallery",
            author: "Amy Chaloupka",
            readTime: "6 min",
            body: """
Barbara Earl Thomas does not stay in one medium. Cut paper, glass, print, and paint all carry her stories of family, Black life, and the unknown she keeps walking into.

The National Gallery’s portrait of her practice is less a career timeline than a way of looking: step toward the next material, let light through the cut, keep telling.

From the National Gallery of Art.
"""
        ),
        HomeArticle(
            title: "Everyday Awe: Through the Eyes of Georgia O’Keeffe",
            kicker: "National Gallery",
            author: "Nathalie Ryan",
            readTime: "4 min",
            body: """
O’Keeffe found the extraordinary in jack-in-the-pulpits, bones, and stones — forms she enlarged until a flower became architecture. Everyday awe, the Gallery argues, is a practice: slow down, look closely, give thanks for what is already in the room.

A high-school teacher once asked her to really see a plant. Decades later, a series of six jack-in-the-pulpit paintings still teach that lesson.

From the National Gallery of Art.
"""
        ),
        HomeArticle(
            title: "10 Ways to Cultivate Everyday Awe",
            kicker: "National Gallery",
            author: "National Gallery of Art",
            readTime: "4 min",
            body: """
Awe is not only canyons and records. Walk outside. Remember a building that stopped you. Watch weather. Notice your hands. Pair each habit with a work in the collection — a Panini church interior, a Backhuysen storm, a Betye Saar assemblage.

The more you look for awe, the article says, the more of it you find. Art is a reliable place to start.

From the National Gallery of Art.
"""
        ),
        HomeArticle(
            title: "Painter George A. Morton Transcends Tradition",
            kicker: "National Gallery",
            author: "National Gallery of Art",
            readTime: "6 min",
            body: """
Atlanta painter George A. Morton studies Rembrandt and Sargent the long way: looking, then remaking, then turning that discipline toward new sitters. Tradition here is a studio method, not a costume.

The piece follows an artist who treats old-master light as something that can still fall on a contemporary face.

From the National Gallery of Art.
"""
        ),
        HomeArticle(
            title: "Artistic Visions of Our Nation’s Nature",
            kicker: "National Gallery",
            author: "Susan Barnett",
            readTime: "8 min",
            body: """
Albert Bierstadt’s bison pictures were not only western spectacle. Buffalo Trail: The Impending Storm shows the animals crossing water under weather — a record of a species being hunted toward disappearance, and of a painter too stunned, at first sight, to shoot or even sketch.

Those canvases joined a wider 19th-century argument for saving the American bison.

From the National Gallery of Art.
"""
        ),
        HomeArticle(
            title: "George Washington, Pictured",
            kicker: "National Gallery",
            author: "National Gallery of Art",
            readTime: "7 min",
            body: """
Washington’s face is an industry: Stuart’s Athenaeum on the dollar, Peale family sittings, Savage’s family group at Mount Vernon, plaster and print. Sitters and painters both struggled with a man who could go blank on the pose.

Read together, the portraits show command, distance, and the making of a national icon.

From the National Gallery of Art.
"""
        ),
        HomeArticle(
            title: "Antonio Canova Sculpts George Washington",
            kicker: "National Gallery",
            author: "National Gallery of Art",
            readTime: "5 min",
            body: """
Jefferson wanted Canova, and he wanted Roman dress, not “puny” boots. Clay sketches try a toga; the plaster settles on armor. The marble that reached North Carolina in 1821 burned with the statehouse ten years later.

A 1970 marble copy, taken from the surviving Italian model, still stands in Raleigh — a second life for a lost sculpture.

From the National Gallery of Art.
"""
        ),
        HomeArticle(
            title: "Artists Who Expand Views of the Southwest",
            kicker: "National Gallery",
            author: "Angélica Becerra",
            readTime: "10 min",
            body: """
Beyond O’Keeffe: Tonita Peña painting Pueblo dances on empty ground, Graciela Iturbide’s angel woman in the Sonoran Desert, Awa Tsireh protecting sacred knowledge, Ruth Asawa’s desert plants, Gene Kloss etching New Mexico light.

Indigenous, Mexican, and incoming artists all redo the borderland — not as empty frontier, but as a lived place.

From the National Gallery of Art.
"""
        ),
        HomeArticle(
            title: "Rare Early Photographs of African American Life",
            kicker: "National Gallery",
            author: "National Gallery of Art",
            readTime: "6 min",
            body: """
A teacher’s 50-year hunt for overlooked pictures became 248 works in the Gallery: Ball, Goodridge, and Augustus Washington running daguerreotype rooms; Douglass using cartes-de-visite as argument; families posing in Sunday clothes after emancipation.

Photography let Black sitters pay for their own image — gold buttons, a school bag, a book — and keep it.

From the National Gallery of Art.
"""
        ),
        HomeArticle(
            title: "Portraits of Trees, a Favorite Subject of Artists",
            kicker: "National Gallery",
            author: "National Gallery of Art",
            readTime: "6 min",
            body: """
Dupré’s oak, Cole’s tornado, Watkins’s Grizzly Giant, Sally Mann’s scarred trunk, Katz’s swamp maple, Roxy Paine’s steel Graft in the Sculpture Garden. Trees here are sitters, not scenery.

An Earth Month walk through paintings, photographs, and prints — and a reminder that a tree can be a witness.

From the National Gallery of Art.
"""
        ),
        HomeArticle(
            title: "16 Black Artists to Know",
            kicker: "National Gallery",
            author: "National Gallery of Art",
            readTime: "7 min",
            body: """
Eight pairings from the collection: Alma Thomas with Sylvia Snowden, Ligon with Dread Scott, Ringgold with McCannon, Gilliam with Whitney, Catlett with Burroughs, Parks with Perkins, Betye Saar with Alison Saar.

Some share a city or a workshop. Two were roommates. Two are mother and daughter. All of them widen what the Gallery’s walls can hold.

From the National Gallery of Art.
"""
        ),
        HomeArticle(
            title: "Alma Thomas: Life in Washington",
            kicker: "National Gallery",
            author: "Sherri Williams",
            readTime: "6 min",
            body: """
Thomas arrived on the Mall at 16, shaking Georgia sand from her shoes. She taught at Shaw for 35 years, painted in a Logan Circle kitchen, and found her mosaic of color after a Howard retrospective dared her to start over.

Pansies, holly, cherry blossom — the city’s flora became the Whitney solo and, later, the White House walls.

From the National Gallery of Art.
"""
        ),
    ]
}

struct CityEventsList: Hashable {}
struct HomeArticlesList: Hashable {}

private enum HomeFeedItem: Identifiable {
    case listing(Artwork)
    case video(ArtistPost)

    var id: String {
        switch self {
        case .listing(let artwork): return "listing-\(artwork.id.uuidString)"
        case .video(let post): return "video-\(post.feedKey)"
        }
    }
}

// MARK: - HomeView
//
// Kept focused on one job: give a returning user a reason to open the app.
// A hero to look at, what's new, what's trending, and the feed from people
// they follow. Category browsing, price filters, and one-off features live
// on the Explore/Services tabs where they belong, not repeated here too.

struct HomeView: View {
    @Binding var showSellSheet: Bool
    @Environment(WishlistStore.self) private var wishlist
    @Environment(TastePreferenceStore.self) private var taste
    @Environment(HomeFeedStore.self) private var homeFeed
    @Environment(\.picardoSplashBridge) private var splashBridge
    @Environment(\.homeRootTick) private var homeRootTick
    @State private var showBuySheet = false
    @State private var buyArtwork: Artwork?
    @State private var path = NavigationPath()

    private var featured: Artwork { homeFeed.featured }
    private var storyArtists: [Artist] { homeFeed.storyArtists }
    private var featuredArticles: [HomeArticle] { homeFeed.articles }
    private var cityEvents: [ArtEventItem] { homeFeed.cityEvents }

    /// Listing, video, listing, video — leftover videos or listings trail at the end.
    private var mixedFeed: [HomeFeedItem] {
        let listings = homeFeed.moreListings
        let videos = homeFeed.studioVideos
        let count = max(listings.count, videos.count)
        var items: [HomeFeedItem] = []
        items.reserveCapacity(listings.count + videos.count)
        for index in 0..<count {
            if index < listings.count {
                items.append(.listing(listings[index]))
            }
            if index < videos.count {
                items.append(.video(videos[index]))
            }
        }
        return items
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                PicartdoBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Picartdo wordmark — tap it, the era steps forward ──
                        PicardoBrandWordmark(size: 24, tracking: 2.5)
                            // During launch the splash wordmark flies onto this spot, then hands over.
                            .opacity(splashBridge?.hidesHomeWordmark == true ? 0 : 1)
                            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                                splashBridge?.reportWordmarkFrame(frame)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 12)
                            .padding(.bottom, 18)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    PicardoEra.advance()
                                }
                            }

                        // ── Circular artist stories ──
                        StoriesRow(artists: storyArtists)
                            .padding(.bottom, 24)

                        ForEach(homeFeed.layout) { block in
                            layoutSection(block)
                                .padding(.bottom, block == .moreForYou ? 40 : 28)
                        }

                        Color.clear.frame(height: 24)
                    }
                }
                .refreshable {
                    try? await Task.sleep(for: .milliseconds(550))
                    withAnimation(PicardoMotion.transition) {
                        homeFeed.refresh(taste: taste)
                    }
                }
                .onAppear {
                    homeFeed.applyTaste(taste)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Artwork.self) { artwork in
                ArtworkDetailView(artwork: artwork)
                    .picardoPushedScreen()
            }
            .navigationDestination(for: Artist.self) { artist in
                ArtistStoreView(artist: artist)
            }
            .navigationDestination(for: HomeArticle.self) { article in
                HomeArticleDetailView(article: article)
                    .picardoPushedScreen()
            }
            .navigationDestination(for: HomeArticlesList.self) { _ in
                HomeArticlesView()
                    .picardoPushedScreen()
            }
            .navigationDestination(for: CityEventsList.self) { _ in
                CityEventsView()
                    .picardoPushedScreen()
            }
            .navigationDestination(for: ArtEventItem.self) { event in
                CityEventDetailView(event: event)
                    .picardoPushedScreen()
            }
            .fullScreenCover(isPresented: $showBuySheet) {
                BuyConfirmationSheet(artwork: featured)
                    .presentationBackground(Color.picardoBackground)
            }
            .fullScreenCover(item: $buyArtwork) { artwork in
                BuyConfirmationSheet(artwork: artwork)
                    .presentationBackground(Color.picardoBackground)
            }
            .overlay(alignment: .topTrailing) {
                PicassoButton()
            }
            .onChange(of: homeRootTick) { _, _ in
                guard !path.isEmpty else { return }
                path = NavigationPath()
            }
        }
    }

    @ViewBuilder
    private func layoutSection(_ block: HomeLayoutBlock) -> some View {
        switch block {
        case .featured:
            FeaturedHeroCard(
                artwork: featured,
                isSaved: wishlist.isLiked(featured),
                onSave: { wishlist.toggle(featured) },
                onBuy: { showBuySheet = true }
            )
            .id(featured.imageName)
            .padding(.horizontal, 16)

        case .artistOfTheWeek:
            VStack(spacing: 8) {
                Text("Artist of the Week")
                    .font(.system(size: 23, weight: .black, design: .serif))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text(homeFeed.artistOfTheWeek.artist?.name ?? "Coming soon")
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                ArtistOfTheWeekCard(feature: homeFeed.artistOfTheWeek)
            }
            .padding(.horizontal, 16)

        case .articles:
            HomeSection(
                title: "Articles",
                subtitle: "National Gallery of Art",
                accessory: {
                    NavigationLink(value: HomeArticlesList()) {
                        Text("Read more ..")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.picardoGold)
                    }
                }
            ) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(featuredArticles) { article in
                            NavigationLink(value: article) {
                                HomeArticleCard(article: article)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

        case .events:
            HomeSection(
                title: "Exhibitions & Events",
                subtitle: "Happening in the city",
                accessory: {
                    NavigationLink(value: CityEventsList()) {
                        Text("Read more ..")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.picardoGold)
                    }
                }
            ) {
                VStack(spacing: 0) {
                    ForEach(Array(cityEvents.enumerated()), id: \.element.id) { index, event in
                        NavigationLink(value: event) {
                            CityEventRow(event: event)
                        }
                        .buttonStyle(.plain)

                        if index < cityEvents.count - 1 {
                            Divider().padding(.leading, 58)
                        }
                    }
                }
                .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }

        case .moreForYou:
            if !mixedFeed.isEmpty {
                HomeSection(title: "More for you", subtitle: "Listings & studio") {
                    LazyVStack(spacing: 28) {
                        ForEach(mixedFeed) { item in
                            switch item {
                            case .listing(let artwork):
                                FeaturedHeroCard(
                                    artwork: artwork,
                                    isSaved: wishlist.isLiked(artwork),
                                    onSave: { wishlist.toggle(artwork) },
                                    onBuy: { buyArtwork = artwork }
                                )
                            case .video(let post):
                                PostCard(post: post)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Simple section title

struct DemoSectionTitle: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Home Section

struct HomeSection<Content: View, Accessory: View>: View {
    let title: String
    let subtitle: String
    let accessory: Accessory
    let content: Content

    init(
        title: String,
        subtitle: String,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.picardoGold)

                    Text(title)
                        .font(.system(size: 23, weight: .black, design: .serif))
                        .foregroundStyle(.primary)

                    Rectangle()
                        .fill(Color.picardoGold)
                        .frame(width: 32, height: 2)
                        .padding(.top, 2)
                }

                Spacer(minLength: 8)

                accessory
                    .padding(.top, 2)
            }
            .padding(.horizontal, 18)

            content
        }
    }
}

extension HomeSection where Accessory == EmptyView {
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.init(title: title, subtitle: subtitle, accessory: { EmptyView() }, content: content)
    }
}

// MARK: - Artist of the Week card

struct ArtistOfTheWeekCard: View {
    var feature: ArtistOfTheWeekFeature = .current

    private var hasPortrait: Bool { !feature.portraitImage.isEmpty }

    var body: some View {
        Group {
            if let artist = feature.artist {
                NavigationLink(value: artist) { card }
                    .buttonStyle(.plain)
            } else {
                card
            }
        }
    }

    private var card: some View {
        ZStack {
            Color.picardoSurface
            if hasPortrait {
                ArtworkImage(imageName: feature.portraitImage, contentMode: .fit, maxDimension: 1600)
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.rectangle")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(Color.picardoGold)
                    Text("Photo coming")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 280)
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

// MARK: - Article cards

struct HomeArticleCard: View {
    let article: HomeArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(article.kicker.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.picardoGold)
            Text(article.title)
                .font(.system(size: 17, weight: .bold, design: .serif))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(article.author) · \(article.readTime)")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 240, alignment: .leading)
        .background(Color.picardoCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}

struct HomeArticlePlaceholderCard: View {
    var title: String = "The story"
    var kicker: String = "Dispatch"

    var body: some View {
        HomeArticleCard(
            article: HomeArticle(
                title: title,
                kicker: kicker,
                author: "Picartdo",
                readTime: "Soon"
            )
        )
    }
}

struct HomeArticleDetailView: View {
    let article: HomeArticle

    var body: some View {
        ZStack {
            PicartdoBackground().ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(article.kicker.uppercased())
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(1)
                            .foregroundStyle(Color.picardoGold)
                        Text(article.title)
                            .font(.system(size: 28, weight: .black, design: .serif))
                        Text("\(article.author) · \(article.readTime)")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text(article.body.isEmpty ? "The full article will live here." : article.body)
                            .font(.system(size: 17, design: .serif))
                            .lineSpacing(6)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HomeArticlesView: View {
    private let articles = HomeArticle.samples

    var body: some View {
        ZStack {
            PicartdoBackground().ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(articles) { article in
                        NavigationLink(value: article) {
                            HomeArticleListRow(article: article)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Articles")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HomeArticleListRow: View {
    let article: HomeArticle

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(article.kicker.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.7)
                    .foregroundStyle(Color.picardoGold)
                Text(article.title)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(article.author) · \(article.readTime)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - City events

struct CityEventRow: View {
    let event: ArtEventItem

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(event.month)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.picardoGold)
                Text("\(event.day)")
                    .font(.system(size: 18, weight: .black, design: .serif))
                    .foregroundStyle(.primary)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(event.venue) · \(event.type)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(event.isOnline ? "Online" : event.distance)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct CityEventsView: View {
    private let events = ArtEventItem.samples
    private let types = ["All", "Exhibition", "Opening", "Gallery Opening", "Live Painting", "Open Studio"]
    @State private var selectedType = "All"

    private var filtered: [ArtEventItem] {
        selectedType == "All" ? events : events.filter { $0.type == selectedType }
    }

    var body: some View {
        ZStack {
            PicartdoBackground().ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(types, id: \.self) { type in
                            let active = selectedType == type
                            Button {
                                withAnimation(PicardoMotion.quick) { selectedType = type }
                            } label: {
                                Text(type)
                                    .font(.system(size: 13, weight: active ? .semibold : .medium))
                                    .foregroundStyle(active ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(active ? Color.black : Color.picardoCard, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { index, event in
                            NavigationLink(value: event) {
                                CityEventRow(event: event)
                            }
                            .buttonStyle(.plain)
                            if index < filtered.count - 1 {
                                Divider().padding(.leading, 58)
                            }
                        }
                    }
                    .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Exhibitions & Events")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CityEventDetailView: View {
    let event: ArtEventItem

    var body: some View {
        ZStack {
            PicartdoBackground().ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(event.type.uppercased())
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(1)
                            .foregroundStyle(Color.picardoGold)
                        Text(event.title)
                            .font(.system(size: 28, weight: .black, design: .serif))
                        Text("\(event.month) \(event.day) · \(event.venue)")
                            .font(.system(size: 15, weight: .medium))
                        Text("\(event.city) · \(event.isOnline ? "Online" : event.distance)")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text("An exhibition and event happening in the city. Details, hours, and tickets will live here.")
                            .font(.system(size: 17, design: .serif))
                            .lineSpacing(6)
                            .padding(.top, 8)
                    }
                    .padding(20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Featured Hero Card

struct FeaturedHeroCard: View {
    let artwork: Artwork
    let isSaved: Bool
    let onSave: () -> Void
    var onBuy: (() -> Void)? = nil
    var onOpen: (() -> Void)? = nil
    var eyebrow: String? = nil
    var allowsMessage: Bool = true

    var body: some View {
        ArtworkCard(
            artwork: artwork,
            variant: .featured,
            isSaved: isSaved,
            onSave: onSave,
            onBuy: onBuy,
            eyebrow: eyebrow,
            onOpenArtwork: onOpen,
            allowsMessage: allowsMessage
        )
    }
}

/// MARK: - Trending Row

struct TrendingRow: View {
    let artwork: Artwork
    let rank: Int
    let isSaved: Bool
    let onSave: () -> Void
    @State private var showBuy = false

    var body: some View {
        ArtworkCard(
            artwork: artwork,
            variant: .listRow,
            isSaved: isSaved,
            onSave: onSave,
            onBuy: { showBuy = true },
            rank: rank
        )
        .fullScreenCover(isPresented: $showBuy) {
            BuyConfirmationSheet(artwork: artwork)
                .presentationBackground(Color.picardoBackground)
        }
    }
}

// MARK: - Grid Card (also used by Explore and the Feed tab)

struct GoatGridCard: View {
    let artwork: Artwork
    var isSaved: Bool = false
    var onSave: (() -> Void)? = nil

    var body: some View {
        ArtworkCard(
            artwork: artwork,
            variant: .grid,
            isSaved: isSaved,
            onSave: onSave
        )
    }
}

// MARK: - Category Feed View (destination from Explore's category chips)

struct CategoryFeedView: View {
    let category: ArtCategory
    var artworks: [Artwork] { Artwork.samples.filter { $0.category == category } }
    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            PicartdoBackground().ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(artworks) { artwork in
                        NavigationLink(value: artwork) {
                            GoatGridCard(artwork: artwork)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
        }
        .navigationTitle(category.rawValue)
        .picardoPushedScreen()
    }
}

// MARK: - Stories Row (circular avatars)

struct StoriesRow: View {
    var artists: [Artist] = Array(Artist.all.prefix(5))
    @State private var openedStory: Artist?
    @State private var messageArtist: Artist?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(artists) { artist in
                    Button {
                        Haptics.tap()
                        openedStory = artist
                    } label: {
                        StoryBubble(artist: artist, showName: true)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            Haptics.tap()
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
            .padding(.horizontal, 18)
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
        .fullScreenCover(item: $openedStory) { artist in
            StoryViewer(story: artist.feedStory, artist: artist) {
                openedStory = nil
            }
        }
        .messageComposer(artist: $messageArtist)
    }
}

struct StoryBubble: View {
    let artist: Artist
    var showName: Bool = true

    private var ringColor: Color {
        let palette: [Color] = [
            Color(red: 0.93, green: 0.40, blue: 0.55), // pink
            Color(red: 0.35, green: 0.62, blue: 0.95), // blue
            Color(red: 0.85, green: 0.68, blue: 0.20), // gold
            Color(red: 0.30, green: 0.72, blue: 0.48), // green
            Color(red: 0.62, green: 0.42, blue: 0.90), // purple
            Color(red: 0.95, green: 0.55, blue: 0.30),
            Color(red: 0.40, green: 0.70, blue: 0.85),
        ]
        let names = ["Elena Rossi", "Marcus Chen", "Lucía Vega", "Amara Diallo", "Kaia Svensson"]
        if let idx = names.firstIndex(of: artist.name) {
            return palette[idx % palette.count]
        }
        let index = Artist.all.firstIndex(where: { $0.id == artist.id }) ?? 0
        return palette[index % palette.count]
    }

    private var fillColor: Color {
        ringColor.opacity(0.22)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(fillColor)
                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.92))
                if !artist.avatarImage.isEmpty {
                    ArtworkImage(imageName: artist.avatarImage, contentMode: .fill, maxDimension: 280)
                        .frame(width: 68, height: 68)
                        .clipped()
                }
            }
            .frame(width: 68, height: 68)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(ringColor, lineWidth: 2.5)
            )

            if showName {
                Text(artist.name.components(separatedBy: " ").first ?? artist.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .frame(width: 76)
    }
}

// MARK: - Post Feed Section

struct PostFeedSection: View {
    var posts: [ArtistPost] = ArtistPost.samples
    @State private var ratedPosts: Set<UUID> = []
    @State private var hiddenKeys: Set<String> = HiddenPosts.load()
    @State private var lastHidden: String?

    private var visiblePosts: [ArtistPost] {
        posts.filter { !hiddenKeys.contains($0.feedKey) }
    }

    var body: some View {
        VStack(spacing: 18) {
            if let lastHidden {
                hiddenBanner(lastHidden)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            ForEach(visiblePosts) { post in
                PostCard(
                    post: post,
                    hasRated: ratedPosts.contains(post.id),
                    onRate: { ratedPosts.formSymmetricDifference([post.id]) },
                    onNotForMe: { hide(post) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.3), value: hiddenKeys)
        .animation(.easeInOut(duration: 0.3), value: lastHidden)
    }

    /// "Not for Me" hides the post from this feed only; the artist stays a muse.
    private func hide(_ post: ArtistPost) {
        Haptics.tap()
        hiddenKeys.insert(post.feedKey)
        HiddenPosts.save(hiddenKeys)
        lastHidden = post.feedKey
        let key = post.feedKey
        Task {
            try? await Task.sleep(for: .seconds(5))
            if lastHidden == key { lastHidden = nil }
        }
    }

    private func hiddenBanner(_ key: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "eye.slash")
                .foregroundStyle(.secondary)
            Text("Post hidden. You'll see less like this.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
            Spacer(minLength: 8)
            Button("Undo") {
                hiddenKeys.remove(key)
                HiddenPosts.save(hiddenKeys)
                lastHidden = nil
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.picardoAccent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}

/// Posts the user marked "Not for Me", kept on this device.
enum HiddenPosts {
    private static let key = "picartdo.feed.hiddenPosts"

    static func load() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    static func save(_ keys: Set<String>) {
        UserDefaults.standard.set(Array(keys), forKey: key)
    }
}

/// A social post from an artist: a photo or a video, never a product card.
///
/// Visual language on Home:
/// - Listings for sale are framed: white mat inside a cream card, with title, price and Buy.
/// - Posts are full-bleed media under the artist's avatar, with social actions and a caption.
/// - When a post shows a piece that is for sale, a shop tag links to that listing.
struct PostCard: View {
    let post: ArtistPost
    var hasRated: Bool = false
    var onRate: () -> Void = {}
    var onNotForMe: () -> Void = {}

    @State private var showOptions = false
    @State private var isFollowing = false
    @State private var confirmRelease = false
    @State private var isSaved = false
    @State private var showReportAlert = false
    @State private var showMessage = false

    /// Logarithmic star rating from total interactions, rounded to nearest 0.5
    /// ~100 interactions ≈ 2.0 ★  |  ~500 ≈ 3.5 ★  |  ~2000 ≈ 4.5 ★  |  ~5000 ≈ 5.0 ★
    private var starRating: Double {
        let total = Double(post.likes + post.comments + (hasRated ? 1 : 0))
        let raw = (log10(total + 1) / log10(5000)) * 5.0
        let clamped = min(5.0, max(1.0, raw))
        return (clamped * 2).rounded() / 2   // rounds to nearest 0.5
    }

    private var firstName: String {
        post.artist.name.components(separatedBy: " ").first ?? post.artist.name
    }

    var body: some View {
        Group {
            if post.isVideo {
                videoPost
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    media
                    if let listing = post.listing {
                        shopTag(listing)
                    }
                    actions
                    caption
                }
            }
        }
        .messageComposer(isPresented: $showMessage, artist: post.artist)
    }

    private var videoShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
    }

    /// One video card. Username top-right, likes / comment / share bottom-center — both on-glass.
    private var videoPost: some View {
        media
            .clipShape(videoShape)
            .overlay {
                GlassEffectContainer(spacing: 12) {
                    VStack(spacing: 0) {
                        videoUsernameChip
                        Spacer(minLength: 0)
                        videoSocialChip
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                }
            }
            .overlay {
                videoShape
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.55),
                                .white.opacity(0.08),
                                .white.opacity(0.22),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.28), radius: 22, y: 14)
            .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
    }

    private var videoUsernameChip: some View {
        HStack(spacing: 8) {
            NavigationLink(value: post.artist) {
                HStack(spacing: 8) {
                    ArtworkImage(imageName: post.artist.avatarImage, contentMode: .fill)
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())

                    HStack(spacing: 4) {
                        Text(post.artist.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        if post.artist.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.picardoSupport)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Button { showOptions = true } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More options")
            .confirmationDialog(post.artist.name, isPresented: $showOptions, titleVisibility: .visible) {
                Button {
                    showMessage = true
                } label: {
                    Label("Message \(firstName)", systemImage: "envelope")
                }
                ShareLink(item: "Check out \"\(post.caption)\" by \(post.artist.name) on Picartdo") {
                    Label("Share Post", systemImage: "square.and.arrow.up")
                }
                Button {
                    if isFollowing {
                        Task {
                            try? await Task.sleep(for: .milliseconds(350))
                            confirmRelease = true
                        }
                    } else {
                        withAnimation { isFollowing = true }
                    }
                } label: {
                    Label(isFollowing ? "Release Muse" : "Muse \(firstName)",
                          systemImage: isFollowing ? "person.badge.minus" : "person.badge.plus")
                }
                Button {
                    onNotForMe()
                } label: {
                    Label("Not for Me", systemImage: "eye.slash")
                }
                Button("Report Post", role: .destructive) {
                    showReportAlert = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Release this muse?", isPresented: $confirmRelease, titleVisibility: .visible) {
                Button("Release", role: .destructive) {
                    withAnimation { isFollowing = false }
                }
                Button("Keep", role: .cancel) {}
            }
            .alert("Report submitted", isPresented: $showReportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Thanks for letting us know. We'll review this post.")
            }
        }
        .padding(.leading, 6)
        .padding(.trailing, 6)
        .padding(.vertical, 5)
        .picardoGlass(in: Capsule(), interactive: true)
    }

    private var videoSocialChip: some View {
        HStack(spacing: 22) {
            Button(action: onRate) {
                HStack(spacing: 6) {
                    Image(systemName: hasRated ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(hasRated ? Color.picardoNeonRed : .primary)
                        .symbolEffect(.bounce, value: hasRated)
                    Text(formatCount(post.likes + (hasRated ? 1 : 0)))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Like, \(post.likes) likes")

            Button {
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 17, weight: .semibold))
                    Text("\(post.comments)")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(post.comments) comments")

            Button {
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
        .picardoGlass(in: Capsule(), interactive: true)
    }

    // MARK: Header — who posted, when, and what kind of post

    private var header: some View {
        HStack(spacing: 10) {
            NavigationLink(value: post.artist) {
                HStack(spacing: 10) {
                    ArtworkImage(imageName: post.artist.avatarImage, contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text(post.artist.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.primary)
                            if post.artist.verified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.picardoSupport)
                            }
                        }
                        Text("\(post.isVideo ? "Video" : "Post") · \(post.timeAgo)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button { showOptions = true } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More options")
            .confirmationDialog(post.artist.name, isPresented: $showOptions, titleVisibility: .visible) {
                Button {
                    showMessage = true
                } label: {
                    Label("Message \(firstName)", systemImage: "envelope")
                }
                ShareLink(item: "Check out \"\(post.caption)\" by \(post.artist.name) on Picartdo") {
                    Label("Share Post", systemImage: "square.and.arrow.up")
                }
                Button {
                    if isFollowing {
                        // Let this menu close before asking to confirm.
                        Task {
                            try? await Task.sleep(for: .milliseconds(350))
                            confirmRelease = true
                        }
                    } else {
                        withAnimation { isFollowing = true }
                    }
                } label: {
                    Label(isFollowing ? "Release Muse" : "Muse \(firstName)",
                          systemImage: isFollowing ? "person.badge.minus" : "person.badge.plus")
                }
                Button {
                    onNotForMe()
                } label: {
                    Label("Not for Me", systemImage: "eye.slash")
                }
                Button("Report Post", role: .destructive) {
                    showReportAlert = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Release this muse?", isPresented: $confirmRelease, titleVisibility: .visible) {
                Button("Release", role: .destructive) {
                    withAnimation { isFollowing = false }
                }
                Button("Keep", role: .cancel) {}
            }
            .alert("Report submitted", isPresented: $showReportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Thanks for letting us know. We'll review this post.")
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 6)
        .padding(.vertical, 10)
    }

    // MARK: Media — full bleed, no gallery frame

    private var media: some View {
        Color.clear
            .aspectRatio(post.isVideo ? 9.0 / 16.0 : 1, contentMode: .fit)
            .overlay {
                if post.isVideo {
                    LoopingPostVideo(
                        resourceName: post.videoName ?? post.imageName,
                        fallbackImageName: post.imageName
                    )
                } else {
                    ArtworkImage(imageName: post.imageName, contentMode: .fill)
                }
            }
            .clipped()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(post.isVideo ? "Video by \(post.artist.name)" : "Photo by \(post.artist.name)")
    }

    // MARK: Shop tag — the bridge from a post to the listing it shows

    private func shopTag(_ listing: Artwork) -> some View {
        NavigationLink(value: listing) {
            HStack(spacing: 12) {
                // A miniature of the listing frame, so it reads as "the piece for sale".
                ArtworkImage(artwork: listing, contentMode: .fill)
                    .frame(width: 34, height: 34)
                    .clipped()
                    .padding(3)
                    .background(Color.picardoPostFrame)
                    .overlay(Rectangle().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))

                VStack(alignment: .leading, spacing: 2) {
                    Text(listing.isSold ? "SOLD" : "FOR SALE")
                        .font(.system(size: 10, weight: .bold))
                        .kerning(1.2)
                        .foregroundStyle(listing.isSold ? Color.secondary : Color.picardoNeonRed)
                    Text(listing.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text(listing.price, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.picardoPolaroidMat)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(listing.isSold ? "Sold" : "For sale"): \(listing.title), \(Int(listing.price)) dollars")
        .accessibilityHint("Opens the listing")
    }

    // MARK: Actions — social, left aligned

    private var actions: some View {
        HStack(spacing: 22) {
            Button(action: onRate) {
                HStack(spacing: 6) {
                    Image(systemName: hasRated ? "star.fill" : "star")
                        .font(.system(size: 20))
                        .foregroundStyle(hasRated ? Color.picardoGold : .primary)
                        .symbolEffect(.bounce, value: hasRated)
                    Text(String(format: "%.1f", starRating))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(hasRated ? Color.picardoGold : .primary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: starRating)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rate, \(String(format: "%.1f", starRating)) stars")

            Button {
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 19))
                    Text("\(post.comments)")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(post.comments) comments")

            Button {
                showMessage = true
            } label: {
                Image(systemName: "paperplane")
                    .font(.system(size: 19))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Message")

            Spacer()

            Button {
                withAnimation { isSaved.toggle() }
            } label: {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 19))
                    .foregroundStyle(isSaved ? Color.picardoGold : .primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSaved ? "Remove from collection" : "Save to collection")
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var caption: some View {
        Text("\(Text(firstName).font(.system(size: 13, weight: .semibold)))  \(post.caption)")
            .font(.system(size: 13))
            .foregroundStyle(.primary)
            .lineLimit(2)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
    }

    private func formatCount(_ n: Int) -> String {
        n >= 1000 ? String(format: "%.1fk", Double(n) / 1000) : "\(n)"
    }
}

#Preview {
    HomeView(showSellSheet: .constant(false))
        .environment(WishlistStore())
        .environment(TastePreferenceStore())
        .environment(HomeFeedStore())
}
