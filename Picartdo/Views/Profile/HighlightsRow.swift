import SwiftUI

struct HighlightsRow: View {
    let items: [ProfileHighlight]
    var onSelect: (ProfileHighlight) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Highlights")
                .font(.headline)
                .foregroundStyle(Color.picardoText)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { item in
                        Button {
                            Haptics.tap()
                            onSelect(item)
                        } label: {
                            VStack(spacing: 8) {
                                Circle()
                                    .strokeBorder(
                                        AngularGradient(
                                            colors: [Color.brand, Color.picardoAccent, Color.brand.opacity(0.4), Color.brand],
                                            center: .center
                                        ),
                                        lineWidth: 2.5
                                    )
                                    .frame(width: DesignTokens.highlightSize, height: DesignTokens.highlightSize)
                                    .overlay {
                                        ArtworkImage(imageName: item.imageName, contentMode: .fill, maxDimension: 240)
                                            .frame(width: DesignTokens.highlightSize - 8, height: DesignTokens.highlightSize - 8)
                                            .clipShape(Circle())
                                    }
                                Text(item.title)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(Color.picardoText)
                                    .lineLimit(1)
                            }
                            .frame(width: DesignTokens.highlightSize + 8)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Highlight, \(item.title)")
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .accessibilityElement(children: .contain)
    }
}
