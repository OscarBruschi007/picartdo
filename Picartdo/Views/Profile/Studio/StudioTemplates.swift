import Foundation

enum StudioTemplates {
    static func make(_ template: StudioTemplate, name: String, tagline: String) -> StudioLayout {
        var layout = StudioLayout.blank(name: name, tagline: tagline)
        layout.template = template
        switch template {
        case .galleryWall:
            layout.accent = .vermillion
            layout.material = .paper
            layout.entrance = .curtain
            layout.blocks = [
                placed(.hero, col: 0, row: 0, w: 12, h: 14),
                placed(.statement, col: 0, row: 14, w: 12, h: 6),
                placed(.contactSheet, col: 0, row: 20, w: 12, h: 10),
                placed(.signature, col: 0, row: 30, w: 12, h: 4),
            ]
        case .zine:
            layout.accent = .ink
            layout.material = .plain
            layout.entrance = .ink
            layout.blocks = [
                placed(.statement, col: 0, row: 0, w: 12, h: 8, style: StudioBlockStyle(paper: .warm, border: .none, corner: .sharp, shadow: .none, typePair: .zine)),
                placed(.processReel, col: 0, row: 8, w: 12, h: 6, style: StudioBlockStyle(paper: .white, border: .rule, corner: .sharp, shadow: .none, typePair: .zine)),
                placed(.hero, col: 0, row: 14, w: 7, h: 12),
                placed(.ledger, col: 7, row: 14, w: 5, h: 12, style: StudioBlockStyle(paper: .warm, border: .hairline, corner: .sharp, shadow: .none, typePair: .ledger)),
                placed(.signature, col: 0, row: 26, w: 12, h: 3),
            ]
        case .contactSheet:
            layout.accent = .graphite
            layout.material = .grid
            layout.entrance = .spotlight
            layout.blocks = [
                placed(.statement, col: 0, row: 0, w: 12, h: 4, style: StudioBlockStyle(paper: .white, border: .none, corner: .sharp, shadow: .none, typePair: .telegram)),
                placed(.contactSheet, col: 0, row: 4, w: 12, h: 11),
                placed(.nowWorking, col: 0, row: 15, w: 12, h: 5),
            ]
        case .shopCounter:
            layout.accent = .ochre
            layout.material = .canvas
            layout.entrance = .door
            layout.blocks = [
                placed(.commissions, col: 0, row: 0, w: 12, h: 8),
                placed(.shelf, col: 0, row: 8, w: 12, h: 7),
                placed(.ledger, col: 0, row: 15, w: 12, h: 7, style: StudioBlockStyle(paper: .warm, border: .hairline, corner: .sharp, shadow: .low, typePair: .ledger)),
            ]
        case .scrapbook:
            layout.accent = .rust
            layout.material = .canvas
            layout.entrance = .ink
            layout.blocks = [
                placed(.moodboard, col: 0, row: 0, w: 12, h: 12, style: StudioBlockStyle(paper: .kraft, border: .none, corner: .sharp, shadow: .none, typePair: .atelier)),
                placed(.guestbook, col: 0, row: 12, w: 12, h: 8),
                placed(.processReel, col: 0, row: 20, w: 12, h: 6),
                placed(.signature, col: 0, row: 26, w: 12, h: 4),
            ]
        case .timeline:
            layout.accent = .cobalt
            layout.material = .paper
            layout.entrance = .spotlight
            layout.blocks = [
                placed(.timeline, col: 0, row: 0, w: 12, h: 8),
                placed(.nowWorking, col: 0, row: 8, w: 12, h: 6),
                placed(.statement, col: 0, row: 14, w: 12, h: 6),
                placed(.hero, col: 0, row: 20, w: 12, h: 10),
            ]
        }
        return layout
    }

    static func seed(_ kind: StudioBlockKind, style: StudioBlockStyle = StudioBlockStyle()) -> StudioPlacedBlock {
        let art = Artwork.samples
        guard let first = art.first else {
            return StudioPlacedBlock(kind: kind, frame: StudioRect(col: 0, row: 0, colSpan: 12, rowSpan: 4), style: style, payload: .statement(text: ""))
        }
        func piece(_ i: Int) -> Artwork { art.indices.contains(i) ? art[i] : first }
        let names = art.prefix(12).map(\.imageName)
        let payload: StudioBlockPayload
        switch kind {
        case .hero:
            payload = .hero(imageName: piece(14).imageName, caption: piece(14).title)
        case .statement:
            payload = .statement(text: "Art made by dots. Every piece a universe I can hold in two hands.")
        case .nowWorking:
            payload = .nowWorking(status: "Gold ground, twenty-first circle.", imageName: piece(25).imageName, inStudio: true)
        case .processReel:
            payload = .process(imageNames: Array(names.prefix(6)))
        case .contactSheet:
            payload = .contact(imageNames: Array(names.prefix(12)))
        case .shelf:
            payload = .shelf(imageNames: Array(names.prefix(5)))
        case .commissions:
            payload = .commissions(open: true, items: [
                StudioService(name: "Portrait sitting", price: "$450"),
                StudioService(name: "Large canvas", price: "$2,400"),
                StudioService(name: "Live painting", price: "$1,200"),
            ])
        case .guestbook:
            payload = .guestbook(notes: [
                StudioNote(text: "Took my breath.", angle: -4),
                StudioNote(text: "The gold one.", angle: 3),
            ])
        case .timeline:
            payload = .timeline(events: [
                StudioEvent(year: "2024", title: "Joined Picartdo"),
                StudioEvent(year: "2025", title: "Collectors’ Picks"),
                StudioEvent(year: "2026", title: "Studio wall opens"),
            ])
        case .moodboard:
            payload = .moodboard(scraps: [
                StudioScrap(imageName: names[0], x: 0.08, y: 0.12, angle: -6),
                StudioScrap(imageName: names[2], x: 0.42, y: 0.20, angle: 4),
                StudioScrap(imageName: names[4], x: 0.18, y: 0.52, angle: 2),
            ])
        case .ledger:
            payload = .ledger(entries: art.prefix(5).enumerated().map { i, work in
                StudioSale(title: work.title, price: work.price.formatted(.currency(code: "USD").precision(.fractionLength(0))), date: "0\(i + 1) / 26")
            })
        case .signature:
            payload = .signature(strokes: [])
        }
        return StudioPlacedBlock(kind: kind, frame: StudioRect(col: 0, row: 0, colSpan: kind.defaultSpan.cols, rowSpan: kind.defaultSpan.rows), style: style, payload: payload)
    }

    private static func placed(_ kind: StudioBlockKind, col: Int, row: Int, w: Int, h: Int, style: StudioBlockStyle = StudioBlockStyle()) -> StudioPlacedBlock {
        var block = seed(kind, style: style)
        block.frame = StudioRect(col: col, row: row, colSpan: w, rowSpan: h)
        return block
    }
}
