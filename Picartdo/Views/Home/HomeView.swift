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
    @State private var identity = ProfileIdentity.load()
    @State private var hiddenPosts: Set<String> = HiddenPosts.load()
    @State private var refreshCount = 0
    @State private var showMessages = false
    @Namespace private var zoom

    private var featured: Artwork { homeFeed.featured }
    private var storyArtists: [Artist] { homeFeed.storyArtists }
    private var featuredArticles: [HomeArticle] { homeFeed.articles }
    private var cityEvents: [ArtEventItem] { homeFeed.cityEvents }

    /// Tonight's piece: the featured work, then a few more to swipe through.
    private var heroArtworks: [Artwork] {
        [featured] + homeFeed.moreListings.filter { $0.id != featured.id }.prefix(4)
    }

    /// Studio posts from people you follow (first three; the rest live on their profiles).
    private var followingPosts: [ArtistPost] {
        Array(homeFeed.studioVideos.filter { !hiddenPosts.contains($0.feedKey) }.prefix(3))
    }

    /// Pieces already used by the featured carousel or the For you shelf.
    private var shownAbove: Set<Artwork.ID> { Set(heroArtworks.map(\.id)) }

    private var forYouPicks: [Artwork] {
        HomeForYouShelf.picks(
            role: taste.role,
            mediums: taste.favoriteMediums,
            budget: taste.budget,
            excluding: shownAbove
        )
    }

    /// Everything not shown higher up, for the open-ended grid at the bottom.
    private func discoverArtworks(excluding shelf: [Artwork]) -> [Artwork] {
        let used = shownAbove.union(shelf.map(\.id))
        return Array(homeFeed.moreListings.filter { !used.contains($0.id) }.prefix(20))
    }

    private var city: String {
        let first = identity.location.split(separator: ",").first
            .map { String($0).trimmingCharacters(in: .whitespaces) }
        return first?.isEmpty == false ? first! : "Toronto"
    }

    var body: some View {
        let shelfPicks = forYouPicks
        return NavigationStack(path: $path) {
            ZStack {
                PicartdoBackground()
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {

                        // The top bar: Picasso, the name and date, messages.
                        HomeHeader(unreadMessages: unreadMessages, onMessages: { showMessages = true }) {
                            // The splash wordmark lands on this exact spot; tap it to step the era.
                            PicardoBrandWordmark(size: 24, tracking: 2.5)
                                .opacity(splashBridge?.hidesHomeWordmark == true ? 0 : 1)
                                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                                    splashBridge?.reportWordmarkFrame(frame)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.6)) {
                                        PicardoEra.advance()
                                    }
                                }
                                .accessibilityAddTraits(.isHeader)
                        }
                        .padding(.top, 4)

                        // Stories from the people you follow.
                        HomeStoriesRow(artists: storyArtists, identity: identity) {
                            showSellSheet = true
                        }
                        .padding(.top, 14)
                        .padding(.bottom, 8)

                        homeFeedSections(shelfPicks)
                            .padding(.top, 20)
                    }
                    .padding(.bottom, 110)
                    .animation(PicardoMotion.transition, value: hiddenPosts)
                }
                .scrollIndicators(.hidden)
                .scrollEdgeEffectStyle(.soft, for: .top)
                .refreshable {
                    try? await Task.sleep(for: .milliseconds(550))
                    withAnimation(PicardoMotion.transition) {
                        homeFeed.refresh(taste: taste)
                    }
                    refreshCount += 1
                }
                .sensoryFeedback(.success, trigger: refreshCount)
                .onAppear {
                    homeFeed.applyTaste(taste)
                    identity = ProfileIdentity.load()
                }
            }
            .environment(\.homeZoomNamespace, zoom)
            .navigationBarHidden(true)
            .navigationDestination(for: Artwork.self) { artwork in
                ArtworkDetailView(artwork: artwork)
                    .picardoPushedScreen()
                    .navigationTransition(.zoom(sourceID: artwork.id, in: zoom))
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
            .fullScreenCover(isPresented: $showMessages) {
                DirectMessagesView(isPresented: $showMessages)
                    .presentationBackground(.clear)
            }
            .onChange(of: homeRootTick) { _, _ in
                guard !path.isEmpty else { return }
                path = NavigationPath()
            }
        }
    }

    /// Everything below the stories.
    private func homeFeedSections(_ shelfPicks: [Artwork]) -> some View {
        VStack(alignment: .leading, spacing: HomeLayout.sectionGap) {
            // Inspire: one big moment.
            VStack(alignment: .leading, spacing: HomeLayout.headerGap) {
                HomeSectionHeader(title: "Tonight\u{2019}s piece", reason: "Five works, chosen for this evening")
                HomeFeaturedCarousel(artworks: heroArtworks) { buyArtwork = $0 }
            }

            // Personalize: the marketplace, picked for you.
            HomeForYouShelf(
                role: taste.role,
                mediums: taste.favoriteMediums,
                budget: taste.budget,
                picks: shelfPicks
            )

            // Connect: what the people you follow are making.
            if !followingPosts.isEmpty {
                VStack(alignment: .leading, spacing: HomeLayout.headerGap) {
                    HomeSectionHeader(title: "From people you follow", reason: "New work and studio moments")
                    VStack(spacing: HomeLayout.sectionGap) {
                        ForEach(followingPosts) { post in
                            HomePostCard(post: post) { hide(post) }
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, HomeLayout.margin)
                }
            }

            HomeStudioVisit(feature: homeFeed.artistOfTheWeek)

            // Explore: out into the city, reading, and everything else.
            HomeEventsShelf(events: cityEvents, city: city)
            HomeReadingList(articles: featuredArticles)
            HomeDiscoverGrid(artworks: discoverArtworks(excluding: shelfPicks))
        }
    }

    private var unreadMessages: Int {
        DMConversation.samples.reduce(0) { $0 + $1.unreadCount }
    }

    /// "Not for me" hides the post here and remembers it on this device.
    private func hide(_ post: ArtistPost) {
        Haptics.tap()
        hiddenPosts.insert(post.feedKey)
        HiddenPosts.save(hiddenPosts)
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
                Text(event.day)
                    .font(.system(size: 18, weight: .black, design: .serif))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text("\(event.type) · \(event.priceLabel)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Color.clear
                .frame(width: 54, height: 54)
                .overlay {
                    ArtworkImage(imageName: event.imageName, contentMode: .fill, maxDimension: 200)
                        .allowsHitTesting(false)
                }
                .clipShape(RoundedRectangle(cornerRadius: GalleryRadius.small, style: .continuous))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

/// The full Exhibitions & Events guide (Home → Read more, Explore, Services → See all).
struct CityEventsView: View {
    var body: some View {
        ZStack {
            PicartdoBackground().ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                EventsGuideContent()
                    .padding(.top, 6)
                    // Room for the floating tab bar so nothing is covered.
                    .padding(.bottom, 120)
            }
        }
        .navigationTitle("Exhibitions & Events")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The guide itself, shared by the full page and Services → Art Exhibitions so both look
/// the same. Built to be read at a glance: one switch (Exhibitions | Events), one
/// featured exhibition, everything else as quiet list rows. Events read like a calendar,
/// grouped by month with a date block on each row.
struct EventsGuideContent: View {
    enum Mode: String, CaseIterable, Identifiable {
        case exhibitions = "Exhibitions"
        case events = "Events"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .exhibitions

    private static func byStart(_ a: ArtEventItem, _ b: ArtEventItem) -> Bool {
        (a.startDate ?? .distantPast) < (b.startDate ?? .distantPast)
    }

    /// On view now, closing soonest first.
    private var onNow: [ArtEventItem] {
        ArtEventItem.exhibitions.filter(\.isOnNow)
            .sorted { ($0.endDate ?? .distantFuture) < ($1.endDate ?? .distantFuture) }
    }

    private var openingSoon: [ArtEventItem] {
        ArtEventItem.exhibitions.filter { !$0.isOnNow }.sorted(by: Self.byStart)
    }

    /// The headline exhibition: the first show on now in the AGO's own order
    /// (they lead their exhibitions page with it).
    private var featured: ArtEventItem? {
        ArtEventItem.exhibitions.first(where: \.isOnNow)
    }

    /// Upcoming events grouped by month, in date order.
    private var eventMonths: [(title: String, items: [ArtEventItem])] {
        let today = Calendar.current.startOfDay(for: Date())
        let upcoming = ArtEventItem.events
            .filter { ($0.startDate ?? .distantPast) >= today }
            .sorted(by: Self.byStart)
        var months: [(title: String, items: [ArtEventItem])] = []
        for event in upcoming {
            let title = (event.startDate ?? today).formatted(.dateTime.month(.wide).year())
            if let last = months.indices.last, months[last].title == title {
                months[last].items.append(event)
            } else {
                months.append((title, [event]))
            }
        }
        return months
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Picker("Show", selection: $mode.animation(PicardoMotion.quick)) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            Group {
                switch mode {
                case .exhibitions: exhibitionsPage
                case .events: eventsPage
                }
            }
            .padding(.top, 22)
        }
    }

    private var exhibitionsPage: some View {
        VStack(alignment: .leading, spacing: 30) {
            if let featured {
                NavigationLink(value: featured) {
                    FeaturedExhibitionCard(event: featured)
                }
                .buttonStyle(PicardoPressStyle())
                .padding(.horizontal, 20)
            }

            let rest = onNow.filter { $0.id != featured?.id }
            if !rest.isEmpty {
                EventListSection(title: "Also on now", items: rest) { ExhibitionListRow(event: $0) }
            }
            if !openingSoon.isEmpty {
                EventListSection(title: "Opening soon", items: openingSoon) { ExhibitionListRow(event: $0) }
            }
        }
    }

    private var eventsPage: some View {
        VStack(alignment: .leading, spacing: 30) {
            ForEach(eventMonths, id: \.title) { month in
                EventListSection(title: month.title, items: month.items) { EventCalendarRow(event: $0) }
            }
        }
    }
}

/// A titled, rounded group of rows, each opening its event.
struct EventListSection<Row: View>: View {
    let title: String
    let items: [ArtEventItem]
    @ViewBuilder let row: (ArtEventItem) -> Row

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(Color.picardoText)
                .padding(.horizontal, 24)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, event in
                    NavigationLink(value: event) { row(event) }
                        .buttonStyle(.plain)
                    if index < items.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }
}

/// The one big image on the Exhibitions page.
struct FeaturedExhibitionCard: View {
    let event: ArtEventItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.picardoCardMid
                .aspectRatio(4.0 / 3.0, contentMode: .fit)
                .overlay {
                    ArtworkImage(imageName: event.imageName, contentMode: .fill, maxDimension: 1100)
                        .allowsHitTesting(false)
                }
                .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text(event.dateLabel.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Color.picardoGold)
                Text(event.title)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color.picardoText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(event.summary)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Text(event.priceLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.picardoText)
                    Spacer()
                    Text("Get tickets")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(Color.black, in: Capsule())
                }
                .padding(.top, 8)
            }
            .multilineTextAlignment(.leading)
            .padding(16)
        }
        .background(Color.picardoCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }
}

/// A list row for an exhibition: small portrait photo, title, when, price.
struct ExhibitionListRow: View {
    let event: ArtEventItem

    private var whenLabel: String {
        if event.isOnNow {
            if let end = event.endDate { return "Until \(end.formatted(.dateTime.month(.abbreviated).day().year()))" }
            return "On view now"
        }
        guard let start = event.startDate else { return "" }
        return "Opens \(start.formatted(.dateTime.month(.abbreviated).day().year()))"
    }

    var body: some View {
        HStack(spacing: 14) {
            Color.picardoCardMid
                .frame(width: 64, height: 80)
                .overlay {
                    ArtworkImage(imageName: event.imageName, contentMode: .fill, maxDimension: 300)
                        .allowsHitTesting(false)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 15.5, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.picardoText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(whenLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.picardoTextSecondary)
                Text(event.priceLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.picardoText)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.picardoTextSecondary.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

/// A calendar-style row for an event: date block, what and when, small photo.
struct EventCalendarRow: View {
    let event: ArtEventItem

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 1) {
                Text((event.startDate ?? Date()).formatted(.dateTime.weekday(.abbreviated)).uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.picardoGold)
                Text((event.startDate ?? Date()).formatted(.dateTime.day()))
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color.picardoText)
            }
            .frame(width: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.picardoText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(event.timeLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.picardoTextSecondary)
                Text("\(event.type) · \(event.priceLabel)")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Color.picardoText.opacity(0.75))
            }
            Spacer(minLength: 4)
            Color.picardoCardMid
                .frame(width: 56, height: 56)
                .overlay {
                    ArtworkImage(imageName: event.imageName, contentMode: .fill, maxDimension: 240)
                        .allowsHitTesting(false)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
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

    /// One ring for everyone, in the brand's own red: calm, recognisable, never a rainbow.
    private var ring: AngularGradient {
        AngularGradient(
            colors: [Color.picardoNeonRed, Color.picardoGoldDeep, Color.picardoNeonRed],
            center: .center
        )
    }

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(Color.picardoCard)
                Image(systemName: "person.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(Color.picardoTextSecondary.opacity(0.5))
                if !artist.avatarImage.isEmpty {
                    ArtworkImage(imageName: artist.avatarImage, contentMode: .fill, maxDimension: 360)
                        .frame(width: 78, height: 78)
                        .clipped()
                }
            }
            .frame(width: 78, height: 78)
            .clipShape(Circle())
            // A hairline gap between photo and ring, the way premium story rings sit.
            .padding(3)
            .background(Circle().fill(Color.picardoBackground))
            .padding(2.5)
            .background(Circle().fill(ring))

            if showName {
                Text(artist.name.components(separatedBy: " ").first ?? artist.name)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Color.picardoText.opacity(0.85))
                    .lineLimit(1)
            }
        }
        .frame(width: 94)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(artist.name)\u{2019}s story")
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
        RoundedRectangle(cornerRadius: GalleryRadius.large, style: .continuous)
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
                        Haptics.success()
                        PicartdoToast.show("\(firstName) is now one of your muses", icon: "person.badge.plus")
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
                    PicartdoToast.show(
                        "Released \(firstName)",
                        icon: "person.badge.minus",
                        action: .undo { withAnimation { isFollowing = true } }
                    )
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
                        Haptics.success()
                        PicartdoToast.show("\(firstName) is now one of your muses", icon: "person.badge.plus")
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
                    PicartdoToast.show(
                        "Released \(firstName)",
                        icon: "person.badge.minus",
                        action: .undo { withAnimation { isFollowing = true } }
                    )
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
