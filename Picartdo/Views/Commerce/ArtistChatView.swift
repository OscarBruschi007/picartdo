import SwiftUI

/// Opens a chat with an artist — from a listing or from their profile.
struct ArtistChatView: View {
    let partnerID: UUID
    let partnerName: String
    let note: String
    @Environment(SessionStore.self) private var session

    @State private var conversation: DMConversation

    init(artwork: Artwork) {
        self.init(partnerID: artwork.artistID, partnerName: artwork.artistName, note: artwork.title)
    }

    init(artist: Artist) {
        self.init(partnerID: artist.id, partnerName: artist.name, note: artist.tagline)
    }

    init(partnerName: String, note: String = "") {
        self.init(
            partnerID: Artist.named(partnerName)?.id ?? UUID(),
            partnerName: partnerName,
            note: note
        )
    }

    private init(partnerID: UUID, partnerName: String, note: String) {
        self.partnerID = partnerID
        self.partnerName = partnerName
        self.note = note
        let handle = partnerName.lowercased().replacingOccurrences(of: " ", with: ".")
        _conversation = State(initialValue: DMConversation(
            id: partnerID,
            name: handle,
            initials: String(partnerName.prefix(2)).uppercased(),
            avatarColor: Color.picardoGold,
            lastMessage: "Start a conversation",
            time: "now",
            unreadCount: 0,
            isActive: true,
            isMuted: false,
            note: note,
            category: .artist,
            relationTag: "Artist",
            hasStory: false,
            messages: [],
            avatarImage: Artist.named(partnerName)?.avatarImage
        ))
    }

    var body: some View {
        ChatView(conversation: $conversation, recipientID: partnerID, onSend: { _ in })
            .task { await loadExistingMessages() }
    }

    private func loadExistingMessages() async {
        guard AppConfig.isBackendConfigured,
              session.isAuthenticated,
              let userID = session.profile?.id else { return }
        guard let rows = try? await MessagingService.loadThread(with: userID, partnerID: partnerID) else { return }
        conversation.messages = rows.map { row in
            ChatMessage(
                text: row.content,
                isFromMe: row.senderId == userID,
                date: row.createdAt
            )
        }
        if let last = conversation.messages.last {
            conversation.lastMessage = last.text
        }
    }
}

extension View {
    func messageComposer(artwork: Binding<Artwork?>) -> some View {
        fullScreenCover(item: artwork) { piece in
            NavigationStack {
                ArtistChatView(artwork: piece)
            }
            .presentationBackground(Color.picardoBackground)
        }
    }

    func messageComposer(artist: Binding<Artist?>) -> some View {
        fullScreenCover(item: artist) { person in
            NavigationStack {
                ArtistChatView(artist: person)
            }
            .presentationBackground(Color.picardoBackground)
        }
    }

    func messageComposer(isPresented: Binding<Bool>, artwork: Artwork) -> some View {
        fullScreenCover(isPresented: isPresented) {
            NavigationStack {
                ArtistChatView(artwork: artwork)
            }
            .presentationBackground(Color.picardoBackground)
        }
    }

    func messageComposer(isPresented: Binding<Bool>, artist: Artist) -> some View {
        fullScreenCover(isPresented: isPresented) {
            NavigationStack {
                ArtistChatView(artist: artist)
            }
            .presentationBackground(Color.picardoBackground)
        }
    }
}
