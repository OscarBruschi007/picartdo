import SwiftUI

struct StudioBlockChrome<Content: View>: View {
    let style: StudioBlockStyle
    let accent: Color
    var isEditing: Bool = false
    var selected: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(style.paper.fill)
            .clipShape(shape)
            .overlay(border)
            .shadow(color: .black.opacity(style.shadow == .none ? 0 : 0.10), radius: style.shadow.radius, y: style.shadow == .none ? 0 : 4)
            .overlay {
                if selected && isEditing {
                    Rectangle().strokeBorder(accent, lineWidth: 2)
                }
            }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: style.corner.radius, style: .continuous)
    }

    @ViewBuilder
    private var border: some View {
        switch style.border {
        case .none:
            EmptyView()
        case .hairline:
            shape.strokeBorder(Color.picardoStudioHairline, lineWidth: 1)
        case .rule:
            shape.strokeBorder(style.paper.ink, lineWidth: 1.5)
        case .stamp:
            shape.strokeBorder(accent, lineWidth: 1.5)
        }
    }
}

struct StudioEmptyBlock: View {
    let line: String
    var body: some View {
        Text("“\(line)”")
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(Color.picardoStudioMute)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct StudioQuoted: View {
    let text: String
    var color: Color = Color.picardoStudioInk
    var body: some View {
        Text("“\(text)”")
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .kerning(1.3)
            .foregroundStyle(color)
    }
}

extension Artwork {
    var studioPrice: String {
        price.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

struct StudioZoomSource: ViewModifier {
    let imageName: String
    var zoom: Namespace.ID

    func body(content: Content) -> some View {
        if let id = Artwork.samples.first(where: { $0.imageName == imageName })?.id {
            content.matchedTransitionSource(id: id, in: zoom)
        } else {
            content
        }
    }
}
