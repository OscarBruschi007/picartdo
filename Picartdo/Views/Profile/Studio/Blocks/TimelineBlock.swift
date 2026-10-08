import SwiftUI

struct TimelineBlock: View {
    @Binding var block: StudioPlacedBlock
    let accent: Color

    private var events: [StudioEvent] {
        if case .timeline(let e) = block.payload { return e }
        return []
    }

    var body: some View {
        StudioBlockChrome(style: block.style, accent: accent) {
            HStack(alignment: .top, spacing: 14) {
                Rectangle()
                    .fill(block.style.paper.ink)
                    .frame(width: 1)
                VStack(alignment: .leading, spacing: 14) {
                    StudioQuoted(text: "TIMELINE", color: accent)
                    if events.isEmpty {
                        StudioEmptyBlock(line: "NO MILESTONES")
                    } else {
                        ForEach(events) { event in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(event.year)
                                    .font(block.style.typePair.meta)
                                    .foregroundStyle(accent)
                                    .frame(width: 44, alignment: .leading)
                                Text(event.title)
                                    .font(block.style.typePair.body)
                                    .foregroundStyle(block.style.paper.ink)
                            }
                        }
                    }
                }
            }
        }
        .accessibilityLabel("Exhibition timeline")
    }
}
