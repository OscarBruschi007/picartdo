import SwiftUI

struct ProfileSettingsSheet: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var confirmSignOut = false
    @State private var confirmDeactivate = false
    @State private var identity = ProfileIdentity.load()

    private var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        NavigationLink(value: SettingsDestination.account) {
                            accountCard
                        }
                        .buttonStyle(.plain)

                        settingsGroup("Your account", rows: [
                            .link("person.text.rectangle", "Personal information", "Email and phone", .personalInfo),
                            .link("key", "Password", "Change how you sign in", .password),
                            .link("lock.shield", "Security", "Two-factor and login alerts", .security),
                            .link("bell", "Notifications", "Push, email, and in-app", .notifications),
                            .link("eye", "Privacy", "Who can see you and how", .privacy),
                            .link("nosign", "Blocked accounts", "People you have blocked", .blocked),
                            .link("envelope", "Messages", "Who can message you and requests", .messages),
                            .link("bubble.left.and.bubble.right", "Interactions", "Comments and tags", .interactions),
                        ])

                        settingsGroup("Payments", rows: [
                            .link("creditcard", "Payments", "Cards on file", .payments),
                            .link("banknote", "Payouts", "How you get paid", .payouts),
                            .link("bag", "Orders", "Buys, sales, and tracking", .orders),
                            .link("shippingbox", "Shipping addresses", "Where work is sent", .shipping),
                        ])

                        settingsGroup("Content and display", rows: [
                            .link("bookmark", "Saved", "Pieces you want later", .saved),
                            .link("globe", "Language and region", "Language, currency, units", .language),
                            .link("internaldrive", "Data and storage", "Download and cache", .dataStorage),
                        ])

                        settingsGroup("More info and support", rows: [
                            .link("questionmark.circle", "Help", "FAQs and support", .help),
                            .link("exclamationmark.bubble", "Report a problem", "Tell us what’s broken", .report),
                            .link("info.circle", "About", "Version, terms, and PICARDO", .about),
                        ])

                        signOutButton
                            .padding(.top, 8)

                        deactivateButton

                        Text("PICARDO")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                            .padding(.bottom, 36)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                panelShape
                    .fill(.clear)
                    .glassEffect(.regular, in: panelShape)
            }
            .clipShape(panelShape)
            .overlay {
                panelShape.strokeBorder(.white.opacity(0.28), lineWidth: 1)
            }
            .padding(10)
            .background(.clear)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SettingsDestination.self) { destination in
                SettingsDestinationView(destination: destination, identity: $identity)
            }
            .confirmationDialog("Sign out of PICARDO?", isPresented: $confirmSignOut, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await session.signOut()
                        Haptics.success()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog(
                "Deactivate this account?",
                isPresented: $confirmDeactivate,
                titleVisibility: .visible
            ) {
                Button("Deactivate", role: .destructive) {
                    Task {
                        await session.signOut()
                        Haptics.success()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You’ll be signed out on this phone. Your public profile stays until you ask PICARDO to delete it.")
            }
        }
        .background(.clear)
        .environment(SettingsStore.shared)
    }

    private var header: some View {
        HStack {
            Button {
                Haptics.tap()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .picardoGlass(in: Circle(), interactive: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close settings")

            Spacer()

            Text("Settings")
                .font(PicardoType.wordmark(20))
                .foregroundStyle(.primary)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var accountCard: some View {
        HStack(spacing: 14) {
            Group {
                if let photo = identity.avatarImage {
                    Image(uiImage: photo).resizable().scaledToFill()
                } else {
                    ArtworkImage(imageName: identity.avatarAsset, contentMode: .fill, maxDimension: 240)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text(identity.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("@\(identity.handle)")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.28), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Account for \(identity.name), @\(identity.handle)")
        .accessibilityHint("Opens account settings")
    }

    private func settingsGroup(_ title: String, rows: [SettingsRow]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(.secondary)
                .padding(.leading, 6)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    NavigationLink(value: row.destination) {
                        HStack(spacing: 14) {
                            Image(systemName: row.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.title)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.primary)
                                if let subtitle = row.subtitle {
                                    Text(subtitle)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer(minLength: 8)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < rows.count - 1 {
                        Divider()
                            .overlay(.white.opacity(0.18))
                            .padding(.leading, 56)
                    }
                }
            }
            .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.28), lineWidth: 1)
            )
        }
    }

    private var signOutButton: some View {
        Button {
            Haptics.tap()
            confirmSignOut = true
        } label: {
            Text("Log out")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.picardoNeonRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                )
        }
        .buttonStyle(PicardoPressStyle())
        .accessibilityLabel("Log out")
    }

    private var deactivateButton: some View {
        Button {
            Haptics.tap()
            confirmDeactivate = true
        } label: {
            Text("Deactivate account")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Deactivate account")
    }
}

private struct SettingsRow: Identifiable {
    let icon: String
    let title: String
    let subtitle: String?
    let destination: SettingsDestination
    var id: String { destination.rawValue }

    static func link(_ icon: String, _ title: String, _ subtitle: String, _ destination: SettingsDestination) -> SettingsRow {
        SettingsRow(icon: icon, title: title, subtitle: subtitle, destination: destination)
    }
}
