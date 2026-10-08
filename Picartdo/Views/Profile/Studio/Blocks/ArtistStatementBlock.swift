import SwiftUI

struct ArtistStatementBlock: View {
    @Binding var block: StudioPlacedBlock
    let accent: Color
    var isOwner: Bool
    var reduceMotion: Bool

    @State private var shown = ""

    private var text: String {
        if case .statement(let t) = block.payload { return t }
        return ""
    }

    var body: some View {
        StudioBlockChrome(style: block.style, accent: accent) {
            VStack(alignment: .leading, spacing: 10) {
                StudioQuoted(text: "STATEMENT", color: accent)
                if text.isEmpty && !isOwner {
                    StudioEmptyBlock(line: "NO STATEMENT")
                } else if isOwner {
                    TextField("Statement", text: statementBinding, axis: .vertical)
                        .font(block.style.typePair.body)
                        .italic()
                        .foregroundStyle(block.style.paper.ink)
                        .lineSpacing(6)
                        .accessibilityLabel("Artist statement")
                } else {
                    Text("“\(shown)”")
                        .font(block.style.typePair.body)
                        .italic()
                        .foregroundStyle(block.style.paper.ink)
                        .lineSpacing(6)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .onAppear { type() }
        .accessibilityLabel("Artist statement")
    }

    private var statementBinding: Binding<String> {
        Binding(
            get: { text },
            set: { block.payload = .statement(text: $0) }
        )
    }

    private func type() {
        if reduceMotion { shown = text; return }
        shown = ""
        Task { @MainActor in
            for ch in text {
                shown.append(ch)
                try? await Task.sleep(nanoseconds: 18_000_000)
            }
        }
    }
}
