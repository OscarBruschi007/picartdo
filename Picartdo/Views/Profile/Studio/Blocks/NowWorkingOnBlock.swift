import SwiftUI

struct NowWorkingOnBlock: View {
    @Binding var block: StudioPlacedBlock
    let accent: Color

    private var status: String {
        if case .nowWorking(let s, _, _) = block.payload { return s }
        return ""
    }
    private var imageName: String {
        if case .nowWorking(_, let n, _) = block.payload { return n }
        return ""
    }
    private var inStudio: Bool {
        if case .nowWorking(_, _, let open) = block.payload { return open }
        return false
    }

    var body: some View {
        StudioBlockChrome(style: block.style, accent: accent) {
            HStack(alignment: .top, spacing: 12) {
                if imageName.isEmpty {
                    Rectangle().fill(Color.picardoStudioHairline).frame(width: 88, height: 88)
                } else {
                    ArtworkImage(imageName: imageName, contentMode: .fill, maxDimension: 400)
                        .frame(width: 88, height: 88)
                        .clipped()
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(inStudio ? accent : Color.picardoStudioMute)
                            .frame(width: 8, height: 8)
                            .phaseAnimator([false, true]) { content, on in
                                content.opacity(inStudio ? (on ? 1 : 0.35) : 1)
                            }
                        StudioQuoted(text: inStudio ? "IN THE STUDIO" : "CLOSED", color: inStudio ? accent : Color.picardoStudioMute)
                    }
                    Text(status.isEmpty ? "Nothing on the easel." : status)
                        .font(block.style.typePair.body)
                        .foregroundStyle(block.style.paper.ink)
                }
            }
        }
        .accessibilityLabel(inStudio ? "In the studio. \(status)" : "Studio closed")
    }
}
