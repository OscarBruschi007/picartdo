import SwiftUI

/// Gallery product page — large uncropped artwork on white, editorial
/// type, expandable details, understated CTAs. Artwork supplies the color.
struct ArtworkDetailView: View {
    let artwork: Artwork
    @Environment(WishlistStore.self) private var wishlist
    @Environment(SessionStore.self) private var session
    @State private var showBuySheet = false
    @State private var showAuth = false
    @State private var showMessages = false
    @State private var detailsExpanded = false
    @State private var showWallTest = false

    private var isLiked: Bool { wishlist.isLiked(artwork) }
    private var isSaved: Bool { wishlist.isLiked(artwork) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // Artwork hero
                ZStack(alignment: .bottomTrailing) {
                    ArtworkImage(imageName: artwork.imageName, contentMode: .fit, maxDimension: 1400)
                        .frame(maxWidth: .infinity)
                        .frame(height: 420)
                        .padding(.horizontal, 20)

                    if !artwork.isSold {
                        Button { showWallTest = true } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Wall Test")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.black.opacity(0.55), in: Capsule())
                        }
                        .padding(.trailing, 32)
                        .padding(.bottom, 12)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 28)

                // Minimal identity — details expand on demand
                VStack(alignment: .leading, spacing: 12) {
                    PicardoEyebrow(text: artwork.category.rawValue)

                    Text(artwork.title)
                        .font(PicardoType.display(30))
                        .foregroundStyle(Color.picardoText)
                        .fixedSize(horizontal: false, vertical: true)

                    ArtistNameLink(
                        name: artwork.artistName,
                        font: PicardoType.body(16),
                        color: Color.picardoTextSecondary,
                        italic: true,
                        lineLimit: nil
                    )

                    HStack(spacing: 12) {
                        Text(artwork.price, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.picardoText)

                        if artwork.isSold {
                            Text("SOLD")
                                .picardoMetaStyle(kerning: 1)
                                .foregroundStyle(Color.picardoTextSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .overlay(Rectangle().strokeBorder(Color.picardoBorder, lineWidth: 1))
                        }

                        Spacer()

                        Text(detailsExpanded ? "LESS" : "DETAILS")
                            .picardoMetaStyle(kerning: 1.2)
                            .foregroundStyle(Color.picardoAccent)
                            .onTapGesture {
                                withAnimation(PicardoMotion.transition) {
                                    detailsExpanded.toggle()
                                }
                            }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                if detailsExpanded {
                    VStack(alignment: .leading, spacing: 0) {
                        Rectangle().fill(Color.picardoDivider).frame(height: 1)

                        VStack(alignment: .leading, spacing: 16) {
                            artistSpecRow
                            specRow("TECHNIQUE", artwork.medium)
                            specRow("MATERIALS", artwork.medium)
                            specRow("DIMENSIONS", artwork.dimensions)
                            specRow("PRICE", artwork.price.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                            specRow("CERTIFICATE", "Included")
                            specRow("EDITION", "1 of 1 · Original")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)

                        if !artwork.description.isEmpty {
                            Rectangle().fill(Color.picardoDivider).frame(height: 1).padding(.horizontal, 24)

                            VStack(alignment: .leading, spacing: 10) {
                                PicardoEyebrow(text: "Story")
                                Text(artwork.description)
                                    .font(PicardoType.body(15))
                                    .italic()
                                    .foregroundStyle(Color.picardoText.opacity(0.85))
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                        }

                        Rectangle().fill(Color.picardoDivider).frame(height: 1)

                        HStack(spacing: 0) {
                            ArtworkTrustBadge(icon: "checkmark.seal", label: "Certificate")
                            ArtworkTrustBadge(icon: "shippingbox", label: "Shipping")
                            ArtworkTrustBadge(icon: "arrow.uturn.left", label: "Returns")
                        }
                        .padding(.vertical, 18)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Color.clear.frame(height: 120)
            }
        }
        .background(Color.picardoBackground)
        .navigationBarTitleDisplayMode(.inline)
        .picardoPushedScreen()
        .navigationDestination(for: Artist.self) { artist in
            ArtistStoreView(artist: artist)
                .picardoPushedScreen()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 18) {
                    Button {
                        withAnimation(PicardoMotion.quick) { wishlist.toggle(artwork) }
                    } label: {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(isLiked ? Color.picardoAccent : Color.picardoText)
                            .scaleEffect(isLiked ? 1.08 : 1)
                    }
                    Button {
                        withAnimation(PicardoMotion.quick) { wishlist.toggle(artwork) }
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(isSaved ? Color.picardoAccent : Color.picardoText)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                PicardoPrimaryButton(
                    title: artwork.isSold ? "SOLD OUT" : "ADD TO COLLECTION",
                    enabled: !artwork.isSold
                ) {
                    showBuySheet = true
                }
                PicardoSecondaryButton(title: "MESSAGE ARTIST") {
                    if AppConfig.isBackendConfigured && !session.isAuthenticated {
                        showAuth = true
                    } else {
                        showMessages = true
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(Color.picardoBackground)
        }
        .sheet(isPresented: $showBuySheet) {
            BuyConfirmationSheet(artwork: artwork)
        }
        .sheet(isPresented: $showWallTest) {
            WallTestView(artwork: artwork)
        }
        .sheet(isPresented: $showAuth) { AuthRequiredSheet() }
        .sheet(isPresented: $showMessages) {
            NavigationStack {
                ArtistChatView(artwork: artwork)
            }
        }
    }

    private var artistSpecRow: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("ARTIST")
                .font(PicardoType.meta(10))
                .kerning(1)
                .foregroundStyle(Color.picardoTextSecondary)
                .frame(width: 110, alignment: .leading)
            ArtistNameLink(
                name: artwork.artistName,
                font: .system(size: 14),
                color: Color.picardoText,
                lineLimit: nil
            )
            Spacer(minLength: 0)
        }
    }

    private func specRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(label)
                .font(PicardoType.meta(10))
                .kerning(1)
                .foregroundStyle(Color.picardoTextSecondary)
                .frame(width: 110, alignment: .leading)
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 14))
                .foregroundStyle(Color.picardoText)
            Spacer(minLength: 0)
        }
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

    private enum Step { case details, payment, cardEntry, success }
    @State private var step: Step = .details
    @State private var selectedCard: Int = 0
    @State private var isProcessing = false
    @State private var showAuth = false
    @State private var showSafari = false
    @State private var safariURL: URL?
    @State private var paymentError: String?

    // Card entry fields
    @State private var cardNumber = ""
    @State private var cardName   = ""
    @State private var expiry     = ""
    @State private var cvv        = ""
    @State private var isScanning = false
    @State private var scanProgress: CGFloat = 0

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .details:   purchaseView
                case .payment:   paymentView
                case .cardEntry: cardEntryView
                case .success:   successView
                }
            }
            .background(PicartdoBackground().ignoresSafeArea())
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if step != .success {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(backLabel) { goBack() }
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.28), value: step)
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
    }

    private var navTitle: String {
        switch step {
        case .details:   return "Purchase"
        case .payment:   return "Pay"
        case .cardEntry: return "Card Details"
        case .success:   return ""
        }
    }
    private var backLabel: String { step == .details ? "Cancel" : "Back" }
    private func goBack() {
        switch step {
        case .details:   dismiss()
        case .payment:   step = .details
        case .cardEntry: step = .payment
        case .success:   dismiss()
        }
    }

    // ── Payment screen ───────────────────────────────────────────────────────
    private var paymentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {

                // Swipeable card picker
                CardPickerView(selectedIndex: $selectedCard)
                    .padding(.top, 4)

                // Order chip
                HStack(spacing: 14) {
                    ArtworkImage(artwork: artwork, contentMode: .fill)
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(artwork.title).font(.system(size: 15, weight: .semibold))
                        Text("by \(artwork.artistName)").font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(artwork.price, format: .currency(code: "USD"))
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(Color.picardoNeonRed)
                }
                .padding(14)
                .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.picardoBorder, lineWidth: 0.5))

                // Title
                HStack {
                    Text("Choose how to pay")
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                }

                // Apple Pay
                Button {
                    Task { await processPayment(useCheckout: true) }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "apple.logo").font(.system(size: 18, weight: .semibold))
                        Text("Pay").font(.system(size: 19, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 16))
                }

                // Or divider
                HStack(spacing: 12) {
                    Rectangle().fill(Color.picardoBorder).frame(height: 0.5)
                    Text("or").font(.system(size: 13)).foregroundStyle(.secondary)
                    Rectangle().fill(Color.picardoBorder).frame(height: 0.5)
                }

                // Credit / Debit
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { step = .cardEntry }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "creditcard.fill").font(.system(size: 16))
                        Text("Credit or Debit Card").font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Color.picardoNeonRed, in: RoundedRectangle(cornerRadius: 16))
                }

                HStack(spacing: 5) {
                    Image(systemName: "lock.fill").font(.system(size: 11))
                    Text("Secure & encrypted payments")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.secondary)
            }
            .padding(24)
        }
    }

    // ── Card entry screen ────────────────────────────────────────────────────
    private var cardEntryView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {

                // Scan button
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
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.picardoCard)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.picardoBorder, lineWidth: 0.5))
                            .frame(height: 54)

                        if isScanning {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.picardoGold.opacity(0.15))
                                .frame(width: UIScreen.main.bounds.width * scanProgress - 48, height: 54)
                                .animation(.linear(duration: 1.6), value: scanProgress)
                        }

                        HStack(spacing: 10) {
                            Image(systemName: isScanning ? "viewfinder" : "camera.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.picardoGold)
                                .symbolEffect(.pulse, isActive: isScanning)
                            Text(isScanning ? "Scanning card..." : "Scan Card to Autofill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.picardoGold)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .disabled(isScanning)

                // Fields
                VStack(spacing: 14) {
                    cardField(icon: "creditcard", placeholder: "Card Number", text: $cardNumber)
                    cardField(icon: "person",     placeholder: "Name on Card", text: $cardName)
                    HStack(spacing: 12) {
                        cardField(icon: "calendar", placeholder: "MM / YY", text: $expiry)
                        cardField(icon: "lock",     placeholder: "CVV",     text: $cvv)
                    }
                }

                // Pay button
                Button {
                    Task { await processPayment(useCheckout: true) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill").font(.system(size: 14))
                        Text("Pay \(artwork.price, format: .currency(code: "USD"))")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Color.picardoNeonRed, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(24)
        }
    }

    private func cardField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.picardoGold)
                .frame(width: 22)
            TextField(placeholder, text: text)
                .font(.system(size: 15))
        }
        .padding(14)
        .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.picardoBorder, lineWidth: 0.5))
    }

    private func processPayment(useCheckout: Bool) async {
        guard !isProcessing else { return }
        guard AppConfig.isBackendConfigured else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { step = .success }
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
                "line1": "123 Gallery Lane",
                "city": "Miami",
                "state": "FL",
                "postal_code": "33101",
                "country": "US",
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
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { step = .success }
            } else if response.status == "succeeded" {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { step = .success }
            } else {
                paymentError = response.error ?? "Payment could not be completed."
            }
        } catch {
            paymentError = error.localizedDescription
        }
    }

    // ── Success screen ────────────────────────────────────────────────────────
    private var successView: some View {
        PurchaseBurstView(title: artwork.title) { dismiss() }
    }

    // ── Purchase screen ───────────────────────────────────────────────────────
    private var purchaseView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // Artwork image
                ZStack {
                    Color.picardoCard
                    ArtworkImage(artwork: artwork, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 0) {

                    // Title + price
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(artwork.title)
                                .font(.system(size: 22, weight: .bold))
                            Text("by \(artwork.artistName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(artwork.price, format: .currency(code: "USD"))
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(Color.picardoNeonRed)
                    }
                    .padding(.top, 20)

                    Divider().padding(.vertical, 16)

                    // Details grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        BuyDetailTile(icon: "ruler", label: "Dimensions",
                                      value: artwork.dimensions.isEmpty ? "—" : artwork.dimensions)
                        BuyDetailTile(icon: "paintbrush", label: "Medium",
                                      value: artwork.medium.isEmpty ? "—" : artwork.medium)
                        BuyDetailTile(icon: "mappin.circle.fill", label: "Ships from", value: "Miami, US")
                        BuyDetailTile(icon: "tag.fill", label: "Category", value: artwork.category.rawValue)
                    }

                    Divider().padding(.vertical, 16)

                    // Shipping note
                    HStack(spacing: 12) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.picardoGold)
                            .frame(width: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Free Worldwide Shipping")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Carefully packed and insured. Arrives in 7–14 days.")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .background(Color.picardoGold.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

                    // Buy bar
                    VStack(spacing: 0) {
                        Divider().padding(.top, 20)
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Total")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(artwork.price, format: .currency(code: "USD"))
                                    .font(.system(size: 20, weight: .black))
                            }
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    step = .payment
                                }
                            } label: {
                                Text("Continue to Payment")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.picardoNeonRed, in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.vertical, 14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

struct BuyDetailTile: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.picardoGold)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview { NavigationStack { ArtworkDetailView(artwork: Artwork.samples[0]) } }
