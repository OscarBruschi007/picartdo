import Foundation
import Observation

/// A ticket or registration for an exhibition or event.
struct EventTicket: Codable, Identifiable, Hashable {
    let id: UUID
    let eventID: String
    let eventTitle: String
    let eventType: String
    let imageName: String
    let venue: String
    let address: String
    let visitDate: Date
    let timeLabel: String
    let quantity: Int
    let total: Double
    let confirmation: String
    let purchasedAt: Date

    var isFree: Bool { total == 0 }

    /// What the QR code encodes. Scanned at the door, it identifies this ticket.
    var qrPayload: String {
        let day = visitDate.formatted(.iso8601.year().month().day())
        return "PICARTDO|\(confirmation)|\(eventID)|\(day)|x\(quantity)"
    }
}

/// Tickets the user has bought or registered for, kept on the phone.
/// Demo only: no payment is taken and nothing is sent to the venue.
@Observable
@MainActor
final class EventTicketStore {
    static let shared = EventTicketStore()

    private(set) var tickets: [EventTicket] = []
    private let key = "picartdo.events.tickets"

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([EventTicket].self, from: data) {
            tickets = saved
        }
    }

    /// The most recent ticket for an event, if any.
    func ticket(for event: ArtEventItem) -> EventTicket? {
        tickets.last { $0.eventID == event.id }
    }

    @discardableResult
    func issue(for event: ArtEventItem, on day: Date, quantity: Int) -> EventTicket {
        let ticket = EventTicket(
            id: UUID(),
            eventID: event.id,
            eventTitle: event.title,
            eventType: event.type,
            imageName: event.imageName,
            venue: event.venue,
            address: event.address,
            visitDate: day,
            timeLabel: event.timeLabel(on: day),
            quantity: quantity,
            total: event.price * Double(quantity),
            confirmation: Self.makeConfirmation(),
            purchasedAt: Date()
        )
        tickets.append(ticket)
        save()
        return ticket
    }

    private func save() {
        if let data = try? JSONEncoder().encode(tickets) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func makeConfirmation() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789") // no 0/O or 1/I to misread
        return "PCD-" + String((0..<6).map { _ in alphabet.randomElement()! })
    }
}
