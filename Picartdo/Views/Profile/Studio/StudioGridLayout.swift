import SwiftUI

struct StudioGridLayout: Layout {
    var columns: Int = 12
    var rowHeight: CGFloat = 28
    var gutter: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 390
        let bottom = subviews.map { $0[StudioFrameKey.self].maxRow }.max() ?? 0
        return CGSize(width: width, height: max(rowHeight * 8, CGFloat(bottom) * rowHeight + gutter))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let totalGutter = gutter * CGFloat(columns - 1)
        let colW = max(1, (bounds.width - totalGutter) / CGFloat(columns))
        for sub in subviews {
            var frame = sub[StudioFrameKey.self]
            frame.snap(columns: columns)
            let x = bounds.minX + CGFloat(frame.col) * (colW + gutter)
            let y = bounds.minY + CGFloat(frame.row) * rowHeight
            let w = CGFloat(frame.colSpan) * colW + CGFloat(max(0, frame.colSpan - 1)) * gutter
            let h = CGFloat(frame.rowSpan) * rowHeight - gutter
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: w, height: max(44, h)))
        }
    }

    static func snap(translation: CGSize, start: StudioRect, columns: Int = 12, rowHeight: CGFloat = 28, width: CGFloat) -> StudioRect {
        let colW = max(1, (width - 8 * 11) / 12)
        var next = start
        next.col = start.col + Int((translation.width / colW).rounded())
        next.row = start.row + Int((translation.height / rowHeight).rounded())
        next.snap(columns: columns)
        return next
    }

    static func resize(translation: CGSize, start: StudioRect, columns: Int = 12, rowHeight: CGFloat = 28, width: CGFloat) -> StudioRect {
        let colW = max(1, (width - 8 * 11) / 12)
        var next = start
        next.colSpan = start.colSpan + Int((translation.width / colW).rounded())
        next.rowSpan = start.rowSpan + Int((translation.height / rowHeight).rounded())
        next.snap(columns: columns)
        return next
    }
}
