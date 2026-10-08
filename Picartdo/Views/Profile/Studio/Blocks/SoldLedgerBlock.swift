import SwiftUI

struct SoldLedgerBlock: View {
    @Binding var block: StudioPlacedBlock
    let accent: Color

    private var entries: [StudioSale] {
        if case .ledger(let e) = block.payload { return e }
        return []
    }

    var body: some View {
        StudioBlockChrome(style: block.style, accent: accent) {
            VStack(alignment: .leading, spacing: 8) {
                StudioQuoted(text: "SOLD LEDGER", color: accent)
                if entries.isEmpty {
                    StudioEmptyBlock(line: "NO SALES")
                } else {
                    ForEach(entries) { entry in
                        HStack(alignment: .firstTextBaseline) {
                            Text(entry.date)
                                .font(block.style.typePair.meta)
                                .foregroundStyle(Color.picardoStudioMute)
                                .frame(width: 52, alignment: .leading)
                            Text(entry.title.uppercased())
                                .font(block.style.typePair.meta)
                                .lineLimit(1)
                            Spacer()
                            Text(entry.price)
                                .font(block.style.typePair.meta)
                        }
                        .foregroundStyle(block.style.paper.ink)
                    }
                }
            }
        }
        .accessibilityLabel("Sold ledger")
    }
}
