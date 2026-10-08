import Foundation
import Observation

// MARK: - Picasso Message

struct PicassoMessage: Identifiable, Hashable, Codable {
    enum Role: String, Codable { case user, picasso }

    let id: UUID
    let role: Role
    let text: String
    /// Artworks Picasso wants to show alongside his answer.
    var artworkIDs: [UUID]
    let date: Date

    init(role: Role, text: String, artworkIDs: [UUID] = []) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.artworkIDs = artworkIDs
        self.date = Date()
    }
}

// MARK: - Picasso Context
// Everything Picasso knows about this marketplace and this user's taste,
// assembled fresh by the view on every question.

struct PicassoContext {
    var artworks: [Artwork] = []
    var artists: [Artist] = []
    var savedIDs: Set<UUID> = []
}

// MARK: - Picasso Engine
// Picartdo's resident art intelligence: a curated knowledge base (masters,
// movements, mediums, collecting wisdom) fused with the app's live catalog
// and artists for personalized answers. Fully on-device and instant.
// The `reply` function is the exact seam where a real LLM API (e.g. Claude)
// drops in later, same messages, same context, a larger mind behind them.

@Observable
@MainActor
final class PicassoEngine {

    // MARK: State

    private(set) var messages: [PicassoMessage] = []
    private(set) var isThinking = false

    init() {
        load()
        if messages.isEmpty { seedWelcome() }
    }

    private func seedWelcome() {
        messages = [PicassoMessage(
            role: .picasso,
            text: "Hey, I'm Picasso, your art guide here on Picartdo.\n\nAsk me anything. An artist, a style, or how to start collecting.\n\nOr just say \"find me something\" and I'll read your taste."
        )]
    }

    // MARK: Suggestions (rotate daily so the studio never feels stale)

    var suggestions: [String] {
        let all = [
            "Find me something", "What is Cubism?", "Who's Oscar Bruschi?",
            "Tell me something cool", "How do I start collecting?", "What is Impressionism?",
            "Who takes commissions?", "Oil vs acrylic?", "Who was Basquiat?",
            "How do I price my art?"
        ]
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let start = day % all.count
        return (0..<4).map { all[(start + $0) % all.count] }
    }

    // MARK: Ask

    func ask(_ raw: String, context: PicassoContext) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }

        messages.append(PicassoMessage(role: .user, text: text))
        persist()
        isThinking = true

        Task { [weak self] in
            // A painter pauses before each stroke.
            try? await Task.sleep(nanoseconds: UInt64.random(in: 800_000_000...1_500_000_000))
            guard let self else { return }
            self.messages.append(Self.reply(to: text, context: context))
            self.isThinking = false
            self.persist()
        }
    }

    func clearConversation() {
        messages = []
        seedWelcome()
        persist()
    }

    /// The on-device answer for a question, used by Picasso's offline mode.
    static func offlineAnswer(to text: String, context: PicassoContext) -> PicassoMessage {
        reply(to: text, context: context)
    }

    // MARK: - The Brain
    // Intent routing over a curated knowledge base + the live catalog.
    // Replace this single function with an API call to bring in a real LLM.

    private static func reply(to raw: String, context: PicassoContext) -> PicassoMessage {
        let query = raw.lowercased()

        // 1. Personal recommendations, reads the user's saved pieces.
        if containsAny(query, ["recommend", "suggest", "what should i buy", "for me", "my taste"]) {
            return recommend(context: context)
        }

        // 2. Commissions, ties into Picartdo's artist services.
        if containsAny(query, ["commission", "hire", "custom piece", "portrait of"]) {
            let open = ([Artist.oscar] + context.artists).filter(\.availableForCommissions)
            guard !open.isEmpty else {
                return PicassoMessage(role: .picasso, text: "No artist has their commission book open right now, a rare silence. Check back soon.")
            }
            let lines = open.prefix(4).map { "\($0.name), from \($0.startingPrice)" }
            return PicassoMessage(
                role: .picasso,
                text: "These artists are taking commissions:\n\n\(lines.joined(separator: "\n"))\n\nFind them in the Services tab, then tap Request Commission.\n\nOne tip: send a reference image and be clear about your budget. Good briefs make good art."
            )
        }

        // 3. What's new on Picartdo.
        if containsAny(query, ["what's new", "whats new", "new on", "new arrivals", "just dropped", "latest"]) {
            let newest = context.artworks
                .filter { !$0.isSold }
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(3)
            return PicassoMessage(
                role: .picasso,
                text: newest.isEmpty
                    ? "Nothing new just this second, check back soon."
                    : "Just landed on Picartdo. Take a look:",
                artworkIDs: newest.map(\.id)
            )
        }

        // 4. An artist on Picartdo, real profile data.
        if let artist = ([Artist.oscar] + context.artists).first(where: { query.contains($0.name.lowercased()) }) {
            let works = context.artworks.filter { $0.artistName == artist.name }
            let commissions = artist.availableForCommissions
                ? "\n\nTaking commissions from \(artist.startingPrice)."
                : ""
            return PicassoMessage(
                role: .picasso,
                text: "\(artist.name). \(artist.tagline).\n\n\(artist.bio)\n\n\(artist.works) works · \(artist.followers) followers · \(String(format: "%.1f", artist.rating))★\(commissions)",
                artworkIDs: Array(works.prefix(3).map(\.id))
            )
        }

        // 5. The masters.
        if let hit = lookup(query, in: masters) { return PicassoMessage(role: .picasso, text: hit) }

        // 6. Movements & periods.
        if let hit = lookup(query, in: movements) { return PicassoMessage(role: .picasso, text: hit) }

        // 7. Mediums & techniques.
        if let hit = lookup(query, in: mediums) { return PicassoMessage(role: .picasso, text: hit) }

        // 8. Collecting & pricing wisdom.
        if let hit = lookup(query, in: collecting) { return PicassoMessage(role: .picasso, text: hit) }

        // 9. Daily insight / "tell me something cool".
        if containsAny(query, ["insight", "fact", "today", "daily", "teach me",
                               "something cool", "cool", "surprise", "fun", "wow", "interesting"]) {
            return PicassoMessage(role: .picasso, text: dailyInsight())
        }

        // 10. Who are you?
        if containsAny(query, ["who are you", "what are you", "picasso"]) {
            return PicassoMessage(
                role: .picasso,
                text: "I'm Picasso, your art guide here on Picartdo.\n\nI know the artists, the history, and what's for sale. And I can point you to work you'll actually love.\n\nWhat are you curious about?"
            )
        }

        // 11. Greetings, matched by whole words so \"hi\" doesn't trigger on \"something\".
        if containsWord(query, ["hello", "hi", "hey", "hola", "yo", "sup"]) {
            return PicassoMessage(
                role: .picasso,
                text: "Hey! Good to see you.\n\nWant to explore an artist, learn a bit of history, or should I find you something to love?"
            )
        }

        // Fallback, honest, with direction.
        return PicassoMessage(
            role: .picasso,
            text: "Hmm, that one got past me.\n\nTry asking about an artist, a style like Cubism, oil vs acrylic, or who's taking commissions. Or just say \"find me something.\""
        )
    }

    // MARK: Personalized recommendation (real catalog, real taste)

    private static func recommend(context: PicassoContext) -> PicassoMessage {
        let available = context.artworks.filter { !$0.isSold }
        guard !available.isEmpty else {
            return PicassoMessage(role: .picasso, text: "Everything worth having has been claimed for now. Check back when new work arrives.")
        }

        let saved = context.artworks.filter { context.savedIDs.contains($0.id) }
        let favoriteCategories = Set(saved.map(\.category))
        let avgPrice = saved.isEmpty ? nil : saved.map(\.price).reduce(0, +) / Double(saved.count)

        // Score: favorite category > near the user's price comfort > popularity.
        let scored = available
            .filter { !context.savedIDs.contains($0.id) }
            .map { artwork -> (Artwork, Int) in
                var score = 0
                if favoriteCategories.contains(artwork.category) { score += 30 }
                if let avg = avgPrice, abs(artwork.price - avg) < avg * 0.5 { score += 15 }
                score += min(artwork.likeCount / 20, 15)
                return (artwork, score)
            }
            .sorted { $0.1 > $1.1 }

        let picks = Array(scored.prefix(3).map(\.0))
        guard let top = picks.first else {
            return PicassoMessage(role: .picasso, text: "You've already saved everything I would have chosen. Your eye is ahead of my brush.")
        }

        let reason: String
        if favoriteCategories.contains(top.category) {
            reason = "You keep saving \(top.category.rawValue.lowercased()), so this one fits right in."
        } else if saved.isEmpty {
            reason = "You haven't saved anything yet, so here's what collectors love most. A place to start."
        } else {
            reason = "It's close to your usual taste, and it's got a following."
        }

        return PicassoMessage(
            role: .picasso,
            text: "Start with \"\(top.title)\" by \(top.artistName).\n\n\(reason)\n\nA couple more below:",
            artworkIDs: picks.map(\.id)
        )
    }

    // MARK: Daily insight (deterministic, one truth per day)

    static func dailyInsight() -> String {
        let facts = [
            "Van Gogh sold just one painting while he was alive.\n\nToday he's one of the most loved artists on earth. Keep going.",
            "Picasso's \"Les Demoiselles d'Avignon\" shocked even his own friends in 1907.\n\nThat painting kicked off Cubism.",
            "The Mona Lisa got famous partly because it was stolen in 1911.\n\nPeople only lined up to see the empty wall.",
            "Michelangelo saw himself as a sculptor, not a painter.\n\nHe complained the whole time he painted the Sistine Chapel, all 500 m² of it.",
            "Monet painted his water lilies for 30 years straight.\n\nSame pond, endless light. That's mastery.",
            "The word \"Impressionism\" started as an insult from a critic.\n\nThe artists kept the name, and had the last laugh.",
            "Rembrandt painted almost 100 self-portraits.\n\nAn autobiography in paint, centuries before the selfie.",
            "Basquiat started out spray-painting poetry on NYC walls.\n\nEight years later his work hung next to Warhol's.",
            "Georgia O'Keeffe painted flowers huge on purpose.\n\nShe wanted busy New Yorkers to stop and actually look.",
            "Hokusai's \"Great Wave\" is a print, thousands were made.\n\nStill priceless. Rare isn't the only way to matter.",
            "Yves Klein invented his own blue and patented it.\n\nImagine owning a color.",
            "Leonardo carried the Mona Lisa around for 16 years, still touching it up.\n\nSome art is never finished, only let go."
        ]
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return facts[day % facts.count]
    }

    // MARK: Knowledge base

    private static let masters: [(keys: [String], answer: String)] = [
        (["van gogh", "vincent"],
         "Van Gogh (1853 to 1890).\n\nSold one painting his whole life. Made ~900 anyway.\n\nHis thick, swirling brushstrokes turned feeling into something you can almost touch. Nobody paints a sky angrier or more alive."),
        (["pablo"],
         "Pablo Picasso (1881 to 1973), my namesake.\n\nHe reinvented himself every decade for 70 years: Blue Period, Cubism, ceramics.\n\n\"Every child is an artist. The trick is staying one.\""),
        (["monet", "claude"],
         "Claude Monet (1840 to 1926), the father of Impressionism.\n\nHe painted light itself: the same pond, haystack, and cathedral over and over as the hour changed.\n\nHe even built a garden just to paint it."),
        (["frida", "kahlo"],
         "Frida Kahlo (1907 to 1954).\n\nMost of her paintings are self-portraits.\n\n\"I paint myself because I'm the subject I know best.\" She turned her pain into some of the most recognizable art in the world."),
        (["da vinci", "leonardo"],
         "Leonardo da Vinci (1452 to 1519), painter, inventor, endless tinkerer.\n\nFewer than 20 finished paintings survive.\n\nHis trick was sfumato: soft, smoky edges with no hard lines. It's why the Mona Lisa's smile seems to shift."),
        (["rembrandt"],
         "Rembrandt (1606 to 1669), master of light and shadow.\n\nHe pulled faces out of the dark like they were memories.\n\nHe died broke. Now his work is priceless. The market isn't always right."),
        (["dalí", "dali", "salvador"],
         "Salvador Dalí (1904 to 1989), Surrealism's great showman.\n\nMelting clocks, lobster telephones, that mustache.\n\nBut under the weirdness was flawless classical skill. Earn your strangeness with craft."),
        (["warhol", "andy"],
         "Andy Warhol (1928 to 1987), the prophet of Pop Art.\n\nSoup cans and Marilyns, printed over and over.\n\nHe understood fame and repetition before anyone else. Every artist posting online today lives in his world."),
        (["basquiat", "jean-michel"],
         "Jean-Michel Basquiat (1960 to 1988).\n\nWent from spray-painting NYC walls to the world's top galleries in under a decade.\n\nCrowns, skulls, raw energy. One canvas later sold for $110M. He was 27 when he died."),
        (["o'keeffe", "okeeffe", "georgia"],
         "Georgia O'Keeffe (1887 to 1986), a giant of American art.\n\nHuge flowers, desert bones, wide New Mexico skies.\n\nShe shrugged off every label critics gave her and kept painting for 70 years."),
        (["banksy"],
         "Banksy, the world's most famous artist nobody can name.\n\nStencils on public walls, sharp and political.\n\nOne of his paintings shredded itself the second it sold at auction. The prank made it worth more."),
        (["kusama", "yayoi"],
         "Yayoi Kusama (1929), the queen of polka dots and infinity rooms.\n\nEndless dots, mirrors, repetition turned into wonder.\n\nIf you love mandalas and pattern, she's your artist. People wait hours just to step inside her rooms.")
    ]

    private static let movements: [(keys: [String], answer: String)] = [
        (["renaissance"],
         "The Renaissance (1400s to 1600s).\n\nArtists cracked perspective and anatomy, and paintings suddenly had real depth.\n\nLeonardo, Michelangelo, Raphael. The canvas became a window you could look through."),
        (["baroque"],
         "Baroque (1600s to 1700s), all about drama.\n\nDeep shadows, bright spotlights, big emotion.\n\nCaravaggio and Rembrandt made scenes that grab you the moment you walk up."),
        (["impressionism", "impressionist"],
         "Impressionism (1870s).\n\nPainters left the studio to chase daylight, capturing a moment instead of every detail.\n\nThe art world rejected them at first. Now they're the most beloved painters alive or dead. Monet, Renoir, Degas."),
        (["post-impressionism", "post impressionism"],
         "Post-Impressionism (1885 to 1910).\n\nThe next wave wanted more than pretty light.\n\nCézanne chased structure, Van Gogh chased emotion, Seurat chased tiny dots of color. It led straight to modern art."),
        (["expressionism", "expressionist"],
         "Expressionism (early 1900s).\n\nPaint your feelings, not the facts.\n\nMunch's \"The Scream\" says it all: warped shapes and loud color in service of raw emotion."),
        (["cubism", "cubist"],
         "Cubism (1907 on), invented by Picasso and Braque.\n\nThey showed a face from the front and the side at the same time.\n\nIt looks broken, but it's honest, you never really see anything from just one angle. It opened the door to abstract art."),
        (["surrealism", "surrealist"],
         "Surrealism (1920s to 40s), the art of dreams.\n\nMelting clocks, floating objects, impossible rooms, painted with total realism.\n\nDalí and Magritte led it. The weirdness works because the skill is real."),
        (["abstract expressionism", "pollock", "rothko"],
         "Abstract Expressionism (1940s to 50s), when New York took over the art world.\n\nPollock dripped paint across huge canvases. Rothko made glowing blocks of color that make people cry in museums.\n\nThe painting itself became the subject."),
        (["pop art", "pop"],
         "Pop Art (1950s to 60s), art meets the supermarket.\n\nWarhol's soup cans, Lichtenstein's comic dots.\n\nThe idea: if an image runs your daily life, it belongs on a gallery wall too."),
        (["minimalism", "minimalist"],
         "Minimalism (1960s), strip away everything you can.\n\nPlain boxes, single colors, pure space.\n\nNo story, no drama. Just the object, the room, and you."),
        (["street art", "graffiti"],
         "Street art (1970s on), from subway tags to museum walls.\n\nBasquiat, Haring, Banksy.\n\nThe city is the canvas and everyone's the audience. No permission needed. The most democratic art there is."),
        (["mandala", "sacred geometry"],
         "Mandalas, circular art older than any museum.\n\nTibetan sand paintings, Gothic rose windows, healing drawings.\n\nThe circle stands for wholeness, and the repeating pattern is like meditation you can see. Want one? Just ask, Picartdo has them."),
        (["digital art", "digital", "nft"],
         "Digital art, made on tablets, screens, and now with AI.\n\nNew tools, same old questions: color, composition, what you're trying to say.\n\nThe newest room in a very old house.")
    ]

    private static let mediums: [(keys: [String], answer: String)] = [
        (["oil vs acrylic", "acrylic vs oil"],
         "Oil vs acrylic, the classic question.\n\nOil dries slowly over days. It blends beautifully and glows. The masters' choice for 600 years.\n\nAcrylic dries in minutes. Bright, tough, forgiving.\n\nOil rewards patience. Acrylic rewards speed. Both last for decades if you take care of them."),
        (["oil paint", "oil painting", "oil on canvas"],
         "Oil paint, pigment mixed with slow-drying oil.\n\nBecause it stays wet for days, colors blend right on the canvas. That's the secret behind those glowing Rembrandt skin tones.\n\nTilt an oil painting in the light and you'll see the brushstrokes, the artist's handwriting."),
        (["acrylic"],
         "Acrylic, the modern favorite.\n\nDries in minutes, sticks to almost anything, and stays bright for decades.\n\nWarhol and Hockney loved it, and it's the backbone of Picartdo's catalog."),
        (["watercolor", "watercolour"],
         "Watercolor, looks gentle, actually the hardest to master.\n\nNo white paint and no undo. The light comes from the paper glowing through the color.\n\nOne tip: keep it out of the sun. It fades faster than anything else."),
        (["ink"],
         "Ink, the oldest permanent mark we make.\n\nNo erasing, no second chances. Every line has to count.\n\nA confident ink line is like a signature, you can spot the artist even without a name."),
        (["pastel"],
         "Pastel, pure color in a stick.\n\nIt's the most direct thing there is: hand to paper, no brush.\n\nDegas made his famous dancers with it. Always framed under glass, it smudges easily."),
        (["sculpture"],
         "Sculpture, art you share a room with.\n\nCarved, molded, cast, or built from found objects.\n\nWalk all the way around it. A good sculpture works from every angle."),
        (["printmaking", "print", "lithograph", "etching"],
         "Printmaking, art made to be copied, on purpose.\n\nEtching, screenprint, woodblock. Prints come numbered, like \"12/50\", the lower the number in the run, the fewer exist.\n\nHokusai and Warhol proved a print can be as great as any painting."),
        (["photography", "photograph"],
         "Photography, it took a century to be taken seriously as art.\n\nWhat makes a photo art is the choices: where to stand, when to click, what to leave out.\n\nFor value, ask about the edition and print quality."),
        (["mixed media", "collage"],
         "Mixed media, when one material isn't enough.\n\nPaint plus paper plus fabric plus whatever else works.\n\nPicasso glued a scrap of oilcloth onto a canvas in 1912 and broke a 500-year rule. It's been broken ever since.")
    ]

    private static let collecting: [(keys: [String], answer: String)] = [
        (["start collecting", "begin collecting", "first piece", "new collector"],
         "Starting out? Three simple rules:\n\n1. Buy what stops you in your tracks. You'll live with it.\n\n2. Buy the best you can afford from a living artist. You're funding their next piece.\n\n3. Go slow. One piece you love beats ten you don't.\n\nYour saved pieces already show me your taste, just ask and I'll find more."),
        (["price my art", "how should i price", "pricing my", "price for my"],
         "Pricing your own work? Here's the honest version:\n\nStart with (hours × a fair rate) + materials. Then compare to artists at your level.\n\nStay consistent, buyers notice when prices jump around.\n\nRaise them once you're actually selling out, not before. And never price low out of fear. It makes people doubt the work."),
        (["worth", "value", "invest", "appreciate"],
         "Will it go up in value? Maybe.\n\nThe honest truth: buy it because you love it first.\n\nValue tends to follow artists who keep working, keep showing, and keep selling.\n\nBut the only guaranteed payoff is the years it hangs on your wall."),
        (["care", "protect", "preserve", "frame"],
         "Taking care of art, watch out for four things:\n\nSunlight fades it. Humidity warps it. Heat swings crack it. And careless handling.\n\nHang it away from windows, radiators, and bathrooms. Use UV glass for anything on paper.\n\nDo that and it'll outlast all of us.")
    ]

    // MARK: Matching helpers

    private static func containsAny(_ query: String, _ keys: [String]) -> Bool {
        keys.contains { query.contains($0) }
    }

    /// Whole-word match, avoids false hits like "hi" inside "something".
    private static func containsWord(_ query: String, _ words: [String]) -> Bool {
        let tokens = Set(query.split { !$0.isLetter }.map(String.init))
        return words.contains { tokens.contains($0) }
    }

    private static func lookup(_ query: String, in base: [(keys: [String], answer: String)]) -> String? {
        base.first { entry in entry.keys.contains { query.contains($0) } }?.answer
    }

    // MARK: Persistence

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("picartdo.picasso.json")
    }

    private func load() {
        guard
            let data = try? Data(contentsOf: Self.fileURL),
            let saved = try? JSONDecoder().decode([PicassoMessage].self, from: data)
        else { return }
        messages = saved
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(messages.suffix(60)) {
            try? data.write(to: Self.fileURL, options: .atomic)
        }
    }
}
