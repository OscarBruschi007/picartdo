import SwiftUI

// MARK: - Picasso — Picartdo's resident art mind
// Opened from the top-right of Home. Chat with curated art intelligence,
// daily insights, commission guidance, and recommendations drawn from the
// user's saved pieces. Styled in the Picartdo gold design language.

struct PicassoView: View {
    /// The user's saved artwork IDs, passed in from Home for taste-reading.
    var savedArtworks: Set<UUID> = []

    @Environment(\.dismiss) private var dismiss
    @State private var engine = PicassoEngine()
    @State private var draft = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.picardoBackground.ignoresSafeArea()

                VStack(spacing: 0) {

                    // MARK: Conversation
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 14) {
                                ForEach(engine.messages) { message in
                                    PicassoBubble(message: message)
                                        .id(message.id)
                                }

                                if engine.isThinking {
                                    PicassoThinkingIndicator()
                                        .id("thinking")
                                }
                            }
                            .padding()
                        }
                        .onChange(of: engine.messages.count) {
                            scrollToBottom(proxy)
                        }
                        .onChange(of: engine.isThinking) {
                            scrollToBottom(proxy)
                        }
                        .onAppear {
                            scrollToBottom(proxy, animated: false)
                        }
                    }

                    // MARK: Suggestion chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(engine.suggestions, id: \.self) { suggestion in
                                Button {
                                    send(suggestion)
                                } label: {
                                    Text(suggestion)
                                        .font(.caption)
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(Color.picardoGoldLight, in: Capsule())
                                        .foregroundStyle(Color.picardoGold)
                                }
                                .disabled(engine.isThinking)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)

                    // MARK: Input bar
                    VStack(spacing: 0) {
                        Divider().opacity(0.3)
                        HStack(spacing: 10) {
                            TextField("Ask Picasso about art…", text: $draft, axis: .vertical)
                                .lineLimit(1...4)
                                .focused($inputFocused)
                                .padding(.horizontal, 14).padding(.vertical, 9)
                                .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 20))

                            Button {
                                send(draft)
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(sendDisabled ? Color.gray : Color.picardoGold)
                            }
                            .disabled(sendDisabled)
                            .accessibilityLabel("Ask Picasso")
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                    }
                }
            }
            .navigationTitle("Picasso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.picardoGold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        engine.clearConversation()
                    } label: {
                        Image(systemName: "eraser")
                            .foregroundStyle(Color.picardoGold)
                    }
                    .accessibilityLabel("Clear conversation")
                }
            }
            .navigationDestination(for: Artwork.self) { ArtworkDetailView(artwork: $0) }
            .navigationDestination(for: Artist.self) { artist in
                ArtistStoreView(artist: artist)
            }
        }
    }

    // MARK: Actions

    private var sendDisabled: Bool {
        draft.trimmingCharacters(in: .whitespaces).isEmpty || engine.isThinking
    }

    private func send(_ text: String) {
        let question = text
        draft = ""
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        engine.ask(question, context: PicassoContext(
            artworks: Artwork.samples,
            artists: Artist.all,
            savedIDs: savedArtworks
        ))
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool = true) {
        let target: AnyHashable? = engine.isThinking ? "thinking" : engine.messages.last?.id
        guard let target else { return }
        if animated {
            withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(target, anchor: .bottom) }
        } else {
            proxy.scrollTo(target, anchor: .bottom)
        }
    }
}

// MARK: - Bubble

private struct PicassoBubble: View {
    let message: PicassoMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .picasso {
                PicassoAvatar()
            } else {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.role == .picasso ? .leading : .trailing, spacing: 8) {
                Text(message.text)
                    .font(.system(size: 15))
                    .lineSpacing(5)
                    .foregroundStyle(message.role == .picasso ? Color.primary : Color.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 15).padding(.vertical, 12)
                    .background(
                        message.role == .picasso
                            ? AnyShapeStyle(Color.picardoCard)
                            : AnyShapeStyle(Color.picardoGold),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
                    .textSelection(.enabled)

                // Recommended artworks — tappable, straight to the piece.
                if !message.artworkIDs.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(message.artworkIDs, id: \.self) { id in
                            if let artwork = Artwork.samples.first(where: { $0.id == id }) {
                                NavigationLink(value: artwork) {
                                    HStack(spacing: 10) {
                                        ArtworkImage(artwork: artwork, contentMode: .fill)
                                            .frame(width: 44, height: 44)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(artwork.title)
                                                .font(.caption.bold())
                                                .foregroundStyle(Color.primary)
                                                .lineLimit(1)
                                            Text(artwork.price, format: .currency(code: "USD"))
                                                .font(.caption2)
                                                .foregroundStyle(Color.picardoNeonRed)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                    .padding(8)
                                    .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: 260)
                }
            }

            if message.role == .user {
                EmptyView()
            } else {
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Avatar

struct PicassoAvatar: View {
    var size: CGFloat = 28
    /// Show the little AI sparkle accent (used on the Home button; off inside chat bubbles).
    var showSparkle: Bool = false

    var body: some View {
        Circle()
            .fill(Color.picardoAccent)
            .frame(width: size, height: size)
            .overlay(
                // Serif "P" monogram — matches the Picartdo wordmark.
                Text("P")
                    .font(.system(size: size * 0.58, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .offset(y: size * 0.01)
            )
            .overlay(alignment: .topTrailing) {
                if showSparkle {
                    Image(systemName: "sparkle")
                        .font(.system(size: size * 0.32, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: Color.picardoGoldDeep.opacity(0.6), radius: 1)
                        .offset(x: size * 0.10, y: -size * 0.06)
                }
            }
            .overlay(
                Circle().strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
            )
    }
}

// MARK: - Thinking dots

private struct PicassoThinkingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            PicassoAvatar()
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 7, height: 7)
                        .opacity(phase == index ? 1 : 0.35)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 18))
            Spacer(minLength: 40)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000)
                phase = (phase + 1) % 3
            }
        }
        .accessibilityLabel("Picasso is thinking")
    }
}

#Preview {
    PicassoView()
}
