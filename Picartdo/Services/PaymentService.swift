import Foundation
import PassKit

nonisolated struct PaymentIntentResponse: Decodable, Sendable {
    let orderId: UUID
    let clientSecret: String?
    let checkoutUrl: String?
    let amount: Double
    let platformFee: Double
    let status: String?
    let error: String?
    let message: String?
}

nonisolated struct SavedPaymentMethod: Decodable, Identifiable, Sendable {
    let id: UUID
    let stripePaymentMethodId: String
    let brand: String?
    let last4: String?
    let expMonth: Int?
    let expYear: Int?
    let isDefault: Bool?
}

nonisolated struct PaymentMethodsResponse: Decodable, Sendable {
    let paymentMethods: [SavedPaymentMethod]
}

enum PaymentService {
    private static let client = SupabaseClient.shared

    static func createPayment(
        listingID: UUID,
        shippingAddress: [String: String],
        useCheckout: Bool = true
    ) async throws -> PaymentIntentResponse {
        try await client.invokeFunction(
            "create-payment-intent",
            body: [
                "listing_id": listingID.uuidString,
                "shipping_address": shippingAddress,
                "use_checkout": useCheckout,
            ],
            type: PaymentIntentResponse.self
        )
    }

    static func fetchSavedPaymentMethods() async throws -> [SavedPaymentMethod] {
        let response: PaymentMethodsResponse = try await client.invokeFunction(
            "payment-methods",
            body: ["action": "list"],
            type: PaymentMethodsResponse.self
        )
        return response.paymentMethods
    }

    static func createSetupIntent() async throws -> String {
        nonisolated struct SetupResponse: Decodable, Sendable { let clientSecret: String }
        let response: SetupResponse = try await client.invokeFunction(
            "payment-methods",
            body: [String: Any](),
            type: SetupResponse.self
        )
        return response.clientSecret
    }

    static func isApplePayAvailable() -> Bool {
        PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex])
    }
}

enum ConnectService {
    private static let client = SupabaseClient.shared

nonisolated struct ConnectResponse: Decodable, Sendable {
        let url: String
        let accountId: String
    }

    static func startOnboarding() async throws -> URL {
        let response: ConnectResponse = try await client.invokeFunction(
            "create-connect-account",
            body: [String: Any](),
            type: ConnectResponse.self
        )
        guard let url = URL(string: response.url) else {
            throw SupabaseError.http(500, "Invalid connect URL")
        }
        return url
    }
}

enum IdentityService {
    private static let client = SupabaseClient.shared

nonisolated struct IdentityResponse: Decodable, Sendable {
        let sessionId: String
        let url: String?
        let clientSecret: String?
    }

    static func startVerification(purpose: String = "artist") async throws -> URL? {
        let response: IdentityResponse = try await client.invokeFunction(
            "create-identity-session",
            body: ["purpose": purpose],
            type: IdentityResponse.self
        )
        guard let urlString = response.url, let url = URL(string: urlString) else { return nil }
        return url
    }
}

enum CommissionService {
    private static let client = SupabaseClient.shared

nonisolated struct CommissionResponse: Decodable, Sendable {
        let commission: CommissionRow
    }

nonisolated struct CommissionRow: Decodable, Sendable {
        let id: UUID
    }

    static func submit(
        artistID: UUID,
        name: String,
        email: String,
        style: String,
        size: String,
        timeline: String,
        budget: String,
        description: String,
        referenceNote: String
    ) async throws -> UUID {
        let response: CommissionResponse = try await client.invokeFunction(
            "create-commission",
            body: [
                "artist_id": artistID.uuidString,
                "guest_name": name,
                "guest_email": email,
                "style": style,
                "size": size,
                "timeline": timeline,
                "budget": budget,
                "description": description,
                "reference_note": referenceNote,
            ],
            type: CommissionResponse.self
        )
        return response.commission.id
    }
}
