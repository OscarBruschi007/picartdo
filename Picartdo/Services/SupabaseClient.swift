import Foundation

enum SupabaseError: LocalizedError, Sendable {
    case notConfigured
    case unauthorized
    case http(Int, String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Backend not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY."
        case .unauthorized: return "Please sign in to continue."
        case .http(let code, let msg): return "Request failed (\(code)): \(msg)"
        case .decoding(let err): return "Data error: \(err.localizedDescription)"
        }
    }
}

actor SupabaseClient {
    static let shared = SupabaseClient()

    private var accessToken: String?
    private var refreshToken: String?
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
        loadTokens()
    }

    func setSession(access: String?, refresh: String?) {
        accessToken = access
        refreshToken = refresh
        persistTokens()
    }

    var isAuthenticated: Bool { accessToken != nil }

    func currentAccessToken() -> String? { accessToken }

    // MARK: - Auth

    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?) async throws -> AuthSession {
        guard let authURL = AppConfig.authURL else { throw SupabaseError.notConfigured }

        var metadata: [String: String]?
        if let fullName {
            var meta: [String: String] = [:]
            if let given = fullName.givenName { meta["given_name"] = given }
            if let family = fullName.familyName { meta["family_name"] = family }
            if !meta.isEmpty { metadata = meta }
        }

        let payload = AppleSignInPayload(
            provider: "apple",
            idToken: idToken,
            nonce: nonce,
            userMetadata: metadata
        )

        let data = try await postEncodable(
            url: authURL.appendingPathComponent("token"),
            query: [URLQueryItem(name: "grant_type", value: "id_token")],
            body: payload,
            authenticated: false
        )

        let session = try JSONDecoder.supabase.decode(AuthSession.self, from: data)
        setSession(access: session.accessToken, refresh: session.refreshToken)
        return session
    }

    func signInWithEmail(_ email: String) async throws {
        guard let authURL = AppConfig.authURL else { throw SupabaseError.notConfigured }
        _ = try await postEncodable(
            url: authURL.appendingPathComponent("otp"),
            body: OTPSignInPayload(email: email, createUser: true),
            authenticated: false
        )
    }

    func refreshSessionIfNeeded() async throws {
        guard let refresh = refreshToken, let authURL = AppConfig.authURL else { return }
        let data = try await postEncodable(
            url: authURL.appendingPathComponent("token"),
            query: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            body: RefreshTokenPayload(refreshToken: refresh),
            authenticated: false
        )
        let session = try JSONDecoder.supabase.decode(AuthSession.self, from: data)
        setSession(access: session.accessToken, refresh: session.refreshToken)
    }

    func signOut() async throws {
        if let authURL = AppConfig.authURL, accessToken != nil {
            _ = try? await postEncodable(
                url: authURL.appendingPathComponent("logout"),
                body: EmptyPayload(),
                authenticated: true
            )
        }
        setSession(access: nil, refresh: nil)
    }

    func fetchCurrentUser() async throws -> UserProfile? {
        guard let authURL = AppConfig.authURL, accessToken != nil else { return nil }
        let data = try await get(url: authURL.appendingPathComponent("user"), authenticated: true)
        let user = try JSONDecoder.supabase.decode(AuthUser.self, from: data)
        return try await fetchProfile(userID: user.id)
    }

    // MARK: - REST

    func select<T: Decodable & Sendable>(
        table: String,
        query: [URLQueryItem] = [],
        type: T.Type
    ) async throws -> T {
        guard let restURL = AppConfig.restURL else { throw SupabaseError.notConfigured }
        var items = query
        items.append(URLQueryItem(name: "select", value: "*"))
        let url = restURL.appendingPathComponent(table)
        let data = try await get(url: url, query: items, authenticated: true)
        return try JSONDecoder.supabase.decode(T.self, from: data)
    }

    func insert<T: Encodable & Sendable, R: Decodable & Sendable>(
        table: String,
        row: T,
        returning: R.Type
    ) async throws -> R {
        guard let restURL = AppConfig.restURL else { throw SupabaseError.notConfigured }
        let url = restURL.appendingPathComponent(table)
        let data = try await postEncodable(
            url: url,
            query: [URLQueryItem(name: "select", value: "*")],
            body: row,
            authenticated: true,
            preferReturn: true
        )
        if let array = try? JSONDecoder.supabase.decode([R].self, from: data), let first = array.first {
            return first
        }
        return try JSONDecoder.supabase.decode(R.self, from: data)
    }

    func upsert<T: Encodable & Sendable>(
        table: String,
        row: T,
        onConflict: String? = nil
    ) async throws {
        guard let restURL = AppConfig.restURL else { throw SupabaseError.notConfigured }
        var query: [URLQueryItem] = []
        if let onConflict { query.append(URLQueryItem(name: "on_conflict", value: onConflict)) }
        let body = try JSONEncoder.supabase.encode(row)
        _ = try await request(
            method: "POST",
            url: restURL.appendingPathComponent(table),
            query: query,
            body: body,
            authenticated: true,
            extraHeaders: ["Prefer": "resolution=merge-duplicates"]
        )
    }

    func delete(table: String, query: [URLQueryItem]) async throws {
        guard let restURL = AppConfig.restURL else { throw SupabaseError.notConfigured }
        _ = try await request(
            method: "DELETE",
            url: restURL.appendingPathComponent(table),
            query: query,
            body: nil,
            authenticated: true
        )
    }

    func patch<T: Encodable & Sendable>(table: String, query: [URLQueryItem], body: T) async throws {
        guard let restURL = AppConfig.restURL else { throw SupabaseError.notConfigured }
        let encoded = try JSONEncoder.supabase.encode(body)
        _ = try await request(
            method: "PATCH",
            url: restURL.appendingPathComponent(table),
            query: query,
            body: encoded,
            authenticated: true
        )
    }

    // MARK: - Edge Functions

    func invokeFunction<T: Decodable & Sendable>(_ name: String, body: [String: Any], type: T.Type) async throws -> T {
        guard let functionsURL = AppConfig.functionsURL else { throw SupabaseError.notConfigured }
        let url = functionsURL.appendingPathComponent(name)
        let data = try await postJSON(url: url, body: body, authenticated: true)
        return try JSONDecoder.supabase.decode(T.self, from: data)
    }

    func invokeFunction(_ name: String, body: [String: Any]) async throws -> Data {
        guard let functionsURL = AppConfig.functionsURL else { throw SupabaseError.notConfigured }
        return try await postJSON(url: functionsURL.appendingPathComponent(name), body: body, authenticated: true)
    }

    // MARK: - Storage

    func uploadFile(bucket: String, path: String, data: Data, contentType: String) async throws -> String {
        guard let storageURL = AppConfig.storageURL else { throw SupabaseError.notConfigured }
        let url = storageURL
            .appendingPathComponent("object")
            .appendingPathComponent("\(bucket)/\(path)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "x-upsert")
        applyAuthHeaders(&request)

        let (responseData, response) = try await session.data(for: request)
        try validate(response: response, data: responseData)

        guard let publicURL = AppConfig.supabaseURL?
            .appendingPathComponent("storage/v1/object/public/\(bucket)/\(path)") else {
            throw SupabaseError.notConfigured
        }
        return publicURL.absoluteString
    }

    // MARK: - HTTP Helpers

    private func get(url: URL, query: [URLQueryItem] = [], authenticated: Bool) async throws -> Data {
        try await request(method: "GET", url: url, query: query, body: nil, authenticated: authenticated)
    }

    private func postEncodable<T: Encodable>(
        url: URL,
        query: [URLQueryItem] = [],
        body: T,
        authenticated: Bool,
        preferReturn: Bool = false
    ) async throws -> Data {
        var headers: [String: String] = [:]
        if preferReturn { headers["Prefer"] = "return=representation" }
        let encoded = try JSONEncoder.supabase.encode(body)
        return try await request(
            method: "POST",
            url: url,
            query: query,
            body: encoded,
            authenticated: authenticated,
            extraHeaders: headers
        )
    }

    private func postJSON(
        url: URL,
        query: [URLQueryItem] = [],
        body: [String: Any],
        authenticated: Bool
    ) async throws -> Data {
        let encoded = try JSONSerialization.data(withJSONObject: body)
        return try await request(method: "POST", url: url, query: query, body: encoded, authenticated: authenticated)
    }

    private func request(
        method: String,
        url: URL,
        query: [URLQueryItem] = [],
        body: Data?,
        authenticated: Bool,
        extraHeaders: [String: String] = [:]
    ) async throws -> Data {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        guard let finalURL = components.url else { throw SupabaseError.notConfigured }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        for (k, v) in extraHeaders { request.setValue(v, forHTTPHeaderField: k) }
        applyAuthHeaders(&request, authenticated: authenticated)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return data
    }

    private func applyAuthHeaders(_ request: inout URLRequest, authenticated: Bool = true) {
        if let key = AppConfig.supabaseAnonKey {
            request.setValue(key, forHTTPHeaderField: "apikey")
        }
        if authenticated, let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if let key = AppConfig.supabaseAnonKey {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            if http.statusCode == 401 { throw SupabaseError.unauthorized }
            throw SupabaseError.http(http.statusCode, msg)
        }
    }

    private func persistTokens() {
        let defaults = UserDefaults.standard
        defaults.set(accessToken, forKey: "picartdo.accessToken")
        defaults.set(refreshToken, forKey: "picartdo.refreshToken")
    }

    private func loadTokens() {
        let defaults = UserDefaults.standard
        accessToken = defaults.string(forKey: "picartdo.accessToken")
        refreshToken = defaults.string(forKey: "picartdo.refreshToken")
    }
}

// MARK: - Auth Payloads

nonisolated private struct AppleSignInPayload: Encodable {
    let provider: String
    let idToken: String
    let nonce: String
    let userMetadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case provider
        case idToken = "id_token"
        case nonce
        case userMetadata = "user_metadata"
    }
}

nonisolated private struct OTPSignInPayload: Encodable {
    let email: String
    let createUser: Bool

    enum CodingKeys: String, CodingKey {
        case email
        case createUser = "create_user"
    }
}

nonisolated private struct RefreshTokenPayload: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

nonisolated private struct EmptyPayload: Encodable {}

extension JSONDecoder {
    static let supabase: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

extension JSONEncoder {
    static let supabase: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()
}

nonisolated struct AuthSession: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let user: AuthUser
}

nonisolated struct AuthUser: Decodable, Sendable {
    let id: UUID
    let email: String?
}

nonisolated struct UserProfile: Codable, Identifiable, Sendable {
    let id: UUID
    var email: String?
    var fullName: String?
    var username: String?
    var avatarUrl: String?
    var bannerUrl: String?
    var userType: String?
    var bio: String?
    var tagline: String?
    var location: String?
    var verified: Bool?
    var stripeIdentityVerified: Bool?
    var stripeAccountId: String?
    var stripeCustomerId: String?
    var onboardingCompleted: Bool?
    var proSubscriptionStatus: String?
}

extension SupabaseClient {
    func fetchProfile(userID: UUID) async throws -> UserProfile? {
        let profiles: [UserProfile] = try await select(
            table: "users",
            query: [URLQueryItem(name: "id", value: "eq.\(userID.uuidString)")],
            type: [UserProfile].self
        )
        return profiles.first
    }
}
