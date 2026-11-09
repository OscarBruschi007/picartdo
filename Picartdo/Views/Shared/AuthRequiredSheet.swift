import SwiftUI
import AuthenticationServices
import SafariServices

/// Presents sign-in when backend actions require auth — does not alter main layout.
struct AuthRequiredSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var session

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                Text("P")
                    .font(.system(size: 44, weight: .bold, design: .serif))
                    .foregroundStyle(Color.picardoNeonRed)
                    .frame(width: 84, height: 84)
                    .background(Color.picardoCream, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                    .accessibilityHidden(true)

                Text("Sign in to Picartdo")
                    .font(.system(size: 26, weight: .black, design: .serif))
                    .foregroundStyle(Color.picardoText)
                    .padding(.top, 22)

                Text("One account to save pieces, message artists, and buy or sell art.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 36)

                Spacer()

                SignInWithAppleButton(.continue) { request in
                    AppleSignInNonce.current = UUID().uuidString
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task {
                        await session.signInWithApple(result: result)
                        if session.isAuthenticated { dismiss() }
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .clipShape(Capsule())
                .padding(.horizontal, 28)

                if let error = session.authError {
                    Label(error, systemImage: "exclamationmark.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.picardoNeonRed)
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                        .padding(.horizontal, 28)
                }

                PicartdoLegalNote()
                    .padding(.top, 14)
                    .padding(.horizontal, 36)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
            .background {
                // Someone at an easel, painting quietly behind the sign-in.
                PainterBackgroundView()
                    .frame(maxWidth: 380, maxHeight: 320)
                    .opacity(0.13)
                    .padding(.top, 120)
            }
            .background(Color.picardoBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Not Now") { dismiss() }
                        .foregroundStyle(Color.picardoTextSecondary)
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
