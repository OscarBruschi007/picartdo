import SwiftUI
import UIKit

struct StudioShareCard: View {
    let layout: StudioLayout

    private var thumbs: [String] {
        layout.blocks.compactMap { block -> String? in
            switch block.payload {
            case .hero(let name, _): return name
            case .nowWorking(_, let name, _): return name
            case .shelf(let names), .contact(let names), .process(let names): return names.first
            default: return nil
            }
        }
        .filter { !$0.isEmpty }
        .prefix(3)
        .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("“STUDIO”")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .kerning(1.4)
                .foregroundStyle(layout.accent.color)
            Text(layout.artistName)
                .font(.system(size: 36, weight: .black, design: .serif))
                .foregroundStyle(Color.picardoStudioInk)
            Text(layout.tagline.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .kerning(1.2)
                .foregroundStyle(Color.picardoStudioMute)
            Rectangle()
                .fill(layout.accent.color)
                .frame(height: 2)
            HStack(spacing: 8) {
                ForEach(thumbs, id: \.self) { name in
                    if let image = UIImage(named: name) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 108, height: 108)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.picardoStudioHairline)
                            .frame(width: 108, height: 108)
                    }
                }
            }
            Spacer()
            Text(layout.template.label)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.picardoStudioMute)
        }
        .padding(28)
        .frame(width: 390, height: 520, alignment: .topLeading)
        .background(layout.material.fill)
    }

    @MainActor
    static func render(_ layout: StudioLayout) -> UIImage? {
        let renderer = ImageRenderer(content: StudioShareCard(layout: layout))
        renderer.scale = 2
        return renderer.uiImage
    }
}

struct StudioActivitySheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
