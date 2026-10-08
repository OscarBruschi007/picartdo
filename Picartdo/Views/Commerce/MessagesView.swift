import SwiftUI
import UIKit

// MARK: - Models

enum DMCategory: String, Hashable, CaseIterable, Identifiable {
    case customer, follower, artist, request
    var id: String { rawValue }
    var label: String {
        switch self {
        case .customer: return "Customer"
        case .follower: return "Follower"
        case .artist:   return "Artist"
        case .request:  return "Request"
        }
    }
}

enum DMFilter: String, CaseIterable, Identifiable {
    case all, customers, followers, unread, requests
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all:        return "All"
        case .customers:  return "Customers"
        case .followers:  return "Followers"
        case .unread:     return "Unread"
        case .requests:   return "Requests"
        }
    }
}

struct DMConversation: Identifiable, Hashable {
    let id: UUID
    var name: String
    var initials: String
    var avatarColor: Color
    var lastMessage: String
    var time: String
    var unreadCount: Int
    var isActive: Bool
    var isMuted: Bool
    var note: String?
    var category: DMCategory
    var relationTag: String?
    var hasStory: Bool
    var messages: [ChatMessage]

    var fullName: String {
        name.split(separator: ".").map { $0.capitalized }.joined(separator: " ")
    }

    static func == (lhs: DMConversation, rhs: DMConversation) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct ChatMessage: Identifiable, Hashable {
    let id: UUID
    var text: String
    var isFromMe: Bool
    var date: Date
    var hearted: Bool
    var reaction: String?

    init(
        id: UUID = UUID(),
        text: String,
        isFromMe: Bool,
        date: Date = Date(),
        hearted: Bool = false,
        reaction: String? = nil
    ) {
        self.id = id
        self.text = text
        self.isFromMe = isFromMe
        self.date = date
        self.hearted = hearted
        self.reaction = reaction
    }

    var time: String {
        date.formatted(date: .omitted, time: .shortened)
    }
}

struct DMNote: Identifiable {
    let id: UUID
    let name: String
    let initials: String
    let color: Color
    let text: String
    var isMine: Bool = false
}

private enum DMClock {
    static let now = Date()
    static func minutes(_ m: Double) -> Date { now.addingTimeInterval(-m * 60) }
    static func hours(_ h: Double) -> Date { now.addingTimeInterval(-h * 3600) }
    static func days(_ d: Double) -> Date { now.addingTimeInterval(-d * 86_400) }
}

extension DMConversation {
    static let samples: [DMConversation] = [
        DMConversation(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000001")!,
            name: "sofia.moretti", initials: "SM",
            avatarColor: Color(red: 0.85, green: 0.35, blue: 0.50),
            lastMessage: "Amazing. I'll take it", time: "2m",
            unreadCount: 2, isActive: true, isMuted: false, note: "Need this",
            category: .customer, relationTag: "Bought Long Canvas", hasStory: true,
            messages: [
                ChatMessage(text: "Hi! I saw your Long Canvas and I'm obsessed", isFromMe: false, date: DMClock.minutes(48)),
                ChatMessage(text: "It's one of my favorites too", isFromMe: true, date: DMClock.minutes(42)),
                ChatMessage(text: "Is the Long Canvas still available?", isFromMe: false, date: DMClock.minutes(18)),
                ChatMessage(text: "Yes — I can hold it for you", isFromMe: true, date: DMClock.minutes(12)),
                ChatMessage(text: "Amazing. I'll take it", isFromMe: false, date: DMClock.minutes(2)),
            ]
        ),
        DMConversation(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000002")!,
            name: "lucas.fern", initials: "LF",
            avatarColor: Color(red: 0.25, green: 0.45, blue: 0.90),
            lastMessage: "Sent you an offer for Neon Portrait", time: "18m",
            unreadCount: 1, isActive: true, isMuted: false, note: nil,
            category: .customer, relationTag: "Offer $1,200", hasStory: true,
            messages: [
                ChatMessage(text: "Hey, saw your latest work. Incredible.", isFromMe: false, date: DMClock.minutes(28)),
                ChatMessage(text: "Thanks Lucas, really appreciate it!", isFromMe: true, date: DMClock.minutes(22)),
                ChatMessage(text: "Sent you an offer for Neon Portrait", isFromMe: false, date: DMClock.minutes(18)),
            ]
        ),
        DMConversation(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000003")!,
            name: "vale.cruz", initials: "VC",
            avatarColor: Color(red: 0.35, green: 0.75, blue: 0.40),
            lastMessage: "I'll have it framed and shipped by Friday", time: "1h",
            unreadCount: 0, isActive: false, isMuted: false, note: "🔥",
            category: .customer, relationTag: "Bought Golden Gate", hasStory: false,
            messages: [
                ChatMessage(text: "The Golden Gate piece arrived", isFromMe: false, date: DMClock.hours(26)),
                ChatMessage(text: "So happy you love it!", isFromMe: true, date: DMClock.hours(25)),
                ChatMessage(text: "Can I commission a similar one?", isFromMe: false, date: DMClock.hours(2)),
                ChatMessage(text: "I'll have it framed and shipped by Friday", isFromMe: true, date: DMClock.hours(1)),
            ]
        ),
        DMConversation(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000004")!,
            name: "matteo.ricci", initials: "MR",
            avatarColor: Color(red: 0.85, green: 0.58, blue: 0.15),
            lastMessage: "Are you taking commissions right now?", time: "3h",
            unreadCount: 1, isActive: false, isMuted: false, note: nil,
            category: .request, relationTag: nil, hasStory: false,
            messages: [
                ChatMessage(text: "Are you taking commissions right now?", isFromMe: false, date: DMClock.hours(3)),
            ]
        ),
        DMConversation(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000005")!,
            name: "camila.torres", initials: "CT",
            avatarColor: Color(red: 0.55, green: 0.25, blue: 0.82),
            lastMessage: "Congrats on the featured listing!", time: "1d",
            unreadCount: 0, isActive: false, isMuted: false, note: "Love this",
            category: .follower, relationTag: "Follows you", hasStory: true,
            messages: [
                ChatMessage(text: "Congrats on the featured listing!", isFromMe: false, date: DMClock.days(1)),
                ChatMessage(text: "Thank you so much!", isFromMe: true, date: DMClock.hours(22)),
            ]
        ),
        DMConversation(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000006")!,
            name: "andres.molina", initials: "AM",
            avatarColor: Color(red: 0.15, green: 0.65, blue: 0.70),
            lastMessage: "Let me know when it arrives!", time: "2d",
            unreadCount: 0, isActive: false, isMuted: false, note: nil,
            category: .follower, relationTag: "Follows you", hasStory: false,
            messages: [
                ChatMessage(text: "Just placed an order for Fire Cycle", isFromMe: false, date: DMClock.days(2.1)),
                ChatMessage(text: "Awesome! I'll package it with care", isFromMe: true, date: DMClock.days(2)),
                ChatMessage(text: "Let me know when it arrives!", isFromMe: true, date: DMClock.days(2)),
            ]
        ),
        DMConversation(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000007")!,
            name: "elena.rossi", initials: "ER",
            avatarColor: Color(red: 0.45, green: 0.38, blue: 0.72),
            lastMessage: "Want to split a booth in May?", time: "4d",
            unreadCount: 0, isActive: false, isMuted: false, note: nil,
            category: .artist, relationTag: "Artist", hasStory: false,
            messages: [
                ChatMessage(text: "Loved your last drop.", isFromMe: false, date: DMClock.days(4.2)),
                ChatMessage(text: "Want to split a booth in May?", isFromMe: false, date: DMClock.days(4)),
            ]
        ),
    ]

    static var withNotes: [DMConversation] { samples.filter { $0.note != nil } }
}

// MARK: - Inbox

struct DirectMessagesView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var chipNS

    @State private var searchText = ""
    @State private var filter: DMFilter = ProcessInfo.processInfo.arguments.contains("--dm-customers") ? .customers : .all
    @State private var conversations = DMConversation.samples
    @State private var pendingDelete: DMConversation?
    @State private var openedID: UUID?
    @State private var identity = ProfileIdentity.load()

    private var theme: DMTheme { DMTheme.resolve(colorScheme) }

    private var filtered: [DMConversation] {
        conversations.filter { convo in
            switch filter {
            case .all:        if convo.category == .request { return false }
            case .customers:  if convo.category != .customer { return false }
            case .followers:  if convo.category != .follower { return false }
            case .unread:     if convo.unreadCount == 0 { return false }
            case .requests:   if convo.category != .request { return false }
            }
            if searchText.isEmpty { return true }
            return convo.name.localizedCaseInsensitiveContains(searchText)
                || convo.lastMessage.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var listAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : PicardoMotion.quick
    }

    var body: some View {
        inbox
            .background {
                PicartdoBackground().ignoresSafeArea()
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $openedID) { id in
                chatView(for: id)
            }
            .confirmationDialog(
                "Delete conversation?",
                isPresented: Binding(
                    get: { pendingDelete != nil },
                    set: { if !$0 { pendingDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let id = pendingDelete?.id {
                        withAnimation(listAnimation) {
                            conversations.removeAll { $0.id == id }
                        }
                    }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
            .background(SwipeBackEnabler())
            .task {
                if ProcessInfo.processInfo.arguments.contains("--open-chat") {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    openedID = conversations.first?.id
                }
                await loadInbox()
            }
    }

    private var inbox: some View {
        VStack(spacing: 0) {
            header
            searchField
            notesRow
            messagesRequestsRow
            filterChips
            conversationList
        }
    }

    // MARK: Header — PICARDO wordmark chrome

    private var header: some View {
        ZStack {
            Text("MESSAGES")
                .font(PicardoType.wordmark(22))
                .kerning(2.5)
                .foregroundStyle(theme.text)
            HStack {
                DMBackChevron()
                Spacer()
                Button {
                    Haptics.tap()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(theme.text)
                }
                .accessibilityLabel("New message")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(theme.secondary)
            TextField("Search", text: $searchText)
                .font(.system(size: 16))
                .foregroundStyle(theme.text)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(theme.searchFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.black.opacity(colorScheme == .dark ? 0 : 0.06), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var notesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                noteBubble(
                    name: "Your note",
                    initials: String(identity.name.prefix(1)).uppercased(),
                    color: Color.picardoNeonRed,
                    text: nil,
                    isMine: true
                )
                ForEach(DMConversation.withNotes) { convo in
                    noteBubble(
                        name: convo.name.split(separator: ".").first.map(String.init) ?? convo.name,
                        initials: convo.initials,
                        color: convo.avatarColor,
                        text: convo.note,
                        isMine: false
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }

    private func noteBubble(name: String, initials: String, color: Color, text: String?, isMine: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .top) {
                Circle()
                    .fill(color.opacity(0.88))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Text(initials)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                    .padding(.top, 20)

                if let text, !text.isEmpty {
                    Text(text)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(theme.text)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(theme.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(theme.hairline, lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 3, y: 1)
                } else {
                    Image(systemName: "bubble.right.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(theme.background)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(theme.secondary)
                                .offset(y: -1)
                        }
                        .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                        .offset(y: 2)
                }
            }
            .frame(width: 72, height: 88)

            Text(name)
                .font(.system(size: 12))
                .foregroundStyle(theme.secondary)
                .lineLimit(1)
                .frame(width: 72)
        }
    }

    private var messagesRequestsRow: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Inbox")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.picardoGold)
                Text("Messages")
                    .font(.system(size: 23, weight: .black, design: .serif))
                    .foregroundStyle(theme.text)
                Rectangle()
                    .fill(Color.picardoGold)
                    .frame(width: 32, height: 2)
                    .padding(.top, 2)
            }
            Spacer()
            Button {
                Haptics.select()
                withAnimation(listAnimation) { filter = .requests }
            } label: {
                Text("Requests")
                    .font(PicardoType.cta(13))
                    .kerning(0.6)
                    .foregroundStyle(Color.picardoGold)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DMFilter.allCases) { item in
                    let selected = filter == item
                    Button {
                        Haptics.select()
                        withAnimation(listAnimation) { filter = item }
                    } label: {
                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(selected ? theme.background : theme.text)
                            .padding(.horizontal, 14)
                            .frame(height: 32)
                            .background {
                                if selected {
                                    Capsule()
                                        .fill(theme.text)
                                        .matchedGeometryEffect(id: "igChip", in: chipNS)
                                } else {
                                    Capsule().fill(theme.chipUnselected)
                                }
                            }
                            .overlay(
                                Capsule().strokeBorder(
                                    Color.black.opacity(selected || colorScheme == .dark ? 0 : 0.06),
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(PicardoPressStyle())
                    .accessibilityLabel(item.title)
                }
            }
            .padding(.horizontal, 16)
            .animation(reduceMotion ? nil : PicardoMotion.quick, value: filter)
        }
        .padding(.bottom, 4)
    }

    private var conversationList: some View {
        List {
            if filtered.isEmpty {
                Text(emptyLine)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 48)
                    .listRowBackground(theme.background)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(filtered) { convo in
                    Button {
                        Haptics.tap()
                        openedID = convo.id
                    } label: {
                        PicardoMessageRow(conversation: convo, theme: theme)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(theme.background)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .contextMenu { rowMenu(convo) }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) { pendingDelete = convo } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button { markUnread(convo.id) } label: {
                            Label("Unread", systemImage: "message.badge")
                        }
                        .tint(DMTheme.unreadBlue)
                        Button { toggleMute(convo.id) } label: {
                            Label(convo.isMuted ? "Unmute" : "Mute", systemImage: "bell.slash")
                        }
                        .tint(.gray)
                    }
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 72)
        .animation(listAnimation, value: filter)
        .animation(listAnimation, value: searchText)
        .refreshable {
            try? await Task.sleep(nanoseconds: 450_000_000)
            await loadInbox()
        }
    }

    @ViewBuilder
    private func chatView(for id: UUID) -> some View {
        if let index = conversations.firstIndex(where: { $0.id == id }) {
            ChatView(conversation: $conversations[index])
        } else {
            Color.clear.background(theme.background)
        }
    }

    private var emptyLine: String {
        switch filter {
        case .all:        return "No messages yet"
        case .customers:  return "No customer messages yet"
        case .followers:  return "No follower messages yet"
        case .unread:     return "No unread messages"
        case .requests:   return "No requests"
        }
    }

    @ViewBuilder
    private func rowMenu(_ convo: DMConversation) -> some View {
        Button { markUnread(convo.id) } label: { Label("Mark as unread", systemImage: "message.badge") }
        Button { toggleMute(convo.id) } label: {
            Label(convo.isMuted ? "Unmute" : "Mute", systemImage: "bell.slash")
        }
        Button(role: .destructive) { pendingDelete = convo } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func markUnread(_ id: UUID) {
        guard let i = conversations.firstIndex(where: { $0.id == id }) else { return }
        withAnimation { conversations[i].unreadCount = max(1, conversations[i].unreadCount) }
    }

    private func toggleMute(_ id: UUID) {
        guard let i = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[i].isMuted.toggle()
    }

    private func loadInbox() async {
        guard AppConfig.isBackendConfigured,
              session.isAuthenticated,
              let userID = session.profile?.id else { return }
        guard let rows = try? await MessagingService.fetchMessages(with: userID), !rows.isEmpty else { return }
        var grouped: [UUID: [MessagingService.MessageRow]] = [:]
        for row in rows {
            let partner = row.senderId == userID ? row.recipientId : row.senderId
            grouped[partner, default: []].append(row)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        conversations = grouped.map { partnerID, msgs in
            let sorted = msgs.sorted { $0.createdAt < $1.createdAt }
            let last = sorted.last!
            return DMConversation(
                id: partnerID,
                name: String(partnerID.uuidString.prefix(8)) + "…",
                initials: String(partnerID.uuidString.prefix(2)).uppercased(),
                avatarColor: DMTheme.unreadBlue,
                lastMessage: last.content,
                time: formatter.string(from: last.createdAt),
                unreadCount: sorted.filter { !$0.read && $0.recipientId == userID }.count,
                isActive: false,
                isMuted: false,
                note: nil,
                category: .request,
                relationTag: nil,
                hasStory: false,
                messages: sorted.map {
                    ChatMessage(text: $0.content, isFromMe: $0.senderId == userID, date: $0.createdAt)
                }
            )
        }
    }
}

private struct DMBackChevron: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button {
            Haptics.tap()
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 28, height: 28)
        }
        .accessibilityLabel("Back")
    }
}

// MARK: - Row  (56pt avatar, no divider)

struct PicardoMessageRow: View {
    let conversation: DMConversation
    var theme: DMTheme

    var body: some View {
        HStack(spacing: 12) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.name)
                    .font(.system(size: 16, weight: conversation.unreadCount > 0 ? .bold : .regular, design: .serif))
                    .foregroundStyle(theme.text)
                    .lineLimit(1)
                HStack(spacing: 0) {
                    Text(conversation.lastMessage)
                        .lineLimit(1)
                    Text(" · \(conversation.time)")
                        .fixedSize()
                }
                .font(.system(size: 14, weight: conversation.unreadCount > 0 ? .regular : .regular))
                .foregroundStyle(theme.secondary)
            }
            Spacer(minLength: 8)
            if conversation.unreadCount > 0 {
                Circle()
                    .fill(theme.unread)
                    .frame(width: 8, height: 8)
                    .transition(.opacity)
            } else {
                Image(systemName: "camera")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(theme.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .frame(minHeight: 72)
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(conversation.avatarColor.opacity(0.9))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(conversation.initials)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .overlay {
                    if conversation.hasStory {
                        Circle()
                            .strokeBorder(
                                AngularGradient(
                                    colors: [
                                        Color.picardoNeonRed,
                                        Color.picardoGold,
                                        Color.picardoNeonRed,
                                    ],
                                    center: .center
                                ),
                                lineWidth: 2.5
                            )
                            .padding(-3)
                    }
                }
            if conversation.isActive {
                Circle()
                    .fill(theme.activeGreen)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(theme.background, lineWidth: 2))
            }
        }
    }
}

// MARK: - Chat

struct ChatView: View {
    @Binding var conversation: DMConversation
    var recipientID: UUID = UUID()
    var onSend: ((ChatMessage) -> Void)? = nil

    @Environment(SessionStore.self) private var session
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var messageText = ""
    @State private var replyTo: ChatMessage?
    @State private var reactionTarget: UUID?
    @State private var isTyping = false
    @FocusState private var inputFocused: Bool

    private var theme: DMTheme { DMTheme.resolve(colorScheme) }
    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            chatNav
            Rectangle()
                .fill(theme.hairline)
                .frame(height: 0.33)
            thread
            inputBar
        }
        .background {
            PicartdoBackground().ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear {
            withAnimation(.easeOut(duration: 0.28)) {
                conversation.unreadCount = 0
            }
        }
        .coordinateSpace(name: "dmChatScreen")
        .background(SwipeBackEnabler())
        .overlay {
            if let reactionTarget, let msg = conversation.messages.first(where: { $0.id == reactionTarget }) {
                reactionOverlay(msg)
            }
        }
        .onAppear {
            isTyping = false
        }
    }

    private var chatNav: some View {
        HStack(spacing: 10) {
            DMBackChevron()
            Circle()
                .fill(conversation.avatarColor.opacity(0.9))
                .frame(width: 28, height: 28)
                .overlay(
                    Text(conversation.initials)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                )
            VStack(alignment: .leading, spacing: 0) {
                Text(conversation.fullName)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundStyle(theme.text)
                Text(conversation.isActive ? "Active now" : "Active \(conversation.time) ago")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.secondary)
            }
            Spacer()
            HStack(spacing: 18) {
                Button { Haptics.tap() } label: {
                    Image(systemName: "phone")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(theme.text)
                }
                Button { Haptics.tap() } label: {
                    Image(systemName: "video")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(theme.text)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var thread: some View {
        GeometryReader { viewport in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileCard
                            .padding(.top, 20)
                            .padding(.bottom, 24)

                        ForEach(Array(conversation.messages.enumerated()), id: \.element.id) { idx, msg in
                            if shouldShowTimestamp(at: idx) {
                                Text(timestampLabel(for: msg.date))
                                    .font(.system(size: 12))
                                    .foregroundStyle(theme.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            bubbleRow(msg, index: idx)
                                .id(msg.id)
                                .padding(.bottom, place(at: idx) == .last || place(at: idx) == .single ? 8 : 2)
                        }

                        if isTyping {
                            typingRow.id("typing")
                        }

                        if let last = conversation.messages.last, last.isFromMe {
                            Text("Seen")
                                .font(.system(size: 12))
                                .foregroundStyle(theme.secondary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.trailing, 16)
                                .padding(.top, 2)
                        }
                        Color.clear.frame(height: 8).id("bottom")
                    }
                    .frame(minHeight: viewport.size.height, alignment: .bottom)
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: conversation.messages.count) {
                    withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.38, dampingFraction: 0.82)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var profileCard: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(conversation.avatarColor.opacity(0.9))
                .frame(width: 88, height: 88)
                .overlay(
                    Text(conversation.initials)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                )
            Text(conversation.fullName)
                .font(.system(size: 18, weight: .black, design: .serif))
                .foregroundStyle(theme.text)
            Text(conversation.name)
                .font(.system(size: 14))
                .foregroundStyle(theme.secondary)
            if let tag = conversation.relationTag {
                Text(tag)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.picardoGold)
            }
            Text("PICARDO")
                .font(PicardoType.meta(11))
                .kerning(1.6)
                .foregroundStyle(theme.secondary)
            Button {
                Haptics.tap()
            } label: {
                Text("View profile")
                    .font(PicardoType.cta(13))
                    .kerning(0.8)
                    .foregroundStyle(theme.text)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(theme.searchFill, in: Capsule())
                    .overlay(Capsule().strokeBorder(theme.hairline, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private func bubbleRow(_ msg: ChatMessage, index: Int) -> some View {
        let cluster = place(at: index)
        let showAvatar = !msg.isFromMe && (cluster == .last || cluster == .single)
        return HStack(alignment: .bottom, spacing: 8) {
            if msg.isFromMe {
                Spacer(minLength: 64)
                bubble(msg, cluster: cluster)
            } else {
                if showAvatar {
                    Circle()
                        .fill(conversation.avatarColor.opacity(0.9))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(conversation.initials)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white)
                        )
                } else {
                    Color.clear.frame(width: 28, height: 28)
                }
                bubble(msg, cluster: cluster)
                Spacer(minLength: 64)
            }
        }
        .padding(.horizontal, 12)
        .overlay(alignment: msg.isFromMe ? .trailing : .leading) {
            if msg.hearted || msg.reaction != nil {
                Text(msg.reaction ?? "❤️")
                    .font(.system(size: 14))
                    .padding(4)
                    .background(theme.background, in: Circle())
                    .overlay(Circle().stroke(theme.hairline, lineWidth: 0.5))
                    .offset(x: msg.isFromMe ? -10 : 42, y: 14)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 24).onEnded { value in
                if value.translation.width > 50 {
                    Haptics.select()
                    replyTo = msg
                }
            }
        )
    }

    private func bubble(_ msg: ChatMessage, cluster: BubblePlace) -> some View {
        Text(msg.text)
            .font(.system(size: 15))
            .foregroundStyle(msg.isFromMe ? .white : theme.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if msg.isFromMe {
                    PicardoOutgoingFill()
                } else {
                    UnevenRoundedRectangle(cornerRadii: radii(for: cluster, me: false), style: .continuous)
                        .fill(theme.theirBubble)
                }
            }
            .clipShape(UnevenRoundedRectangle(cornerRadii: radii(for: cluster, me: msg.isFromMe), style: .continuous))
            .contentShape(UnevenRoundedRectangle(cornerRadii: radii(for: cluster, me: msg.isFromMe), style: .continuous))
            .onTapGesture(count: 2) {
                Haptics.success()
                heart(msg.id)
            }
            .onLongPressGesture {
                Haptics.tap()
                reactionTarget = msg.id
            }
            .transition(
                reduceMotion
                    ? .opacity
                    : .scale(scale: 0.9, anchor: msg.isFromMe ? .bottomTrailing : .bottomLeading).combined(with: .opacity)
            )
    }

    private func reactionBar(for msg: ChatMessage) -> some View {
        HStack(spacing: 10) {
            ForEach(["❤️", "😂", "😮", "😢", "😡"], id: \.self) { emoji in
                Button {
                    setReaction(msg.id, emoji)
                    reactionTarget = nil
                } label: {
                    Text(emoji).font(.system(size: 22))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func reactionOverlay(_ msg: ChatMessage) -> some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { reactionTarget = nil }
            VStack(spacing: 14) {
                reactionBar(for: msg)
                VStack(spacing: 0) {
                    overlayAction("Reply", "arrowshape.turn.up.left") {
                        replyTo = msg
                        reactionTarget = nil
                    }
                    overlayAction("Copy", "doc.on.doc") {
                        UIPasteboard.general.string = msg.text
                        reactionTarget = nil
                    }
                    overlayAction("Forward", "paperplane") {
                        Haptics.tap()
                        reactionTarget = nil
                    }
                    if msg.isFromMe {
                        overlayAction("Unsend", "trash", destructive: true) {
                            unsend(msg.id)
                            reactionTarget = nil
                        }
                    }
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 48)
        }
    }

    private func overlayAction(_ title: String, _ icon: String, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundStyle(destructive ? Color.red : theme.text)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(destructive ? Color.red : theme.text)
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
        }
        .buttonStyle(.plain)
    }

    private var typingRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(conversation.avatarColor.opacity(0.9))
                .frame(width: 28, height: 28)
            IGTypingDots(color: theme.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(theme.theirBubble, in: Capsule())
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    private var inputBar: some View {
        VStack(spacing: 6) {
            if let replyTo {
                HStack {
                    Rectangle().fill(DMTheme.unreadBlue).frame(width: 2)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Replying to \(replyTo.isFromMe ? "yourself" : conversation.name)")
                            .font(.system(size: 12, weight: .semibold))
                        Text(replyTo.text).font(.system(size: 12)).foregroundStyle(theme.secondary).lineLimit(1)
                    }
                    Spacer()
                    Button { self.replyTo = nil } label: {
                        Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(theme.secondary)
                    }
                }
                .padding(.horizontal, 16)
            }
            HStack(alignment: .bottom, spacing: 8) {
                Button { Haptics.tap() } label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(theme.cameraBlue, in: Circle())
                }
                .accessibilityLabel("Camera")

                HStack(spacing: 8) {
                    TextField("Message...", text: $messageText, axis: .vertical)
                        .font(.system(size: 15))
                        .foregroundStyle(theme.text)
                        .lineLimit(1...5)
                        .focused($inputFocused)
                    if canSend {
                        Button("Send", action: sendMessage)
                            .font(PicardoType.cta(14))
                            .kerning(0.6)
                            .foregroundStyle(Color.picardoNeonRed)
                    } else {
                        Button { Haptics.tap() } label: {
                            Image(systemName: "mic")
                                .font(.system(size: 18))
                                .foregroundStyle(theme.text)
                        }
                        Button { Haptics.tap() } label: {
                            Image(systemName: "photo")
                                .font(.system(size: 18))
                                .foregroundStyle(theme.text)
                        }
                        Button { Haptics.tap() } label: {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 18))
                                .foregroundStyle(theme.text)
                        }
                    }
                }
                .padding(.leading, 14)
                .padding(.trailing, 10)
                .padding(.vertical, 8)
                .background(theme.searchFill, in: Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .animation(reduceMotion ? .easeInOut(duration: 0.15) : PicardoMotion.quick, value: canSend)
        }
        .background(theme.background)
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messageText = ""
        let msg = ChatMessage(text: text, isFromMe: true, date: Date())
        let animation: Animation = reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.38, dampingFraction: 0.78)
        withAnimation(animation) {
            conversation.messages.append(msg)
            conversation.lastMessage = msg.text
            conversation.time = "now"
            conversation.unreadCount = 0
        }
        replyTo = nil
        onSend?(msg)
        Haptics.tap()
        guard AppConfig.isBackendConfigured,
              session.isAuthenticated,
              let senderID = session.profile?.id else { return }
        Task {
            try? await MessagingService.sendMessage(to: recipientID, content: text, listingID: nil, senderID: senderID)
        }
    }

    private func heart(_ id: UUID) {
        guard let i = conversation.messages.firstIndex(where: { $0.id == id }) else { return }
        conversation.messages[i].hearted.toggle()
        if conversation.messages[i].hearted { conversation.messages[i].reaction = "❤️" }
        else { conversation.messages[i].reaction = nil }
    }

    private func setReaction(_ id: UUID, _ emoji: String) {
        guard let i = conversation.messages.firstIndex(where: { $0.id == id }) else { return }
        conversation.messages[i].reaction = emoji
        conversation.messages[i].hearted = emoji == "❤️"
    }

    private func unsend(_ id: UUID) {
        conversation.messages.removeAll { $0.id == id }
    }

    private func shouldShowTimestamp(at index: Int) -> Bool {
        if index == 0 { return true }
        let prev = conversation.messages[index - 1]
        return conversation.messages[index].date.timeIntervalSince(prev.date) > 3600
    }

    private func timestampLabel(for date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).hour().minute())
    }

    private func place(at index: Int) -> BubblePlace {
        let messages = conversation.messages
        let msg = messages[index]
        let prevSame = index > 0
            && messages[index - 1].isFromMe == msg.isFromMe
            && msg.date.timeIntervalSince(messages[index - 1].date) <= 3600
        let nextSame = index + 1 < messages.count
            && messages[index + 1].isFromMe == msg.isFromMe
            && messages[index + 1].date.timeIntervalSince(msg.date) <= 3600
        switch (prevSame, nextSame) {
        case (false, false): return .single
        case (false, true):  return .first
        case (true, true):   return .middle
        case (true, false):  return .last
        }
    }

    private func radii(for place: BubblePlace, me: Bool) -> RectangleCornerRadii {
        let large: CGFloat = 22
        let small: CGFloat = 4
        if me {
            switch place {
            case .single: return .init(topLeading: large, bottomLeading: large, bottomTrailing: large, topTrailing: large)
            case .first:  return .init(topLeading: large, bottomLeading: large, bottomTrailing: small, topTrailing: large)
            case .middle: return .init(topLeading: large, bottomLeading: large, bottomTrailing: small, topTrailing: small)
            case .last:   return .init(topLeading: large, bottomLeading: large, bottomTrailing: 4, topTrailing: small)
            }
        } else {
            switch place {
            case .single: return .init(topLeading: large, bottomLeading: large, bottomTrailing: large, topTrailing: large)
            case .first:  return .init(topLeading: large, bottomLeading: small, bottomTrailing: large, topTrailing: large)
            case .middle: return .init(topLeading: small, bottomLeading: small, bottomTrailing: large, topTrailing: large)
            case .last:   return .init(topLeading: small, bottomLeading: 4, bottomTrailing: large, topTrailing: large)
            }
        }
    }
}

private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        Controller()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard let pop = navigationController?.interactivePopGestureRecognizer else { return }
            pop.isEnabled = true
            pop.delegate = self
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }
    }
}

private struct PicardoOutgoingFill: View {
    var body: some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .global)
            let screen = UIScreen.main.bounds
            LinearGradient(
                colors: DMTheme.outgoingGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: screen.width, height: screen.height)
            .offset(x: -frame.minX, y: -frame.minY)
        }
    }
}

private struct IGTypingDots: View {
    var color: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bounce = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .offset(y: reduceMotion ? 0 : (bounce ? -2.5 : 2.5))
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.12),
                        value: bounce
                    )
            }
        }
        .onAppear { bounce = true }
        .accessibilityLabel("Typing")
    }
}

enum BubblePlace {
    case single, first, middle, last
}

#Preview {
    NavigationStack {
        DirectMessagesView()
    }
    .environment(SessionStore())
}
