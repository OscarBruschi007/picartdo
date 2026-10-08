import Foundation
import SwiftUI

struct StudioRect: Codable, Hashable {
    var col: Int
    var row: Int
    var colSpan: Int
    var rowSpan: Int

    var maxRow: Int { row + rowSpan }

    mutating func snap(columns: Int = 12) {
        col = min(max(0, col), columns - 1)
        colSpan = min(max(2, colSpan), columns - col)
        row = max(0, row)
        rowSpan = max(3, rowSpan)
    }
}

struct StudioPoint: Codable, Hashable {
    var x: Double
    var y: Double
    var cg: CGPoint { CGPoint(x: x, y: y) }
    init(_ p: CGPoint) { x = p.x; y = p.y }
    init(x: Double, y: Double) { self.x = x; self.y = y }
}

struct StudioNote: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var text: String
    var angle: Double
}

struct StudioEvent: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var year: String
    var title: String
}

struct StudioService: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var price: String
}

struct StudioScrap: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var imageName: String
    var x: Double
    var y: Double
    var angle: Double
}

struct StudioSale: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var price: String
    var date: String
}

enum StudioBlockPayload: Codable, Hashable {
    case hero(imageName: String, caption: String)
    case statement(text: String)
    case nowWorking(status: String, imageName: String, inStudio: Bool)
    case process(imageNames: [String])
    case contact(imageNames: [String])
    case shelf(imageNames: [String])
    case commissions(open: Bool, items: [StudioService])
    case guestbook(notes: [StudioNote])
    case timeline(events: [StudioEvent])
    case moodboard(scraps: [StudioScrap])
    case ledger(entries: [StudioSale])
    case signature(strokes: [[StudioPoint]])
}

struct StudioBlockStyle: Codable, Hashable {
    var paper: StudioPaper = .white
    var border: StudioBorder = .hairline
    var corner: StudioCorner = .soft
    var shadow: StudioShadow = .low
    var typePair: StudioTypePair = .exhibition
}

struct StudioPlacedBlock: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var kind: StudioBlockKind
    var frame: StudioRect
    var style: StudioBlockStyle
    var payload: StudioBlockPayload
}

struct StudioLayout: Codable, Hashable {
    var template: StudioTemplate
    var accent: StudioAccent
    var material: StudioMaterial
    var entrance: StudioEntrance
    var artistName: String
    var tagline: String
    var blocks: [StudioPlacedBlock]

    static func blank(name: String, tagline: String) -> StudioLayout {
        StudioLayout(
            template: .galleryWall,
            accent: .vermillion,
            material: .paper,
            entrance: .curtain,
            artistName: name,
            tagline: tagline,
            blocks: []
        )
    }
}

enum StudioFrameKey: LayoutValueKey {
    static let defaultValue = StudioRect(col: 0, row: 0, colSpan: 12, rowSpan: 4)
}
