import SwiftUI

// MARK: - Commission Request View

struct CommissionRequestView: View {
    let artist: Artist
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var session

    @State private var name = ""
    @State private var email = ""
    @State private var style = "Any style"
    @State private var size = "Medium (16×20 in)"
    @State private var timeline = "1 month"
    @State private var budget = ""
    @State private var description = ""
    @State private var referenceNote = ""
    @State private var showSuccess = false
    @State private var appeared = false
    @State private var isSubmitting = false
    @State private var showAuth = false
    @State private var submitError = ""

    let styles = ["Any style", "Realistic", "Abstract", "Impressionist",
                  "Watercolour", "Ink / Line Art", "Digital", "Mixed Media"]
    let sizes  = ["Small (8×10 in)", "Medium (16×20 in)", "Large (24×36 in)",
                  "Extra Large (36×48 in)", "Custom size"]
    let timelines = ["ASAP (rush fee applies)", "2 weeks", "1 month", "2–3 months", "Flexible"]

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(budget) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PicartdoBackground().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        // ── Artist Banner ─────────────────────────────────
                        HStack(spacing: 12) {
                            Image(artist.avatarImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(Color.picardoGold.opacity(0.5), lineWidth: 1.5)
                                )

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 4) {
                                    Text(artist.name)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(.primary)
                                    if artist.verified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.picardoSupport)
                                    }
                                }
                                Text(artist.tagline)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.picardoGold)
                                    Text(String(format: "%.1f", artist.rating))
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Text("· Starts from \(artist.startingPrice)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 14))

                        // ── Your Details ──────────────────────────────────
                        FormSection(title: "About You") {
                            FormField(label: "Your name", systemImage: "person") {
                                TextField("Full name", text: $name)
                                    .foregroundStyle(.primary)
                                    .tint(Color.picardoGold)
                            }
                            Divider().background(Color.picardoDivider).padding(.leading, 16)
                            FormField(label: "Email", systemImage: "envelope") {
                                TextField("your@email.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .foregroundStyle(.primary)
                                    .tint(Color.picardoGold)
                            }
                        }

                        // ── Artwork Details ───────────────────────────────
                        FormSection(title: "Artwork Details") {
                            PickerField(label: "Style", systemImage: "paintbrush", selection: $style, options: styles)
                            Divider().background(Color.picardoDivider).padding(.leading, 16)
                            PickerField(label: "Size", systemImage: "ruler", selection: $size, options: sizes)
                            Divider().background(Color.picardoDivider).padding(.leading, 16)
                            PickerField(label: "Timeline", systemImage: "calendar", selection: $timeline, options: timelines)
                        }

                        // ── Budget ────────────────────────────────────────
                        FormSection(title: "Budget & Description") {
                            FormField(label: "Budget (USD)", systemImage: "dollarsign.circle") {
                                HStack(spacing: 4) {
                                    Text("$")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                    TextField("0", text: $budget)
                                        .keyboardType(.numberPad)
                                        .foregroundStyle(.primary)
                                        .tint(Color.picardoGold)
                                }
                            }
                            Divider().background(Color.picardoDivider).padding(.leading, 16)
                            VStack(alignment: .leading, spacing: 8) {
                                Label("What are you envisioning?", systemImage: "text.alignleft")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                TextField("Describe the piece — subject, mood, colours, any special meaning…",
                                          text: $description, axis: .vertical)
                                    .lineLimit(4...8)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.primary)
                                    .tint(Color.picardoGold)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 12)
                            }
                            Divider().background(Color.picardoDivider).padding(.leading, 16)
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Reference / inspiration (optional)", systemImage: "photo")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                TextField("Describe any reference images or links…",
                                          text: $referenceNote, axis: .vertical)
                                    .lineLimit(2...4)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.primary)
                                    .tint(Color.picardoGold)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 12)
                            }
                        }

                        // Disclaimer
                        Text("The artist will review your request and respond within 48 hours. No payment is taken at this stage.")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)

                        Color.clear.frame(height: 72)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                }

                // ── Sticky Submit ─────────────────────────────────────
                VStack {
                    Spacer()
                    Button {
                        submitCommission()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 14))
                            Text("Send Commission Request")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(isValid ? .black : Color(.secondaryLabel))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            isValid ? Color.picardoGold : Color.picardoCard,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                    .disabled(!isValid)
                    .animation(.easeInOut(duration: 0.18), value: isValid)
                    .background(
                        LinearGradient(
                            colors: [Color.picardoBackground.opacity(0), Color.picardoBackground],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: 90)
                        .allowsHitTesting(false)
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Commission Request")
                        .font(.system(size: 16, weight: .semibold))
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { appeared = true }
                if name.isEmpty, let fullName = session.profile?.fullName { name = fullName }
                if email.isEmpty, let userEmail = session.profile?.email { email = userEmail }
            }
            .alert("Request Sent!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("\(artist.name) will review your commission request and respond within 48 hours.")
            }
            .sheet(isPresented: $showAuth) { AuthRequiredSheet() }
            .alert("Could not send request", isPresented: .init(
                get: { !submitError.isEmpty },
                set: { if !$0 { submitError = "" } }
            )) {
                Button("OK") { submitError = "" }
            } message: {
                Text(submitError)
            }
        }
    }

    private func submitCommission() {
        guard !isSubmitting else { return }
        guard AppConfig.isBackendConfigured else {
            showSuccess = true
            return
        }
        if !session.isAuthenticated {
            showAuth = true
            return
        }
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                _ = try await CommissionService.submit(
                    artistID: artist.id,
                    name: name,
                    email: email,
                    style: style,
                    size: size,
                    timeline: timeline,
                    budget: budget,
                    description: description,
                    referenceNote: referenceNote
                )
                showSuccess = true
            } catch {
                submitError = error.localizedDescription
            }
        }
    }
}

// MARK: - Helpers

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.8)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct FormField<Content: View>: View {
    let label: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 10) {
            Label(label, systemImage: systemImage)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 130, alignment: .leading)
            Spacer()
            content()
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct PickerField: View {
    let label: String
    let systemImage: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        HStack(spacing: 10) {
            Label(label, systemImage: systemImage)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .tint(Color.picardoGold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

#Preview {
    CommissionRequestView(artist: Artist.all[0])
}
