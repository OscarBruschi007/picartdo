import SwiftUI

struct GuestbookWallBlock: View {
    @Binding var block: StudioPlacedBlock
    let accent: Color
    var isOwner: Bool

    @State private var draft = ""

    private var notes: [StudioNote] {
        if case .guestbook(let n) = block.payload { return n }
        return []
    }

    var body: some View {
        StudioBlockChrome(style: block.style, accent: accent) {
            VStack(alignment: .leading, spacing: 8) {
                StudioQuoted(text: "GUESTBOOK", color: accent)
                if notes.isEmpty {
                    StudioEmptyBlock(line: "NO MARKS YET")
                } else {
                    ZStack {
                        ForEach(Array(notes.enumerated()), id: \.element.id) { i, note in
                            Text(note.text)
                                .font(.system(size: 13, design: .serif))
                                .italic()
                                .foregroundStyle(block.style.paper.ink)
                                .padding(8)
                                .background(Color.white)
                                .overlay(Rectangle().strokeBorder(Color.picardoStudioHairline, lineWidth: 1))
                                .rotationEffect(.degrees(note.angle))
                                .offset(x: CGFloat((i % 3) * 70 - 40), y: CGFloat((i / 3) * 36))
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 90)
                }
                HStack {
                    TextField("Leave a mark", text: $draft)
                        .font(block.style.typePair.meta)
                    Button("PIN") { pin() }
                        .font(block.style.typePair.meta)
                        .foregroundStyle(accent)
                        .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                    if isOwner && !notes.isEmpty {
                        Button("CLEAR") { block.payload = .guestbook(notes: []) }
                            .font(block.style.typePair.meta)
                            .foregroundStyle(Color.picardoStudioMute)
                    }
                }
            }
        }
        .accessibilityLabel("Guestbook wall")
    }

    private func pin() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        var next = notes
        next.append(StudioNote(text: text, angle: Double.random(in: -6...6)))
        block.payload = .guestbook(notes: next)
        draft = ""
    }
}
