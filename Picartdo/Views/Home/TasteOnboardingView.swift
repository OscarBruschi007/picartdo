import SwiftUI

/// First thing a new user does, before any tab bar, before any account.
/// A fast swipe pass across the catalogue — love it or pass — that reads
/// as play, not paperwork, and quietly teaches Home what to lead with.
/// This is the Cal AI move: the value and the data collection happen in
/// the same three seconds, instead of one gating the other.
struct TasteOnboardingView: View {
    @Environment(TastePreferenceStore.self) private var tasteStore

    @State private var deck: [Artwork] = TasteOnboardingView.buildDeck()
    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            header

            Spacer(minLength: 8)

            ZStack {
                if currentIndex < deck.count {
                    SwipeCard(artwork: deck[currentIndex]) { liked in
                        decide(liked: liked)
                    }
                    .id(deck[currentIndex].id)
                    .padding(.horizontal, 28)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.94).combined(with: .opacity),
                        removal: .opacity))
                } else {
                    doneView
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: currentIndex)

            Spacer(minLength: 8)

            if currentIndex < deck.count {
                actionRow
                    .padding(.bottom, 34)
            } else {
                Color.clear.frame(height: 96)
            }
        }
        .background(Color.picardoBackground.ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("What speaks to you?")
                .font(PicardoType.display(27))
                .foregroundStyle(Color.picardoText)

            Text("Swipe through a few pieces. We'll shape what you see next around it, no account needed.")
                .font(PicardoType.body(14))
                .foregroundStyle(Color.picardoTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 42)

            if currentIndex < deck.count {
                ProgressView(value: Double(currentIndex), total: Double(deck.count))
                    .tint(Color.picardoAccent)
                    .padding(.horizontal, 64)
                    .padding(.top, 4)
            }
        }
        .padding(.top, 28)
        .padding(.bottom, 10)
    }

    private var actionRow: some View {
        HStack(spacing: 32) {
            roundButton(icon: "xmark", tint: Color.picardoTextSecondary, background: Color.picardoCard) {
                decide(liked: false)
            }
            roundButton(icon: "heart.fill", tint: .white, background: Color.picardoAccent, big: true) {
                decide(liked: true)
            }
        }
    }

    private func roundButton(icon: String, tint: Color, background: Color, big: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: big ? 23 : 19, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: big ? 66 : 52, height: big ? 66 : 52)
                .background(background, in: Circle())
                .overlay(Circle().stroke(Color.picardoBorder, lineWidth: big ? 0 : 1))
                .shadow(color: .black.opacity(big ? 0.18 : 0), radius: 10, y: 6)
        }
    }

    private var doneView: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 38))
                .foregroundStyle(Color.picardoSupport)
            Text("Got it.")
                .font(PicardoType.display(26))
                .foregroundStyle(Color.picardoText)
            Text("Home is yours now.")
                .font(PicardoType.body(15))
                .foregroundStyle(Color.picardoTextSecondary)
        }
    }

    private func decide(liked: Bool) {
        guard currentIndex < deck.count else { return }
        tasteStore.recordSwipe(category: deck[currentIndex].category, liked: liked)
        currentIndex += 1
        if currentIndex >= deck.count {
            Task {
                try? await Task.sleep(for: .milliseconds(650))
                tasteStore.completeTastePass()
            }
        }
    }

    /// Two per category, spanning the whole catalogue, shuffled once per pass.
    private static func buildDeck() -> [Artwork] {
        var picks: [Artwork] = []
        for category in ArtCategory.allCases {
            let matches = Artwork.samples.filter { $0.category == category }
            picks.append(contentsOf: matches.shuffled().prefix(2))
        }
        return picks.shuffled()
    }
}

/// One draggable card. Owns its own drag state, keyed to the artwork by
/// the parent's `.id()`, so a fresh card always starts centered.
private struct SwipeCard: View {
    let artwork: Artwork
    let onDecision: (Bool) -> Void

    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .bottom) {
            ArtworkImage(artwork: artwork, contentMode: .fill)
                .frame(height: 460)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(artwork.category.rawValue)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.75))
                Text(artwork.title)
                    .font(PicardoType.title(21))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)

            decisionBadge
        }
        .frame(height: 460)
        .shadow(color: .black.opacity(0.22), radius: 18, y: 12)
        .offset(offset)
        .rotationEffect(.degrees(Double(offset.width / 16)))
        .gesture(
            DragGesture()
                .onChanged { value in offset = value.translation }
                .onEnded { value in
                    if abs(value.translation.width) > 120 {
                        let liked = value.translation.width > 0
                        withAnimation(.easeIn(duration: 0.2)) {
                            offset = CGSize(width: liked ? 700 : -700, height: value.translation.height)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                            onDecision(liked)
                        }
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { offset = .zero }
                    }
                }
        )
    }

    @ViewBuilder
    private var decisionBadge: some View {
        if offset.width > 20 {
            badge("LOVE IT", Color.picardoSupport)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else if offset.width < -20 {
            badge("PASS", Color.picardoTextSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }

    private func badge(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .heavy))
            .kerning(1.2)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(color, lineWidth: 2))
            .padding(16)
    }
}

#Preview {
    TasteOnboardingView()
        .environment(TastePreferenceStore())
}
