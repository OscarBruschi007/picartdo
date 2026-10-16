import Foundation

// MARK: - Service Category
enum ServiceCategory: String, CaseIterable, Identifiable, Hashable {
    case tattoo          = "Tattoo Art"
    case digitalArt      = "Digital Art"
    case mural           = "Wall Murals"
    case wallpaper       = "Wallpapers"
    case fashion         = "Wearable Art"
    case paintingService = "Painting Services"
    case liveEvent       = "Art Exhibitions"
    case classes         = "Art Workshops"
    case sculpture       = "Sculpture"
    case ceramics        = "Ceramics & Pottery"
    case kidsWorkshop    = "Kids Workshops"
    case restoration     = "Art Restoration"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .tattoo:          return "🪡"
        case .mural:           return "🎨"
        case .paintingService: return "🖌️"
        case .classes:         return "📚"
        case .liveEvent:       return "🎭"
        case .ceramics:        return "🏺"
        case .digitalArt:      return "💻"
        case .restoration:     return "🔧"
        case .wallpaper:       return "🖼️"
        case .kidsWorkshop:    return "🖍️"
        case .fashion:         return "👗"
        case .sculpture:       return "🗿"
        }
    }

    var iconName: String {
        switch self {
        case .tattoo:          return "pencil.and.outline"
        case .mural:           return "building.2"
        case .paintingService: return "paintbrush.fill"
        case .classes:         return "books.vertical.fill"
        case .liveEvent:       return "star.fill"
        case .ceramics:        return "circle.dotted"
        case .digitalArt:      return "laptopcomputer"
        case .restoration:     return "wand.and.stars"
        case .wallpaper:       return "rectangle.pattern.checkered"
        case .kidsWorkshop:    return "paintpalette.fill"
        case .fashion:         return "tshirt.fill"
        case .sculpture:       return "cube.fill"
        }
    }

    /// Asset name for the category home hero. Drop a jpg into Assets as `{heroImageName}`.
    var heroImageName: String {
        switch self {
        case .tattoo:          return "tattoo_hero"
        case .digitalArt:      return "digitalArt_hero"
        case .mural:           return "mural_hero"
        case .wallpaper:       return "wallpaper_hero"
        case .fashion:         return "fashion_hero"
        case .paintingService: return "painting_hero"
        case .liveEvent:       return "liveEvent_hero"
        case .classes:         return "classes_hero"
        case .sculpture:       return "sculpture_hero"
        case .ceramics:        return "ceramics_hero"
        case .kidsWorkshop:    return "kidsWorkshop_hero"
        case .restoration:     return "restoration_hero"
        }
    }

    /// Short line under the title on each service home.
    var introLine: String {
        switch self {
        case .tattoo:          return "Studios, flash, and custom work — book the artist, not the shop."
        case .digitalArt:      return "Illustration, character, and screen-born originals, made to order."
        case .mural:           return "Walls, rooms, and city sides — artists who work at building scale."
        case .wallpaper:       return "Pattern for rooms. Botanical, deco, quiet, or loud."
        case .fashion:         return "Garments and textiles that belong on a body and a wall."
        case .paintingService: return "Commissioned paintings — portraits, landscapes, interiors."
        case .liveEvent:       return "Exhibitions, live painting, and nights built around the work."
        case .classes:         return "Workshops and studios you can sit down in."
        case .sculpture:       return "Bronze, stone, wood, and clay — work that occupies space."
        case .ceramics:        return "Vessels, tiles, and tableware from working kilns."
        case .kidsWorkshop:    return "Rooms for kids to make something they can take home."
        case .restoration:     return "Conservators for paintings, paper, frames, and walls."
        }
    }

    var matchKeys: [String] {
        switch self {
        case .tattoo:          return ["tattoo", "irezumi", "blackwork"]
        case .digitalArt:      return ["digital", "nft", "anime", "motion", "concept art"]
        case .mural:           return ["mural", "street art", "graffiti", "fresco"]
        case .wallpaper:       return ["wallpaper", "surface"]
        case .fashion:         return ["wearable", "fashion", "textile", "denim", "silk", "batik"]
        case .paintingService: return ["painting", "plein air", "gouache", "oil portraits"]
        case .liveEvent:       return ["exhibition", "live painting", "live events", "performance"]
        case .classes:         return ["workshop", "teaching"]
        case .sculpture:       return ["sculpture", "bronze", "marble", "stone"]
        case .ceramics:        return ["ceramics", "pottery", "raku", "stoneware", "terracotta"]
        case .kidsWorkshop:    return ["kids", "kids workshops"]
        case .restoration:     return ["restoration", "conservation", "gilding"]
        }
    }

    func matches(_ artist: Artist) -> Bool {
        artist.specialties.contains { spec in
            matchKeys.contains { key in
                spec.localizedCaseInsensitiveContains(key) || key.localizedCaseInsensitiveContains(spec)
            }
        }
    }
}

// MARK: - Service Model
struct Service: Identifiable, Hashable {
    let id: UUID
    var title: String
    var providerName: String
    var category: ServiceCategory
    var description: String
    var priceDisplay: String      // e.g. "$150 / hr", "From $800", "$50 / session"
    var imageName: String         // SF Symbol
    var tags: [String]            // e.g. ["NYC", "Remote", "Studio"]
    var isAvailable: Bool
    var rating: Double            // 0 – 5
    var reviewCount: Int

    init(
        id: UUID = UUID(),
        title: String,
        providerName: String,
        category: ServiceCategory,
        description: String = "",
        priceDisplay: String,
        imageName: String,
        tags: [String] = [],
        isAvailable: Bool = true,
        rating: Double = 5.0,
        reviewCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.providerName = providerName
        self.category = category
        self.description = description
        self.priceDisplay = priceDisplay
        self.imageName = imageName
        self.tags = tags
        self.isAvailable = isAvailable
        self.rating = rating
        self.reviewCount = reviewCount
    }
}

// MARK: - Sample Data
extension Service {
    static let samples: [Service] = [
        Service(
            title: "Custom Sleeve Design",
            providerName: "Marcus Chen",
            category: .tattoo,
            description: "Full sleeve illustration — from concept sketch to final session. Specialising in fine-line botanical and geometric styles.",
            priceDisplay: "$150 / hr",
            imageName: "pencil.and.outline",
            tags: ["NYC", "Fine-Line", "Booking Open"],
            rating: 4.9, reviewCount: 142
        ),
        Service(
            title: "Large-Scale Wall Mural",
            providerName: "Lucía Vega",
            category: .mural,
            description: "Transform blank walls into immersive art. Commercial and residential murals, indoor and outdoor.",
            priceDisplay: "From $800",
            imageName: "building.2",
            tags: ["Miami", "Outdoor", "Commercial"],
            rating: 5.0, reviewCount: 38
        ),
        Service(
            title: "Watercolour for Beginners",
            providerName: "Elena Rossi",
            category: .classes,
            description: "6-week group course covering washes, blooms, wet-on-wet techniques. All materials provided.",
            priceDisplay: "$60 / session",
            imageName: "books.vertical.fill",
            tags: ["Rome", "6 Weeks", "Materials Incl."],
            rating: 4.8, reviewCount: 91
        ),
        Service(
            title: "Live Wedding Painting",
            providerName: "Amara Diallo",
            category: .liveEvent,
            description: "Capture your ceremony in real time. Finished canvas delivered within 3 weeks, ready to hang.",
            priceDisplay: "From $1,200",
            imageName: "star.fill",
            tags: ["Destination", "Oil", "3-wk Delivery"],
            rating: 5.0, reviewCount: 24
        ),
        Service(
            title: "Hand-Thrown Ceramic Vessels",
            providerName: "Kaia Svensson",
            category: .ceramics,
            description: "Wheel-throwing workshops for small groups. Take home your own glazed piece.",
            priceDisplay: "$75 / session",
            imageName: "circle.dotted",
            tags: ["Copenhagen", "Groups", "Take-Home"],
            rating: 4.9, reviewCount: 29
        ),
        Service(
            title: "Digital Illustration Commission",
            providerName: "Yuki Tanaka",
            category: .digitalArt,
            description: "Character design, editorial illustration, brand mascots. Print-ready files delivered.",
            priceDisplay: "From $200",
            imageName: "laptopcomputer",
            tags: ["Remote", "48-hr Draft", "Print Ready"],
            rating: 5.0, reviewCount: 110
        ),
        Service(
            title: "Art Restoration & Conservation",
            providerName: "Henri Beaumont",
            category: .restoration,
            description: "Professional cleaning, re-lining, and inpainting for damaged paintings and works on paper.",
            priceDisplay: "Quote on request",
            imageName: "wand.and.stars",
            tags: ["Paris", "Certified", "Insurance OK"],
            rating: 5.0, reviewCount: 18
        ),
        Service(
            title: "Kids Art Party (Ages 5–12)",
            providerName: "Rainbow Studio",
            category: .kidsWorkshop,
            description: "2-hour guided art party: painting, collage, and take-home frames. We bring everything.",
            priceDisplay: "From $250 (up to 12 kids)",
            imageName: "paintpalette.fill",
            tags: ["At Your Venue", "All Ages", "Full Setup"],
            rating: 4.8, reviewCount: 76
        ),
        Service(
            title: "Hand-Painted Denim Jacket",
            providerName: "Nadia Kouros",
            category: .fashion,
            description: "Send your garment or commission a piece from scratch. Acrylic and fabric-safe paints, fully washable.",
            priceDisplay: "From $180",
            imageName: "tshirt.fill",
            tags: ["Athens", "Custom", "Washable"],
            rating: 4.9, reviewCount: 33
        ),
        Service(
            title: "Commissioned Sculpture",
            providerName: "Mira Solano",
            category: .sculpture,
            description: "Street-cast classics, found-object figures, and carved masks — made to occupy a room.",
            priceDisplay: "From $1,400",
            imageName: "cube.fill",
            tags: ["Barcelona", "Studio", "Shipping"],
            rating: 4.9, reviewCount: 28
        )
    ]
}

extension ServiceCategory {
    /// Categories shown in the app. Art Restoration, Painting Services and
    /// Ceramics & Pottery are kept in the model but hidden for now.
    static let offered: [ServiceCategory] = allCases.filter {
        ![.restoration, .paintingService, .ceramics].contains($0)
    }
}
