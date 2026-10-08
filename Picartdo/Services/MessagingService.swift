import Foundation

enum MessagingService {
    private static let client = SupabaseClient.shared

    nonisolated struct MessageRow: Decodable, Sendable, Identifiable {
        let id: UUID
        let senderId: UUID
        let recipientId: UUID
        let listingId: UUID?
        let content: String
        let read: Bool
        let createdAt: Date
    }

    nonisolated struct SendPayload: Encodable, Sendable {
        let senderId: UUID
        let recipientId: UUID
        let listingId: UUID?
        let content: String
    }

    static func fetchMessages(with userID: UUID) async throws -> [MessageRow] {
        let sent: [MessageRow] = try await client.select(
            table: "messages",
            query: [
                URLQueryItem(name: "or", value: "(sender_id.eq.\(userID.uuidString),recipient_id.eq.\(userID.uuidString))"),
                URLQueryItem(name: "order", value: "created_at.asc"),
            ],
            type: [MessageRow].self
        )
        return sent
    }

    static func sendMessage(to recipientID: UUID, content: String, listingID: UUID? = nil, senderID: UUID) async throws {
        let payload = SendPayload(
            senderId: senderID,
            recipientId: recipientID,
            listingId: listingID,
            content: content
        )
        _ = try await client.insert(table: "messages", row: payload, returning: MessageRow.self)
    }

    static func loadThread(with userID: UUID, partnerID: UUID) async throws -> [MessageRow] {
        try await client.select(
            table: "messages",
            query: [
                URLQueryItem(
                    name: "or",
                    value: "and(sender_id.eq.\(userID.uuidString),recipient_id.eq.\(partnerID.uuidString)),and(sender_id.eq.\(partnerID.uuidString),recipient_id.eq.\(userID.uuidString))"
                ),
                URLQueryItem(name: "order", value: "created_at.asc"),
            ],
            type: [MessageRow].self
        )
    }

    static func markRead(messageIDs: [UUID]) async throws {
        for id in messageIDs {
            try await client.patch(
                table: "messages",
                query: [URLQueryItem(name: "id", value: "eq.\(id.uuidString)")],
                body: ["read": true]
            )
        }
    }
}
