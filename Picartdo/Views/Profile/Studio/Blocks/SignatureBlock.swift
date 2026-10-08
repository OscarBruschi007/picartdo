import SwiftUI

struct SignatureBlock: View {
    @Binding var block: StudioPlacedBlock
    let accent: Color
    var isOwner: Bool

    @State private var current: [StudioPoint] = []

    private var strokes: [[StudioPoint]] {
        if case .signature(let s) = block.payload { return s }
        return []
    }

    var body: some View {
        StudioBlockChrome(style: block.style, accent: accent) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    StudioQuoted(text: "SIGNATURE", color: accent)
                    Spacer()
                    if isOwner && !strokes.isEmpty {
                        Button("CLEAR") { block.payload = .signature(strokes: []) }
                            .font(block.style.typePair.meta)
                            .foregroundStyle(Color.picardoStudioMute)
                    }
                }
                ZStack {
                    if strokes.isEmpty && current.isEmpty {
                        StudioEmptyBlock(line: isOwner ? "DRAW YOUR MARK" : "UNSIGNED")
                    }
                    SignatureInk(strokes: strokes + (current.isEmpty ? [] : [current]), color: block.style.paper.ink)
                }
                .frame(maxWidth: .infinity, minHeight: 64)
                .contentShape(Rectangle())
                .gesture(isOwner ? draw : nil)
            }
        }
        .accessibilityLabel("Artist signature")
    }

    private var draw: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                current.append(StudioPoint(value.location))
            }
            .onEnded { _ in
                var next = strokes
                if !current.isEmpty { next.append(current) }
                block.payload = .signature(strokes: next)
                current = []
            }
    }
}

private struct SignatureInk: View {
    let strokes: [[StudioPoint]]
    let color: Color

    var body: some View {
        Canvas { ctx, _ in
            for stroke in strokes where stroke.count > 1 {
                var path = Path()
                path.move(to: stroke[0].cg)
                for p in stroke.dropFirst() { path.addLine(to: p.cg) }
                ctx.stroke(path, with: .color(color), lineWidth: 1.6)
            }
        }
    }
}
