import PhotosUI
import SwiftUI
import UIKit

// MARK: - Drop in Picasso tutor
//
// Usage on any homepage:
//   .overlay(alignment: .topTrailing) { PicassoButton() }

private enum PicassoPrefs {
    static let hasUsedKey = "hasUsedPicasso"

    static var hasUsed: Bool {
        get { UserDefaults.standard.bool(forKey: hasUsedKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasUsedKey) }
    }
}

// MARK: - Small floating P button

struct PicassoButton: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var isOpen = false
    @State private var appeared = false
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            PicassoPrefs.hasUsed = true
            pulse = false
            isOpen = true
        } label: {
            PicassoAvatar(size: 38)
                .shadow(color: Color.picardoAccent.opacity(0.30), radius: 6, y: 3)
                .scaleEffect(appeared ? (pulse ? 1.07 : 1) : 0.6)
                .opacity(appeared ? 1 : 0)
        }
        .buttonStyle(.plain)
        .padding(.top, 12)
        .padding(.trailing, 16)
        .accessibilityLabel("Open Picasso, your art assistant")
        .accessibilityHint("Opens your art guide")
        .fullScreenCover(isPresented: $isOpen) {
            PicassoHubView(viewModel: viewModel) {
                isOpen = false
            }
        }
        .onAppear {
            guard !reduceMotion else {
                appeared = true
                return
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                appeared = true
            }
        }
        .task {
            await runIdlePulseLoop()
        }
    }

    /// Gentle pulse every 8 seconds until first use. Off when Reduce Motion is on.
    private func runIdlePulseLoop() async {
        guard !PicassoPrefs.hasUsed, !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            if Task.isCancelled || PicassoPrefs.hasUsed || isOpen { break }
            withAnimation(.easeInOut(duration: 0.45)) { pulse = true }
            try? await Task.sleep(nanoseconds: 450_000_000)
            withAnimation(.easeInOut(duration: 0.45)) { pulse = false }
        }
    }
}

// MARK: - Full page hub

enum PicassoMode: String, CaseIterable, Identifiable {
    case chat = "Chat"
    case voice = "Voice"
    case visual = "Visual"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .chat:   return "bubble.left.and.bubble.right.fill"
        case .voice:  return "mic.fill"
        case .visual: return "photo.on.rectangle.angled"
        }
    }
}

struct PicassoHubView: View {
    @ObservedObject var viewModel: ChatViewModel
    var onClose: () -> Void

    @State private var mode: PicassoMode = .chat
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            header
            modePicker
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            Divider().opacity(0.4)

            switch mode {
            case .chat:
                PicassoChatTab(viewModel: viewModel)
            case .voice:
                PicassoVoiceTab(viewModel: viewModel) {
                    withAnimation(.easeInOut(duration: 0.2)) { mode = .chat }
                }
            case .visual:
                PicassoVisualTab(
                    onAsk: { question in
                        viewModel.send(question)
                        withAnimation(.easeInOut(duration: 0.2)) { mode = .chat }
                    },
                    onAskWithImage: { question, image in
                        viewModel.send(question, image: image)
                        withAnimation(.easeInOut(duration: 0.2)) { mode = .chat }
                    }
                )
            }
        }
        .background(colorScheme == .dark ? Color(white: 0.10) : Color.white)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            PicassoAvatar(size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text("Picasso")
                    .font(.system(.title3, design: .serif).weight(.bold))
                Text("Your art guide")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.primary.opacity(0.06)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close Picasso")
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(PicassoMode.allCases) { item in
                let active = mode == item
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(.easeInOut(duration: 0.2)) { mode = item }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: item.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(item.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(active ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(active ? Color.picardoAccent : Color.primary.opacity(0.06))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(active ? [.isSelected] : [])
            }
        }
    }
}

// MARK: - Chat tab

private struct PicassoChatTab: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var inputFocused: Bool
    @State private var openedArtwork: Artwork?
    @State private var pendingImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var developerKey = ""

    var body: some View {
        VStack(spacing: 0) {
            messageList
            if viewModel.showSuggestions && viewModel.messages.count <= 1 {
                suggestionChips
            }
            #if DEBUG
            if viewModel.needsDeveloperKey { developerKeyBanner }
            #endif
            Divider().opacity(0.4)
            inputBar
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    pendingImage = image
                }
                photoItem = nil
            }
        }
        .fullScreenCover(item: $openedArtwork) { artwork in
            NavigationStack {
                ArtworkDetailView(artwork: artwork)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { openedArtwork = nil }
                        }
                    }
            }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        PicassoTutorBubble(
                            message: message,
                            onRetry: { viewModel.retryLast() },
                            onOpenArtwork: { openedArtwork = $0 },
                            onRate: { viewModel.rate(message, positive: $0) }
                        )
                        .id(message.id)
                    }
                    if viewModel.isLoading {
                        PicassoTypingIndicator()
                            .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: viewModel.isLoading) { _, loading in
                if loading { scrollToBottom(proxy) }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            if viewModel.isLoading {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let last = viewModel.messages.last?.id {
                proxy.scrollTo(last, anchor: .bottom)
            }
        }
    }

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChatViewModel.suggestedPrompts, id: \.self) { prompt in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.send(prompt)
                    } label: {
                        Text(prompt)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.picardoAccent.opacity(0.12)))
                            .overlay(
                                Capsule().strokeBorder(Color.picardoAccent.opacity(0.35), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isLoading)
                    .accessibilityLabel("Suggested prompt: \(prompt)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    #if DEBUG
    /// Debug builds only: lets a developer paste their own key so Picasso works without the backend.
    /// The key is stored in the Keychain and never ships in the app.
    private var developerKeyBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Offline mode", systemImage: "wifi.slash")
                .font(.caption.weight(.semibold))
            Text("Picasso is answering from the catalog on this device. For the full AI (photos, real conversation), sign in, or paste an Anthropic API key here. It's saved in this device's Keychain, debug builds only.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                SecureField("sk-ant-…", text: $developerKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.callout)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.primary.opacity(0.06)))
                Button("Save") {
                    viewModel.saveDeveloperKey(developerKey)
                    developerKey = ""
                }
                .font(.callout.weight(.semibold))
                .disabled(developerKey.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.picardoAccent.opacity(0.08)))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    #endif

    private var inputBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let pendingImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: pendingImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Button {
                        self.pendingImage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .offset(x: 6, y: -6)
                    .accessibilityLabel("Remove photo")
                }
                .padding(.top, 4)
            }

            HStack(alignment: .bottom, spacing: 8) {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.picardoAccent)
                        .frame(width: 36, height: 40)
                }
                .disabled(viewModel.isLoading)
                .accessibilityLabel("Attach a photo of an artwork")

                composeRow
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var composeRow: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField(pendingImage == nil ? "Ask Picasso" : "Ask about this photo", text: $viewModel.draft, axis: .vertical)
                .submitLabel(.send)
                .onChange(of: viewModel.draft) { _, text in
                    // Return sends, like a messaging app. The field grows for long questions.
                    guard text.hasSuffix("\n") else { return }
                    viewModel.draft = String(text.dropLast())
                    sendDraft()
                }
                .font(.body)
                .lineLimit(1...5)
                .focused($inputFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.05))
                )
                .disabled(viewModel.isLoading)

            Button(action: sendDraft) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? Color.picardoAccent : Color.secondary.opacity(0.4))
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
    }

    private var canSend: Bool {
        !viewModel.isLoading
            && (pendingImage != nil || !viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func sendDraft() {
        guard canSend else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        viewModel.send(image: pendingImage)
        pendingImage = nil
    }
}

// MARK: - Voice tab

/// Talk with Picasso: tap the mic, speak, tap again. Picasso answers out loud.
private struct PicassoVoiceTab: View {
    @ObservedObject var viewModel: ChatViewModel
    var onShowChat: () -> Void

    @StateObject private var speech = PicassoSpeech()
    @State private var breathe = false
    @State private var awaitingReplyAfter: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let quickQuestions = [
        "Find me a calm piece for a bedroom",
        "Tell me about Impressionism",
        "Quiz me on famous artists",
    ]

    private var isListening: Bool { speech.state == .listening }
    private var latestReply: PicassoChatMessage? {
        viewModel.messages.last { $0.role == .assistant }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                Spacer().frame(height: 16)

                Button(action: toggleMic) {
                    ZStack {
                        Circle()
                            .fill(Color.picardoAccent.opacity(isListening ? 0.22 : 0.14))
                            .frame(width: 150, height: 150)
                            .scaleEffect(breathe ? 1.06 : 1)
                        Circle()
                            .fill(isListening ? Color.picardoNeonRed : Color.picardoAccent)
                            .frame(width: 96, height: 96)
                        Image(systemName: isListening ? "stop.fill" : "mic.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.white)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
                .accessibilityLabel(isListening ? "Stop and send" : "Start talking")

                Text(statusTitle)
                    .font(.system(.title3, design: .serif).weight(.bold))

                Text(statusDetail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .animation(.easeInOut(duration: 0.2), value: statusDetail)

                if let reply = latestReply, awaitingReplyAfter == nil, viewModel.messages.count > 1 {
                    replyCard(reply)
                        .padding(.horizontal, 20)
                }

                VStack(spacing: 10) {
                    ForEach(quickQuestions, id: \.self) { question in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            ask(question)
                        } label: {
                            Text(question)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.primary.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.picardoAccent.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isLoading || isListening)
                    }
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 24)
            }
        }
        .onChange(of: viewModel.isLoading) { _, loading in
            // Speak Picasso's answer to a question asked from this tab.
            guard !loading, let count = awaitingReplyAfter else { return }
            awaitingReplyAfter = nil
            if viewModel.messages.count > count, let reply = latestReply, !reply.isError {
                speech.speak(reply.content)
            }
        }
        .onChange(of: isListening) { _, listening in
            guard !reduceMotion else { return }
            if listening {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { breathe = true }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { breathe = false }
            }
        }
        .onDisappear { speech.reset() }
    }

    private var statusTitle: String {
        switch speech.state {
        case .listening: return "Listening…"
        case .speaking:  return "Picasso is speaking"
        default:         return viewModel.isLoading ? "Thinking…" : "Talk with Picasso"
        }
    }

    private var statusDetail: String {
        switch speech.state {
        case .listening:
            return speech.transcript.isEmpty ? "Ask anything about art. Tap stop when you're done." : speech.transcript
        case .unavailable(let reason):
            return reason
        case .speaking:
            return "Tap the mic to interrupt and ask something else."
        case .idle:
            return "Tap the mic to ask out loud, or pick a question below."
        }
    }

    private func replyCard(_ reply: PicassoChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                PicassoAvatar(size: 22)
                Text("Picasso")
                    .font(.caption.weight(.semibold))
                Spacer()
                Button {
                    if speech.state == .speaking { speech.stopSpeaking() } else { speech.speak(reply.content) }
                } label: {
                    Image(systemName: speech.state == .speaking ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.picardoAccent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(speech.state == .speaking ? "Stop reading" : "Read aloud")
            }
            Text(reply.content)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(6)
            if !reply.artworks.isEmpty {
                Button(action: onShowChat) {
                    Label("See \(reply.artworks.count) \(reply.artworks.count == 1 ? "piece" : "pieces") in chat", systemImage: "rectangle.stack")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.picardoAccent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.primary.opacity(0.05)))
    }

    private func toggleMic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if isListening {
            let heard = speech.stopListening()
            if !heard.isEmpty { ask(heard) }
        } else {
            Task { await speech.startListening() }
        }
    }

    private func ask(_ question: String) {
        speech.stopSpeaking()
        awaitingReplyAfter = viewModel.messages.count
        viewModel.send(question)
    }
}

// MARK: - Visual tab

private struct PicassoVisualTab: View {
    var onAsk: (String) -> Void
    var onAskWithImage: (String, UIImage) -> Void

    @State private var photo: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false

    private let photoQuestions = [
        "What style is this?",
        "Find similar pieces on Picartdo",
        "Explain the technique",
    ]

    private var artworks: [Artwork] {
        Artwork.samples.filter { UIImage(named: $0.imageName) != nil }
    }

    private let topics = ["Cubism", "Renaissance", "Abstract art", "Ink drawing", "Color theory", "Sculpture"]

    private let galleries: [(name: String, place: String)] = [
        ("The Louvre", "Paris"),
        ("MoMA", "New York"),
        ("Uffizi Gallery", "Florence"),
        ("Tate Modern", "London"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {

                showPicasso

                // Ask about a piece
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("Ask about a piece", subtitle: "Tap any artwork and Picasso will explain it")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(artworks.prefix(10)) { artwork in
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    onAsk("Tell me about the artwork \(artwork.title), made with \(artwork.medium). What style is it and what should I notice?")
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ArtworkImage(artwork: artwork, contentMode: .fill)
                                            .frame(width: 120, height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        Text(artwork.title)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                            .frame(width: 120, alignment: .leading)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                // Art info topics
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("Art info", subtitle: "Quick lessons on any topic")

                    FlowChips(items: topics) { topic in
                        onAsk("Explain \(topic) in simple words")
                    }
                    .padding(.horizontal, 16)
                }

                // Galleries
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("Art galleries", subtitle: "Learn about famous museums")

                    VStack(spacing: 10) {
                        ForEach(galleries, id: \.name) { gallery in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                onAsk("Tell me about \(gallery.name) in \(gallery.place). What art is it known for?")
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "building.columns.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color.picardoAccent)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(Color.picardoAccent.opacity(0.12)))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(gallery.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.primary)
                                        Text(gallery.place)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.primary.opacity(0.04))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Engage
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("Practice", subtitle: "Test what you know")

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onAsk("Quiz me on art history. One question at a time please.")
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "gamecontroller.fill")
                            Text("Start a quiz with Picasso")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Capsule().fill(Color.picardoAccent))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }

                Spacer().frame(height: 20)
            }
            .padding(.top, 18)
        }
    }

    /// Take or pick a photo of any artwork, then choose what to ask about it.
    private var showPicasso: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Show Picasso a piece", subtitle: "Snap a painting at a gallery, a mural, or your own work")

            if let photo {
                VStack(alignment: .leading, spacing: 12) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        Button {
                            self.photo = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.55))
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                        .accessibilityLabel("Remove photo")
                    }
                    ForEach(photoQuestions, id: \.self) { question in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onAskWithImage(question, photo)
                            self.photo = nil
                        } label: {
                            HStack {
                                Text(question)
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.primary.opacity(0.05)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            } else {
                HStack(spacing: 10) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Take photo", systemImage: "camera.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(Color.picardoAccent))
                        }
                        .buttonStyle(.plain)
                    }
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Choose photo", systemImage: "photo.on.rectangle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.picardoAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Capsule().strokeBorder(Color.picardoAccent, lineWidth: 1.5))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    photo = image
                }
                photoItem = nil
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            PicassoCameraPicker { image in photo = image }
                .ignoresSafeArea()
        }
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(.headline, design: .serif).weight(.bold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Simple wrapping chips

private struct FlowChips: View {
    let items: [String]
    var onTap: (String) -> Void

    var body: some View {
        let rows = items.chunked(into: 3)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onTap(item)
                        } label: {
                            Text(item)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.picardoAccent.opacity(0.12)))
                                .overlay(
                                    Capsule().strokeBorder(Color.picardoAccent.opacity(0.35), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Bubbles

private struct PicassoTutorBubble: View {
    let message: PicassoChatMessage
    var onRetry: () -> Void
    var onOpenArtwork: (Artwork) -> Void = { _ in }
    var onRate: (Bool) -> Void = { _ in }

    @State private var rating: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .bottom, spacing: 8) {
                if message.role == .assistant {
                    PicassoAvatar(size: 26)
                    bubble
                    Spacer(minLength: 28)
                } else {
                    Spacer(minLength: 28)
                    bubble
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)

            if message.role == .assistant && !message.isError {
                VStack(alignment: .leading, spacing: 10) {
                    if !message.artworks.isEmpty { artworkCards }
                    ForEach(message.checkoutActions) { action in checkoutButton(action) }
                    if message.requestID != nil { feedbackRow }
                }
                .padding(.leading, 34)
            }
        }
    }

    private var artworkCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(message.artworks) { artwork in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onOpenArtwork(artwork)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            ArtworkImage(artwork: artwork, contentMode: .fill)
                                .frame(width: 140, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            Text(artwork.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Text("\(artwork.artistName) · \(artwork.price, format: .currency(code: "USD").precision(.fractionLength(0)))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(width: 140, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(artwork.title) by \(artwork.artistName), \(Int(artwork.price)) dollars")
                    .accessibilityHint("Opens the artwork")
                }
            }
        }
    }

    /// Opens the artwork page, where the buyer reviews and confirms the purchase themselves.
    private func checkoutButton(_ action: PicassoCheckoutAction) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if let artwork = message.artworks.first(where: { $0.id == action.listingId }) {
                onOpenArtwork(artwork)
            }
        } label: {
            Text("Buy \(action.title) · \(action.price, format: .currency(code: "USD").precision(.fractionLength(0)))")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.picardoAccent))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the artwork so you can review and confirm the purchase")
    }

    private var feedbackRow: some View {
        HStack(spacing: 14) {
            ForEach([true, false], id: \.self) { positive in
                Button {
                    guard rating == nil else { return }
                    rating = positive
                    onRate(positive)
                } label: {
                    Image(systemName: positive
                          ? (rating == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                          : (rating == false ? "hand.thumbsdown.fill" : "hand.thumbsdown"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(rating != nil)
                .accessibilityLabel(positive ? "Good reply" : "Bad reply")
            }
        }
    }

    private var bubble: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
            if let data = message.imageData, let photo = UIImage(data: data) {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel("Attached photo")
            }
            Text(message.content)
                .font(.body)
                .foregroundStyle(message.role == .user ? Color.white : Color.primary)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)

            if message.isError && message.canRetry {
                Button("Retry") {
                    onRetry()
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
                .tint(Color.picardoAccent)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(bubbleColor)
        )
    }

    private var bubbleColor: Color {
        if message.isError {
            return Color.red.opacity(0.12)
        }
        return message.role == .user ? Color.picardoAccent : Color.primary.opacity(0.06)
    }

    private var accessibilityLabel: String {
        let who = message.role == .user ? "You" : "Picasso"
        return "\(who): \(message.content)"
    }
}

private struct PicassoTypingIndicator: View {
    @State private var phase = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            PicassoAvatar(size: 26)
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 7, height: 7)
                        .opacity(phase == index ? 1 : 0.35)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
            Spacer(minLength: 28)
        }
        .accessibilityLabel("Picasso is thinking")
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 280_000_000)
                phase = (phase + 1) % 3
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        PicassoButton()
    }
}

// MARK: - Camera

/// System camera for "Show Picasso a piece".
private struct PicassoCameraPicker: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PicassoCameraPicker
        init(_ parent: PicassoCameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onCapture(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
