import Foundation
import Observation

@Observable
@MainActor
final class SettingsStore {
    static let shared = SettingsStore()

    var flags: Flags
    var blocked: [BlockedUser]
    var cards: [SavedCard]
    var addresses: [Address]
    var orders: [ShopOrder]
    var reports: [SupportReport]

    private let flagsKey = "picardo.settings.flags.v1"
    private let blockedKey = "picardo.settings.blocked.v1"
    private let cardsKey = "picardo.settings.cards.v1"
    private let addressesKey = "picardo.settings.addresses.v1"
    private let ordersKey = "picardo.settings.orders.v1"
    private let reportsKey = "picardo.settings.reports.v1"

    private init() {
        flags = Self.load(Flags.self, key: "picardo.settings.flags.v1") ?? .defaults
        blocked = Self.load([BlockedUser].self, key: "picardo.settings.blocked.v1") ?? BlockedUser.samples
        cards = Self.load([SavedCard].self, key: "picardo.settings.cards.v1") ?? SavedCard.samples
        addresses = Self.load([Address].self, key: "picardo.settings.addresses.v1") ?? Address.samples
        orders = Self.load([ShopOrder].self, key: "picardo.settings.orders.v1") ?? ShopOrder.samples
        reports = Self.load([SupportReport].self, key: "picardo.settings.reports.v1") ?? []
    }

    func save() {
        Self.write(flags, key: flagsKey)
        Self.write(blocked, key: blockedKey)
        Self.write(cards, key: cardsKey)
        Self.write(addresses, key: addressesKey)
        Self.write(orders, key: ordersKey)
        Self.write(reports, key: reportsKey)
    }

    func block(name: String, handle: String) {
        let user = BlockedUser(id: handle, name: name, handle: handle)
        guard !blocked.contains(where: { $0.handle == handle }) else { return }
        blocked.insert(user, at: 0)
        save()
    }

    func unblock(_ user: BlockedUser) {
        blocked.removeAll { $0.id == user.id }
        save()
    }

    func addCard(_ card: SavedCard) {
        if card.isDefault { cards = cards.map { var c = $0; c.isDefault = false; return c } }
        cards.insert(card, at: 0)
        save()
    }

    func removeCard(_ card: SavedCard) {
        cards.removeAll { $0.id == card.id }
        if !cards.contains(where: \.isDefault), !cards.isEmpty {
            cards[0].isDefault = true
        }
        save()
    }

    func addAddress(_ address: Address) {
        if address.isDefault { addresses = addresses.map { var a = $0; a.isDefault = false; return a } }
        addresses.insert(address, at: 0)
        save()
    }

    func removeAddress(_ address: Address) {
        addresses.removeAll { $0.id == address.id }
        save()
    }

    func cancelOrder(_ order: ShopOrder) {
        guard let index = orders.firstIndex(where: { $0.id == order.id }) else { return }
        orders[index].status = .cancelled
        save()
    }

    func addReport(_ report: SupportReport) {
        reports.insert(report, at: 0)
        save()
    }

    func clearLocalCache() {
        ArtworkImageCache.shared.clear()
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func write<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

extension SettingsStore {
    struct Flags: Codable, Equatable {
        var privateAccount = false
        var showActivityStatus = true
        var allowMessages = true
        /// everyone | following | nobody
        var messageAudience = "everyone"
        var allowMessageRequests = true
        var readReceipts = true
        var allowComments = true
        var allowMentions = true
        var allowTags = true
        var suggestAccount = true
        var notifyPush = true
        var notifyEmail = true
        var notifyLikes = true
        var notifyComments = true
        var notifyFollows = true
        var notifyMessages = true
        var notifyOrders = true
        var notifyPromotions = false
        var pauseAllNotifications = false
        var filterSensitive = true
        var hideLikeCounts = false
        var email = "oscar@picardo.app"
        var phone = ""
        var language = "English"
        var currency = "CAD"
        var measurement = "cm"
        var twoFactor = false
        var loginAlerts = true

        static let defaults = Flags()
    }

    struct BlockedUser: Codable, Identifiable, Equatable, Hashable {
        var id: String
        var name: String
        var handle: String

        static let samples: [BlockedUser] = [
            .init(id: "spamstudio", name: "Spam Studio", handle: "spamstudio"),
        ]
    }

    struct SavedCard: Codable, Identifiable, Equatable, Hashable {
        var id: UUID
        var brand: String
        var last4: String
        var expiry: String
        var isDefault: Bool

        var label: String { "\(brand) •••• \(last4)" }

        static let samples: [SavedCard] = [
            .init(id: UUID(), brand: "Visa", last4: "4242", expiry: "08/28", isDefault: true),
        ]
    }

    struct Address: Codable, Identifiable, Equatable, Hashable {
        var id: UUID
        var label: String
        var line1: String
        var city: String
        var region: String
        var postal: String
        var country: String
        var isDefault: Bool

        var summary: String { "\(line1), \(city)" }

        static let samples: [Address] = [
            .init(
                id: UUID(),
                label: "Studio",
                line1: "240 Richmond St W",
                city: "Toronto",
                region: "ON",
                postal: "M5V 1V6",
                country: "Canada",
                isDefault: true
            ),
        ]
    }

    struct ShopOrder: Codable, Identifiable, Equatable, Hashable {
        var id: UUID
        var title: String
        var artist: String
        var imageName: String
        var amount: Double
        var date: Date
        var status: Status
        var role: Role

        enum Role: String, Codable { case purchase, sale }
        enum Status: String, Codable, CaseIterable { case processing, shipped, delivered, cancelled }

        static let samples: [ShopOrder] = [
            .init(id: UUID(), title: "Circle Worlds", artist: "Oscar Bruschi", imageName: "color_field", amount: 620, date: Date().addingTimeInterval(-86_400 * 4), status: .shipped, role: .sale),
            .init(id: UUID(), title: "Night Watch", artist: "Oscar Bruschi", imageName: "night_watch", amount: 1_100, date: Date().addingTimeInterval(-86_400 * 12), status: .delivered, role: .sale),
            .init(id: UUID(), title: "Floral Horse", artist: "Isla Bennett", imageName: "floral_horse", amount: 400, date: Date().addingTimeInterval(-86_400 * 20), status: .delivered, role: .purchase),
        ]
    }

    struct SupportReport: Codable, Identifiable, Equatable {
        var id: UUID
        var topic: String
        var body: String
        var date: Date
    }
}

