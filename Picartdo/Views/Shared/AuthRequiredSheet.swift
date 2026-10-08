import SwiftUI
import AuthenticationServices
import SafariServices

/// Presents sign-in when backend actions require auth — does not alter main layout.
struct AuthRequiredSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var session

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Text("Sign in to continue")
                    .font(.system(size: 22, weight: .bold))
                Text("Create an account or sign in with Apple to buy, sell, and message artists.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                SignInWithAppleButton(.signIn) { request in
                    AppleSignInNonce.current = UUID().uuidString
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task {
                        await session.signInWithApple(result: result)
                        if session.isAuthenticated { dismiss() }
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal, 32)

                if let error = session.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 32)
                }
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

/// Opens Stripe Checkout or Identity verification in Safari — keeps checkout UI unchanged.
struct SafariSheet: UIViewControllerRepresentable {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) { dismiss() }
    }
}
