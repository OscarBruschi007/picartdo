import SwiftUI

// MARK: - Picked for your wall (collectors)

/// A collector's wall on Home: framed pieces matched to the mediums and budget
/// they chose when they first opened the app.
struct HomeWallPicks: View {
    let mediums: Set<ArtCategory>
    let budget: CollectorBudget?

    private var picks: [Artwork] {
        let available = Artwork.samples.filter { !$0.isSold }
        let inMedium = mediums.isEmpty ? available : available.filter { mediums.contains($0.category) }
        let inBudget = inMedium.filter { fits($0.price) }
        // Never show an empty wall: loosen budget first, then medium.
        let pool = inBudget.count >= 3 ? inBudget : (inMedium.count >= 3 ? inMedium : available)
        return Array(pool.sorted { $0.likeCount > $1.likeCount }.prefix(10))
    }

    private func fits(_ price: Double) -> Bool {
        switch budget {
        case .under500:  price < 500
        case .upTo2000:  price <= 2000
        case .statement: price >= 2000
        case .browsing, nil: true
        }
    }

    /// Says why these pieces are here, in plain words.
    private var reason: String {
        let names = ArtCategory.allCases.filter(mediums.contains).prefix(2).map { $0.rawValue.lowercased() }
        var line = names.isEmpty ? "Chosen from what collectors love most" : "Because you love " + names.joined(separator: " and ")
        if let budget, budget != .browsing { line += " \u{00B7} " + budget.price }
        return line
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GallerySectionHeader(title: "Picked for your wall", reason: reason)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 18) {
                    ForEach(picks) { artwork in
                        NavigationLink(value: artwork) {
                            FramedPick(artwork: artwork, tilt: 0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
        }
    }
}

private struct FramedPick: View {
    let artwork: Artwork
    let tilt: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GalleryArtworkTile(artwork: artwork, radius: GalleryRadius.large, inset: 14, maxDimension: 500)
                .frame(width: 164, height: 205)

            VStack(alignment: .leading, spacing: 2) {
                Text(artwork.artistName)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Color.picardoText)
                    .lineLimit(1)
                Text(artwork.title)
                    .font(.system(size: 14, weight: .semibold, design: .serif).italic())
                    .foregroundStyle(Color.picardoText)
                    .lineLimit(1)
                Text(artwork.price, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.picardoText)
                    .padding(.top, 2)
            }
            .frame(width: 164, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}
