import SwiftUI
import UIKit

// MARK: - Artist Model

struct Artist: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let tagline: String
    let bio: String
    let location: String
    let bannerImage: String
    let avatarImage: String
    let works: Int
    let followers: String
    let sales: String
    let verified: Bool
    // Connection fields
    let availableForCommissions: Bool
    let rating: Double
    let reviewCount: Int
    let specialties: [String]
    let startingPrice: String
    let portfolioImages: [String]   // art_XX image names

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Artist, rhs: Artist) -> Bool { lhs.id == rhs.id }

    /// Cover used on service homes. Uses portfolio, then banner — replace those assets when you have studio photos.
    var serviceCoverName: String {
        if let first = portfolioImages.first, !first.isEmpty { return first }
        if !bannerImage.isEmpty { return bannerImage }
        if !avatarImage.isEmpty { return avatarImage }
        return portfolioImages.first ?? bannerImage
    }

    var storeName: String { "\(name) Studio" }

    /// Stable following count for profile stats.
    var followingCount: String {
        let count = max(48, min(980, works * 9 + name.count * 3))
        return "\(count)"
    }

    /// Instagram-style handle, e.g. Oscar Bruschi → oscarbruschi
    var username: String {
        name.folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    var handle: String { "@\(username)" }

    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    var hostedByLine: String { "Hosted by \(firstName)" }

    /// Resolve a listing’s artist name to the catalog profile.
    static func named(_ name: String) -> Artist? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if oscar.name.caseInsensitiveCompare(trimmed) == .orderedSame { return oscar }
        return all.first { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }
    }

    var storePhotos: [String] {
        var seen = Set<String>()
        var photos: [String] = []
        func add(_ name: String) {
            guard !name.isEmpty, !seen.contains(name) else { return }
            seen.insert(name)
            photos.append(name)
        }
        if ServiceCategory.tattoo.matches(self), let studio = ServiceGallery.studioPhoto(for: self, in: .tattoo) {
            add(studio)
        }
        add(serviceCoverName)
        for name in portfolioImages { add(name) }
        add(bannerImage)
        return photos
    }
}

extension Artist {

    /// Oscar Bruschi — the app owner / primary artist
    static let oscar = Artist(
        name: "Oscar Bruschi",
        tagline: "Painter, Draughtsman & Mixed Media",
        bio: "Abstract art.",
        location: "Toronto, ON",
        bannerImage: "profile_cover_rapanui", avatarImage: "profile_photo_oscar",
        works: 26, followers: "1.4k", sales: "$24k", verified: true,
        availableForCommissions: true,
        rating: 5.0, reviewCount: 26,
        specialties: ["Acrylic", "Ink", "Mixed Media", "Mandalas"],
        startingPrice: "$620",
        portfolioImages: ["color_field", "circle_worlds", "blue_moon", "cross_garden", "orange_scallops", "violet_window", "chorus", "night_watch"]
    )

    static let all: [Artist] = [
        Artist(name: "Elena Rossi",
               tagline: "Watercolour & Mixed Media",
               bio: "Capturing light and emotion through fluid washes and intricate detail. Based in Rome, available for portrait and landscape commissions worldwide.",
               location: "Rome, IT",
               bannerImage: "art_05", avatarImage: "avatar_01",
               works: 32, followers: "2.1k", sales: "$18k", verified: true,
               availableForCommissions: true,
               rating: 4.9, reviewCount: 47,
               specialties: ["Watercolour", "Portraits", "Landscapes"],
               startingPrice: "$350",
               portfolioImages: ["art_05", "art_07", "art_12", "art_21"]),

        Artist(name: "Marcus Chen",
               tagline: "Fine-Line Ink & Geometry",
               bio: "Precision and pattern — geometric compositions in monochromatic ink. Specialises in large-format commissions and limited edition prints.",
               location: "NYC, US",
               bannerImage: "art_04", avatarImage: "avatar_02",
               works: 18, followers: "980", sales: "$12k", verified: true,
               availableForCommissions: false,
               rating: 4.7, reviewCount: 23,
               specialties: ["Ink", "Geometric", "Prints"],
               startingPrice: "$500",
               portfolioImages: ["art_04", "art_09", "art_26", "art_11"]),

        Artist(name: "Lucía Vega",
               tagline: "Large-Scale Murals & Acrylics",
               bio: "From studio canvases to city walls — bold color, bold ideas. Available for commercial murals, events, and large canvas commissions.",
               location: "Miami, US",
               bannerImage: "art_15", avatarImage: "avatar_03",
               works: 24, followers: "3.4k", sales: "$34k", verified: true,
               availableForCommissions: true,
               rating: 5.0, reviewCount: 61,
               specialties: ["Murals", "Acrylics", "Live Events"],
               startingPrice: "$800",
               portfolioImages: ["art_15", "art_19", "art_22", "art_03"]),

        Artist(name: "Amara Diallo",
               tagline: "Oil Portraits & Live Event Art",
               bio: "Bespoke oil portraits that carry the weight of a moment. I paint weddings, galas, and private commissions with equal care.",
               location: "Paris, FR",
               bannerImage: "art_12", avatarImage: "avatar_04",
               works: 15, followers: "1.7k", sales: "$22k", verified: false,
               availableForCommissions: true,
               rating: 4.8, reviewCount: 34,
               specialties: ["Oil", "Portraits", "Live Painting"],
               startingPrice: "$600",
               portfolioImages: ["art_12", "art_20", "art_22", "art_06"]),

        Artist(name: "Kaia Svensson",
               tagline: "Ceramics & Textile Art",
               bio: "The beauty of imperfection — hand-thrown vessels and woven forms. Custom ceramic sets and textile installations on request.",
               location: "Copenhagen, DK",
               bannerImage: "art_17", avatarImage: "avatar_05",
               works: 41, followers: "1.2k", sales: "$9k", verified: true,
               availableForCommissions: false,
               rating: 4.6, reviewCount: 18,
               specialties: ["Ceramics", "Textiles", "Installation"],
               startingPrice: "$250",
               portfolioImages: ["art_17", "art_21", "art_25", "art_08"]),

        Artist(name: "Yuki Tanaka",
               tagline: "Digital Illustration",
               bio: "Characters, worlds, and brands — brought to life with a tablet and vision. Fast turnaround on commercial and personal commissions.",
               location: "Tokyo, JP",
               bannerImage: "art_01", avatarImage: "avatar_06",
               works: 60, followers: "5.8k", sales: "$41k", verified: true,
               availableForCommissions: true,
               rating: 4.9, reviewCount: 112,
               specialties: ["Digital", "Character Design", "Branding"],
               startingPrice: "$150",
               portfolioImages: ["art_01", "art_02", "art_13", "art_09"]),

        Artist(name: "James Okafor",
               tagline: "Charcoal & Oil Portraits",
               bio: "Every face tells a story. I just find the right way to tell it. Accepting portrait commissions for individuals, couples, and families.",
               location: "Lagos, NG",
               bannerImage: "art_10", avatarImage: "story_avatar_wave",
               works: 27, followers: "890", sales: "$15k", verified: false,
               availableForCommissions: true,
               rating: 4.7, reviewCount: 29,
               specialties: ["Charcoal", "Oil", "Portraits"],
               startingPrice: "$400",
               portfolioImages: ["art_08", "art_10", "art_11", "art_22"]),

        Artist(name: "Sofía Martínez",
               tagline: "Abstract Expressionism",
               bio: "Raw emotion distilled into paint. No rules, only feeling. Available for large-scale abstract commissions and corporate art installations.",
               location: "Buenos Aires",
               bannerImage: "art_20", avatarImage: "avatar_08",
               works: 38, followers: "2.9k", sales: "$28k", verified: true,
               availableForCommissions: true,
               rating: 4.8, reviewCount: 53,
               specialties: ["Abstract", "Expressionism", "Installation"],
               startingPrice: "$550",
               portfolioImages: ["art_03", "art_14", "art_18", "art_20"]),

        Artist(name: "Camila Ruiz",
               tagline: "Cubist Portrait Painting",
               bio: "Split faces, watching eyes, colour fields. Portraits that hold more than one angle at once.",
               location: "Madrid, ES",
               bannerImage: "red_dress_portrait", avatarImage: "story_avatar_furcoat",
               works: 19, followers: "2.4k", sales: "$41k", verified: true,
               availableForCommissions: true, rating: 4.9, reviewCount: 31,
               specialties: ["Painting", "Portraits", "Cubism"],
               startingPrice: "$1,800",
               portfolioImages: ["red_dress_portrait"]),

        Artist(name: "Jonah Hale",
               tagline: "Collage & Mixed Media Portraits",
               bio: "Newspaper, paint and found type. Faces built from the day's paper.",
               location: "Brooklyn, US",
               bannerImage: "people_collage", avatarImage: "people_collage",
               works: 27, followers: "3.1k", sales: "$22k", verified: true,
               availableForCommissions: true, rating: 4.8, reviewCount: 44,
               specialties: ["Mixed Media", "Collage", "Portraits"],
               startingPrice: "$900",
               portfolioImages: ["people_collage"]),

        Artist(name: "Léa Morel",
               tagline: "Figurative Cubist Painting",
               bio: "Bodies in green and cream. Figurative painting after the Paris atelier.",
               location: "Lyon, FR",
               bannerImage: "green_figures", avatarImage: "green_figures",
               works: 14, followers: "1.8k", sales: "$58k", verified: true,
               availableForCommissions: false, rating: 5.0, reviewCount: 17,
               specialties: ["Painting", "Figurative", "Oil"],
               startingPrice: "$3,200",
               portfolioImages: ["green_figures"]),

        Artist(name: "Ivo Petrov",
               tagline: "Expressionist Portrait Painting",
               bio: "Yellow faces, spiral eyes, teal grounds. Expression that starts with the stare.",
               location: "Sofia, BG",
               bannerImage: "spiral_eye", avatarImage: "spiral_eye",
               works: 33, followers: "2.9k", sales: "$19k", verified: false,
               availableForCommissions: true, rating: 4.7, reviewCount: 39,
               specialties: ["Painting", "Expressionism", "Portraits"],
               startingPrice: "$650",
               portfolioImages: ["spiral_eye"]),

        Artist(name: "Nora Lind",
               tagline: "Geometric Abstract Portraits",
               bio: "A face reduced to a line. Navy, cream, rust — portraits as architecture.",
               location: "Stockholm, SE",
               bannerImage: "blue_profile", avatarImage: "blue_profile",
               works: 21, followers: "1.6k", sales: "$27k", verified: true,
               availableForCommissions: true, rating: 4.8, reviewCount: 22,
               specialties: ["Painting", "Abstract", "Geometric"],
               startingPrice: "$780",
               portfolioImages: ["blue_profile"]),

        Artist(name: "Dante Cole",
               tagline: "Neo-Expressionist Painting",
               bio: "Thick paint, black line, electric colour. Portraits that don't sit still.",
               location: "Detroit, US",
               bannerImage: "electric_face", avatarImage: "electric_face",
               works: 40, followers: "4.2k", sales: "$33k", verified: true,
               availableForCommissions: true, rating: 4.8, reviewCount: 51,
               specialties: ["Painting", "Expressionism", "Portraits"],
               startingPrice: "$900",
               portfolioImages: ["electric_face"]),

        Artist(name: "Enzo Marchetti", tagline: "Cubist Portrait Painting", bio: "Split faces in blue and yellow. Portraits that look back twice.", location: "Milan, IT", bannerImage: "musketeer_face", avatarImage: "musketeer_face", works: 22, followers: "1.9k", sales: "$31k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 24, specialties: ["Painting", "Portraits", "Cubism"], startingPrice: "$1,200", portfolioImages: ["musketeer_face"]),
        Artist(name: "Isla Bennett", tagline: "Painted Animal Photography", bio: "Studio portraits of painted animals — colour on a living body.", location: "London, UK", bannerImage: "floral_horse", avatarImage: "floral_horse", works: 18, followers: "4.6k", sales: "$16k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 41, specialties: ["Photography", "Portrait", "Studio"], startingPrice: "$400", portfolioImages: ["floral_horse"]),
        Artist(name: "Ananya Rao", tagline: "Collage & Mixed Media", bio: "Paper, crayon and pattern. Animals built from scraps.", location: "Mumbai, IN", bannerImage: "collage_elephant", avatarImage: "collage_elephant", works: 35, followers: "2.2k", sales: "$12k", verified: false, availableForCommissions: true, rating: 4.7, reviewCount: 29, specialties: ["Mixed Media", "Collage"], startingPrice: "$280", portfolioImages: ["collage_elephant"]),
        Artist(name: "Owen Blake", tagline: "Found-Page Printmaking", bio: "Drawings on dictionary leaves. Prints that keep the type.", location: "Portland, US", bannerImage: "dictionary_zebra", avatarImage: "dictionary_zebra", works: 61, followers: "1.5k", sales: "$8k", verified: false, availableForCommissions: true, rating: 4.6, reviewCount: 33, specialties: ["Printmaking", "Ink", "Found Paper"], startingPrice: "$120", portfolioImages: ["dictionary_zebra"]),
        Artist(name: "Marin Costa", tagline: "Watercolour Still Life", bio: "Fish, fruit and the table. Watercolour that stays wet in the looking.", location: "Lisbon, PT", bannerImage: "stacked_fish", avatarImage: "stacked_fish", works: 29, followers: "2.0k", sales: "$14k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 22, specialties: ["Painting", "Watercolour", "Still Life"], startingPrice: "$350", portfolioImages: ["stacked_fish"]),
        Artist(name: "Luca Voss", tagline: "Digital Pop & Remix", bio: "Old history, new colour. Digital prints that refuse the original.", location: "Berlin, DE", bannerImage: "zebra_crossing", avatarImage: "zebra_crossing", works: 44, followers: "8.1k", sales: "$27k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 67, specialties: ["Digital", "Pop", "Print"], startingPrice: "$220", portfolioImages: ["zebra_crossing"]),
        Artist(name: "Sable Quinn", tagline: "Staged Photography", bio: "Masks, costumes and a blue sky. Portraits built as a circle.", location: "Los Angeles, US", bannerImage: "carnival_circle", avatarImage: "carnival_circle", works: 16, followers: "5.4k", sales: "$21k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 19, specialties: ["Photography", "Portrait", "Costume"], startingPrice: "$500", portfolioImages: ["carnival_circle"]),
        Artist(name: "Reza Farhadi", tagline: "Figurative Painting", bio: "Bodies against wallpaper. Figurative painting with the skeleton showing.", location: "Tehran, IR", bannerImage: "gilded_ribs", avatarImage: "gilded_ribs", works: 20, followers: "1.7k", sales: "$24k", verified: true, availableForCommissions: false, rating: 4.8, reviewCount: 15, specialties: ["Painting", "Figurative", "Portraits"], startingPrice: "$900", portfolioImages: ["gilded_ribs"]),
        Artist(name: "Hélène Dubois", tagline: "Animal Painting", bio: "Roosters, dogs, and farm colour. Paint that sits like a print.", location: "Marseille, FR", bannerImage: "red_rooster", avatarImage: "red_rooster", works: 38, followers: "1.4k", sales: "$11k", verified: false, availableForCommissions: true, rating: 4.7, reviewCount: 28, specialties: ["Painting", "Animals", "Acrylic"], startingPrice: "$280", portfolioImages: ["red_rooster"]),
        Artist(name: "Casper Holm", tagline: "Surreal Portrait Painting", bio: "Faces made of eyes. Portraits that watch you back.", location: "Copenhagen, DK", bannerImage: "thousand_eyes", avatarImage: "thousand_eyes", works: 17, followers: "3.3k", sales: "$19k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 21, specialties: ["Painting", "Portraits", "Surreal"], startingPrice: "$620", portfolioImages: ["thousand_eyes"]),
        Artist(name: "Talia Brooks", tagline: "Expressionist Painting", bio: "Stitched faces, coloured eyes. Abstract expression that still has a mouth.", location: "Chicago, US", bannerImage: "stitch_face", avatarImage: "stitch_face", works: 26, followers: "2.8k", sales: "$17k", verified: false, availableForCommissions: true, rating: 4.7, reviewCount: 34, specialties: ["Painting", "Expressionism", "Abstract"], startingPrice: "$480", portfolioImages: ["stitch_face"]),
        Artist(name: "Arun Mehta", tagline: "Devotional Abstract Painting", bio: "Seated figures on colour fields. Abstract painting with a still centre.", location: "Jaipur, IN", bannerImage: "lotus_buddha", avatarImage: "lotus_buddha", works: 31, followers: "2.5k", sales: "$36k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 27, specialties: ["Painting", "Abstract", "Mixed Media"], startingPrice: "$1,100", portfolioImages: ["lotus_buddha"]),
        Artist(name: "Nix Calder", tagline: "Neon Abstract Painting", bio: "Skeletons, third eyes, gold grounds. Abstract painting as a diagram of the body.", location: "Austin, US", bannerImage: "third_eye_seat", avatarImage: "story_avatar_inkface", works: 23, followers: "3.9k", sales: "$22k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 31, specialties: ["Painting", "Abstract", "Expressionism"], startingPrice: "$740", portfolioImages: ["third_eye_seat"]),
        Artist(name: "Jules Perrin", tagline: "Playing-Card Printmaking", bio: "Kings redrawn. Small prints that behave like a deck.", location: "Lyon, FR", bannerImage: "king_of_spots", avatarImage: "king_of_spots", works: 80, followers: "1.1k", sales: "$7k", verified: false, availableForCommissions: true, rating: 4.6, reviewCount: 44, specialties: ["Printmaking", "Illustration"], startingPrice: "$90", portfolioImages: ["king_of_spots"]),
        Artist(name: "Cleo Hart", tagline: "Playing-Card Printmaking", bio: "Queens in stripe and flower. Printmaking the size of a hand.", location: "Brighton, UK", bannerImage: "queen_of_clubs", avatarImage: "queen_of_clubs", works: 74, followers: "1.3k", sales: "$8k", verified: false, availableForCommissions: true, rating: 4.7, reviewCount: 39, specialties: ["Printmaking", "Illustration"], startingPrice: "$90", portfolioImages: ["queen_of_clubs"]),
        Artist(name: "Miles Archer", tagline: "Jazz Figurative Painting", bio: "Horns, hats, checkerboard nights. Figurative painting with a beat.", location: "New Orleans, US", bannerImage: "night_sax", avatarImage: "night_sax", works: 28, followers: "2.1k", sales: "$13k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 26, specialties: ["Painting", "Figurative", "Music"], startingPrice: "$320", portfolioImages: ["night_sax"]),
        Artist(name: "Kai Moreau", tagline: "Geometric Illusion Painting", bio: "Impossible volumes on a flat plane. Process videos from the studio.", location: "Paris, FR", bannerImage: "studio_cubes", avatarImage: "studio_cubes", works: 34, followers: "12.4k", sales: "$41k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 58, specialties: ["Painting", "Geometry", "Process"], startingPrice: "$1,400", portfolioImages: ["studio_cubes"]),
        Artist(name: "Ellis Ward", tagline: "Printmaking & Framing", bio: "Ink, paper, and the box that holds them. Studio work, filmed close.", location: "Brooklyn, US", bannerImage: "studio_frame", avatarImage: "studio_frame", works: 47, followers: "6.8k", sales: "$19k", verified: false, availableForCommissions: true, rating: 4.7, reviewCount: 39, specialties: ["Printmaking", "Paper", "Process"], startingPrice: "$180", portfolioImages: ["studio_frame"]),
        Artist(name: "Noah Pell", tagline: "Process Painting", bio: "Colour laid down in passes. The video is the work being decided.", location: "Melbourne, AU", bannerImage: "studio_switching", avatarImage: "studio_switching", works: 29, followers: "9.1k", sales: "$22k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 44, specialties: ["Painting", "Process", "Colour Field"], startingPrice: "$640", portfolioImages: ["studio_switching"]),
        Artist(name: "Wren Solis", tagline: "Studio Notes & Painting", bio: "What I read ends up on the canvas. Quiet studio, slow looking.", location: "Copenhagen, DK", bannerImage: "studio_books", avatarImage: "studio_books", works: 18, followers: "15.2k", sales: "$27k", verified: true, availableForCommissions: false, rating: 4.9, reviewCount: 31, specialties: ["Painting", "Studio", "Writing"], startingPrice: "$520", portfolioImages: ["studio_books"]),
        Artist(name: "Mateo Ruiz", tagline: "Installation Painting", bio: "Squares on a wall until the room answers. Work that hangs in space.", location: "Barcelona, ES", bannerImage: "studio_hang", avatarImage: "studio_hang", works: 22, followers: "7.4k", sales: "$33k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 27, specialties: ["Painting", "Installation", "Minimal"], startingPrice: "$900", portfolioImages: ["studio_hang"]),
        Artist(name: "Silas Kane", tagline: "Studio Painting", bio: "Stretch the colour, then the canvas. Portraits around the room.", location: "Mexico City, MX", bannerImage: "studio_stretch", avatarImage: "studio_stretch", works: 41, followers: "11.0k", sales: "$38k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 62, specialties: ["Painting", "Portraits", "Studio"], startingPrice: "$780", portfolioImages: ["studio_stretch"]),
        Artist(name: "Samir Cole", tagline: "Figurative Painting", bio: "Walking the work into the light. Rooms, colour, a held canvas.", location: "Lisbon, PT", bannerImage: "studio_carry", avatarImage: "studio_carry", works: 26, followers: "8.6k", sales: "$29k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 35, specialties: ["Painting", "Figurative", "Studio"], startingPrice: "$1,100", portfolioImages: ["studio_carry"]),
        Artist(name: "Hugo Kessler", tagline: "Figurative Painting", bio: "Elongated figures, red grounds, a room that still holds the work. This week's studio.", location: "Berlin, DE", bannerImage: "artist_of_the_week", avatarImage: "story_avatar_spiral", works: 19, followers: "4.8k", sales: "$44k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 21, specialties: ["Painting", "Figurative", "Expressionism"], startingPrice: "$2,200", portfolioImages: ["artist_of_the_week"]),

        // ── Tattoo Artist ──────────────────────────────────────────────
        Artist(name: "Raf Torres",
               tagline: "Tattoo Art · Fine-Line & Botanical",
               bio: "Ten years under the needle — precision fine-line, botanical sleeves, and custom black-work. Book a consultation to discuss your vision.",
               location: "Barcelona, ES",
               bannerImage: "tattoo_studio_03", avatarImage: "tattoo_studio_03",
               works: 310, followers: "12.4k", sales: "$95k", verified: true,
               availableForCommissions: true,
               rating: 5.0, reviewCount: 218,
               specialties: ["Tattoo", "Fine-Line", "Botanical"],
               startingPrice: "$200",
               portfolioImages: ["tattoo_studio_03", "tattoo_studio_01", "tattoo_studio_04", "tattoo_studio_09"]),

        // ── Street Muralist ────────────────────────────────────────────
        Artist(name: "Maya Jackson",
               tagline: "Street Murals & Urban Art",
               bio: "Walls are my canvas. From community murals to brand activations, I create work that stops people in their tracks.",
               location: "Los Angeles, US",
               bannerImage: "art_19", avatarImage: "avatar_10",
               works: 74, followers: "18.7k", sales: "$120k", verified: true,
               availableForCommissions: true,
               rating: 4.9, reviewCount: 89,
               specialties: ["Murals", "Street Art", "Graffiti"],
               startingPrice: "$1,200",
               portfolioImages: ["art_19", "art_22", "art_15", "art_26"]),

        // ── Fashion / Wearable Art ─────────────────────────────────────
        Artist(name: "Diego Herrera",
               tagline: "Wearable Art & Textile Design",
               bio: "Hand-painted garments, one-of-a-kind accessories, and custom textile installations. Fashion that belongs on a gallery wall.",
               location: "Mexico City, MX",
               bannerImage: "art_24", avatarImage: "avatar_11",
               works: 52, followers: "6.1k", sales: "$31k", verified: false,
               availableForCommissions: true,
               rating: 4.8, reviewCount: 41,
               specialties: ["Wearable Art", "Textile", "Fashion"],
               startingPrice: "$180",
               portfolioImages: ["art_24", "art_18", "art_25", "art_14"]),

        // ── Fine Art Photographer ─────────────────────────────────────
        Artist(name: "Priya Nair",
               tagline: "Fine Art Photography",
               bio: "I chase the light that most people overlook. Limited-edition fine art prints, bespoke portrait sessions, and editorial commissions.",
               location: "Mumbai, IN",
               bannerImage: "art_13", avatarImage: "art_05",
               works: 145, followers: "9.3k", sales: "$57k", verified: true,
               availableForCommissions: true,
               rating: 4.9, reviewCount: 103,
               specialties: ["Photography", "Portraits", "Fine Art Print"],
               startingPrice: "$300",
               portfolioImages: ["art_13", "art_05", "art_21", "art_02"]),

        // ── Sculptor ─────────────────────────────────────────────────
        Artist(name: "Ivan Kozlov",
               tagline: "Sculpture · Bronze & Stone",
               bio: "Carving narratives from raw materials. Commissions for residential gardens, public spaces, and private collections.",
               location: "Prague, CZ",
               bannerImage: "art_26", avatarImage: "art_22",
               works: 29, followers: "1.5k", sales: "$88k", verified: true,
               availableForCommissions: false,
               rating: 4.9, reviewCount: 17,
               specialties: ["Sculpture", "Bronze", "Stone"],
               startingPrice: "$2,500",
               portfolioImages: ["art_26", "art_22", "art_10", "art_09"]),

        // ── Spray Paint / Aerosol ─────────────────────────────────────
        Artist(name: "Carlos Romero",
               tagline: "Aerosol Art & Large-Format",
               bio: "From rooftops to galleries — aerosol is my medium and the city is my studio. Available for large-format canvas and outdoor mural projects.",
               location: "São Paulo, BR",
               bannerImage: "art_03", avatarImage: "art_14",
               works: 88, followers: "22.0k", sales: "$76k", verified: true,
               availableForCommissions: true,
               rating: 4.7, reviewCount: 66,
               specialties: ["Aerosol", "Street Art", "Murals"],
               startingPrice: "$900",
               portfolioImages: ["art_03", "art_14", "art_19", "art_22"]),

        // ── Calligraphy & Typography Art ──────────────────────────────
        Artist(name: "Hassan Bakr",
               tagline: "Calligraphy & Typography Art",
               bio: "Words become art. Custom calligraphy for weddings, brand identity, and gallery pieces. Arabic and Latin scripts both welcome.",
               location: "Cairo, EG",
               bannerImage: "art_11", avatarImage: "art_25",
               works: 203, followers: "4.8k", sales: "$19k", verified: false,
               availableForCommissions: true,
               rating: 4.8, reviewCount: 72,
               specialties: ["Calligraphy", "Typography", "Mixed Media"],
               startingPrice: "$120",
               portfolioImages: ["art_11", "art_25", "art_04", "art_17"]),

        // ── Henna & Pattern Artist ─────────────────────────────────────
        Artist(name: "Fatima Al-Rashid",
               tagline: "Henna · Pattern & Illustration",
               bio: "Intricate patterns rooted in tradition, reimagined for the modern world. Bridal henna, pattern illustration, and custom print design.",
               location: "Dubai, AE",
               bannerImage: "art_07", avatarImage: "art_20",
               works: 174, followers: "7.6k", sales: "$24k", verified: true,
               availableForCommissions: true,
               rating: 5.0, reviewCount: 134,
               specialties: ["Henna", "Pattern", "Illustration"],
               startingPrice: "$90",
               portfolioImages: ["art_07", "art_20", "art_06", "art_16"]),

        // ── Kids Workshop Artist ───────────────────────────────────────
        Artist(name: "Lena Fischer",
               tagline: "Kids Art & Stained Glass",
               bio: "Bringing colour and joy to the next generation. I run kids workshops, school residencies, and also create stunning stained glass installations for grown-ups.",
               location: "Vienna, AT",
               bannerImage: "art_02", avatarImage: "art_17",
               works: 93, followers: "3.2k", sales: "$14k", verified: false,
               availableForCommissions: true,
               rating: 4.9, reviewCount: 88,
               specialties: ["Kids Workshops", "Stained Glass", "Installation"],
               startingPrice: "$75",
               portfolioImages: ["art_02", "art_17", "art_08", "art_13"]),

        // ── Restoration Specialist ─────────────────────────────────────
        Artist(name: "Henri Beaumont",
               tagline: "Art Restoration & Conservation",
               bio: "Giving masterpieces a second life. Certified conservator with 20 years of experience in painting restoration, cleaning, and archival documentation.",
               location: "Paris, FR",
               bannerImage: "art_08", avatarImage: "art_26",
               works: 156, followers: "1.1k", sales: "$210k", verified: true,
               availableForCommissions: false,
               rating: 5.0, reviewCount: 22,
               specialties: ["Restoration", "Conservation", "Oil Painting"],
               startingPrice: "$800",
               portfolioImages: ["art_08", "art_26", "art_11", "art_22"]),

        // ── Tattoo Art ────────────────────────────────────────────────
        Artist(name: "Kim Soo-Yeon", tagline: "Blackwork & Geometric Tattoo", bio: "Precise geometric blackwork with a Korean minimalist edge.", location: "Seoul, KR", bannerImage: "tattoo_studio_06", avatarImage: "tattoo_studio_06", works: 180, followers: "8.2k", sales: "$65k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 142, specialties: ["Tattoo", "Blackwork", "Geometric"], startingPrice: "$180", portfolioImages: ["tattoo_studio_06", "tattoo_studio_09"]),
        Artist(name: "Jake Morrison", tagline: "American Traditional Tattoo", bio: "Bold lines, classic flash. Traditional American tattoo done right.", location: "Austin, US", bannerImage: "tattoo_studio_02", avatarImage: "tattoo_studio_02", works: 250, followers: "11.0k", sales: "$78k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 203, specialties: ["Tattoo", "Traditional", "Flash"], startingPrice: "$220", portfolioImages: ["tattoo_studio_02", "tattoo_studio_04"]),
        Artist(name: "Nadia Petrov", tagline: "Watercolour Tattoo Specialist", bio: "Dreamy watercolour tattoos blending ink and light.", location: "Moscow, RU", bannerImage: "tattoo_studio_07", avatarImage: "tattoo_studio_07", works: 120, followers: "5.5k", sales: "$42k", verified: false, availableForCommissions: true, rating: 4.9, reviewCount: 98, specialties: ["Tattoo", "Watercolour", "Fine-Line"], startingPrice: "$250", portfolioImages: ["tattoo_studio_07", "tattoo_studio_09"]),
        Artist(name: "Tomas Bauer", tagline: "Realism & Portrait Tattoo", bio: "Hyper-realistic portrait tattoos with impeccable shading.", location: "Berlin, DE", bannerImage: "tattoo_studio_05", avatarImage: "tattoo_studio_05", works: 310, followers: "14.3k", sales: "$120k", verified: true, availableForCommissions: false, rating: 5.0, reviewCount: 267, specialties: ["Tattoo", "Realism", "Portraits"], startingPrice: "$300", portfolioImages: ["tattoo_studio_05", "tattoo_studio_01"]),
        Artist(name: "Aiko Yamamoto", tagline: "Japanese Irezumi Tattoo", bio: "Traditional Japanese irezumi — dragons, koi, and sakura.", location: "Osaka, JP", bannerImage: "tattoo_studio_08", avatarImage: "tattoo_studio_08", works: 190, followers: "9.1k", sales: "$88k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 156, specialties: ["Tattoo", "Japanese", "Irezumi"], startingPrice: "$280", portfolioImages: ["tattoo_studio_08", "tattoo_studio_03"]),

        // ── Digital Art ───────────────────────────────────────────────
        Artist(name: "Leo Chen", tagline: "Concept Art & Digital Painting", bio: "AAA game concept art and editorial illustration from San Francisco.", location: "San Francisco, US", bannerImage: "art_13", avatarImage: "art_03", works: 88, followers: "6.7k", sales: "$53k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 74, specialties: ["Digital", "Concept Art", "Illustration"], startingPrice: "$200", portfolioImages: ["art_13", "art_03"]),
        Artist(name: "Mia Johansson", tagline: "Digital Portraits & Branding", bio: "Clean, modern digital portraits and brand identity design.", location: "Stockholm, SE", bannerImage: "art_21", avatarImage: "art_05", works: 60, followers: "3.4k", sales: "$29k", verified: true, availableForCommissions: true, rating: 4.7, reviewCount: 51, specialties: ["Digital", "Portraits", "Branding"], startingPrice: "$150", portfolioImages: ["art_21", "art_05"]),
        Artist(name: "Raj Patel", tagline: "3D Digital Sculpture & NFT Art", bio: "3D digital sculptor bridging fine art and the metaverse.", location: "Bangalore, IN", bannerImage: "art_14", avatarImage: "art_22", works: 45, followers: "12.1k", sales: "$94k", verified: true, availableForCommissions: true, rating: 5.0, reviewCount: 88, specialties: ["Digital", "3D", "NFT"], startingPrice: "$400", portfolioImages: ["art_14", "art_22"]),
        Artist(name: "Sara Kim", tagline: "Anime & Character Illustration", bio: "Vibrant anime-inspired character design and webtoon illustration.", location: "Seoul, KR", bannerImage: "art_02", avatarImage: "art_18", works: 130, followers: "22.4k", sales: "$61k", verified: false, availableForCommissions: true, rating: 4.8, reviewCount: 194, specialties: ["Digital", "Anime", "Character Design"], startingPrice: "$120", portfolioImages: ["art_02", "art_18"]),
        Artist(name: "Omar Hassan", tagline: "Motion Graphics & Digital Art", bio: "Where digital illustration meets motion — looping art and animated prints.", location: "Dubai, AE", bannerImage: "art_15", avatarImage: "art_11", works: 72, followers: "8.9k", sales: "$47k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 63, specialties: ["Digital", "Motion Graphics", "Animation"], startingPrice: "$350", portfolioImages: ["art_15", "art_11"]),

        // ── Wall Murals ───────────────────────────────────────────────
        Artist(name: "Pedro Silva", tagline: "Tropical Mural & Street Art", bio: "Vivid tropical murals that transform urban spaces.", location: "Rio, BR", bannerImage: "art_19", avatarImage: "art_03", works: 65, followers: "7.2k", sales: "$58k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 54, specialties: ["Mural", "Tropical", "Street Art"], startingPrice: "$700", portfolioImages: ["art_19", "art_03"]),
        Artist(name: "Naomi Williams", tagline: "Community & Social Murals", bio: "Community-driven murals that tell neighbourhood stories.", location: "Chicago, US", bannerImage: "art_22", avatarImage: "art_17", works: 38, followers: "4.1k", sales: "$31k", verified: false, availableForCommissions: true, rating: 4.7, reviewCount: 29, specialties: ["Mural", "Community Art", "Social"], startingPrice: "$600", portfolioImages: ["art_22", "art_17"]),
        Artist(name: "Zara Ahmed", tagline: "Geometric Mural & Pattern Art", bio: "Large-scale geometric patterns for commercial and residential walls.", location: "London, UK", bannerImage: "art_25", avatarImage: "art_08", works: 47, followers: "5.8k", sales: "$44k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 41, specialties: ["Mural", "Geometric", "Pattern"], startingPrice: "$900", portfolioImages: ["art_25", "art_08"]),
        Artist(name: "Renzo Ferrari", tagline: "Classical Fresco & Mural", bio: "Renaissance-inspired fresco and decorative mural painting.", location: "Milan, IT", bannerImage: "art_10", avatarImage: "art_26", works: 29, followers: "2.3k", sales: "$72k", verified: true, availableForCommissions: false, rating: 5.0, reviewCount: 18, specialties: ["Mural", "Fresco", "Classical"], startingPrice: "$1,500", portfolioImages: ["art_10", "art_26"]),
        Artist(name: "Kenji Nakamura", tagline: "Ink Mural & Japanese Motifs", bio: "Massive ink murals blending Japanese woodblock motifs with modern urban spaces.", location: "Tokyo, JP", bannerImage: "art_06", avatarImage: "art_24", works: 52, followers: "9.6k", sales: "$83k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 67, specialties: ["Mural", "Japanese", "Ink"], startingPrice: "$1,100", portfolioImages: ["art_06", "art_24"]),

        // ── Wallpapers ────────────────────────────────────────────────
        Artist(name: "Emma Wilson", tagline: "Botanical Wallpaper Design", bio: "Lush botanical patterns for premium home wallpaper and fabric print.", location: "London, UK", bannerImage: "art_05", avatarImage: "art_12", works: 94, followers: "6.3k", sales: "$38k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 72, specialties: ["Wallpaper", "Botanical", "Pattern"], startingPrice: "$180", portfolioImages: ["art_05", "art_12"]),
        Artist(name: "François Martin", tagline: "Art Deco Wallpaper & Print", bio: "Luxurious Art Deco wallpaper designs for high-end interiors.", location: "Paris, FR", bannerImage: "art_11", avatarImage: "art_20", works: 60, followers: "3.8k", sales: "$45k", verified: false, availableForCommissions: true, rating: 4.7, reviewCount: 44, specialties: ["Wallpaper", "Art Deco", "Print"], startingPrice: "$220", portfolioImages: ["art_11", "art_20"]),
        Artist(name: "Anya Sokolova", tagline: "Abstract Wallpaper & Textile", bio: "Bold abstract wallpaper collections for residential and hotel interiors.", location: "Prague, CZ", bannerImage: "art_03", avatarImage: "art_14", works: 78, followers: "4.5k", sales: "$33k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 58, specialties: ["Wallpaper", "Abstract", "Interior"], startingPrice: "$160", portfolioImages: ["art_03", "art_14"]),
        Artist(name: "Luis Mendez", tagline: "Illustrative Wallpaper Design", bio: "Storytelling through illustrated wallpaper — each panel a scene.", location: "Madrid, ES", bannerImage: "art_18", avatarImage: "art_07", works: 42, followers: "2.9k", sales: "$27k", verified: false, availableForCommissions: true, rating: 4.6, reviewCount: 31, specialties: ["Wallpaper", "Illustration", "Narrative"], startingPrice: "$200", portfolioImages: ["art_18", "art_07"]),
        Artist(name: "Hana Park", tagline: "Minimalist Wallpaper & Surface", bio: "Calm, sophisticated minimalist wallpaper for modern living.", location: "Seoul, KR", bannerImage: "art_21", avatarImage: "art_09", works: 55, followers: "5.1k", sales: "$41k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 49, specialties: ["Wallpaper", "Minimalist", "Surface Design"], startingPrice: "$140", portfolioImages: ["art_21", "art_09"]),

        // ── Wearable Art ──────────────────────────────────────────────
        Artist(name: "Celeste Moreau", tagline: "Hand-Painted Silk & Wearable", bio: "One-of-a-kind hand-painted silk scarves and garments.", location: "Paris, FR", bannerImage: "art_25", avatarImage: "art_16", works: 110, followers: "7.4k", sales: "$52k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 88, specialties: ["Wearable", "Silk", "Hand-Painted"], startingPrice: "$250", portfolioImages: ["art_25", "art_16"]),
        Artist(name: "Kai Nguyen", tagline: "Embroidered Wearable Art", bio: "Intricate hand-embroidered pieces fusing traditional and contemporary.", location: "Ho Chi Minh City, VN", bannerImage: "art_08", avatarImage: "art_23", works: 85, followers: "4.2k", sales: "$29k", verified: false, availableForCommissions: true, rating: 4.7, reviewCount: 61, specialties: ["Wearable", "Embroidery", "Textile"], startingPrice: "$190", portfolioImages: ["art_08", "art_23"]),
        Artist(name: "Bianca Costa", tagline: "Painted Denim & Streetwear Art", bio: "Custom painted denim and streetwear pieces for collectors.", location: "São Paulo, BR", bannerImage: "art_14", avatarImage: "art_04", works: 70, followers: "9.8k", sales: "$37k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 113, specialties: ["Wearable", "Denim", "Streetwear"], startingPrice: "$170", portfolioImages: ["art_14", "art_04"]),
        Artist(name: "Matteo Ricci", tagline: "Luxury Wearable Sculpture", bio: "Where fashion meets sculpture — wearable art pieces for runways and collectors.", location: "Rome, IT", bannerImage: "art_22", avatarImage: "art_10", works: 38, followers: "5.6k", sales: "$78k", verified: true, availableForCommissions: false, rating: 5.0, reviewCount: 27, specialties: ["Wearable", "Sculpture", "Luxury"], startingPrice: "$800", portfolioImages: ["art_22", "art_10"]),
        Artist(name: "Leila Ahmadi", tagline: "Batik & Wearable Textile Art", bio: "Modern batik wearable art rooted in Persian and Indonesian tradition.", location: "Tehran, IR", bannerImage: "art_17", avatarImage: "art_02", works: 95, followers: "3.7k", sales: "$24k", verified: false, availableForCommissions: true, rating: 4.6, reviewCount: 42, specialties: ["Wearable", "Batik", "Textile"], startingPrice: "$140", portfolioImages: ["art_17", "art_02"]),

        // ── Painting Services ─────────────────────────────────────────
        Artist(name: "Robert Walsh", tagline: "Oil Painting Commission", bio: "Classically trained oil painter available for portrait and landscape commissions.", location: "Dublin, IE", bannerImage: "art_12", avatarImage: "art_05", works: 76, followers: "2.8k", sales: "$48k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 54, specialties: ["Painting", "Oil", "Portraits"], startingPrice: "$450", portfolioImages: ["art_12", "art_05"]),
        Artist(name: "Ana Flores", tagline: "Acrylic & Mixed Media Painting", bio: "Vibrant acrylic paintings inspired by Latin American colour and culture.", location: "Bogotá, CO", bannerImage: "art_20", avatarImage: "art_15", works: 58, followers: "3.3k", sales: "$22k", verified: false, availableForCommissions: true, rating: 4.7, reviewCount: 37, specialties: ["Painting", "Acrylic", "Mixed Media"], startingPrice: "$300", portfolioImages: ["art_20", "art_15"]),
        Artist(name: "Viktor Novak", tagline: "Pastel & Gouache Painting", bio: "Soft, luminous pastel and gouache paintings for interiors and collectors.", location: "Vienna, AT", bannerImage: "art_07", avatarImage: "art_21", works: 102, followers: "1.9k", sales: "$31k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 69, specialties: ["Painting", "Pastel", "Gouache"], startingPrice: "$380", portfolioImages: ["art_07", "art_21"]),
        Artist(name: "Mei Lin", tagline: "Chinese Ink & Watercolour Painting", bio: "Traditional Chinese ink painting reimagined for contemporary collectors.", location: "Shanghai, CN", bannerImage: "art_04", avatarImage: "art_11", works: 140, followers: "6.7k", sales: "$57k", verified: true, availableForCommissions: true, rating: 5.0, reviewCount: 91, specialties: ["Painting", "Ink", "Watercolour"], startingPrice: "$280", portfolioImages: ["art_04", "art_11"]),
        Artist(name: "Callum Grant", tagline: "Plein Air & Landscape Painting", bio: "Painting nature on location — Scottish highlands to Mediterranean coasts.", location: "Edinburgh, UK", bannerImage: "art_26", avatarImage: "art_13", works: 88, followers: "2.4k", sales: "$36k", verified: false, availableForCommissions: true, rating: 4.8, reviewCount: 46, specialties: ["Painting", "Plein Air", "Landscape"], startingPrice: "$420", portfolioImages: ["art_26", "art_13"]),

        // ── Art Exhibitions ───────────────────────────────────────────
        Artist(name: "Claire Dupont", tagline: "Curator & Exhibition Artist", bio: "Immersive exhibition experiences blending installation and fine art.", location: "Brussels, BE", bannerImage: "art_03", avatarImage: "art_25", works: 22, followers: "4.1k", sales: "$110k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 19, specialties: ["Exhibition", "Installation", "Curation"], startingPrice: "$1,200", portfolioImages: ["art_03", "art_25"]),
        Artist(name: "Santiago Reyes", tagline: "Pop Art Exhibition & Events", bio: "High-energy pop art events and gallery shows across Latin America.", location: "Guadalajara, MX", bannerImage: "art_15", avatarImage: "art_06", works: 41, followers: "8.8k", sales: "$74k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 35, specialties: ["Exhibition", "Pop Art", "Events"], startingPrice: "$900", portfolioImages: ["art_15", "art_06"]),
        Artist(name: "Ingrid Hansen", tagline: "Textile & Fibre Exhibition Art", bio: "Large-scale fibre and textile installations for museum and gallery shows.", location: "Oslo, NO", bannerImage: "art_17", avatarImage: "art_08", works: 17, followers: "2.6k", sales: "$88k", verified: false, availableForCommissions: false, rating: 5.0, reviewCount: 12, specialties: ["Exhibition", "Textile", "Installation"], startingPrice: "$2,000", portfolioImages: ["art_17", "art_08"]),
        Artist(name: "Tariq Mansour", tagline: "Photography Exhibition Artist", bio: "Cinematic large-format photography for gallery and commercial exhibition.", location: "Cairo, EG", bannerImage: "art_23", avatarImage: "art_14", works: 55, followers: "5.3k", sales: "$62k", verified: true, availableForCommissions: true, rating: 4.7, reviewCount: 44, specialties: ["Exhibition", "Photography", "Large Format"], startingPrice: "$800", portfolioImages: ["art_23", "art_14"]),
        Artist(name: "Yuki Ishida", tagline: "Performance & Exhibition Art", bio: "Interdisciplinary performance and visual art exhibitions exploring identity.", location: "Kyoto, JP", bannerImage: "art_09", avatarImage: "art_19", works: 28, followers: "3.9k", sales: "$55k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 23, specialties: ["Exhibition", "Performance", "Interdisciplinary"], startingPrice: "$1,000", portfolioImages: ["art_09", "art_19"]),

        // ── Art Workshops ─────────────────────────────────────────────
        Artist(name: "Grace Murphy", tagline: "Watercolour Workshop Instructor", bio: "Beginner-friendly watercolour workshops in a welcoming Boston studio.", location: "Boston, US", bannerImage: "art_05", avatarImage: "art_21", works: 0, followers: "2.1k", sales: "$18k", verified: false, availableForCommissions: true, rating: 4.9, reviewCount: 112, specialties: ["Workshop", "Watercolour", "Teaching"], startingPrice: "$65", portfolioImages: ["art_05", "art_21"]),
        Artist(name: "Dani Hertz", tagline: "Abstract Painting Workshop", bio: "Expressive abstract painting workshops for all skill levels.", location: "Tel Aviv, IL", bannerImage: "art_18", avatarImage: "art_03", works: 0, followers: "1.8k", sales: "$14k", verified: true, availableForCommissions: true, rating: 4.7, reviewCount: 78, specialties: ["Workshop", "Abstract", "Painting"], startingPrice: "$55", portfolioImages: ["art_18", "art_03"]),
        Artist(name: "Marco Esposito", tagline: "Life Drawing & Anatomy Workshop", bio: "Traditional life drawing and anatomy classes in a Florence atelier.", location: "Florence, IT", bannerImage: "art_10", avatarImage: "art_16", works: 0, followers: "3.5k", sales: "$25k", verified: true, availableForCommissions: true, rating: 5.0, reviewCount: 94, specialties: ["Workshop", "Life Drawing", "Anatomy"], startingPrice: "$80", portfolioImages: ["art_10", "art_16"]),
        Artist(name: "Fatou Diallo", tagline: "Textile & Print Workshop", bio: "Hands-on textile printing and natural dyeing workshops.", location: "Dakar, SN", bannerImage: "art_24", avatarImage: "art_07", works: 0, followers: "1.4k", sales: "$9k", verified: false, availableForCommissions: true, rating: 4.8, reviewCount: 53, specialties: ["Workshop", "Textile", "Printmaking"], startingPrice: "$50", portfolioImages: ["art_24", "art_07"]),
        Artist(name: "Lily Zhang", tagline: "Calligraphy & Ink Workshop", bio: "Chinese calligraphy and ink wash painting for beginners and intermediates.", location: "Beijing, CN", bannerImage: "art_11", avatarImage: "art_20", works: 0, followers: "4.7k", sales: "$21k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 136, specialties: ["Workshop", "Calligraphy", "Ink"], startingPrice: "$70", portfolioImages: ["art_11", "art_20"]),

        // ── Sculpture ─────────────────────────────────────────────────
        Artist(name: "Mira Solano", tagline: "Street Sculpture & Tagged Classics", bio: "Classical plaster recast as street sculpture — graffiti, colour, and a bust that already lived a life.", location: "Barcelona, ES", bannerImage: "tagged_david", avatarImage: "story_avatar_outline", works: 16, followers: "6.8k", sales: "$44k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 28, specialties: ["Sculpture", "Street Art", "Plaster"], startingPrice: "$1,400", portfolioImages: ["tagged_david", "sculpture_studio_01"]),
        Artist(name: "Alex Rivera", tagline: "Found-Object Pop Sculpture", bio: "Supermarket packaging as marble. Pop sculptures assembled from the aisle.", location: "Mexico City, MX", bannerImage: "tide_venus", avatarImage: "tide_venus", works: 23, followers: "5.1k", sales: "$51k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 36, specialties: ["Sculpture", "Found Object", "Pop"], startingPrice: "$1,800", portfolioImages: ["tide_venus", "sculpture_studio_02"]),
        Artist(name: "Kofi Mensah", tagline: "Carved Mask & Wood Sculpture", bio: "Small carved faces in pigment and gold-worn wood. Sculpture you hold.", location: "Accra, GH", bannerImage: "lapis_mask", avatarImage: "story_avatar_lovecap", works: 41, followers: "2.2k", sales: "$29k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 47, specialties: ["Sculpture", "Wood", "Carving"], startingPrice: "$620", portfolioImages: ["lapis_mask", "sculpture_studio_03"]),
        Artist(name: "Theo Lang", tagline: "Terracotta Mask Sculpture", bio: "Hollow heads in fired clay. Sculpture reduced to brow, nose and mouth.", location: "Lisbon, PT", bannerImage: "terracotta_mask", avatarImage: "terracotta_mask", works: 19, followers: "1.2k", sales: "$18k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 16, specialties: ["Sculpture", "Clay", "Mask"], startingPrice: "$540", portfolioImages: ["terracotta_mask"]),
        Artist(name: "Amina Diallo", tagline: "Carved Wood Mask Sculpture", bio: "Wall masks with radiating crowns. Sculpture you hang, not stand.", location: "Dakar, SN", bannerImage: "sunburst_mask", avatarImage: "sunburst_mask", works: 27, followers: "2.0k", sales: "$24k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 22, specialties: ["Sculpture", "Wood", "Carving"], startingPrice: "$720", portfolioImages: ["sunburst_mask"]),
        Artist(name: "Haruto Saito", tagline: "Fiber & Wood Sculpture", bio: "Carved faces with fiber beards. Sculpture that hangs in the air.", location: "Kyoto, JP", bannerImage: "fiber_beard_mask", avatarImage: "fiber_beard_mask", works: 21, followers: "1.6k", sales: "$26k", verified: true, availableForCommissions: false, rating: 4.8, reviewCount: 14, specialties: ["Sculpture", "Wood", "Fiber"], startingPrice: "$800", portfolioImages: ["fiber_beard_mask"]),
        Artist(name: "Nia Okonkwo", tagline: "Ceremonial Mask Sculpture", bio: "Cowries, bells and carved wood. Sculpture that still sounds.", location: "Lagos, NG", bannerImage: "cowrie_bell_mask", avatarImage: "cowrie_bell_mask", works: 15, followers: "3.2k", sales: "$33k", verified: true, availableForCommissions: true, rating: 5.0, reviewCount: 18, specialties: ["Sculpture", "Wood", "Mixed Media"], startingPrice: "$980", portfolioImages: ["cowrie_bell_mask"]),
        Artist(name: "Anton Müller", tagline: "Bronze & Cast Sculpture", bio: "Monumental bronze castings for public spaces and private collections.", location: "Munich, DE", bannerImage: "tagged_david", avatarImage: "lapis_mask", works: 34, followers: "1.8k", sales: "$140k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 21, specialties: ["Sculpture", "Bronze", "Casting"], startingPrice: "$3,000", portfolioImages: ["tagged_david", "lapis_mask"]),
        Artist(name: "Chiara Romano", tagline: "Marble & Stone Sculpture", bio: "Hand-carved marble sculpture rooted in the Italian classical tradition.", location: "Naples, IT", bannerImage: "tide_venus", avatarImage: "tagged_david", works: 22, followers: "1.3k", sales: "$95k", verified: true, availableForCommissions: false, rating: 5.0, reviewCount: 14, specialties: ["Sculpture", "Marble", "Stone"], startingPrice: "$4,500", portfolioImages: ["tide_venus", "tagged_david"]),
        Artist(name: "Kwame Asante", tagline: "Wood & Mixed Media Sculpture", bio: "Reclaimed wood sculptures celebrating African heritage and contemporary identity.", location: "Kumasi, GH", bannerImage: "lapis_mask", avatarImage: "tide_venus", works: 48, followers: "2.7k", sales: "$38k", verified: false, availableForCommissions: true, rating: 4.8, reviewCount: 31, specialties: ["Sculpture", "Wood", "Mixed Media"], startingPrice: "$1,200", portfolioImages: ["lapis_mask", "tide_venus"]),
        Artist(name: "Elena Voronova", tagline: "Glass & Metal Sculpture", bio: "Delicate glass and oxidised metal sculptures exploring tension and light.", location: "St. Petersburg, RU", bannerImage: "tagged_david", avatarImage: "tide_venus", works: 37, followers: "2.1k", sales: "$62k", verified: true, availableForCommissions: true, rating: 4.7, reviewCount: 19, specialties: ["Sculpture", "Glass", "Metal"], startingPrice: "$1,800", portfolioImages: ["tagged_david", "sculpture_studio_02"]),
        Artist(name: "Felipe Ochoa", tagline: "Clay & Ceramic Sculpture", bio: "Narrative ceramic sculptures fired in a Colombian mountain studio.", location: "Bogotá, CO", bannerImage: "tide_venus", avatarImage: "lapis_mask", works: 61, followers: "3.4k", sales: "$29k", verified: false, availableForCommissions: true, rating: 4.9, reviewCount: 44, specialties: ["Sculpture", "Clay", "Ceramics"], startingPrice: "$600", portfolioImages: ["tide_venus", "sculpture_studio_03"]),

        // ── Ceramics & Pottery ────────────────────────────────────────
        Artist(name: "Yuki Mori", tagline: "Japanese Raku & Tea Ceremony Ware", bio: "Raku-fired vessels and tea bowls in the wabi-sabi tradition.", location: "Kyoto, JP", bannerImage: "art_17", avatarImage: "art_08", works: 230, followers: "5.2k", sales: "$44k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 87, specialties: ["Ceramics", "Raku", "Japanese"], startingPrice: "$120", portfolioImages: ["art_17", "art_08"]),
        Artist(name: "Astrid Lindqvist", tagline: "Scandinavian Stoneware & Glaze", bio: "Minimal Scandinavian stoneware with experimental glaze surfaces.", location: "Gothenburg, SE", bannerImage: "art_21", avatarImage: "art_25", works: 175, followers: "3.9k", sales: "$31k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 63, specialties: ["Ceramics", "Stoneware", "Glaze"], startingPrice: "$90", portfolioImages: ["art_21", "art_25"]),
        Artist(name: "Rania El-Masri", tagline: "Mosaic & Decorative Ceramics", bio: "Hand-painted decorative ceramics blending Levantine and contemporary motifs.", location: "Beirut, LB", bannerImage: "art_04", avatarImage: "art_19", works: 310, followers: "4.6k", sales: "$27k", verified: false, availableForCommissions: true, rating: 4.7, reviewCount: 99, specialties: ["Ceramics", "Mosaic", "Decorative"], startingPrice: "$75", portfolioImages: ["art_04", "art_19"]),
        Artist(name: "João Santos", tagline: "Terracotta & Earthenware Pottery", bio: "Handmade terracotta pottery inspired by the Alentejo landscape.", location: "Lisbon, PT", bannerImage: "art_16", avatarImage: "art_06", works: 195, followers: "2.7k", sales: "$19k", verified: false, availableForCommissions: true, rating: 4.6, reviewCount: 55, specialties: ["Ceramics", "Terracotta", "Earthenware"], startingPrice: "$65", portfolioImages: ["art_16", "art_06"]),
        Artist(name: "Sera Kaya", tagline: "Iznik-Inspired Ceramic Art", bio: "Modern reinterpretations of classic Iznik tile and vessel traditions.", location: "Istanbul, TR", bannerImage: "art_23", avatarImage: "art_12", works: 142, followers: "5.8k", sales: "$38k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 76, specialties: ["Ceramics", "Iznik", "Tiles"], startingPrice: "$110", portfolioImages: ["art_23", "art_12"]),

        // ── Kids Workshops ────────────────────────────────────────────
        Artist(name: "Penny Brooks", tagline: "Kids Painting & Creative Play", bio: "Fun, mess-friendly painting workshops for ages 4–12. Every child is an artist.", location: "Sydney, AU", bannerImage: "art_02", avatarImage: "art_05", works: 0, followers: "3.1k", sales: "$22k", verified: true, availableForCommissions: true, rating: 4.9, reviewCount: 148, specialties: ["Kids", "Painting", "Creative Play"], startingPrice: "$45", portfolioImages: ["art_02", "art_05"]),
        Artist(name: "Tom Eriksson", tagline: "Kids Sculpture & Clay Play", bio: "Clay sculpture workshops for children — take-home kiln-fired creations.", location: "Helsinki, FI", bannerImage: "art_08", avatarImage: "art_17", works: 0, followers: "1.7k", sales: "$14k", verified: false, availableForCommissions: true, rating: 4.8, reviewCount: 92, specialties: ["Kids", "Sculpture", "Clay"], startingPrice: "$55", portfolioImages: ["art_08", "art_17"]),
        Artist(name: "Zoe Fontaine", tagline: "Kids Art & Storytelling", bio: "Illustrated storytelling workshops combining drawing and creative writing.", location: "Montreal, CA", bannerImage: "art_13", avatarImage: "art_20", works: 0, followers: "2.4k", sales: "$17k", verified: true, availableForCommissions: true, rating: 4.7, reviewCount: 83, specialties: ["Kids", "Illustration", "Storytelling"], startingPrice: "$50", portfolioImages: ["art_13", "art_20"]),
        Artist(name: "David Park", tagline: "Kids Digital Art & Animation", bio: "Intro to digital art and animation for curious kids aged 8–14.", location: "Vancouver, CA", bannerImage: "art_01", avatarImage: "art_14", works: 0, followers: "2.9k", sales: "$19k", verified: false, availableForCommissions: true, rating: 4.8, reviewCount: 67, specialties: ["Kids", "Digital", "Animation"], startingPrice: "$60", portfolioImages: ["art_01", "art_14"]),
        Artist(name: "Iris Nakamura", tagline: "Kids Watercolour & Nature Art", bio: "Nature-inspired watercolour workshops exploring the world around us.", location: "Honolulu, US", bannerImage: "art_07", avatarImage: "art_03", works: 0, followers: "1.5k", sales: "$11k", verified: true, availableForCommissions: true, rating: 5.0, reviewCount: 104, specialties: ["Kids", "Watercolour", "Nature"], startingPrice: "$48", portfolioImages: ["art_07", "art_03"]),

        // ── Art Restoration ───────────────────────────────────────────
        Artist(name: "Sophia Bianchi", tagline: "Painting Restoration & Conservation", bio: "Certified conservator specialising in oil and tempera painting restoration.", location: "Florence, IT", bannerImage: "art_12", avatarImage: "art_22", works: 203, followers: "1.4k", sales: "$195k", verified: true, availableForCommissions: true, rating: 5.0, reviewCount: 31, specialties: ["Restoration", "Oil Painting", "Conservation"], startingPrice: "$700", portfolioImages: ["art_12", "art_22"]),
        Artist(name: "Pierre Renard", tagline: "Frame & Gilding Restoration", bio: "Expert gilding and frame restoration for museums and private collectors.", location: "Lyon, FR", bannerImage: "art_16", avatarImage: "art_04", works: 154, followers: "0.8k", sales: "$88k", verified: true, availableForCommissions: false, rating: 4.9, reviewCount: 18, specialties: ["Restoration", "Gilding", "Frames"], startingPrice: "$500", portfolioImages: ["art_16", "art_04"]),
        Artist(name: "Marta Kowalski", tagline: "Paper & Prints Restoration", bio: "Archival restoration of works on paper, maps, and historical documents.", location: "Warsaw, PL", bannerImage: "art_11", avatarImage: "art_25", works: 312, followers: "0.9k", sales: "$67k", verified: true, availableForCommissions: true, rating: 4.8, reviewCount: 24, specialties: ["Restoration", "Paper", "Archival"], startingPrice: "$350", portfolioImages: ["art_11", "art_25"]),
        Artist(name: "James McAllister", tagline: "Mural & Wall Painting Restoration", bio: "In-situ mural restoration for churches, estates, and heritage buildings.", location: "Edinburgh, UK", bannerImage: "art_10", avatarImage: "art_26", works: 88, followers: "1.1k", sales: "$142k", verified: true, availableForCommissions: true, rating: 5.0, reviewCount: 15, specialties: ["Restoration", "Mural", "Heritage"], startingPrice: "$1,200", portfolioImages: ["art_10", "art_26"]),
        Artist(name: "Nikos Papadopoulos", tagline: "Ancient Art & Icon Restoration", bio: "Byzantine icon and ancient artifact restoration with museum-grade materials.", location: "Athens, GR", bannerImage: "art_23", avatarImage: "art_09", works: 175, followers: "1.3k", sales: "$220k", verified: true, availableForCommissions: false, rating: 5.0, reviewCount: 22, specialties: ["Restoration", "Icons", "Ancient Art"], startingPrice: "$900", portfolioImages: ["art_23", "art_09"]),
    ]
}


// MARK: - DiscoverView — GOAT Styles (full-screen scrollable cards)

struct DiscoverView: View {
    @State private var path = NavigationPath()

    private let categories = ServiceCategory.allCases

    private let categoryImage: [ServiceCategory: String] = Dictionary(
        uniqueKeysWithValues: ServiceCategory.allCases.map { ($0, $0.heroImageName) }
    )

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    ForEach(categories) { cat in
                        GoatFullCard(
                            category: cat,
                            imageName: categoryImage[cat] ?? "art_01"
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .onTapGesture { path.append(cat) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
            .background(Color.picardoBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: ServiceCategory.self) { category in
                CategoryServicesView(category: category)
            }
            .navigationDestination(for: ServiceArtistList.self) { list in
                ServiceArtistListView(title: list.title, artists: list.artists)
            }
            .navigationDestination(for: Artist.self) { artist in
                ArtistStoreView(artist: artist)
            }
        }
        .environment(\.heroVideoEnabled, path.count < 2)
        .onAppear { HeroVideoControl.setEnabled(path.count < 2) }
        .onChange(of: path.count) { _, count in
            HeroVideoControl.setEnabled(count < 2)
        }
    }
}

// MARK: - GOAT Full Card

struct GoatFullCard: View {
    let category: ServiceCategory
    let imageName: String

    private var mediaShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
    }

    /// Native photo ratio so the picture is not cropped to a tall screen slot.
    private var photoAspect: CGFloat {
        guard let image = UIImage(named: imageName), image.size.height > 0 else {
            return 3.0 / 4.0
        }
        return image.size.width / image.size.height
    }

    var body: some View {
        Color.black
            .aspectRatio(photoAspect, contentMode: .fit)
            .overlay {
                ArtworkImage(imageName: imageName, contentMode: .fit, maxDimension: 1400)
            }
            .overlay {
                VStack(spacing: 0) {
                    VStack(spacing: 3) {
                        Text("Explore")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(category.rawValue)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .picardoGlass(in: Capsule(), interactive: true)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
            }
            .picardoGlassMedia(in: mediaShape)
    }
}


// MARK: - Booking Request View

struct BookingRequestView: View {
    let service: Service
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var details = ""
    @State private var budget = ""
    @State private var timeline = "Flexible"

    let timelines = ["ASAP", "1–2 weeks", "1 month", "Flexible"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Details") {
                    TextField("Full name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                Section("Project") {
                    TextField("Describe what you're looking for…", text: $details, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                    TextField("Budget (USD)", text: $budget)
                        .keyboardType(.numberPad)
                    Picker("Timeline", selection: $timeline) {
                        ForEach(timelines, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section {
                    Button("Send Booking Request") { dismiss() }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Color.picardoNeonRed)
                        .fontWeight(.bold)
                }
            }
            .navigationTitle("Book \(service.providerName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview { DiscoverView() }
