import SwiftUI

struct CommissionsCounterBlock: View {
    @Binding var block: StudioPlacedBlock
    let accent: Color
    var isOwner: Bool
    var onKnock: () -> Void

    private var isOpen: Bool {
        if case .commissions(let open, _) = block.payload { return open }
        return false
    }
    private var items: [StudioService] {
        if case .commissions(_, let items) = block.payload { return items }
        return []
    }

    var body: some View {
        StudioBlockChrome(style: block.style, accent: accent) {
            VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        StudioQuoted(text: "COMMISSIONS", color: accent)
                        Spacer()
                        if isOwner {
                            Button {
                                toggleOpen()
                            } label: {
                                sign
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(isOpen ? "Open for commissions" : "Closed")
                        } else {
                            sign
                        }
                    }

                if items.isEmpty {
                    StudioEmptyBlock(line: "NO MENU")
                } else {
                    ForEach(items) { item in
                        HStack {
                            Text(item.name)
                                .font(block.style.typePair.body)
                            Spacer()
                            Text(item.price)
                                .font(block.style.typePair.meta)
                        }
                        .foregroundStyle(block.style.paper.ink)
                    }
                }

                Button(action: onKnock) {
                    HStack {
                        StudioQuoted(text: "KNOCK")
                        Spacer()
                        Image(systemName: "door.left.hand.closed")
                    }
                    .foregroundStyle(block.style.paper.ink)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .overlay(Rectangle().strokeBorder(block.style.paper.ink, lineWidth: 1))
                }
                .buttonStyle(PicardoPressStyle())
                .disabled(!isOpen)
                .opacity(isOpen ? 1 : 0.4)
                .accessibilityLabel("Knock to request a commission")
            }
        }
    }

    private var sign: some View {
        Text(isOpen ? "OPEN" : "CLOSED")
            .font(block.style.typePair.meta)
            .foregroundStyle(isOpen ? Color.white : block.style.paper.ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isOpen ? accent : Color.clear)
            .overlay(Rectangle().strokeBorder(block.style.paper.ink, lineWidth: 1))
    }

    private func toggleOpen() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        block.payload = .commissions(open: !isOpen, items: items)
    }
}
