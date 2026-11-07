import Foundation
import Observation
import AuthenticationServices

@Observable
@MainActor
final class SessionStore {
    var profile: UserProfile?
    var isAuthenticated: Bool { profile != nil }
    var isLoading = false
    var authError: String?

    private let client = SupabaseClient.shared

    func bootstrap() async {
        guard AppConfig.isBackendConfigured else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await client.refreshSessionIfNeeded()
            profile = try await client.fetchCurrentUser()
        } catch {
            profile = nil
        }
    }

    func signInWithApple(result: Result<ASAuthorization, Error>) async {
        guard AppConfig.isBackendConfigured else {
            authError = "Backend not configured"
            return
        }
        isLoading = true
        authError = nil
        defer { isLoading = false }

        switch result {
        case .failure(let error):
            authError = PicartdoErrorCopy.signIn(error)
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                authError = "Apple didn\u{2019}t return your sign-in details. Try again."
                return
            }
            do {
                let nonce = AppleSignInNonce.current
                _ = try await client.signInWithApple(
                    idToken: idToken,
                    nonce: nonce,
                    fullName: credential.fullName
                )
                profile = try await client.fetchCurrentUser()
            } catch {
                authError = PicartdoErrorCopy.signIn(error)
            }
        }
    }

    func signInWithEmail(_ email: String) async throws {
        try await client.signInWithEmail(email)
    }

    func signOut() async {
        try? await client.signOut()
        profile = nil
    }

    func refreshProfile() async {
        profile = try? await client.fetchCurrentUser()
    }
}

enum AppleSignInNonce {
    static var current: String = UUID().uuidString
}
