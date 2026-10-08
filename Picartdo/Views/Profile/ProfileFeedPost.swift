import SwiftUI

/// Profile feed row — Home’s featured drop card, one work per row.
struct ProfileFeedPost: View {
    let artwork: Artwork
    var isSaved: Bool
    var onSave: () -> Void
    var onBuy: (() -> Void)?
    var onOpen: () -> Void

    var body: some View {
        FeaturedHeroCard(
            artwork: artwork,
            isSaved: isSaved,
            onSave: onSave,
            onBuy: artwork.isSold ? nil : onBuy,
            onOpen: onOpen,
            eyebrow: artwork.isSold ? "SOLD" : artwork.category.rawValue.uppercased()
        )
        .accessibilityLabel("\(artwork.title), \(artwork.artistName)")
    }
}
