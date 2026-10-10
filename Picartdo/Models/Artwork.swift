
import Foundation

struct Artwork: Identifiable, Hashable {
    let id: UUID
    var title: String
    var artistName: String
    var artistID: UUID
    var description: String
    var medium: String
    var dimensions: String
    var price: Double
    var imageName: String
    var imageURLs: [String]
    var category: ArtCategory
    var isSold: Bool
    var likeCount: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        artistName: String,
        artistID: UUID = UUID(),
        description: String = "",
        medium: String = "",
        dimensions: String = "",
        price: Double,
        imageName: String = "photo",
        imageURLs: [String] = [],
        category: ArtCategory = .painting,
        isSold: Bool = false,
        likeCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.artistID = artistID
        self.description = description
        self.medium = medium
        self.dimensions = dimensions
        self.price = price
        self.imageName = imageName
        self.imageURLs = imageURLs
        self.category = category
        self.isSold = isSold
        self.likeCount = likeCount
        self.createdAt = createdAt
    }

    /// 1–5 stars from how the work performs (likes as a quality signal).
    var qualityStars: Int {
        switch likeCount {
        case ..<20:   return 1
        case 20..<70: return 2
        case 70..<140: return 3
        case 140..<280: return 4
        default:      return 5
        }
    }

    /// Width ÷ height. Landscape > 1, portrait < 1.
    var displayAspect: CGFloat {
        let pixels = ArtworkImageCache.shared.pixelSize(for: self)
        let cached = pixels.width > 4 || pixels.height > 5
        if cached {
            return Self.clampAspect(pixels.width / max(pixels.height, 1))
        }
        if let parsed = Self.aspect(fromDimensions: dimensions) {
            return Self.clampAspect(parsed)
        }
        return 1
    }

    var isLandscape: Bool { displayAspect > 1.2 }

    private static func clampAspect(_ value: CGFloat) -> CGFloat {
        min(max(value, 0.52), 2.5)
    }

    private static func aspect(fromDimensions raw: String) -> CGFloat? {
        let cleaned = raw
            .replacingOccurrences(of: "×", with: "x")
            .replacingOccurrences(of: " ", with: "")
            .lowercased()
            .replacingOccurrences(of: "in", with: "")
        let parts = cleaned.split(separator: "x")
        guard parts.count >= 2,
              let width = Double(parts[0]),
              let height = Double(parts[1]),
              height > 0 else { return nil }
        return CGFloat(width / height)
    }
}

enum ArtCategory: String, CaseIterable, Identifiable {
    case painting    = "Painting"
    case photography = "Photography"
    case sculpture   = "Sculpture"
    case digital     = "Digital"
    case drawing     = "Drawing"
    case printmaking = "Printmaking"
    case mixedMedia  = "Mixed Media"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .painting:    return "paintbrush"
        case .photography: return "camera"
        case .sculpture:   return "cube"
        case .digital:     return "laptopcomputer"
        case .drawing:     return "pencil"
        case .printmaking: return "doc.on.doc"
        case .mixedMedia:  return "square.3.layers.3d"
        }
    }
}

extension Artwork {
    static let samples: [Artwork] = [
        Artwork(title: "Circle Worlds", artistName: "Oscar Bruschi", description: "Twenty living worlds — each circle a universe of creatures, color, and symbol — scattered across a golden crosshatch ground.", medium: "Acrylic & ink on canvas", dimensions: "24 × 24 in", price: 3200, imageName: "circle_worlds", category: .painting, likeCount: 500),
        Artwork(title: "Blue Moon", artistName: "Oscar Bruschi", description: "A crescent moon holds a dotted world, ringed by blue suns and old symbols.", medium: "Acrylic & marker on paper", dimensions: "12 × 12 in", price: 950, imageName: "blue_moon", category: .painting, likeCount: 410),
        Artwork(title: "Red Compass", artistName: "Oscar Bruschi", description: "Four quarters of red, blue and checkerboard meet around a dotted face, framed by wavy lines.", medium: "Acrylic & marker on paper", dimensions: "12 × 12 in", price: 900, imageName: "red_compass", category: .painting, likeCount: 365),
        Artwork(title: "Violet Frame", artistName: "Oscar Bruschi", description: "Purple rings hold a small universe of dots, triangles, and watching eyes.", medium: "Marker on paper", dimensions: "11 × 14 in", price: 780, imageName: "violet_window", category: .drawing, likeCount: 298),
        Artwork(title: "Orange Border", artistName: "Oscar Bruschi", description: "Black organic bodies on a dotted ground, held by an orange scalloped frame and a watching moon.", medium: "Marker on paper", dimensions: "12 × 11 in", price: 720, imageName: "orange_scallops", category: .drawing, likeCount: 254),
        Artwork(title: "Green Crosses", artistName: "Oscar Bruschi", description: "Blue and yellow forms grow inside a border of green crosses.", medium: "Marker on paper", dimensions: "12 × 12 in", price: 720, imageName: "cross_garden", category: .drawing, likeCount: 231),
        Artwork(title: "Tangled Minds", artistName: "Oscar Bruschi", description: "Black-and-white figures over a dense field of red and blue scribbles.", medium: "Pen & ink on paper", dimensions: "16 × 12 in", price: 680, imageName: "chorus", category: .drawing, likeCount: 212),
        Artwork(title: "Eyes & Waves", artistName: "Oscar Bruschi", description: "Bold black ink waves, eyes and patterns fill the whole sheet.", medium: "Pen & ink on paper", dimensions: "16 × 12 in", price: 650, imageName: "night_watch", category: .drawing, likeCount: 196),
        Artwork(title: "Ink Labyrinth", artistName: "Oscar Bruschi", description: "Panels of lines, waves and eyes meet at a central cross.", medium: "Pen & ink on paper", dimensions: "16 × 12 in", price: 620, imageName: "crossroads", category: .drawing, likeCount: 174),
        Artwork(title: "Fluid Forms", artistName: "Oscar Bruschi", description: "Lace-like black shapes float over a loose web of handwritten lines.", medium: "Pen & ink on paper", dimensions: "16 × 12 in", price: 580, imageName: "ink_garden", category: .drawing, likeCount: 158),
        Artwork(title: "Color Field", artistName: "Oscar Bruschi", description: "A dense dotted landscape of red, gold, green and violet islands — each shape a world of its own.", medium: "Acrylic & marker on paper", dimensions: "16 × 12 in", price: 1100, imageName: "color_field", category: .painting, likeCount: 286),
        Artwork(title: "Dark Grin", artistName: "Nico Alvarez", description: "A black-suited portrait: one white eye, one red, and a wide red mouth of teeth on a brown ground.", medium: "Acrylic & ink on paper", dimensions: "12 × 12 in", price: 640, imageName: "dark_grin", category: .painting, likeCount: 188),
        Artwork(title: "Red Field Muse", artistName: "Nico Alvarez", description: "A cubist face in black line on a red field — one cheek striped, hair in a single coil.", medium: "Acrylic on paper", dimensions: "16 × 12 in", price: 880, imageName: "red_field_muse", category: .painting, likeCount: 241),
        Artwork(title: "Yellow Tie", artistName: "Nico Alvarez", description: "A crowned figure in a yellow diamond tie, scribbled on lined paper with watching heads behind.", medium: "Ink, acrylic & collage on paper", dimensions: "16 × 12 in", price: 920, imageName: "yellow_tie", category: .mixedMedia, likeCount: 267),
        Artwork(title: "Blue Halo", artistName: "Nico Alvarez", description: "A dark portrait with gold hoops and a red jacket of yellow discs, on a blue dotted ground.", medium: "Acrylic on paper", dimensions: "16 × 12 in", price: 860, imageName: "blue_halo", category: .painting, likeCount: 219),
        Artwork(title: "Wire Grin", artistName: "Nico Alvarez", description: "A scribbled head in orange and green, teeth bared, on a field of blue crayon rain.", medium: "Oil pastel & ink on paper", dimensions: "16 × 12 in", price: 540, imageName: "wire_grin", category: .drawing, likeCount: 176),
        Artwork(title: "Five Fish", artistName: "Nico Alvarez", description: "Five fish stacked in wet blues and gold — orange eyes, a still life of the catch.", medium: "Oil on paper", dimensions: "16 × 12 in", price: 720, imageName: "five_fish", category: .painting, likeCount: 203),
        Artwork(title: "Pink Smoke", artistName: "Nico Alvarez", description: "A man in a checkered jacket and red cap, pipe in mouth, pink smoke on a blue ground.", medium: "Acrylic on paper", dimensions: "16 × 12 in", price: 780, imageName: "pink_smoke", category: .painting, likeCount: 194),
        Artwork(title: "Straw Hat", artistName: "Nico Alvarez", description: "A portrait in a yellow hat with a blue band, pipe at the lip, green-and-white jacket.", medium: "Acrylic on paper", dimensions: "16 × 12 in", price: 760, imageName: "straw_hat", category: .painting, likeCount: 211),
        Artwork(title: "Split Gaze", artistName: "Nico Alvarez", description: "A split face — one watching eye, a yellow panel, pink and red on a white wall.", medium: "Mixed media on canvas", dimensions: "24 × 18 in", price: 1400, imageName: "split_gaze", category: .mixedMedia, likeCount: 288),
        Artwork(title: "Raised Arms", artistName: "Nico Alvarez", description: "Dancing silhouettes in red, blue and gold — bodies stacked in a night of colour.", medium: "Acrylic on canvas", dimensions: "20 × 16 in", price: 980, imageName: "raised_arms", category: .painting, likeCount: 232),
        Artwork(title: "Olive Crown", artistName: "Nico Alvarez", description: "A split face on olive green — black line, a red crown, three red marks on the cheek.", medium: "Acrylic & ink on paper", dimensions: "16 × 12 in", price: 620, imageName: "olive_crown", category: .painting, likeCount: 171),
        Artwork(title: "Red Rifle", artistName: "Nico Alvarez", description: "A red figure on grey, rifle raised, eyes stacked in black line.", medium: "Acrylic & ink on canvas", dimensions: "16 × 12 in", price: 840, imageName: "red_rifle", category: .painting, likeCount: 198),
        Artwork(title: "Stacked Heads", artistName: "Nico Alvarez", description: "A blue figure on coral — faces piled as a crown, white line holding the crowd.", medium: "Acrylic on canvas", dimensions: "20 × 16 in", price: 1120, imageName: "stacked_heads", category: .painting, likeCount: 254),
        Artwork(title: "Lined Sleep", artistName: "Nico Alvarez", description: "A closed-eye portrait in white line on dusk colour, one extra eye in the cheek.", medium: "Acrylic & oil stick on canvas", dimensions: "16 × 12 in", price: 890, imageName: "lined_sleep", category: .painting, likeCount: 187),
        Artwork(title: "Yellow Cow", artistName: "Nico Alvarez", description: "A cow in yellow and red against a farm sky — thick paint, a watching animal.", medium: "Oil on canvas", dimensions: "16 × 12 in", price: 740, imageName: "yellow_cow", category: .painting, likeCount: 209),
        Artwork(title: "Night Cafe", artistName: "Nico Alvarez", description: "A cafe terrace under a starred blue night — yellow awning, cobbles, figures at tables.", medium: "Oil on canvas", dimensions: "24 × 12 in", price: 1600, imageName: "night_cafe", category: .painting, likeCount: 312),
        Artwork(title: "Orange Head", artistName: "Nico Alvarez", description: "A cubist head on orange — blue bars, green marks, a face built from planes.", medium: "Acrylic on canvas", dimensions: "16 × 12 in", price: 820, imageName: "orange_head", category: .painting, likeCount: 225),
        Artwork(title: "Three Tomatoes", artistName: "Nico Alvarez", description: "Three tomatoes on a cloth — one cut open, wet red, a still life in thick paint.", medium: "Oil on canvas", dimensions: "12 × 12 in", price: 480, imageName: "three_tomatoes", category: .painting, likeCount: 164),
        Artwork(title: "City Coffee", artistName: "Nico Alvarez", description: "A figure in a pale coat holds coffee and a raised hand against a city of towers.", medium: "Acrylic on paper", dimensions: "16 × 12 in", price: 700, imageName: "city_coffee", category: .painting, likeCount: 191),

        Artwork(title: "Woman in Red", artistName: "Camila Ruiz", description: "A cubist portrait of a woman in a red dress against a green field — split face, watching eye, and a blue shutter at her shoulder.", medium: "Oil on canvas", dimensions: "24 × 36 in", price: 4800, imageName: "red_dress_portrait", category: .painting, likeCount: 412),
        Artwork(title: "People.", artistName: "Jonah Hale", description: "A mixed-media portrait built from newspaper, paint and collage. Two eyes, one face, the word people. on a red ground.", medium: "Collage, acrylic & newsprint on board", dimensions: "20 × 28 in", price: 2200, imageName: "people_collage", category: .mixedMedia, likeCount: 338),
        Artwork(title: "Green Figures", artistName: "Léa Morel", description: "Two intertwined figurative nudes in green and cream — a cubist study of bodies, hands and watching faces.", medium: "Oil on canvas", dimensions: "36 × 32 in", price: 6400, imageName: "green_figures", category: .painting, likeCount: 267),
        Artwork(title: "Spiral Eye", artistName: "Ivo Petrov", description: "An expressionist portrait: yellow face, teal ground, one eye a grey spiral. Abstract geometry in the features.", medium: "Acrylic on canvas", dimensions: "18 × 24 in", price: 1650, imageName: "spiral_eye", category: .painting, likeCount: 291),
        Artwork(title: "Blue Profile", artistName: "Nora Lind", description: "A geometric abstract portrait in navy and cream — profile of a face reduced to a line, a dark eye, a rust mouth.", medium: "Acrylic on canvas", dimensions: "16 × 20 in", price: 1900, imageName: "blue_profile", category: .painting, likeCount: 244),
        Artwork(title: "Tagged David", artistName: "Mira Solano", description: "A classical plaster bust tagged in red, yellow and blue. Street sculpture — stone meeting graffiti.", medium: "Painted plaster sculpture", dimensions: "18 × 12 × 10 in", price: 2800, imageName: "tagged_david", category: .sculpture, likeCount: 455),
        Artwork(title: "Tide Venus", artistName: "Alex Rivera", description: "A Venus figure wrapped in packaging, labels and found objects. Pop sculpture built from the supermarket aisle.", medium: "Found-object sculpture", dimensions: "32 × 10 × 8 in", price: 3600, imageName: "tide_venus", category: .sculpture, likeCount: 389),
        Artwork(title: "Lapis Mask", artistName: "Kofi Mensah", description: "A carved blue mask with a gold-worn edge. Sculpture you hold in the hand — a face from stone and pigment.", medium: "Carved wood & pigment", dimensions: "8 × 5 × 4 in", price: 1400, imageName: "lapis_mask", category: .sculpture, likeCount: 318),
        Artwork(title: "Electric Face", artistName: "Dante Cole", description: "A neo-expressionist portrait: a blue face on a field of yellow, magenta and green. Thick paint, black line, one yellow eye.", medium: "Acrylic on canvas", dimensions: "20 × 30 in", price: 2100, imageName: "electric_face", category: .painting, likeCount: 276),

        Artwork(title: "Musketeer", artistName: "Enzo Marchetti", description: "A cubist portrait in blue, yellow and magenta — split eyes, a black moustache, and a watching face.", medium: "Oil on canvas", dimensions: "24 × 40 in", price: 4200, imageName: "musketeer_face", category: .painting, likeCount: 301),
        Artwork(title: "Terracotta Head", artistName: "Theo Lang", description: "A folded terracotta mask, hollow and watchful. Sculpture reduced to brow, nose and mouth.", medium: "Terracotta sculpture", dimensions: "10 × 7 × 6 in", price: 1800, imageName: "terracotta_mask", category: .sculpture, likeCount: 264),
        Artwork(title: "Sunburst Mask", artistName: "Amina Diallo", description: "A carved wood mask with a radiating crown. Sculpture for the wall — cut eyes, scored cheeks, a fan of points.", medium: "Painted wood sculpture", dimensions: "22 × 12 × 4 in", price: 2400, imageName: "sunburst_mask", category: .sculpture, likeCount: 312),
        Artwork(title: "Fiber Beard", artistName: "Haruto Saito", description: "A carved wood face with a long fiber beard and brows. Sculpture that hangs in the air.", medium: "Wood, fiber & pigment", dimensions: "16 × 10 × 5 in", price: 2100, imageName: "fiber_beard_mask", category: .sculpture, likeCount: 278),
        Artwork(title: "Cowrie Bells", artistName: "Nia Okonkwo", description: "A dark carved portrait mask with cowrie shells, turquoise beads and hanging bells.", medium: "Wood, cowrie, brass & beads", dimensions: "18 × 10 × 6 in", price: 3200, imageName: "cowrie_bell_mask", category: .sculpture, likeCount: 401),
        Artwork(title: "Floral Horse", artistName: "Isla Bennett", description: "A photographic portrait of a black horse painted with flowers against a blue field.", medium: "Archival pigment print", dimensions: "20 × 24 in", price: 950, imageName: "floral_horse", category: .photography, likeCount: 388),
        Artwork(title: "Patchwork Elephant", artistName: "Ananya Rao", description: "A mixed-media elephant built from collage, crayon and patterned paper.", medium: "Collage & crayon on paper", dimensions: "16 × 20 in", price: 780, imageName: "collage_elephant", category: .mixedMedia, likeCount: 221),
        Artwork(title: "Dictionary Zebra", artistName: "Owen Blake", description: "A zebra in red glasses drawn over a 1954 dictionary page. Print on found paper.", medium: "Ink on vintage book page", dimensions: "8 × 11 in", price: 420, imageName: "dictionary_zebra", category: .printmaking, likeCount: 198),
        Artwork(title: "Catch of Eight", artistName: "Marin Costa", description: "Eight fish stacked in watercolor — reds, olives and a silver top. A still life of the sea.", medium: "Watercolour on paper", dimensions: "12 × 24 in", price: 1100, imageName: "stacked_fish", category: .painting, likeCount: 247),
        Artwork(title: "Zebra Crossing", artistName: "Luca Voss", description: "A digital remix: Napoleon on a pink-maned zebra, leopard cape, spray can in hand. Abstract pop on a mountain.", medium: "Digital print", dimensions: "16 × 20 in", price: 680, imageName: "zebra_crossing", category: .digital, likeCount: 356),
        Artwork(title: "Carnival Circle", artistName: "Sable Quinn", description: "A photographic portrait from below: seven masked figures around a silver moon, shot against a blue sky.", medium: "Archival pigment print", dimensions: "24 × 30 in", price: 1400, imageName: "carnival_circle", category: .photography, likeCount: 429),
        Artwork(title: "Gilded Ribs", artistName: "Reza Farhadi", description: "A figurative painting: a person against red-and-gold wallpaper, the skeleton drawn in colour on the chest.", medium: "Acrylic on canvas", dimensions: "30 × 40 in", price: 2600, imageName: "gilded_ribs", category: .painting, likeCount: 274),
        Artwork(title: "Red Rooster", artistName: "Hélène Dubois", description: "A rooster on a red ground — black, white and gold marks. Painting with the weight of a print.", medium: "Acrylic & ink on paper", dimensions: "14 × 18 in", price: 890, imageName: "red_rooster", category: .painting, likeCount: 203),
        Artwork(title: "Thousand Eyes", artistName: "Casper Holm", description: "A portrait with no face — a black silhouette filled with watching eyes, blue suit, yellow ground.", medium: "Acrylic on board", dimensions: "18 × 24 in", price: 1750, imageName: "thousand_eyes", category: .painting, likeCount: 331),
        Artwork(title: "Stitch Face", artistName: "Talia Brooks", description: "An abstract expressionist portrait: yellow and green eyes, a blue mouth, stitches down the chest.", medium: "Acrylic on canvas", dimensions: "20 × 24 in", price: 1450, imageName: "stitch_face", category: .painting, likeCount: 259),
        Artwork(title: "Lotus Buddha", artistName: "Arun Mehta", description: "A black seated figure on yellow and magenta — abstract colour field behind a watching face.", medium: "Acrylic & mixed media on canvas", dimensions: "36 × 48 in", price: 3800, imageName: "lotus_buddha", category: .painting, likeCount: 342),
        Artwork(title: "Third Eye Seat", artistName: "Nix Calder", description: "A neon skeleton in lotus pose, a radiating eye for a head. Abstract painting of the body as diagram.", medium: "Acrylic on canvas", dimensions: "30 × 40 in", price: 2400, imageName: "third_eye_seat", category: .painting, likeCount: 287),
        Artwork(title: "King of Spots", artistName: "Jules Perrin", description: "A king of spades re-drawn with dalmatians. Printmaking as a playing card.", medium: "Hand-coloured print", dimensions: "3.5 × 5 in", price: 280, imageName: "king_of_spots", category: .printmaking, likeCount: 176),
        Artwork(title: "Queen of Clubs", artistName: "Cleo Hart", description: "A queen of clubs in striped pink, with a white cat. Printmaking as a playing card.", medium: "Hand-coloured print", dimensions: "3.5 × 5 in", price: 280, imageName: "queen_of_clubs", category: .printmaking, likeCount: 184),
        Artwork(title: "Night Sax", artistName: "Miles Archer", description: "A figurative painting of a saxophonist in black and gold, on a checkerboard night.", medium: "Acrylic on paper", dimensions: "16 × 22 in", price: 920, imageName: "night_sax", category: .painting, likeCount: 218),
    ]
}
