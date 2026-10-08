import SwiftUI

struct MoodboardBlock: View {
    @Binding var block: StudioPlacedBlock
    let accent: Color
    var isOwner: Bool

    private var scraps: [StudioScrap] {
        if case .moodboard(let s) = block.payload { return s }
        return []
    }

    var body: some View {
        StudioBlockChrome(style: block.style, accent: accent) {
            VStack(alignment: .leading, spacing: 8) {
                StudioQuoted(text: "MOODBOARD", color: accent)
                GeometryReader { geo in
                    if scraps.isEmpty {
                        StudioEmptyBlock(line: "NO SCRAPS")
                    } else {
                        ZStack(alignment: .topLeading) {
                            ForEach(scraps) { scrap in
                                ArtworkImage(imageName: scrap.imageName, contentMode: .fill, maxDimension: 400)
                                    .frame(width: 88, height: 88)
                                    .clipped()
                                    .rotationEffect(.degrees(scrap.angle))
                                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                                    .offset(x: scrap.x * geo.size.width, y: scrap.y * geo.size.height)
                                    .gesture(isOwner ? drag(scrap, in: geo.size) : nil)
                            }
                        }
                    }
                }
            }
        }
        .accessibilityLabel("Moodboard")
    }

    private func drag(_ scrap: StudioScrap, in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                var next = scraps
                guard let i = next.firstIndex(where: { $0.id == scrap.id }) else { return }
                next[i].x = min(0.7, max(0, scrap.x + value.translation.width / max(size.width, 1)))
                next[i].y = min(0.6, max(0, scrap.y + value.translation.height / max(size.height, 1)))
                block.payload = .moodboard(scraps: next)
            }
    }
}
