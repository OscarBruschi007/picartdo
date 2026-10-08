import SwiftUI

struct ContactSheetBlock: View {
    @Binding var block: StudioPlacedBlock
    let accent: Color
    var zoom: Namespace.ID
    var onOpen: (String) -> Void

    private var names: [String] {
        if case .contact(let n) = block.payload { return n }
        return []
    }

    var body: some View {
        StudioBlockChrome(style: block.style, accent: accent) {
            VStack(alignment: .leading, spacing: 8) {
                StudioQuoted(text: "CONTACT SHEET", color: accent)
                if names.isEmpty {
                    StudioEmptyBlock(line: "NO FRAMES")
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 4) {
                        ForEach(Array(names.enumerated()), id: \.offset) { i, name in
                            ZStack(alignment: .bottomTrailing) {
                                ArtworkImage(imageName: name, contentMode: .fill, maxDimension: 400)
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .frame(height: 64)
                                    .clipped()
                                Text(String(format: "%02d", i + 1))
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.picardoStudioInk)
                                    .padding(3)
                                    .background(Color.white)
                            }
                            .modifier(StudioZoomSource(imageName: name, zoom: zoom))
                            .onTapGesture { onOpen(name) }
                        }
                    }
                }
            }
        }
        .accessibilityLabel("Contact sheet")
    }
}
