import SwiftUI
import LocalAuthentication

/// Gallery product page — title on the piece, placard always visible.
struct ArtworkDetailView: View {
    let artwork: Artwork
    @Environment(WishlistStore.self) private var wishlist
    @Environment(SessionStore.self) private var session
    @State private var showAuth = false
    @State private var showMessages = false

    private var isWanted: Bool { wishlist.isLiked(artwork) }

    private var pieceDescription: String {
        let story = artwork.description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !story.isEmpty { return story }
        return "\(artwork.category.rawValue) on Picartdo."
    }

    private var materialsLine: String {
        var parts: [String] = []
        let medium = artwork.medium.trimmingCharacters(in: .whitespacesAndNewlines)
        let size = artwork.dimensions.trimmingCharacters(in: .whitespacesAndNewlines)
        if !medium.isEmpty { parts.append(medium) }
        if !size.isEmpty { parts.append(size) }
        parts.append("Original 1 of 1")
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(artwork.title)
                .font(PicardoType.display(28))
                .foregroundStyle(Color.picardoText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 12)

            pieceImage
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 6) {
                ArtistNameLink(
                    name: artwork.artistName,
                    font: PicardoType.body(16),
                    color: Color.picardoTextSecondary,
                    italic: true,
                    lineLimit: nil
                )

                HStack(spacing: 10) {
                    Text(artwork.price, format: .currency(code: "USD").precision(.fractionLength(0)))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.picardoNeonRed)
                    if artwork.isSold {
                        Text("SOLD")
                            .picardoMetaStyle(kerning: 1)
                            .foregroundStyle(Color.picardoTextSecondary)
                    }
                }

                Text(pieceDescription)
                    .font(PicardoType.body(15))
                    .foregroundStyle(Color.picardoText.opacity(0.9))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Text(materialsLine)
                    .font(PicardoType.meta(11))
                    .kerning(0.4)
                    .foregroundStyle(Color.picardoTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 12)

            listingActions
        }
        .background(Color.picardoBackground)
        .picardoSwipeBackOnly()
        .navigationDestination(for: Artist.self) { artist in
            ArtistStoreView(artist: artist)
        }
        .sheet(isPresented: $showAuth) { AuthRequiredSheet() }
        .fullScreenCover(isPresented: $showMessages) {
            NavigationStack {
                ArtistChatView(artwork: artwork)
            }
            .presentationBackground(Color.picardoBackground)
        }
    }

    private var pieceImage: some View {
        PolaroidFrame(inset: 12, bottomLip: 36, cornerRadius: 6) {
            ArtworkImage(artwork: artwork, contentMode: .fit, maxDimension: 1400)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Equal-width Inquire + Wants, above the floating tab bar.
    private var listingActions: some View {
        HStack(spacing: 10) {
            Button {
                if AppConfig.isBackendConfigured && !session.isAuthenticated {
                    showAuth = true
                } else {
                    showMessages = true
                }
            } label: {
                Text("INQUIRE")
                    .font(PicardoType.cta())
                    .kerning(0.8)
                    .foregroundStyle(Color.picardoText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .buttonStyle(PicardoPressStyle())
            .glassEffect(.regular.interactive(), in: Capsule())
            .accessibilityLabel("Inquire")

            Button {
                withAnimation(PicardoMotion.quick) { wishlist.toggle(artwork) }
            } label: {
                Text(artwork.isSold ? "SOLD OUT" : (isWanted ? "WANTED" : "WANTS"))
                    .font(PicardoType.cta())
                    .kerning(0.8)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        artwork.isSold
                            ? Color.picardoTextSecondary
                            : Color.picardoNeonRed,
                        in: Capsule()
                    )
            }
            .buttonStyle(PicardoPressStyle())
            .disabled(artwork.isSold)
            .accessibilityLabel(artwork.isSold ? "Sold out" : (isWanted ? "Wanted" : "Wants"))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 72)
    }
}

// MARK: - Sub-components

struct ArtworkTrustBadge: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.picardoTextSecondary)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .kerning(0.5)
                .foregroundStyle(Color.picardoTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - Card Network

enum CardNetwork: Int, CaseIterable, Identifiable {
    case amexCenturion = 0
    case amexPlatinum  = 1
    case visa          = 2
    case mastercard    = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .amexCenturion: return "Amex Centurion"
        case .amexPlatinum:  return "Amex Platinum"
        case .visa:          return "Visa Infinite"
        case .mastercard:    return "Mastercard World Elite"
        }
    }

    var colors: [Color] {
        switch self {
        case .amexCenturion:
            return [Color(red: 0.06, green: 0.06, blue: 0.07),
                    Color(red: 0.18, green: 0.16, blue: 0.18)]
        case .amexPlatinum:
            return [Color(red: 0.62, green: 0.64, blue: 0.68),
                    Color(red: 0.85, green: 0.87, blue: 0.90)]
        case .visa:
            return [Color(red: 0.07, green: 0.18, blue: 0.55),
                    Color(red: 0.18, green: 0.38, blue: 0.82)]
        case .mastercard:
            return [Color(red: 0.07, green: 0.07, blue: 0.10),
                    Color(red: 0.18, green: 0.14, blue: 0.22)]
        }
    }

    var shadowColor: Color {
        switch self {
        case .amexCenturion: return .black
        case .amexPlatinum:  return Color(red: 0.62, green: 0.64, blue: 0.68)
        case .visa:          return Color(red: 0.07, green: 0.18, blue: 0.55)
        case .mastercard:    return .black
        }
    }

    // Is text dark (for Platinum)
    var darkText: Bool { self == .amexPlatinum }
}

// MARK: - Card Logo Views

private struct VisaLogo: View {
    var body: some View {
        Text("VISA")
            .font(.system(size: 22, weight: .black, design: .default))
            .italic()
            .foregroundStyle(.white)
            .tracking(1)
    }
}

private struct MastercardLogo: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(red: 0.85, green: 0.10, blue: 0.12).opacity(0.92))
                .frame(width: 32, height: 32).offset(x: -10)
            Circle().fill(Color(red: 1.0, green: 0.60, blue: 0.0).opacity(0.88))
                .frame(width: 32, height: 32).offset(x: 10)
        }
        .frame(width: 52, height: 32)
    }
}

private struct AmexCenturionLogo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("AMERICAN EXPRESS")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
                .tracking(1.5)
            Text("CENTURION")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white)
                .tracking(3)
        }
    }
}

private struct AmexPlatinumLogo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("AMERICAN EXPRESS")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color(red: 0.3, green: 0.3, blue: 0.35).opacity(0.8))
                .tracking(1.5)
            Text("PLATINUM")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(Color(red: 0.3, green: 0.3, blue: 0.35))
                .tracking(3)
        }
    }
}

// MARK: - Floating Card

struct FloatingPaymentCard: View {
    let network: CardNetwork
    @State private var tilt: Double = -6
    @State private var floatY: CGFloat = 0

    var textColor: Color { network.darkText ? Color(red: 0.2, green: 0.2, blue: 0.25) : .white }
    var subTextColor: Color { network.darkText ? Color(red: 0.4, green: 0.4, blue: 0.45) : .white.opacity(0.5) }

    var body: some View {
        ZStack {
            // Glow shadow
            RoundedRectangle(cornerRadius: 20)
                .fill(network.shadowColor.opacity(0.4))
                .frame(height: 190)
                .blur(radius: 20)
                .offset(y: 20)

            // Card face
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(
                    colors: network.colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 190)
                .overlay(cardOverlay)
                .rotation3DEffect(.degrees(tilt), axis: (x: 0.15, y: 1, z: 0))
                .offset(y: floatY)
                .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                tilt = 6; floatY = -8
            }
        }
    }

    private var cardOverlay: some View {
        ZStack {
            // Subtle sheen circles
            Circle().fill(.white.opacity(network == .amexPlatinum ? 0.18 : 0.06))
                .frame(width: 180).offset(x: 80, y: -40)
            Circle().fill(.white.opacity(network == .amexPlatinum ? 0.12 : 0.04))
                .frame(width: 130).offset(x: -60, y: 70)

            VStack(alignment: .leading, spacing: 0) {
                // Top row: chip + network logo
                HStack(alignment: .top) {
                    // Chip
                    RoundedRectangle(cornerRadius: 5)
                        .fill(LinearGradient(
                            colors: network == .amexPlatinum
                                ? [Color(red: 0.7, green: 0.6, blue: 0.3), Color(red: 0.9, green: 0.8, blue: 0.5)]
                                : [Color.yellow.opacity(0.85), Color.orange.opacity(0.6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 38, height: 28)

                    Spacer()

                    // Network logo top-right
                    Group {
                        switch network {
                        case .visa:          VisaLogo()
                        case .mastercard:    MastercardLogo()
                        case .amexCenturion: AmexCenturionLogo()
                        case .amexPlatinum:  AmexPlatinumLogo()
                        }
                    }
                }

                Spacer()

                // Card number
                Text(network == .amexCenturion || network == .amexPlatinum
                     ? "•••• •••••• •••••"
                     : "•••• •••• •••• ••••")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundStyle(textColor.opacity(0.85))
                    .tracking(2)
                    .padding(.bottom, 10)

                // Bottom row: holder + expiry
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CARD HOLDER")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(subTextColor)
                        Text("OSCAR BRUSCHI")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(textColor)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("EXPIRES")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(subTextColor)
                        Text("MM / YY")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(textColor)
                    }
                }
            }
            .padding(22)
        }
    }
}

/// MARK: - Card Picker

struct CardPickerView: View {
    @Binding var selectedIndex: Int

    var body: some View {
        VStack(spacing: 16) {
            TabView(selection: $selectedIndex) {
                ForEach(CardNetwork.allCases) { network in
                    FloatingPaymentCard(network: network)
                        .padding(.horizontal, 24)
                        .tag(network.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 230)

            // Dot indicators
            HStack(spacing: 8) {
                ForEach(CardNetwork.allCases) { network in
                    Circle()
                        .fill(selectedIndex == network.id
                              ? (network.colors.first ?? Color.picardoGold)
                              : Color.picardoBorder)
                        .frame(width: selectedIndex == network.id ? 10 : 7,
                               height: selectedIndex == network.id ? 10 : 7)
                        .animation(.spring(response: 0.3), value: selectedIndex)
                        .onTapGesture { selectedIndex = network.id }
                }
            }

            // Card name label
            Text(CardNetwork(rawValue: selectedIndex)?.label ?? "")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .animation(.easeInOut, value: selectedIndex)
        }
    }
}

// MARK: - Apple Pay + Face ID + Dynamic Island

private enum ApplePayAuthPhase {
    case island, face, paid
}

struct ApplePayAuthOverlay: View {
    let title: String
    let amount: String
    var onCancel: () -> Void
    var onPaid: () -> Void

    @State private var phase: ApplePayAuthPhase = .island
    @State private var islandWidth: CGFloat = 126
    @State private var islandHeight: CGFloat = 37
    @State private var sheetOffset: CGFloat = 420
    @State private var dimOpacity: Double = 0
    @State private var scanSpin: Double = 0
    @State private var cancelled = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(dimOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    guard phase == .island else { return }
                    cancel()
                }

            VStack {
                Spacer()
                paySheet
                    .offset(y: sheetOffset)
            }
            .ignoresSafeArea(edges: .bottom)

            Capsule(style: .continuous)
                .fill(.black)
                .frame(width: islandWidth, height: islandHeight)
                .overlay { islandContent }
                .shadow(color: .black.opacity(0.4), radius: 8, y: 2)
                .padding(.top, 11)
        }
        .onAppear { start() }
    }

    @ViewBuilder
    private var islandContent: some View {
        switch phase {
        case .island:
            HStack(spacing: 8) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Pay")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .opacity(islandWidth > 160 ? 1 : 0)
        case .face:
            HStack(spacing: 10) {
                Image(systemName: "faceid")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(scanSpin))
                Text("Face ID")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
        case .paid:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(red: 0.20, green: 0.84, blue: 0.29))
                Text(amount)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var paySheet: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.black.opacity(0.12))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            HStack {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18, weight: .semibold))
                Text("Pay")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                Button("Cancel") { cancel() }
                    .font(.system(size: 15))
                    .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
            }
            .padding(.horizontal, 4)

            VStack(spacing: 4) {
                Text("Picartdo")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(amount)
                    .font(.system(size: 34, weight: .bold))
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.top, 4)

            HStack(spacing: 12) {
                Image(systemName: phase == .paid ? "checkmark.circle.fill" : "faceid")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(phase == .paid ? Color(red: 0.20, green: 0.84, blue: 0.29) : .primary)
                    .symbolEffect(.pulse, isActive: phase == .face)
                VStack(alignment: .leading, spacing: 2) {
                    Text(phaseCopy)
                        .font(.system(size: 16, weight: .semibold))
                    Text(phase == .island ? "Side Button" : (phase == .face ? "Look at iPhone" : "Picartdo"))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(20)
        .padding(.bottom, 18)
        .background(.ultraThickMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 28, style: .continuous))
    }

    private var phaseCopy: String {
        switch phase {
        case .island: return "Double Click to Pay"
        case .face: return "Confirm with Face ID"
        case .paid: return "Payment Complete"
        }
    }

    private func start() {
        withAnimation(.easeOut(duration: 0.25)) { dimOpacity = 0.55 }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            islandWidth = 168
            islandHeight = 44
            sheetOffset = 0
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        Task { await runAuth() }
    }

    private func runAuth() async {
        try? await Task.sleep(for: .milliseconds(700))
        guard !cancelled else { return }

        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
            phase = .face
            islandWidth = 196
            islandHeight = 52
        }
        withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
            scanSpin = 360
        }

        let ok = await requestFaceID()
        guard !cancelled else { return }

        if !ok {
            cancel()
            return
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
            phase = .paid
            islandWidth = 168
            islandHeight = 44
            scanSpin = 0
        }

        try? await Task.sleep(for: .milliseconds(900))
        guard !cancelled else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            islandWidth = 126
            islandHeight = 37
            sheetOffset = 420
            dimOpacity = 0
        }
        try? await Task.sleep(for: .milliseconds(380))
        guard !cancelled else { return }
        onPaid()
    }

    private func requestFaceID() async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            try? await Task.sleep(for: .milliseconds(1100))
            return !cancelled
        }
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Confirm your Apple Pay purchase on Picartdo"
            )
        } catch {
            return false
        }
    }

    private func cancel() {
        cancelled = true
        withAnimation(.easeInOut(duration: 0.28)) {
            sheetOffset = 420
            dimOpacity = 0
            islandWidth = 126
            islandHeight = 37
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onCancel()
        }
    }
}

// MARK: - Purchase Burst Animation

struct PurchaseBurstView: View {
    let title: String
    let onDone: () -> Void
    @State private var checkScale:  CGFloat = 0.3
    @State private var checkOpacity: Double = 0
    @State private var r1Scale: CGFloat = 0.4
    @State private var r2Scale: CGFloat = 0.3
    @State private var r3Scale: CGFloat = 0.2
    @State private var rOpacity: Double = 1
    @State private var textOpacity: Double = 0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Burst + checkmark
            ZStack {
                Circle()
                    .stroke(Color.picardoGold.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 160)
                    .scaleEffect(r1Scale)
                    .opacity(rOpacity)
                Circle()
                    .stroke(Color.picardoGold.opacity(0.22), lineWidth: 1)
                    .frame(width: 210)
                    .scaleEffect(r2Scale)
                    .opacity(rOpacity * 0.7)
                Circle()
                    .stroke(Color.picardoGold.opacity(0.12), lineWidth: 1)
                    .frame(width: 260)
                    .scaleEffect(r3Scale)
                    .opacity(rOpacity * 0.4)

                ZStack {
                    Circle()
                        .fill(Color.picardoGold.opacity(0.12))
                        .frame(width: 110)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.picardoGold)
                }
                .scaleEffect(checkScale)
                .opacity(checkOpacity)
            }
            .frame(height: 280)

            VStack(spacing: 10) {
                Text("You're all set!")
                    .font(.system(size: 26, weight: .bold))
                Text("\(title) is yours.\nThe artist will be in touch to arrange shipping.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .opacity(textOpacity)

            Spacer()

            Button(action: onDone) {
                Text("Done")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.picardoNeonRed, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .opacity(textOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.58).delay(0.1)) {
                checkScale = 1; checkOpacity = 1
            }
            withAnimation(.easeOut(duration: 1.4).delay(0.15).repeatForever(autoreverses: false)) {
                r1Scale = 2.2; r2Scale = 2.2; r3Scale = 2.2; rOpacity = 0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                textOpacity = 1
            }
        }
    }
}

// MARK: - Buy Confirmation Sheet

struct BuyConfirmationSheet: View {
    let artwork: Artwork
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var session

    @State private var didSucceed = false
    @State private var showCard = false
    @State private var isProcessing = false
    @State private var showAuth = false
    @State private var showSafari = false
    @State private var safariURL: URL?
    @State private var paymentError: String?

    @State private var cardNumber = ""
    @State private var cardName   = ""
    @State private var expiry     = ""
    @State private var cvv        = ""
    @State private var isScanning = false
    @State private var scanProgress: CGFloat = 0
    @State private var showApplePayAuth = false
    @State private var shipName = ""
    @State private var shipLine1 = ""
    @State private var shipCity = ""
    @State private var shipState = ""
    @State private var shipZIP = ""
    @State private var shipCountry = "United States"

    var body: some View {
        NavigationStack {
            Group {
                if didSucceed {
                    PurchaseBurstView(title: artwork.title) { dismiss() }
                } else {
                    checkoutPage
                }
            }
            .background(PicartdoBackground().ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !didSucceed {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(.secondary)
                    }
                    ToolbarItem(placement: .principal) {
                        Text(artwork.title)
                            .font(PicardoType.display(18))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
        }
        .sheet(isPresented: $showAuth) { AuthRequiredSheet() }
        .sheet(isPresented: $showSafari) {
            if let safariURL { SafariSheet(url: safariURL) }
        }
        .alert("Payment Error", isPresented: .init(
            get: { paymentError != nil },
            set: { if !$0 { paymentError = nil } }
        )) {
            Button("OK") { paymentError = nil }
        } message: {
            Text(paymentError ?? "")
        }
        .overlay {
            if showApplePayAuth {
                ApplePayAuthOverlay(
                    title: artwork.title,
                    amount: money(orderTotal),
                    onCancel: { showApplePayAuth = false },
                    onPaid: {
                        showApplePayAuth = false
                        Task { await processPayment(useCheckout: true) }
                    }
                )
                .ignoresSafeArea()
            }
        }
    }

    private var pieceCopy: String {
        let story = artwork.description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !story.isEmpty { return story }
        return "\(artwork.category.rawValue) on Picartdo."
    }

    private var shipsDomestic: Bool {
        let country = shipCountry.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return country.isEmpty
            || country == "us"
            || country == "usa"
            || country == "united states"
    }

    private var shippingCost: Double { shipsDomestic ? 65 : 145 }
    private var taxAmount: Double {
        let rate = shipsDomestic ? 0.07 : 0
        return (artwork.price * rate * 100).rounded() / 100
    }
    private var orderTotal: Double { artwork.price + shippingCost + taxAmount }

    private var canPay: Bool {
        !shipName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !shipLine1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !shipCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !shipZIP.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }

    private var checkoutPage: some View {
        VStack(alignment: .leading, spacing: 8) {
            ArtworkImage(artwork: artwork, contentMode: .fit, maxDimension: 1400)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .shadow(color: .black.opacity(0.28), radius: 12, y: 6)
                .padding(.horizontal, 24)

            HStack(alignment: .firstTextBaseline) {
                ArtistNameLink(
                    name: artwork.artistName,
                    prefix: "by ",
                    font: PicardoType.body(14),
                    italic: true
                )
                Spacer(minLength: 8)
                Text(money(artwork.price))
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(Color.picardoNeonRed)
            }

            Text("Ship to")
                .font(PicardoType.meta(10))
                .kerning(0.8)
                .foregroundStyle(Color.picardoTextSecondary)

            addressFields

            VStack(spacing: 6) {
                totalRow("Work", money(artwork.price))
                totalRow("Shipping · insured crate", money(shippingCost))
                totalRow(shipsDomestic ? "Tax · 7%" : "Tax", money(taxAmount))
                Rectangle().fill(Color.picardoDivider).frame(height: 0.5).padding(.vertical, 2)
                HStack {
                    Text("Total")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    Text(money(orderTotal))
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(Color.picardoNeonRed)
                }
            }

            if !canPay {
                Text("Add a shipping address to pay.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.picardoNeonRed)
                    .frame(maxWidth: .infinity)
            }

            if showCard {
                cardFields
            } else {
                HStack(spacing: 10) {
                    Button {
                        guard canPay else { return }
                        showApplePayAuth = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "apple.logo").font(.system(size: 17, weight: .semibold))
                            Text("Pay").font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.black.opacity(canPay ? 1 : 0.35), in: Capsule())
                    }
                    .disabled(!canPay)

                    Button {
                        guard canPay else { return }
                        withAnimation(PicardoMotion.quick) { showCard = true }
                    } label: {
                        Text("Card")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.picardoNeonRed.opacity(canPay ? 1 : 0.35), in: Capsule())
                    }
                    .disabled(!canPay)
                }
            }

            Text("Packed and tracked · 7–14 days · 14-day returns")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    private var addressFields: some View {
        VStack(spacing: 6) {
            cardField(icon: "person", placeholder: "Full name", text: $shipName)
            cardField(icon: "house", placeholder: "Street address", text: $shipLine1)
            HStack(spacing: 6) {
                cardField(icon: "building.2", placeholder: "City", text: $shipCity)
                cardField(icon: "map", placeholder: "State", text: $shipState)
            }
            HStack(spacing: 6) {
                cardField(icon: "number", placeholder: "ZIP", text: $shipZIP)
                cardField(icon: "globe", placeholder: "Country", text: $shipCountry)
            }
        }
    }

    private func totalRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
        }
    }

    private var cardFields: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    isScanning = true
                    scanProgress = 0
                    withAnimation(.linear(duration: 1.6)) { scanProgress = 1 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        cardNumber = "4242  4242  4242  4242"
                        cardName   = "Oscar Bruschi"
                        expiry     = "12/27"
                        cvv        = "•••"
                        isScanning = false
                        scanProgress = 0
                    }
                } label: {
                    Label(isScanning ? "Scanning..." : "Scan", systemImage: isScanning ? "viewfinder" : "camera.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.picardoGold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.picardoCard, in: Capsule())
                }
                .disabled(isScanning)

                Button {
                    withAnimation(PicardoMotion.quick) { showCard = false }
                } label: {
                    Text("Apple Pay")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.black, in: Capsule())
                }
            }

            cardField(icon: "creditcard", placeholder: "Card Number", text: $cardNumber)
            cardField(icon: "person", placeholder: "Name on Card", text: $cardName)
            HStack(spacing: 8) {
                cardField(icon: "calendar", placeholder: "MM / YY", text: $expiry)
                cardField(icon: "lock", placeholder: "CVV", text: $cvv)
            }

            Button {
                guard canPay else { return }
                Task { await processPayment(useCheckout: true) }
            } label: {
                Text("Pay \(money(orderTotal))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.picardoNeonRed.opacity(canPay ? 1 : 0.35), in: Capsule())
            }
            .disabled(!canPay)
        }
    }

    private func cardField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color.picardoGold)
                .frame(width: 18)
            TextField(placeholder, text: text)
                .font(.system(size: 14))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.picardoBorder, lineWidth: 0.5))
    }

    private func processPayment(useCheckout: Bool) async {
        guard canPay, !isProcessing else { return }
        guard AppConfig.isBackendConfigured else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { didSucceed = true }
            return
        }
        guard session.isAuthenticated else {
            showAuth = true
            return
        }
        isProcessing = true
        defer { isProcessing = false }
        do {
            let address: [String: String] = [
                "name": shipName.trimmingCharacters(in: .whitespacesAndNewlines),
                "line1": shipLine1.trimmingCharacters(in: .whitespacesAndNewlines),
                "city": shipCity.trimmingCharacters(in: .whitespacesAndNewlines),
                "state": shipState.trimmingCharacters(in: .whitespacesAndNewlines),
                "postal_code": shipZIP.trimmingCharacters(in: .whitespacesAndNewlines),
                "country": shipsDomestic ? "US" : shipCountry.trimmingCharacters(in: .whitespacesAndNewlines),
            ]
            let response = try await PaymentService.createPayment(
                listingID: artwork.id,
                shippingAddress: address,
                useCheckout: useCheckout
            )
            if response.error == "identity_required" {
                if let url = try await IdentityService.startVerification(purpose: "buyer") {
                    safariURL = url
                    showSafari = true
                } else {
                    paymentError = response.message ?? "ID verification required for purchases over $500."
                }
                return
            }
            if let urlString = response.checkoutUrl, let url = URL(string: urlString) {
                safariURL = url
                showSafari = true
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { didSucceed = true }
            } else if response.status == "succeeded" {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { didSucceed = true }
            } else {
                paymentError = response.error ?? "Payment could not be completed."
            }
        } catch {
            paymentError = error.localizedDescription
        }
    }

}

#Preview { NavigationStack { ArtworkDetailView(artwork: Artwork.samples[0]) } }
