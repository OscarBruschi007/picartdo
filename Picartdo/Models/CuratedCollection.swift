import Foundation

/// Curated exhibition — not a marketplace category.
struct CuratedCollection: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let yearLabel: String
    let coverImageName: String
    let artworkImageNames: [String]
    let essay: String

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        yearLabel: String = "2026",
        coverImageName: String,
        artworkImageNames: [String],
        essay: String
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.yearLabel = yearLabel
        self.coverImageName = coverImageName
        self.artworkImageNames = artworkImageNames
        self.essay = essay
    }

    var artworks: [Artwork] {
        artworkImageNames.compactMap { name in
            Artwork.samples.first { $0.imageName == name }
        }
    }
}

extension CuratedCollection {
    static let all: [CuratedCollection] = [
        CuratedCollection(
            title: "Future Geometry",
            subtitle: "Precision, rhythm, and constructed form",
            coverImageName: "art_26",
            artworkImageNames: ["art_26", "art_02", "art_16", "art_09"],
            essay: "A study in structure — grids dissolve into gesture, orbits become icons, and geometry becomes living space."
        ),
        CuratedCollection(
            title: "Black & White",
            subtitle: "Contrast as composition",
            coverImageName: "art_04",
            artworkImageNames: ["art_04", "art_09", "art_10", "art_11"],
            essay: "Monochrome as theatre. Ink, void, and silver tension — work that speaks without chroma."
        ),
        CuratedCollection(
            title: "Abstract Movement",
            subtitle: "Energy held in paint",
            coverImageName: "art_12",
            artworkImageNames: ["art_12", "art_19", "art_14", "art_03"],
            essay: "Figures and fields in motion — chroma as velocity, gesture as narrative."
        ),
        CuratedCollection(
            title: "Organic Forms",
            subtitle: "Nature rewritten",
            coverImageName: "art_25",
            artworkImageNames: ["art_25", "art_17", "art_21", "art_01"],
            essay: "Coral, bloom, spiral — biomorphic worlds that feel discovered rather than drawn."
        ),
        CuratedCollection(
            title: "Minimal Space",
            subtitle: "Quiet architecture of the canvas",
            coverImageName: "art_16",
            artworkImageNames: ["art_16", "art_04", "art_21", "art_26"],
            essay: "Breathing room as material. Sparse mark-making, measured silence, museum spacing."
        ),
        CuratedCollection(
            title: "Digital Canvas",
            subtitle: "Screen-born originals",
            coverImageName: "art_19",
            artworkImageNames: ["art_19", "art_12", "art_05", "art_14"],
            essay: "Contemporary signals rendered with the gravity of oil — luminous, immediate, collectible."
        ),
        CuratedCollection(
            title: "Collectors’ Picks",
            subtitle: "Works held in private regard",
            coverImageName: "art_27",
            artworkImageNames: ["art_27", "art_22", "art_15", "art_07"],
            essay: "A shortlist shaped by desire — pieces that collectors return to, quietly and repeatedly."
        ),
    ]
}
