import SwiftUI
import UIKit

enum SettingsDestination: String, Hashable, Identifiable {
    case account, personalInfo, password, security
    case notifications, privacy, blocked, interactions, messages
    case payments, payouts, orders, shipping
    case saved, language, dataStorage
    case help, about, terms, privacyPolicy, report
    var id: String { rawValue }
}

struct SettingsChrome<Content: View>: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder var content: Content

    private var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    Haptics.tap()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .picardoGlass(in: Circle(), interactive: true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer()

                Text(title)
                    .font(PicardoType.wordmark(18))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)

            ScrollView(showsIndicators: false) {
                content
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
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
    }
}

struct SettingsCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.28), lineWidth: 1)
            )
    }
}

struct SettingsToggleRow: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    var onChange: () -> Void = {}

    var body: some View {
        Toggle(isOn: Binding(
            get: { isOn },
            set: { isOn = $0; onChange() }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(Color.picardoGold)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

struct SettingsInfoRow: View {
    let title: String
    var value: String = ""

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }
}

struct SettingsDivider: View {
    var body: some View {
        Divider()
            .overlay(.white.opacity(0.18))
            .padding(.leading, 14)
    }
}

struct SettingsDestinationView: View {
    let destination: SettingsDestination
    @Binding var identity: ProfileIdentity

    var body: some View {
        switch destination {
        case .account: AccountSettingsView(identity: $identity)
        case .personalInfo: PersonalInfoSettingsView()
        case .password: PasswordSettingsView()
        case .security: SecuritySettingsView()
        case .notifications: NotificationSettingsView()
        case .privacy: PrivacySettingsView()
        case .blocked: BlockedAccountsView()
        case .interactions: InteractionSettingsView()
        case .messages: SettingsChrome(title: "Messages") { MessageSettingsForm() }
        case .payments: PaymentsSettingsView()
        case .payouts: PayoutsSettingsView()
        case .orders: OrdersSettingsView()
        case .shipping: ShippingSettingsView()
        case .saved: SavedSettingsView()
        case .language: LanguageSettingsView()
        case .dataStorage: DataAndStorageView()
        case .help: HelpSettingsView()
        case .about: AboutSettingsView()
        case .terms: LegalSettingsView(title: "Terms of use", copy: LegalCopy.terms)
        case .privacyPolicy: LegalSettingsView(title: "Privacy policy", copy: LegalCopy.privacy)
        case .report: ReportProblemView()
        }
    }
}

// MARK: - Account

struct AccountSettingsView: View {
    @Binding var identity: ProfileIdentity
    @State private var showEdit = false

    var body: some View {
        SettingsChrome(title: "Account") {
            VStack(alignment: .leading, spacing: 16) {
                SettingsCard {
                    SettingsInfoRow(title: "Name", value: identity.name)
                    SettingsDivider()
                    SettingsInfoRow(title: "Username", value: "@\(identity.handle)")
                    SettingsDivider()
                    SettingsInfoRow(title: "Studio", value: identity.studioCity)
                    SettingsDivider()
                    SettingsInfoRow(title: "Joined", value: String(identity.sinceYear))
                }

                Button {
                    showEdit = true
                } label: {
                    Text("Edit public profile")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                )
                .buttonStyle(PicardoPressStyle())

                SettingsCard {
                    SettingsToggleRow(
                        title: "Professional account",
                        subtitle: "Commissions and a public shop",
                        isOn: $identity.commissionsOpen
                    ) {
                        identity.save()
                    }
                    SettingsDivider()
                    SettingsToggleRow(
                        title: "Ships worldwide",
                        isOn: $identity.shipsWorldwide
                    ) {
                        identity.save()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showEdit) {
            EditProfileSheet(identity: $identity, isPresented: $showEdit)
                .presentationBackground(.clear)
        }
    }
}

struct PersonalInfoSettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var email = ""
    @State private var phone = ""
    @State private var saved = false

    var body: some View {
        SettingsChrome(title: "Personal information") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Only you can see this. It is used for receipts, shipping, and account recovery.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                SettingsCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .foregroundStyle(.primary)
                    }
                    .padding(14)
                    SettingsDivider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        TextField("Phone", text: $phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                            .foregroundStyle(.primary)
                    }
                    .padding(14)
                }

                Button("Save") {
                    settings.flags.email = email.trimmingCharacters(in: .whitespaces)
                    settings.flags.phone = phone.trimmingCharacters(in: .whitespaces)
                    settings.save()
                    saved = true
                    Haptics.success()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                )

                if saved {
                    Text("Saved.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.picardoGold)
                }
            }
        }
        .onAppear {
            email = settings.flags.email
            phone = settings.flags.phone
        }
    }
}

struct PasswordSettingsView: View {
    @Environment(SessionStore.self) private var session
    @State private var current = ""
    @State private var next = ""
    @State private var confirm = ""
    @State private var message = ""

    var body: some View {
        SettingsChrome(title: "Password") {
            VStack(alignment: .leading, spacing: 16) {
                Text(session.profile?.email == nil
                     ? "You’re signed in with Apple. A Picartdo password is optional for email login."
                     : "Change the password for \(session.profile?.email ?? "your account").")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                SettingsCard {
                    SecureField("Current password", text: $current)
                        .padding(14)
                    SettingsDivider()
                    SecureField("New password", text: $next)
                        .padding(14)
                    SettingsDivider()
                    SecureField("Confirm new password", text: $confirm)
                        .padding(14)
                }

                Button("Update password") {
                    if next.count < 8 {
                        message = "Use at least 8 characters."
                    } else if next != confirm {
                        message = "The new passwords don’t match."
                    } else {
                        message = "Password updated."
                        current = ""; next = ""; confirm = ""
                        Haptics.success()
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                )

                if !message.isEmpty {
                    Text(message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(message.contains("updated") ? Color.picardoGold : Color.picardoNeonRed)
                }
            }
        }
    }
}

struct SecuritySettingsView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        let store = settings
        SettingsChrome(title: "Security") {
            VStack(alignment: .leading, spacing: 16) {
                SettingsCard {
                    SettingsToggleRow(
                        title: "Two-factor authentication",
                        subtitle: "Ask for a code when you log in",
                        isOn: Binding(get: { store.flags.twoFactor }, set: { store.flags.twoFactor = $0; store.save() })
                    )
                    SettingsDivider()
                    SettingsToggleRow(
                        title: "Login alerts",
                        subtitle: "Email you when a new device signs in",
                        isOn: Binding(get: { store.flags.loginAlerts }, set: { store.flags.loginAlerts = $0; store.save() })
                    )
                }

                SettingsCard {
                    SettingsInfoRow(title: "This device", value: "iPhone · Toronto")
                    SettingsDivider()
                    SettingsInfoRow(title: "Last login", value: "Today")
                }
            }
        }
    }
}

// MARK: - Privacy / notifications / interactions

struct NotificationSettingsView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        let store = settings
        let muted = store.flags.pauseAllNotifications
        SettingsChrome(title: "Notifications") {
            VStack(alignment: .leading, spacing: 16) {
                SettingsCard {
                    SettingsToggleRow(
                        title: "Pause all",
                        subtitle: "Mute likes, comments, orders, and messages",
                        isOn: Binding(get: { store.flags.pauseAllNotifications }, set: { store.flags.pauseAllNotifications = $0; store.save() })
                    )
                }

                SettingsCard {
                    SettingsToggleRow(title: "Push notifications", isOn: Binding(get: { store.flags.notifyPush }, set: { store.flags.notifyPush = $0; store.save() }))
                    SettingsDivider()
                    SettingsToggleRow(title: "Email", isOn: Binding(get: { store.flags.notifyEmail }, set: { store.flags.notifyEmail = $0; store.save() }))
                }
                .disabled(muted)
                .opacity(muted ? 0.45 : 1)

                SettingsCard {
                    SettingsToggleRow(title: "Likes and saves", isOn: Binding(get: { store.flags.notifyLikes }, set: { store.flags.notifyLikes = $0; store.save() }))
                    SettingsDivider()
                    SettingsToggleRow(title: "Comments", isOn: Binding(get: { store.flags.notifyComments }, set: { store.flags.notifyComments = $0; store.save() }))
                    SettingsDivider()
                    SettingsToggleRow(title: "New followers", isOn: Binding(get: { store.flags.notifyFollows }, set: { store.flags.notifyFollows = $0; store.save() }))
                    SettingsDivider()
                    SettingsToggleRow(title: "Messages", isOn: Binding(get: { store.flags.notifyMessages }, set: { store.flags.notifyMessages = $0; store.save() }))
                    SettingsDivider()
                    SettingsToggleRow(title: "Orders and shipping", isOn: Binding(get: { store.flags.notifyOrders }, set: { store.flags.notifyOrders = $0; store.save() }))
                    SettingsDivider()
                    SettingsToggleRow(title: "Promotions", isOn: Binding(get: { store.flags.notifyPromotions }, set: { store.flags.notifyPromotions = $0; store.save() }))
                }
                .disabled(muted)
                .opacity(muted ? 0.45 : 1)
            }
        }
    }
}

struct PrivacySettingsView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        let store = settings
        SettingsChrome(title: "Privacy") {
            VStack(alignment: .leading, spacing: 16) {
                SettingsCard {
                    SettingsToggleRow(
                        title: "Private account",
                        subtitle: "Approve who follows you",
                        isOn: Binding(get: { store.flags.privateAccount }, set: { store.flags.privateAccount = $0; store.save() })
                    )
                    SettingsDivider()
                    SettingsToggleRow(
                        title: "Activity status",
                        subtitle: "Show when you were last on Picartdo",
                        isOn: Binding(get: { store.flags.showActivityStatus }, set: { store.flags.showActivityStatus = $0; store.save() })
                    )
                    SettingsDivider()
                    SettingsToggleRow(
                        title: "Suggest your account",
                        subtitle: "Let Picartdo recommend you to collectors",
                        isOn: Binding(get: { store.flags.suggestAccount }, set: { store.flags.suggestAccount = $0; store.save() })
                    )
                    SettingsDivider()
                    SettingsToggleRow(
                        title: "Hide like counts",
                        isOn: Binding(get: { store.flags.hideLikeCounts }, set: { store.flags.hideLikeCounts = $0; store.save() })
                    )
                    SettingsDivider()
                    SettingsToggleRow(
                        title: "Filter sensitive content",
                        isOn: Binding(get: { store.flags.filterSensitive }, set: { store.flags.filterSensitive = $0; store.save() })
                    )
                }

                NavigationLink(value: SettingsDestination.blocked) {
                    SettingsInfoRow(title: "Blocked accounts", value: "\(store.blocked.count)")
                }
                .buttonStyle(.plain)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                )
            }
        }
    }
}

struct BlockedAccountsView: View {
    @Environment(SettingsStore.self) private var settings

    private var candidates: [Artist] {
        Artist.all.filter { artist in
            !settings.blocked.contains { $0.handle == artist.username }
        }
    }

    var body: some View {
        SettingsChrome(title: "Blocked accounts") {
            VStack(alignment: .leading, spacing: 16) {
                if settings.blocked.isEmpty {
                    Text("You haven’t blocked anyone.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                } else {
                    SettingsCard {
                        ForEach(Array(settings.blocked.enumerated()), id: \.element.id) { index, user in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.primary)
                                    Text("@\(user.handle)")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Unblock") {
                                    settings.unblock(user)
                                    Haptics.select()
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.picardoGold)
                            }
                            .padding(14)
                            if index < settings.blocked.count - 1 { SettingsDivider() }
                        }
                    }
                }

                Menu {
                    ForEach(candidates.prefix(20), id: \.username) { artist in
                        Button(artist.name) {
                            settings.block(name: artist.name, handle: artist.username)
                            Haptics.success()
                        }
                    }
                } label: {
                    Text("Block an account")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                        )
                }
            }
        }
    }
}

struct InteractionSettingsView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        let store = settings
        SettingsChrome(title: "Interactions") {
            VStack(alignment: .leading, spacing: 16) {
                NavigationLink(value: SettingsDestination.messages) {
                    SettingsInfoRow(title: "Message settings", value: "Who can reach you")
                }
                .buttonStyle(.plain)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                )

                SettingsCard {
                    SettingsToggleRow(
                        title: "Comments",
                        isOn: Binding(get: { store.flags.allowComments }, set: { store.flags.allowComments = $0; store.save() })
                    )
                    SettingsDivider()
                    SettingsToggleRow(
                        title: "Mentions",
                        isOn: Binding(get: { store.flags.allowMentions }, set: { store.flags.allowMentions = $0; store.save() })
                    )
                    SettingsDivider()
                    SettingsToggleRow(
                        title: "Tags on listings",
                        isOn: Binding(get: { store.flags.allowTags }, set: { store.flags.allowTags = $0; store.save() })
                    )
                }
            }
        }
    }
}

struct MessageSettingsForm: View {
    @Environment(SettingsStore.self) private var settings

    private var audience: String {
        settings.flags.messageAudience
    }

    var body: some View {
        let store = settings
        VStack(alignment: .leading, spacing: 16) {
            Text("Who can message you")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            SettingsCard {
                audienceRow("Everyone", value: "everyone", detail: "Anyone on Picartdo")
                SettingsDivider()
                audienceRow("Friends", value: "friends", detail: "Muses and people who muse you")
                SettingsDivider()
                audienceRow("People you follow", value: "following", detail: "Your muses and buyers")
                SettingsDivider()
                audienceRow("No one", value: "nobody", detail: "Turn messages off")
            }

            Text("Marketplace")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .padding(.top, 4)

            SettingsCard {
                SettingsToggleRow(
                    title: "Marketplace messages",
                    subtitle: "Collectors can message you about a listing",
                    isOn: Binding(get: { store.flags.allowMarketplaceMessages }, set: { store.flags.allowMarketplaceMessages = $0; store.save() })
                )
                SettingsDivider()
                SettingsToggleRow(
                    title: "Offers in Marketplace",
                    subtitle: "Keep offers and sales in the Marketplace tab",
                    isOn: Binding(get: { store.flags.marketplaceOffersInInbox }, set: { store.flags.marketplaceOffersInInbox = $0; store.save() })
                )
                SettingsDivider()
                SettingsToggleRow(
                    title: "Order messages",
                    subtitle: "Buyers can ask about shipping and orders",
                    isOn: Binding(get: { store.flags.allowOrderMessages }, set: { store.flags.allowOrderMessages = $0; store.save() })
                )
            }

            SettingsCard {
                SettingsToggleRow(
                    title: "Message requests",
                    subtitle: "Others can still send a request",
                    isOn: Binding(get: { store.flags.allowMessageRequests }, set: { store.flags.allowMessageRequests = $0; store.save() })
                )
                SettingsDivider()
                SettingsToggleRow(
                    title: "Read receipts",
                    subtitle: "Let people see when you read a message",
                    isOn: Binding(get: { store.flags.readReceipts }, set: { store.flags.readReceipts = $0; store.save() })
                )
                SettingsDivider()
                SettingsToggleRow(
                    title: "Activity status",
                    subtitle: "Show when you were last active",
                    isOn: Binding(get: { store.flags.showActivityStatus }, set: { store.flags.showActivityStatus = $0; store.save() })
                )
                SettingsDivider()
                SettingsToggleRow(
                    title: "Message notifications",
                    isOn: Binding(get: { store.flags.notifyMessages }, set: { store.flags.notifyMessages = $0; store.save() })
                )
            }
        }
    }

    private func audienceRow(_ title: String, value: String, detail: String) -> some View {
        let selected = settings.flags.messageAudience == value
        return Button {
            Haptics.select()
            settings.flags.messageAudience = value
            settings.flags.allowMessages = value != "nobody"
            settings.save()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.picardoGold)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Marketplace

struct PaymentsSettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var showAdd = false
    @State private var last4 = ""
    @State private var expiry = ""
    @State private var brand = "Visa"

    var body: some View {
        SettingsChrome(title: "Payments") {
            VStack(alignment: .leading, spacing: 16) {
                if settings.cards.isEmpty {
                    Text("No cards on file.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                } else {
                    SettingsCard {
                        ForEach(Array(settings.cards.enumerated()), id: \.element.id) { index, card in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(card.label)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.primary)
                                    Text(card.isDefault ? "Default · \(card.expiry)" : card.expiry)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Remove") {
                                    settings.removeCard(card)
                                    Haptics.select()
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.picardoNeonRed)
                            }
                            .padding(14)
                            if index < settings.cards.count - 1 { SettingsDivider() }
                        }
                    }
                }

                Button("Add a card") { showAdd = true }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                    )
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                Form {
                    Picker("Brand", selection: $brand) {
                        Text("Visa").tag("Visa")
                        Text("Mastercard").tag("Mastercard")
                        Text("Amex").tag("Amex")
                    }
                    TextField("Last 4 digits", text: $last4)
                        .keyboardType(.numberPad)
                    TextField("Expiry MM/YY", text: $expiry)
                }
                .navigationTitle("Add card")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showAdd = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let digits = String(last4.filter(\.isNumber).suffix(4))
                            guard digits.count == 4 else { return }
                            settings.addCard(.init(id: UUID(), brand: brand, last4: digits, expiry: expiry.isEmpty ? "12/28" : expiry, isDefault: settings.cards.isEmpty))
                            Haptics.success()
                            showAdd = false
                            last4 = ""; expiry = ""
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

struct PayoutsSettingsView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        SettingsChrome(title: "Payouts") {
            VStack(alignment: .leading, spacing: 16) {
                SettingsCard {
                    SettingsInfoRow(title: "Payouts to", value: settings.cards.first(where: \.isDefault)?.label ?? "Add a card")
                    SettingsDivider()
                    SettingsInfoRow(title: "Currency", value: settings.flags.currency)
                    SettingsDivider()
                    SettingsInfoRow(title: "Schedule", value: "Weekly")
                    SettingsDivider()
                    SettingsInfoRow(title: "Next payout", value: "Friday")
                }
                Text("Sales settle to your default card. Picartdo holds funds until the collector confirms delivery.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct OrdersSettingsView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        SettingsChrome(title: "Orders") {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(settings.orders) { order in
                    SettingsCard {
                        HStack(alignment: .top, spacing: 12) {
                            ArtworkImage(imageName: order.imageName, contentMode: .fill, maxDimension: 200)
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(order.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text(order.role == .sale ? "Sold to a collector" : "Bought from \(order.artist)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                Text(order.status.rawValue.capitalized)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.picardoGold)
                            }
                            Spacer()
                            Text(order.amount.formatted(.currency(code: settings.flags.currency).precision(.fractionLength(0))))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.picardoNeonRed)
                        }
                        .padding(14)
                        if order.status == .processing {
                            SettingsDivider()
                            Button("Cancel order") {
                                settings.cancelOrder(order)
                                Haptics.select()
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.picardoNeonRed)
                            .padding(14)
                        }
                    }
                }
            }
        }
    }
}

struct ShippingSettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var showAdd = false
    @State private var label = "Home"
    @State private var line1 = ""
    @State private var city = ""
    @State private var region = ""
    @State private var postal = ""

    var body: some View {
        SettingsChrome(title: "Shipping addresses") {
            VStack(alignment: .leading, spacing: 16) {
                SettingsCard {
                    ForEach(Array(settings.addresses.enumerated()), id: \.element.id) { index, address in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(address.label + (address.isDefault ? " · Default" : ""))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text(address.summary)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                Text("\(address.region) \(address.postal), \(address.country)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Remove") {
                                settings.removeAddress(address)
                                Haptics.select()
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.picardoNeonRed)
                        }
                        .padding(14)
                        if index < settings.addresses.count - 1 { SettingsDivider() }
                    }
                }

                Button("Add an address") { showAdd = true }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                    )
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                Form {
                    TextField("Label", text: $label)
                    TextField("Street", text: $line1)
                    TextField("City", text: $city)
                    TextField("Province / state", text: $region)
                    TextField("Postal code", text: $postal)
                }
                .navigationTitle("New address")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showAdd = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            guard !line1.isEmpty, !city.isEmpty else { return }
                            settings.addAddress(.init(
                                id: UUID(),
                                label: label.isEmpty ? "Home" : label,
                                line1: line1,
                                city: city,
                                region: region,
                                postal: postal,
                                country: "Canada",
                                isDefault: settings.addresses.isEmpty
                            ))
                            Haptics.success()
                            showAdd = false
                            line1 = ""; city = ""; region = ""; postal = ""
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

struct SavedSettingsView: View {
    @Environment(WishlistStore.self) private var wishlist

    private var items: [Artwork] {
        Artwork.samples.filter { wishlist.isLiked($0) }
    }

    var body: some View {
        SettingsChrome(title: "Saved") {
            if items.isEmpty {
                Text("Pieces you save will live here.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(items) { art in
                        HStack(spacing: 12) {
                            ArtworkImage(artwork: art, contentMode: .fill, maxDimension: 240)
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(art.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text(art.artistName)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                wishlist.toggle(art)
                            } label: {
                                Image(systemName: "bookmark.fill")
                                    .foregroundStyle(Color.picardoGold)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
    }
}

struct LanguageSettingsView: View {
    @Environment(SettingsStore.self) private var settings
    private let languages = ["English", "Français", "Español", "Português"]
    private let currencies = ["CAD", "USD", "EUR", "GBP"]
    private let measures = ["cm", "in"]

    var body: some View {
        let store = settings
        SettingsChrome(title: "Language and region") {
            VStack(alignment: .leading, spacing: 16) {
                SettingsCard {
                    ForEach(languages, id: \.self) { item in
                        Button {
                            store.flags.language = item
                            store.save()
                            Haptics.select()
                        } label: {
                            SettingsInfoRow(title: item, value: store.flags.language == item ? "✓" : "")
                        }
                        .buttonStyle(.plain)
                        if item != languages.last { SettingsDivider() }
                    }
                }
                SettingsCard {
                    ForEach(currencies, id: \.self) { item in
                        Button {
                            store.flags.currency = item
                            store.save()
                            Haptics.select()
                        } label: {
                            SettingsInfoRow(title: item, value: store.flags.currency == item ? "✓" : "")
                        }
                        .buttonStyle(.plain)
                        if item != currencies.last { SettingsDivider() }
                    }
                }
                SettingsCard {
                    ForEach(measures, id: \.self) { item in
                        Button {
                            store.flags.measurement = item
                            store.save()
                            Haptics.select()
                        } label: {
                            SettingsInfoRow(title: item == "cm" ? "Centimetres" : "Inches", value: store.flags.measurement == item ? "✓" : "")
                        }
                        .buttonStyle(.plain)
                        if item != measures.last { SettingsDivider() }
                    }
                }
            }
        }
    }
}

// MARK: - Support

struct HelpSettingsView: View {
    private let faqs: [(String, String)] = [
        ("How do I sell a work?", "Open +, choose Listing, add a photo, title, story and price, then tap List."),
        ("When do I get paid?", "Payouts go out weekly after the collector confirms delivery."),
        ("How do commissions work?", "Turn on commissions in Edit profile. Collectors can request a work from your profile."),
        ("Can I make my profile private?", "Yes. Privacy → Private account. You approve each follow."),
    ]

    var body: some View {
        SettingsChrome(title: "Help") {
            VStack(alignment: .leading, spacing: 16) {
                SettingsCard {
                    ForEach(Array(faqs.enumerated()), id: \.offset) { index, item in
                        DisclosureGroup {
                            Text(item.1)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 12)
                        } label: {
                            Text(item.0)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        if index < faqs.count - 1 { SettingsDivider() }
                    }
                }

                if let mail = URL(string: "mailto:hello@picartdo.app?subject=Picartdo%20help") {
                    Link(destination: mail) {
                        Text("Email support")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
}

struct AboutSettingsView: View {
    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        SettingsChrome(title: "About") {
            VStack(alignment: .leading, spacing: 16) {
                SettingsCard {
                    SettingsInfoRow(title: "Picartdo", value: version)
                    SettingsDivider()
                    SettingsInfoRow(title: "Toronto", value: "Canada")
                }
                NavigationLink(value: SettingsDestination.terms) {
                    SettingsInfoRow(title: "Terms of use", value: "")
                }
                .buttonStyle(.plain)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.white.opacity(0.28), lineWidth: 1))

                NavigationLink(value: SettingsDestination.privacyPolicy) {
                    SettingsInfoRow(title: "Privacy policy", value: "")
                }
                .buttonStyle(.plain)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.white.opacity(0.28), lineWidth: 1))
            }
        }
    }
}

struct LegalSettingsView: View {
    let title: String
    let copy: String

    var body: some View {
        SettingsChrome(title: title) {
            Text(copy)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ReportProblemView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var topic = "Something’s broken"
    @State private var details = ""
    @State private var sent = false
    private let topics = ["Something’s broken", "A listing", "A payment", "Abuse or spam", "Other"]

    var body: some View {
        SettingsChrome(title: "Report a problem") {
            VStack(alignment: .leading, spacing: 16) {
                SettingsCard {
                    ForEach(topics, id: \.self) { item in
                        Button {
                            topic = item
                            Haptics.select()
                        } label: {
                            SettingsInfoRow(title: item, value: topic == item ? "✓" : "")
                        }
                        .buttonStyle(.plain)
                        if item != topics.last { SettingsDivider() }
                    }
                }

                TextEditor(text: $details)
                    .frame(minHeight: 120)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(.primary)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                    )

                Button("Send") {
                    let text = details.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    settings.addReport(.init(id: UUID(), topic: topic, body: text, date: Date()))
                    sent = true
                    details = ""
                    Haptics.success()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                )

                if sent {
                    Text("Thanks. We received your report.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.picardoGold)
                }
            }
        }
    }
}

struct DataAndStorageView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var cleared = false
    @State private var copied = false

    private var exportText: String {
        let identity = ProfileIdentity.load()
        let flags = settings.flags
        let orderLines = settings.orders.map {
            "\($0.title) · \($0.status.rawValue) · \($0.amount)"
        }.joined(separator: "\n")
        return """
        Picartdo data export
        Name: \(identity.name)
        Username: @\(identity.handle)
        Email: \(flags.email)
        Phone: \(flags.phone)
        Language: \(flags.language)
        Currency: \(flags.currency)
        Private account: \(flags.privateAccount)
        Cards on file: \(settings.cards.count)
        Addresses: \(settings.addresses.count)
        Blocked: \(settings.blocked.map(\.handle).joined(separator: ", "))
        Orders:
        \(orderLines)
        """
    }

    var body: some View {
        SettingsChrome(title: "Data and storage") {
            VStack(alignment: .leading, spacing: 16) {
                ShareLink(item: exportText) {
                    Text("Download your information")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                        )
                }
                .simultaneousGesture(TapGesture().onEnded { Haptics.tap() })

                Button("Copy a text copy") {
                    UIPasteboard.general.string = exportText
                    copied = true
                    Haptics.success()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                )

                Button("Clear image cache") {
                    ArtworkImageCache.shared.clear()
                    cleared = true
                    Haptics.success()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                )

                if copied {
                    Text("Copied to the clipboard.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.picardoGold)
                }
                if cleared {
                    Text("Cache cleared. Photos will load again as you browse.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

enum LegalCopy {
    static let terms = """
    Picartdo is a marketplace for original art. You keep the copyright in work you list. Collectors receive the physical work they buy, not the copyright, unless you agree otherwise in writing.

    Listings must be yours to sell. Prices are set by you. Picartdo may remove work that is copied, unlawful, or misleading.

    Sales are contracts between you and the collector. Picartdo facilitates payment and may hold funds until delivery is confirmed.
    """

    static let privacy = """
    Picartdo stores the account details you give us — name, email, studio city, and the photos you upload — to run the app.

    We use this to show your profile, process orders, and send the notifications you turn on. We do not sell your list of collectors.

    You can edit or delete profile copy in Settings, log out, or email hello@picartdo.app to ask for a copy of your data.
    """
}
