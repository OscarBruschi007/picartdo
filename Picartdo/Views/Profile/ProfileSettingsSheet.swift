import SwiftUI

struct ProfileSettingsSheet: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var confirmSignOut = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    settingsRow("bell", "Notifications")
                    settingsRow("creditcard", "Payment Methods")
                    settingsRow("shippingbox", "Orders & Shipping")
                    settingsRow("lock.shield", "Privacy & Security")
                }

                Section {
                    Button(role: .destructive) {
                        confirmSignOut = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .accessibilityLabel("Sign Out")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Sign out of Picartdo?", isPresented: $confirmSignOut, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await session.signOut()
                        Haptics.success()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func settingsRow(_ icon: String, _ title: String) -> some View {
        NavigationLink {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundStyle(Color.picardoAccent)
                Text(title)
                    .font(.headline)
                Text("You’ll manage this here. Nothing to change yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.picardoBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            Label(title, systemImage: icon)
        }
        .accessibilityLabel(title)
    }
}
