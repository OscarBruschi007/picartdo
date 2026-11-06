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

    private var subtitle: String {
        var parts = ArtCategory.allCases.filter(mediums.contains).prefix(3).map(\.rawValue)
        if let budget, budget != .browsing { parts.append(budget.price) }
        return parts.isEmpty ? "The Collection of You" : parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.picardoGold)
                Text("Picked for your wall")
                    .font(.system(size: 26, weight: .black, design: .serif))
                    .foregroundStyle(Color.picardoText)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 18) {
                    ForEach(Array(picks.enumerated()), id: \.element.id) { index, artwork in
                        NavigationLink(value: artwork) {
                            FramedPick(artwork: artwork, tilt: index.isMultiple(of: 2) ? -1.2 : 0.9)
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
            Color.clear
                .frame(width: 150, height: 186)
                .overlay {
                    ArtworkImage(artwork: artwork, contentMode: .fill, maxDimension: 500)
                        .scaleEffect(1.3) // crop the wall the piece was photographed on
                        .allowsHitTesting(false)
                }
                .clipped()
                .padding(7)
                .background(Color.picardoPolaroidMat)
                .overlay(Rectangle().stroke(Color.black, lineWidth: 4))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 6)
                .rotationEffect(.degrees(tilt))
                .contentShape(Rectangle())

            VStack(alignment: .leading, spacing: 2) {
                Text(artwork.title)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundStyle(Color.picardoText)
                    .lineLimit(1)
                Text(artwork.artistName)
                    .font(.system(size: 11.5, design: .serif).italic())
                    .foregroundStyle(Color.picardoTextSecondary)
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
