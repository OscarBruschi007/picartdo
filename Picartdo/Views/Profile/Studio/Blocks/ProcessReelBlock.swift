import SwiftUI

struct ProcessReelBlock: View {
    @Binding var block: StudioPlacedBlock
    let accent: Color
    var zoom: Namespace.ID
    var onOpen: (String) -> Void

    private var names: [String] {
        if case .process(let n) = block.payload { return n }
        return []
    }

    var body: some View {
        StudioBlockChrome(style: block.style, accent: accent) {
            VStack(alignment: .leading, spacing: 8) {
                StudioQuoted(text: "PROCESS", color: accent)
                if names.isEmpty {
                    StudioEmptyBlock(line: "NO STAGES")
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(names.enumerated()), id: \.offset) { i, name in
                                VStack(alignment: .leading, spacing: 4) {
                                    ArtworkImage(imageName: name, contentMode: .fill, maxDimension: 500)
                                        .frame(width: 110, height: 110)
                                        .clipped()
                                        .modifier(StudioZoomSource(imageName: name, zoom: zoom))
                                        .onTapGesture { onOpen(name) }
                                    Text(String(format: "%02d", i + 1))
                                        .font(block.style.typePair.meta)
                                        .foregroundStyle(Color.picardoStudioMute)
                                }
                            }
                        }
                    }
                }
            }
        }
        .accessibilityLabel("Process reel")
    }
}
