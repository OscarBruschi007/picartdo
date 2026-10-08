import SwiftUI

enum GalleryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case forSale = "For Sale"
    case collected = "Collected"
    case sold = "Sold"
    var id: String { rawValue }
}

struct GalleryMosaic: View {
    let items: [Artwork]
    var videos: Set<String> = []
    @Binding var filter: GalleryFilter
    var onSelect: (Artwork) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Gallery")
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundStyle(Color.picardoText)
                Spacer()
                Picker("Gallery filter", selection: $filter) {
                    ForEach(GalleryFilter.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 240)
                .onChange(of: filter) { _, _ in Haptics.select() }
            }
            .padding(.horizontal, 20)

            if items.isEmpty {
                Text("Nothing in this room yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color.picardoTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
            } else {
                mosaic
                    .padding(.horizontal, 4)
            }
        }
    }

    private var mosaic: some View {
        let gap: CGFloat = 4
        return GeometryReader { geo in
            let unit = (geo.size.width - gap * 2) / 3
            let large = unit * 2 + gap
            let tiles = Array(items.prefix(9))
            VStack(spacing: gap) {
                HStack(alignment: .top, spacing: gap) {
                    if let first = tiles[safe: 0] {
                        tile(first, width: large, height: large, video: videos.contains(first.imageName))
                    }
                    VStack(spacing: gap) {
                        if let a = tiles[safe: 1] { tile(a, width: unit, height: unit, video: true) }
                        if let b = tiles[safe: 2] { tile(b, width: unit, height: unit, video: videos.contains(b.imageName)) }
                    }
                }
                HStack(spacing: gap) {
                    ForEach(tiles.dropFirst(3).prefix(3)) { art in
                        tile(art, width: unit, height: unit, video: videos.contains(art.imageName))
                    }
                }
                HStack(alignment: .top, spacing: gap) {
                    VStack(spacing: gap) {
                        if let a = tiles[safe: 6] { tile(a, width: unit, height: unit, video: videos.contains(a.imageName)) }
                        if let b = tiles[safe: 7] { tile(b, width: unit, height: unit, video: videos.contains(b.imageName)) }
                    }
                    if let last = tiles[safe: 8] {
                        tile(last, width: large, height: large, video: true)
                    } else if let last = tiles[safe: 6] {
                        Color.clear.frame(width: large, height: large)
                            .overlay { EmptyView() }
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .frame(height: mosaicHeight)
    }

    private var mosaicHeight: CGFloat {
        let count = min(items.count, 9)
        if count <= 3 { return 280 }
        if count <= 6 { return 430 }
        return 640
    }

    private func tile(_ art: Artwork, width: CGFloat, height: CGFloat, video: Bool) -> some View {
        Button {
            Haptics.tap()
            onSelect(art)
        } label: {
            Color.clear
                .frame(width: width, height: height)
                .overlay {
                    if video {
                        LoopingHeroVideo(resourceName: "tattoo_hero", fallbackImageName: art.imageName)
                            .allowsHitTesting(false)
                    } else {
                        ArtworkImage(artwork: art, contentMode: .fill, maxDimension: 900)
                    }
                }
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(alignment: .bottomTrailing) {
                    if video {
                        Image(systemName: "speaker.slash.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(.black.opacity(0.45), in: Circle())
                            .padding(6)
                    } else if art.isSold {
                        Text("SOLD")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.brand.opacity(0.9), in: Capsule())
                            .padding(6)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(art.title)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
