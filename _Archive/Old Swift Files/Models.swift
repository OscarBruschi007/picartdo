import SwiftUI

// MARK: - Artwork

struct Artwork: Identifiable, Hashable {
    let id: Int
    let title: String
    let price: Int
    let category: String
    var likes: Int
    let sold: Bool
    let medium: String
    let dimensions: String
    let description: String
    let imageExtension: String   // "jpeg" or "jpg"

    var imageName: String {
        let pad = id < 10 ? "0\(id)" : "\(id)"
        return "art_\(pad)"
    }

    var priceFormatted: String {
        "$\(price.formatted())"
    }
}

// MARK: - Artist

struct Artist: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let tagline: String
    let bio: String
    let works: Int
    let followers: String
    let sales: String
    let bannerImage: String   // asset name
    let avatarImage: String   // asset name
    let verified: Bool
}

// MARK: - Service Category

struct ServiceCategory: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let name: String
    let description: String
    let count: String
    let image: String          // asset name
}

// MARK: - Service Provider

struct ServiceProvider: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: String
    let rating: Double
    let reviews: Int
    let description: String
    let startingFrom: Int
    let portfolioImage: String  // asset name
    let avatarImage: String     // asset name
    let service: String

    var starsFormatted: String {
        String(format: "%.1f", rating)
    }

    var priceFormatted: String {
        "From $\(startingFrom)"
    }
}

// MARK: - Sample Data

extension Artwork {
    static let all: [Artwork] = [
        Artwork(id:1,  title:"Hearts & Circles",   price:680,  category:"Painting",    likes:142, sold:false, medium:"Acrylic on canvas",     dimensions:"12×12 in", description:"A circular mandala bursting with pink hearts and blue forms — playful yet deeply intricate.", imageExtension:"jpeg"),
        Artwork(id:2,  title:"Solar System",        price:720,  category:"Painting",    likes:98,  sold:false, medium:"Acrylic on canvas",     dimensions:"12×12 in", description:"Black orbiting forms trace celestial paths across a field of yellow dots and lines.", imageExtension:"jpeg"),
        Artwork(id:3,  title:"Fire Cycle",          price:750,  category:"Painting",    likes:115, sold:false, medium:"Acrylic on canvas",     dimensions:"12×12 in", description:"A warm circular composition in red, orange, and yellow — energy spiraling inward.", imageExtension:"jpeg"),
        Artwork(id:4,  title:"Silver Void",         price:620,  category:"Drawing",     likes:77,  sold:false, medium:"Ink on canvas",         dimensions:"12×12 in", description:"Monochromatic tension — silver ink tracing dual forms against deep black.", imageExtension:"jpeg"),
        Artwork(id:5,  title:"Spectrum",            price:800,  category:"Painting",    likes:203, sold:false, medium:"Acrylic on canvas",     dimensions:"12×12 in", description:"A mandala celebrating every color — gold threads, a pink heart, and a rainbow arc.", imageExtension:"jpeg"),
        Artwork(id:6,  title:"Crimson Eye",         price:690,  category:"Painting",    likes:88,  sold:false, medium:"Acrylic on canvas",     dimensions:"12×12 in", description:"Red and silver watch forms emerge from a dark field, bold and unsettling.", imageExtension:"jpeg"),
        Artwork(id:7,  title:"Golden Gate",         price:950,  category:"Painting",    likes:167, sold:false, medium:"Acrylic & metallic ink", dimensions:"12×12 in", description:"Gold metallic ink flows through organic shapes — luxurious and totemic.", imageExtension:"jpeg"),
        Artwork(id:8,  title:"Red Ritual",          price:710,  category:"Painting",    likes:91,  sold:false, medium:"Acrylic on canvas",     dimensions:"12×12 in", description:"Dark ceremonial forms arranged in a dense circular composition of red and black.", imageExtension:"jpeg"),
        Artwork(id:9,  title:"Labyrinth",           price:1400, category:"Drawing",     likes:256, sold:false, medium:"Pen & ink on paper",    dimensions:"24×18 in", description:"A monumental pen & ink drawing — panels within panels, creatures and symbols woven together.", imageExtension:"jpeg"),
        Artwork(id:10, title:"Fluid Forms",         price:890,  category:"Drawing",     likes:134, sold:false, medium:"Pen & ink on paper",    dimensions:"18×14 in", description:"Loose black ink creatures drift across the page — lyrical and dreamlike.", imageExtension:"jpeg"),
        Artwork(id:11, title:"Eyes & Waves",        price:960,  category:"Drawing",     likes:178, sold:false, medium:"Pen & ink on paper",    dimensions:"18×14 in", description:"Dense ink work layering eye motifs, organic patterns, and dotted fields.", imageExtension:"jpeg"),
        Artwork(id:12, title:"Neon Portrait",       price:1200, category:"Painting",    likes:312, sold:false, medium:"Acrylic on paper",      dimensions:"20×28 in", description:"An expressive figure painted in vivid magenta — raw energy meets anatomical precision.", imageExtension:"jpeg"),
        Artwork(id:13, title:"Oval Universe",       price:780,  category:"Mixed Media", likes:145, sold:false, medium:"Marker & ink on paper", dimensions:"20×10 in", description:"A red and orange oval frame contains a world of eyes, creatures, and tangled forms.", imageExtension:"jpeg"),
        Artwork(id:14, title:"Blue Frequency",      price:870,  category:"Drawing",     likes:119, sold:false, medium:"Pen & ink on paper",    dimensions:"18×14 in", description:"Red, blue, and teal ink swirl around figurative shapes in an intense chromatic composition.", imageExtension:"jpeg"),
        Artwork(id:15, title:"Long Canvas",         price:2400, category:"Painting",    likes:389, sold:false, medium:"Acrylic on canvas",     dimensions:"48×16 in", description:"A wide-format canvas with sweeping blue arcs, faces, and intricate patterning across its full length.", imageExtension:"jpeg"),
        Artwork(id:16, title:"Blue Mandala",        price:700,  category:"Painting",    likes:162, sold:false, medium:"Acrylic on canvas",     dimensions:"12×12 in", description:"A serene blue circular work — rhythmic dotwork and fish-like forms circle a calm center.", imageExtension:"jpeg"),
        Artwork(id:17, title:"Green Spiral",        price:680,  category:"Painting",    likes:108, sold:false, medium:"Acrylic on canvas",     dimensions:"12×12 in", description:"Emerald green and black ink interlock in a yin-yang-like mandala of organic balance.", imageExtension:"jpeg"),
        Artwork(id:18, title:"Red & Yellow",        price:730,  category:"Painting",    likes:131, sold:false, medium:"Acrylic on canvas",     dimensions:"12×12 in", description:"Warm sun tones fill a complex circular composition — yellow sunflower rings meet red energy.", imageExtension:"jpeg"),
        Artwork(id:19, title:"Chromatic Figures",   price:1100, category:"Painting",    likes:220, sold:false, medium:"Acrylic on canvas",     dimensions:"16×20 in", description:"Bold silhouettes in vivid primary colors dance across a charged black field.", imageExtension:"jpg"),
        Artwork(id:20, title:"Tangled Minds",       price:1350, category:"Mixed Media", likes:185, sold:false, medium:"Mixed media on paper",  dimensions:"18×24 in", description:"Interlocking faces and abstract thought-forms rendered in dense ink and wax.", imageExtension:"jpg"),
        Artwork(id:21, title:"Violet Bloom",        price:980,  category:"Painting",    likes:149, sold:false, medium:"Acrylic on canvas",     dimensions:"20×20 in", description:"Soft violet masses bloom outward from a luminous center — meditative and expansive.", imageExtension:"jpg"),
        Artwork(id:22, title:"Ink Portraits",       price:640,  category:"Drawing",     likes:97,  sold:false, medium:"Pen & ink on paper",    dimensions:"12×16 in", description:"A series of expressive portrait sketches captured in rapid, confident ink strokes.", imageExtension:"jpg"),
        Artwork(id:23, title:"Alchemy",             price:1800, category:"Mixed Media", likes:271, sold:false, medium:"Mixed media on canvas", dimensions:"24×24 in", description:"Gold and rust tones layer over textured ground — a study in material transformation.", imageExtension:"jpg"),
        Artwork(id:24, title:"Solar Glyph",         price:760,  category:"Painting",    likes:138, sold:false, medium:"Acrylic on canvas",     dimensions:"12×12 in", description:"Ancient symbols circle a blazing golden center — myth encoded in paint.", imageExtension:"jpg"),
        Artwork(id:25, title:"Coral Dream",         price:850,  category:"Painting",    likes:192, sold:false, medium:"Acrylic on canvas",     dimensions:"16×16 in", description:"Underwater organic forms — coral-pink shapes drift through a pale aqueous field.", imageExtension:"jpg"),
        Artwork(id:26, title:"Night Grid",          price:920,  category:"Drawing",     likes:163, sold:false, medium:"Pen & ink on paper",    dimensions:"18×18 in", description:"A precise geometric grid dissolves into loose mark-making at the edges — order vs chaos.", imageExtension:"jpg"),
    ]

    static var featured: Artwork {
        all.max(by: { $0.likes < $1.likes })!
    }

    static var trending: [Artwork] {
        all.sorted { $0.likes > $1.likes }.prefix(10).map { $0 }
    }

    static var justDropped: [Artwork] {
        Array(all.prefix(8))
    }
}

extension Artist {
    static let all: [Artist] = [
        Artist(name:"Oscar Bruschi",   tagline:"Painter · Mixed Media",    bio:"Founder of Picardo. Painter of worlds — circular, luminous, and alive.",           works:26, followers:"1.4k", sales:"$28k", bannerImage:"art_15", avatarImage:"avatar_01", verified:true),
        Artist(name:"Maya Chen",       tagline:"Tattoo Artist",            bio:"Fine-line botanical and portrait tattoos. Based in NYC, booking worldwide.",         works:48, followers:"8.2k", sales:"$42k", bannerImage:"art_11", avatarImage:"avatar_02", verified:true),
        Artist(name:"Luis Fernandez",  tagline:"Muralist",                 bio:"Walls are my canvas. From Barcelona to Brooklyn, color follows me.",                 works:19, followers:"3.1k", sales:"$65k", bannerImage:"art_15", avatarImage:"avatar_03", verified:true),
        Artist(name:"Sofia Reyes",     tagline:"Portrait Artist",          bio:"Every face tells a story. I help you keep it forever.",                              works:34, followers:"5.6k", sales:"$31k", bannerImage:"art_12", avatarImage:"avatar_04", verified:false),
        Artist(name:"James Park",      tagline:"Digital Illustrator",      bio:"Characters, worlds, NFTs. The digital frontier is my studio.",                       works:67, followers:"12k",  sales:"$18k", bannerImage:"art_20", avatarImage:"avatar_05", verified:true),
        Artist(name:"Amira Hassan",    tagline:"Ceramics & Sculpture",     bio:"Earth, water, fire — the oldest technology is still the most beautiful.",            works:22, followers:"2.4k", sales:"$14k", bannerImage:"art_16", avatarImage:"avatar_06", verified:false),
        Artist(name:"Eli Moreau",      tagline:"Event Painter",            bio:"I paint your moments. Live at weddings, galas and private events.",                  works:15, followers:"1.8k", sales:"$55k", bannerImage:"art_19", avatarImage:"avatar_07", verified:true),
        Artist(name:"Nadia Okafor",    tagline:"Art Therapist",            bio:"Healing through creativity. Your mind and your hands know more than you think.",     works:30, followers:"4.7k", sales:"$22k", bannerImage:"art_21", avatarImage:"avatar_08", verified:true),
    ]
}

extension ServiceCategory {
    static let all: [ServiceCategory] = [
        ServiceCategory(icon:"🎨", name:"Painting Classes",        description:"In-person & online workshops",           count:"12 artists", image:"art_05"),
        ServiceCategory(icon:"💉", name:"Tattoo Artists",          description:"Custom flash & commission booking",      count:"8 artists",  image:"art_11"),
        ServiceCategory(icon:"🏠", name:"Mural & Wall Painting",   description:"Indoor & outdoor large-scale work",      count:"6 artists",  image:"art_15"),
        ServiceCategory(icon:"🖼️", name:"Custom Portraits",        description:"Commission your likeness",               count:"15 artists", image:"art_12"),
        ServiceCategory(icon:"🎉", name:"Event Live Painting",     description:"Weddings, parties & corporate",          count:"5 artists",  image:"art_19"),
        ServiceCategory(icon:"🖥️", name:"Digital Art & NFTs",      description:"Illustration, animation & minting",     count:"10 artists", image:"art_20"),
        ServiceCategory(icon:"📸", name:"Photography",             description:"Fine art & portrait sessions",           count:"9 artists",  image:"art_23"),
        ServiceCategory(icon:"🏺", name:"Ceramics & Pottery",      description:"Classes and custom commissions",         count:"4 artists",  image:"art_16"),
    ]
}

extension ServiceProvider {
    static let all: [ServiceProvider] = [
        ServiceProvider(name:"Oscar Bruschi",  type:"Painter · Mixed Media",  rating:4.9, reviews:128, description:"Multi-disciplinary artist offering custom paintings, live event art, and private classes.", startingFrom:350, portfolioImage:"art_07", avatarImage:"profile", service:"Painting Classes"),
        ServiceProvider(name:"Maya Chen",      type:"Tattoo Artist",          rating:4.8, reviews:94,  description:"Fine-line and neo-traditional tattoos. Specialising in botanical and portrait work.",       startingFrom:200, portfolioImage:"art_11", avatarImage:"art_04",  service:"Tattoo Artists"),
        ServiceProvider(name:"Luis Fernandez", type:"Muralist",               rating:4.9, reviews:67,  description:"Large-scale indoor and outdoor murals. Commercial and residential commissions welcome.",    startingFrom:800, portfolioImage:"art_15", avatarImage:"art_16",  service:"Mural & Wall Painting"),
        ServiceProvider(name:"Sofia Reyes",    type:"Portrait Artist",        rating:4.7, reviews:203, description:"Oil and acrylic portraits of people, pets and places. 2–4 week turnaround.",               startingFrom:450, portfolioImage:"art_12", avatarImage:"art_01",  service:"Custom Portraits"),
    ]
}

// MARK: - App Colors

extension Color {
    static let picardoGold = Color(red: 198/255, green: 154/255, blue: 31/255)
    static let picardoGoldDim = Color(red: 198/255, green: 154/255, blue: 31/255).opacity(0.12)
}
