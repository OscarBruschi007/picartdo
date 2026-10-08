import Foundation

// MARK: - Picasso tutor chat message
// Named distinctly from Commerce `ChatMessage` in MessagesView.

struct PicassoChatMessage: Identifiable, Equatable, Codable {
    enum Role: String, Codable {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    var content: String
    let timestamp: Date
    /// Inline error bubble with retry (assistant-side).
    var isError: Bool
    var canRetry: Bool
    /// Server request id, used for thumbs up/down feedback.
    var requestID: UUID?
    /// Listings Picasso recommended, shown as cards under the reply. Not persisted.
    var artworks: [Artwork]
    /// Buy buttons Picasso proposed. The user always confirms. Not persisted.
    var checkoutActions: [PicassoCheckoutAction]
    /// A photo the user attached (JPEG). Not persisted.
    var imageData: Data?

    init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        timestamp: Date = Date(),
        isError: Bool = false,
        canRetry: Bool = false,
        requestID: UUID? = nil,
        artworks: [Artwork] = [],
        checkoutActions: [PicassoCheckoutAction] = [],
        imageData: Data? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isError = isError
        self.canRetry = canRetry
        self.requestID = requestID
        self.artworks = artworks
        self.checkoutActions = checkoutActions
        self.imageData = imageData
    }

    private enum CodingKeys: String, CodingKey {
        case id, role, content, timestamp, isError, canRetry, requestID
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        role = try c.decode(Role.self, forKey: .role)
        content = try c.decode(String.self, forKey: .content)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        isError = try c.decode(Bool.self, forKey: .isError)
        canRetry = try c.decode(Bool.self, forKey: .canRetry)
        requestID = try c.decodeIfPresent(UUID.self, forKey: .requestID)
        artworks = []
        checkoutActions = []
        imageData = nil
    }
}

/// A Buy button Picasso suggested. Tapping it opens the artwork; nothing is charged automatically.
nonisolated struct PicassoCheckoutAction: Identifiable, Equatable, Decodable, Sendable {
    let listingId: UUID
    let title: String
    let price: Double
    var id: UUID { listingId }
}

/// Spec alias — prefer `PicassoChatMessage` in new code.
typealias TutorChatMessage = PicassoChatMessage
