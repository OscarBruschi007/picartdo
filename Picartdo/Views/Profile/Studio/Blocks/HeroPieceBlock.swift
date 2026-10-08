import SwiftUI

struct HeroPieceBlock: View {
    @Binding var block: StudioPlacedBlock
    let accent: Color
    var isOwner: Bool
    var zoom: Namespace.ID
    var onInspect: (String) -> Void
    var onOpen: (String) -> Void

    @State private var scale: CGFloat = 1

    private var imageName: String {
        if case .hero(let name, _) = block.payload { return name }
        return ""
    }

    private var caption: String {
        if case .hero(_, let cap) = block.payload { return cap }
        return ""
    }

    var body: some View {
        StudioBlockChrome(style: block.style, accent: accent) {
            if imageName.isEmpty {
                StudioEmptyBlock(line: "NO PIECE ON VIEW")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ArtworkImage(imageName: imageName, contentMode: .fill, maxDimension: 1400)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .scaleEffect(scale)
                        .modifier(StudioZoomSource(imageName: imageName, zoom: zoom))
                        .gesture(
                            MagnifyGesture()
                                .onChanged { value in
                                    scale = min(2.4, max(1, value.magnification))
                                }
                                .onEnded { _ in
                                    if abs(scale - 1) < 0.12 {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                    withAnimation(PicardoMotion.transition) { scale = 1 }
                                }
                        )
                        .onTapGesture { onOpen(imageName) }
                        .onLongPressGesture { onInspect(imageName) }

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            StudioQuoted(text: "ON VIEW", color: accent)
                            Text(caption.isEmpty ? "Untitled" : caption)
                                .font(block.style.typePair.display)
                                .foregroundStyle(block.style.paper.ink)
                                .lineLimit(2)
                        }
                        Spacer()
                        if isOwner {
                            Button("CHANGE") {
                                cyclePiece()
                            }
                            .font(block.style.typePair.meta)
                            .foregroundStyle(accent)
                        }
                    }
                }
            }
        }
        .accessibilityLabel("Hero piece \(caption)")
    }

    private func cyclePiece() {
        let names = Artwork.samples.map(\.imageName)
        guard let i = names.firstIndex(of: imageName) else { return }
        let next = names[(i + 1) % names.count]
        let caption = Artwork.samples.first { $0.imageName == next }?.title ?? caption
        block.payload = .hero(imageName: next, caption: caption)
    }
}
