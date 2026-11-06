import Foundation

/// An exhibition or event happening in the city.
///
/// The current list is real programming at the Art Gallery of Ontario (ago.ca, read
/// November 2026): titles, dates, times, prices and images come from the AGO website.
/// Descriptions are written for Picartdo. Images load from ago.ca, so they need a
/// connection, and they belong to the AGO: fine for a demo, but a public release
/// needs the AGO's permission or our own photography.
struct ArtEventItem: Identifiable, Hashable {
    let id: String
    let title: String
    let type: String
    /// A remote image URL (https://…) or a bundled asset name.
    let imageName: String
    let summary: String
    let isExhibition: Bool
    /// For events: the day it happens. For exhibitions: opening day (`nil` when already on view).
    let startDate: Date?
    /// For exhibitions: the last day on view (`nil` when open-ended).
    let endDate: Date?
    let timeLabel: String
    /// Price per ticket in CAD. 0 means free.
    let price: Double
    let priceNote: String
    let sourceURL: URL

    var venue: String = "Art Gallery of Ontario"
    var city: String = "Toronto, ON"
    var address: String = "317 Dundas Street West, Toronto, ON M5T 1G4"
    var isOnline: Bool = false
    var distance: String = "Dundas St W"

    var isFree: Bool { price == 0 }

    /// An exhibition that is open today.
    var isOnNow: Bool {
        guard isExhibition else { return false }
        guard let startDate else { return true }
        return startDate <= Date()
    }

    /// Small label above the day in list rows ("NOV", or "ON" for exhibitions on view).
    var month: String {
        if isOnNow { return "ON" }
        guard let startDate else { return "" }
        return startDate.formatted(.dateTime.month(.abbreviated)).uppercased()
    }

    /// Big label in list rows ("13", or "NOW").
    var day: String {
        if isOnNow { return "NOW" }
        guard let startDate else { return "" }
        return startDate.formatted(.dateTime.day())
    }

    /// One line describing when: "On now until February 28, 2027", "Opens January 23, 2027",
    /// "Friday, November 13, 2026".
    var dateLabel: String {
        let long = Date.FormatStyle.dateTime.month(.wide).day().year()
        if isExhibition {
            if isOnNow {
                if let endDate { return "On now until \(endDate.formatted(long))" }
                return "On now"
            }
            if let startDate { return "Opens \(startDate.formatted(long))" }
            return ""
        }
        guard let startDate else { return "" }
        return startDate.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
    }

    /// Short date for cards: "On now", "Opens Jan 23", "Nov 13".
    var shortDateLabel: String {
        if isOnNow { return "On now" }
        guard let startDate else { return "" }
        let short = startDate.formatted(.dateTime.month(.abbreviated).day())
        return isExhibition ? "Opens \(short)" : short
    }

    var priceLabel: String {
        isFree ? "Free" : price.formatted(.currency(code: "CAD").precision(.fractionLength(0)))
    }

    /// Days a ticket can be booked for. Events: their one day. Exhibitions: the next open
    /// days (the AGO is closed Mondays) from opening, up to the closing date.
    func bookableDays(limit: Int = 14) -> [Date] {
        let calendar = Calendar.current
        if !isExhibition { return startDate.map { [$0] } ?? [] }
        var day = calendar.startOfDay(for: max(Date(), startDate ?? Date()))
        var days: [Date] = []
        while days.count < limit {
            if let endDate, day > endDate { break }
            if calendar.component(.weekday, from: day) != 2 { days.append(day) } // 2 = Monday
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }

    /// The hours that apply on a given day. Events keep their own time; exhibitions follow
    /// AGO gallery hours (Tue & Thu to 5, Wed & Fri to 9, Sat & Sun to 5:30).
    func timeLabel(on day: Date) -> String {
        guard isExhibition else { return timeLabel }
        switch Calendar.current.component(.weekday, from: day) {
        case 4, 6: return "10:30 am – 9:00 pm"   // Wednesday, Friday
        case 1, 7: return "10:30 am – 5:30 pm"   // Sunday, Saturday
        default:   return "10:30 am – 5:00 pm"   // Tuesday, Thursday
        }
    }

    // MARK: - Hashable on identity only

    static func == (lhs: ArtEventItem, rhs: ArtEventItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - AGO programming

extension ArtEventItem {
    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private static let galleryHours = "Tue–Sun 10:30 am – 5:00 pm · Wed & Fri until 9:00 pm"
    private static let ago = "https://ago.ca"
    private static func img(_ path: String) -> String { ago + "/sites/default/files/styles/" + path }
    private static func page(_ path: String) -> URL { URL(string: ago + path)! }

    static let samples: [ArtEventItem] = exhibitions + events

    static let exhibitions: [ArtEventItem] = [
        ArtEventItem(
            id: "ago-sunday-best",
            title: "Sunday Best: The Power & The Glory of Black Style",
            type: "Exhibition",
            imageName: img("image_large/public/2026-06/EXH.175222-1200px-72dpi.jpg?itok=eFCbGKOg"),
            summary: "A celebration of Black style: dressing up as self-expression, pride and joy, told through fashion, photography and art.",
            isExhibition: true, startDate: nil, endDate: date(2027, 2, 28),
            timeLabel: galleryHours, price: 30, priceNote: "Adult general admission",
            sourceURL: page("/exhibitions/sunday-best-power-glory-black-style")
        ),
        ArtEventItem(
            id: "ago-melissa-auf-der-maur",
            title: "Melissa Auf der Maur: My ’90s Rock Photographs",
            type: "Exhibition",
            imageName: img("image_large/public/2025-10/Auf%20der%20maur%20EDIT_0.jpg?itok=X8cUdwLo"),
            summary: "Photographs by musician Melissa Auf der Maur from inside the 1990s rock scene: backstage, on the road and on stage.",
            isExhibition: true, startDate: nil, endDate: date(2027, 6, 6),
            timeLabel: galleryHours, price: 30, priceNote: "Adult general admission",
            sourceURL: page("/exhibitions/melissa-auf-der-maur-my-90s-rock-photographs")
        ),
        ArtEventItem(
            id: "ago-dawoud-bey",
            title: "Dawoud Bey: Material Histories, Living Landscapes",
            type: "Exhibition",
            imageName: img("image_medium/public/2025-10/Dawoud%20Bey%20install%20350%2C000.png?itok=aPzYfQrj"),
            summary: "Large photographs by Dawoud Bey that look at how land holds the histories of the people who lived and worked on it.",
            isExhibition: true, startDate: nil, endDate: date(2027, 7, 4),
            timeLabel: galleryHours, price: 30, priceNote: "Adult general admission",
            sourceURL: page("/exhibitions/dawoud-bey-material-histories-living-landscapes")
        ),
        ArtEventItem(
            id: "ago-kazuo-nakamura",
            title: "Kazuo Nakamura: Blue Dimension",
            type: "Exhibition",
            imageName: img("image_medium/public/2023-09/AGO.11081-1200px-72dpi.jpg?itok=-HR6yBEc"),
            summary: "Quiet, structured blue paintings by Kazuo Nakamura, a member of the Painters Eleven, where landscape turns into pattern and order.",
            isExhibition: true, startDate: nil, endDate: nil,
            timeLabel: galleryHours, price: 30, priceNote: "Adult general admission",
            sourceURL: page("/exhibitions/kazuo-nakamura-blue-dimension")
        ),
        ArtEventItem(
            id: "ago-ranbir-sidhu",
            title: "Ranbir Sidhu: No Limits",
            type: "Exhibition",
            imageName: img("image_medium/public/2025-10/Asteroid.jpg?itok=_kSwANVw"),
            summary: "An exhibition of work by artist Ranbir Sidhu. Last chance: it closes January 3, 2027.",
            isExhibition: true, startDate: nil, endDate: date(2027, 1, 3),
            timeLabel: galleryHours, price: 30, priceNote: "Adult general admission",
            sourceURL: page("/exhibitions/ranbir-sidhu-no-limits")
        ),
        ArtEventItem(
            id: "ago-danh-vo",
            title: "Danh Vo: Ships that pass in the night",
            type: "Exhibition",
            imageName: img("image_medium/public/2026-10/DV_38893.jpg?itok=YR7HUOUQ"),
            summary: "Danh Vo takes over Galleria Italia, the AGO's long timber gallery overlooking Dundas Street.",
            isExhibition: true, startDate: date(2026, 11, 28), endDate: nil,
            timeLabel: galleryHours, price: 30, priceNote: "Adult general admission",
            sourceURL: page("/exhibitions/danh-vo")
        ),
        ArtEventItem(
            id: "ago-kusama",
            title: "Yayoi Kusama's Infinity Mirrored Room – Let's Survive Forever",
            type: "Exhibition",
            imageName: img("ago_card_325/public/2024-10/AGO.151397-1200px-72dpi.jpg?itok=DUPYtpsR"),
            summary: "Step inside Yayoi Kusama's mirrored room, where polished spheres and your own reflection repeat into infinity.",
            isExhibition: true, startDate: date(2027, 1, 23), endDate: nil,
            timeLabel: galleryHours, price: 30, priceNote: "Adult general admission",
            sourceURL: page("/exhibitions/yayoi-kusamas-infinity-mirrored-room-lets-survive-forever")
        ),
        ArtEventItem(
            id: "ago-future-geographies",
            title: "Future Geographies: Art in the Century of Climate Change",
            type: "Exhibition",
            imageName: img("ago_card_325/public/2026-09/EXH.174525-1200px-72dpi.jpg?itok=wffz3Z2w"),
            summary: "Artists respond to a changing planet: how climate change is reshaping land, water and the way we live.",
            isExhibition: true, startDate: date(2027, 3, 3), endDate: nil,
            timeLabel: galleryHours, price: 30, priceNote: "Adult general admission",
            sourceURL: page("/exhibitions/future-geographies-art-century-climate-change")
        ),
    ]

    static let events: [ArtEventItem] = [
        ArtEventItem(
            id: "ago-canadian-chamber-orchestra",
            title: "Canadian Chamber Orchestra at the AGO",
            type: "Performance",
            imageName: img("image_medium/public/2026-07/CCO-Fall-1.jpg?itok=Fr9pTA8f"),
            summary: "Musicians from the Canadian Chamber Orchestra play Friday night at the gallery in small ensembles: classical masterworks, contemporary music and their own compositions.",
            isExhibition: false, startDate: date(2026, 11, 13), endDate: nil,
            timeLabel: "6:00 pm – 9:00 pm", price: 30, priceNote: "Free with general admission",
            sourceURL: page("/events/canadian-chamber-orchestra-ago")
        ),
        ArtEventItem(
            id: "ago-living-black-style",
            title: "Living Black Style: Panel Discussion on Sunday Best",
            type: "Talk",
            imageName: img("image_medium/public/2026-09/Sunday%20Best%20Panel%20Rectangle.png?itok=qqEN60jy"),
            summary: "Designers and fashion voices talk about Black style, dressing up and the ideas behind the Sunday Best exhibition.",
            isExhibition: false, startDate: date(2026, 11, 18), endDate: nil,
            timeLabel: "7:00 pm – 8:30 pm", price: 10, priceNote: "Talk ticket",
            sourceURL: page("/events/living-black-style-panel-discussion-sunday-best")
        ),
        ArtEventItem(
            id: "ago-art-hangs",
            title: "Art Hangs",
            type: "Special Event",
            imageName: img("image_medium/public/2026-07/A-206268.jpg?itok=vxdpCba3"),
            summary: "30-minute guided romps through iconic works in the AGO Collection, with games and conversation. Groups meet in Walker Court at 6, 7 and 8 pm.",
            isExhibition: false, startDate: date(2026, 11, 27), endDate: nil,
            timeLabel: "5:30 pm – 9:00 pm", price: 30, priceNote: "Included with general admission",
            sourceURL: page("/events/art-hangs")
        ),
        ArtEventItem(
            id: "ago-danh-vo-talk",
            title: "Danh Vo in conversation with Tom McDonough",
            type: "Talk",
            imageName: img("image_medium/public/2026-10/Untitled%20design.png?itok=VgMjtN4c"),
            summary: "Artist Danh Vo and art historian and critic Tom McDonough discuss Vo's new exhibition in Galleria Italia.",
            isExhibition: false, startDate: date(2026, 11, 28), endDate: nil,
            timeLabel: "2:00 pm – 3:30 pm", price: 10, priceNote: "Talk ticket",
            sourceURL: page("/events/danh-vo-conversation-tom-mcdonough")
        ),
        ArtEventItem(
            id: "ago-open-door-wednesday",
            title: "Open Door Wednesday",
            type: "Special Event",
            imageName: img("ago_card_325/public/2022-12/openDoorimg.jpg?h=96bebde0&itok=K3URkQbt"),
            summary: "The AGO is free on the first Wednesday night of every month. Reserve your spot and walk the whole collection after dark.",
            isExhibition: false, startDate: date(2026, 12, 2), endDate: nil,
            timeLabel: "6:00 pm – 9:00 pm", price: 0, priceNote: "Free admission",
            sourceURL: page("/events/open-door-wednesdays")
        ),
        ArtEventItem(
            id: "ago-drawing-drinks-social",
            title: "Drawing. Drinks. Social.",
            type: "Workshop",
            imageName: img("ago_card_325/public/2023-08/A-172451_rsz-640x512%5B1%5D.jpg?h=aa94de3f&itok=NAhZl-o9"),
            summary: "A drink, conversation, then drawing in the galleries with an AGO artist instructor. All skill levels, 19+. Gallery admission, materials and one drink included. Meet in the Tanenbaum Sculpture Atrium.",
            isExhibition: false, startDate: date(2026, 12, 4), endDate: nil,
            timeLabel: "6:00 pm – 9:00 pm", price: 80, priceNote: "Public ticket · drink & materials included",
            sourceURL: page("/events/drawing.-drinks.-social.")
        ),
        ArtEventItem(
            id: "ago-maker-friday-winter-village",
            title: "Maker Friday: Winter Village",
            type: "Workshop",
            imageName: img("image_medium/public/2026-07/Maker-Night-Winter-Village.jpg?itok=KYIXzdRN"),
            summary: "Build a glowing paper house with simple papercraft and LED lights, then add it to a shared winter village.",
            isExhibition: false, startDate: date(2026, 12, 11), endDate: nil,
            timeLabel: "6:00 pm – 9:00 pm", price: 30, priceNote: "Free with general admission",
            sourceURL: page("/events/maker-friday-winter-village")
        ),
    ]

    static let typeFilters = ["All", "Exhibition", "Talk", "Performance", "Workshop", "Special Event"]
}
