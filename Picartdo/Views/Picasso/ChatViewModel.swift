import Foundation
import Combine
import Network
import UIKit

// MARK: - Picasso Chat ViewModel (Claude Messages API)
//
// Spec shape: ObservableObject with messages / isLoading / errorMessage.
// Message type is `PicassoChatMessage` (Commerce already owns `ChatMessage`).

@MainActor
final class ChatViewModel: ObservableObject {

    @Published var messages: [PicassoChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var draft: String = ""
    @Published var showSuggestions: Bool = true
    /// Debug builds without a backend session: true until a developer key is available.
    @Published private(set) var needsDeveloperKey = false
    @Published private(set) var isNetworkAvailable = true
    @Published private(set) var showsConnectionHelp = false
    @Published private(set) var keyError: String?

    static let suggestedPrompts = [
        "Find me something under $800",
        "Bold abstract for a living room",
        "Explain Cubism",
        "Quiz me on art history",
    ]

    private let contextLimit = 16
    private var lastFailedUserText: String?
    private var pathMonitor: NWPathMonitor?

    init() {
        seedWelcome()
        Task { await refreshKeyState() }
    }

    func seedWelcome() {
        guard messages.isEmpty else { return }
        messages = [
            PicassoChatMessage(
                role: .assistant,
                content: "Hi, I'm Picasso. Tell me your style, space or budget and I'll find pieces on Picartdo, show me a photo of any artwork, or ask me anything about art."
            )
        ]
        showSuggestions = true
    }

    /// Sends a message, optionally with a photo of an artwork for Picasso to look at.
    func send(_ text: String? = nil, image: UIImage? = nil) {
        var raw = (text ?? draft).trimmingCharacters(in: .whitespacesAndNewlines)
        let imageData = image.flatMap(Self.jpegData(from:))
        if raw.isEmpty, imageData != nil { raw = "What can you tell me about this artwork?" }
        guard !raw.isEmpty, !isLoading else { return }

        draft = ""
        showSuggestions = false
        errorMessage = nil
        lastFailedUserText = raw

        messages.append(PicassoChatMessage(role: .user, content: raw, imageData: imageData))
        isLoading = true

        Task {
            await requestAssistantReply()
        }
    }

    func retryLast() {
        guard lastFailedUserText != nil else { return }
        if let last = messages.last, last.isError {
            messages.removeLast()
        }
        isLoading = true
        errorMessage = nil
        Task { await requestAssistantReply() }
    }

    func clearSession() {
        messages.removeAll()
        seedWelcome()
        errorMessage = nil
        isLoading = false
    }

    /// Thumbs up/down on a Picasso reply. Best effort; failures are ignored.
    func rate(_ message: PicassoChatMessage, positive: Bool) {
        guard let requestID = message.requestID else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task {
            guard let token = await SupabaseClient.shared.currentAccessToken(),
                  let userID = Self.userID(fromJWT: token) else { return }
            try? await SupabaseClient.shared.upsert(
                table: "picasso_feedback",
                row: PicassoFeedbackRow(userId: userID, requestId: requestID, rating: positive ? 1 : -1),
                onConflict: "user_id,request_id"
            )
        }
    }

    // MARK: - Developer key (debug builds only)

    private func usesBackend() async -> Bool {
        guard AppConfig.isBackendConfigured else { return false }
        return await SupabaseClient.shared.currentAccessToken() != nil
    }

    func startNetworkMonitor() {
        guard pathMonitor == nil else {
            Task { await refreshKeyState() }
            return
        }
        let monitor = NWPathMonitor()
        pathMonitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }
                self.isNetworkAvailable = path.status == .satisfied
                await self.refreshKeyState()
            }
        }
        monitor.start(queue: DispatchQueue(label: "com.picartdo.picasso.network"))
        Task { await refreshKeyState() }
    }

    func refreshKeyState() async {
        let backend = await usesBackend()
        #if DEBUG
        let hasKey = !(PicassoAPIKeyStore.resolve() ?? "").isEmpty
        needsDeveloperKey = !backend && !hasKey
        showsConnectionHelp = !isNetworkAvailable || needsDeveloperKey
        #else
        needsDeveloperKey = false
        showsConnectionHelp = !isNetworkAvailable || (AppConfig.isBackendConfigured && !backend)
        #endif
    }

    /// Stores a developer key in the Keychain so Picasso works locally without the backend.
    /// Never used by release builds.
    @Published private(set) var isCheckingKey = false

    func saveDeveloperKey(_ key: String) {
        #if DEBUG
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isCheckingKey else { return }
        guard trimmed.hasPrefix("sk-ant-") else {
            keyError = "That doesn't look like an Anthropic key. It starts with sk-ant-."
            return
        }
        isCheckingKey = true
        keyError = nil
        Task {
            // Check the key with Anthropic before saving, so a bad key never hides this box.
            let result = await Self.validate(key: trimmed)
            isCheckingKey = false
            switch result {
            case .valid:
                guard PicassoAPIKeyStore.saveToKeychain(trimmed) else {
                    keyError = "Couldn't save the key. Try again."
                    return
                }
                needsDeveloperKey = false
                await refreshKeyState()
                Haptics.success()
                if let last = messages.last, last.isError, last.canRetry { retryLast() }
            case .rejected:
                keyError = "Anthropic rejected this key. Check it in console.anthropic.com."
            case .offline:
                keyError = "Couldn't reach Anthropic. Check your connection and try again."
            }
        }
        #endif
    }

    /// Removes the saved developer key (Picasso goes back to catalog-only answers).
    func removeDeveloperKey() {
        #if DEBUG
        PicassoAPIKeyStore.clear()
        Task { await refreshKeyState() }
        #endif
    }

    var hasDeveloperKey: Bool {
        #if DEBUG
        !(PicassoAPIKeyStore.resolve() ?? "").isEmpty
        #else
        false
        #endif
    }

    private enum KeyCheck { case valid, rejected, offline }

    private static func validate(key: String) async -> KeyCheck {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/models?limit=1")!)
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 15
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let status = (response as? HTTPURLResponse)?.statusCode else { return .offline }
        switch status {
        case 200..<300: return .valid
        case 401, 403: return .rejected
        default: return .offline
        }
    }

    // MARK: - Network

    private func requestAssistantReply() async {
        if await usesBackend() {
            await requestAgentReply()
            return
        }
        #if DEBUG
        if isNetworkAvailable, !(PicassoAPIKeyStore.resolve() ?? "").isEmpty {
            await requestLocalAgentReply()
            return
        }
        #endif
        await requestOfflineReply()
    }

    // MARK: - Offline mode

    /// Picasso without the AI service: real catalog search with budgets, plus the on-device
    /// art knowledge base. Used when there is no signed-in backend session (and, in debug
    /// builds, no developer key), so Picasso always answers instead of showing an error.
    private func requestOfflineReply() async {
        guard let question = messages.last(where: { $0.role == .user }) else { return }
        try? await Task.sleep(for: .milliseconds(450))

        let catalog = Artwork.samples
        let text = question.content
        let lower = text.lowercased()

        if question.imageData != nil {
            let suggestions = PicassoCatalogSearch.search("bold colorful", in: catalog, limit: 3).results
            finish(PicassoChatMessage(
                role: .assistant,
                content: "I can look at photos once I'm connected to my full AI. Sign in and I'll tell you about this piece. In the meantime, here are a few favourites on Picartdo.",
                artworks: suggestions
            ))
            return
        }

        let price = PicassoCatalogSearch.priceRange(in: text)
        let shoppingWords = ["find", "show me", "looking for", "recommend", "suggest", "buy", "under", "below",
                             "budget", "for my", "for a", "living room", "bedroom", "office", "something", "piece", "$"]
        let wantsToShop = price != PicassoCatalogSearch.PriceRange() || shoppingWords.contains { lower.contains($0) }

        if wantsToShop {
            let found = PicassoCatalogSearch.search(text, price: price, in: catalog, limit: 3)
            if found.results.isEmpty {
                // Nothing in budget: offer the closest pieces instead of a dead end.
                let target = price.max ?? price.min ?? 0
                let nearest = catalog
                    .filter { !$0.isSold }
                    .sorted { abs($0.price - target) < abs($1.price - target) }
                    .prefix(3)
                    .sorted { $0.price < $1.price }
                let reply = nearest.isEmpty
                    ? "Nothing is available right now. Check back soon, new work drops every week."
                    : "Nothing fits that budget right now. The closest pieces start at $\(Int(nearest[0].price)):\n\n"
                        + nearest.map { "\($0.title) by \($0.artistName), $\(Int($0.price))" }.joined(separator: "\n")
                        + "\n\nTap a card to see it up close."
                finish(PicassoChatMessage(role: .assistant, content: reply, artworks: Array(nearest)))
                return
            }
            finish(PicassoChatMessage(
                role: .assistant,
                content: Self.shoppingReply(found.results, exact: found.exact, price: price),
                artworks: found.results
            ))
            return
        }

        let context = PicassoContext(artworks: catalog, artists: Artist.all, savedIDs: [])
        let answer = PicassoEngine.offlineAnswer(to: text, context: context)
        let shown = answer.artworkIDs.compactMap { id in catalog.first { $0.id == id } }
        finish(PicassoChatMessage(role: .assistant, content: answer.text, artworks: shown))
    }

    private static func shoppingReply(
        _ results: [Artwork],
        exact: Bool,
        price: PicassoCatalogSearch.PriceRange
    ) -> String {
        let budget: String = {
            switch (price.min, price.max) {
            case let (min?, max?): return " between $\(Int(min)) and $\(Int(max))"
            case let (nil, max?): return " under $\(Int(max))"
            case let (min?, nil): return " over $\(Int(min))"
            default: return ""
            }
        }()
        guard !results.isEmpty else {
            return "Nothing is available\(budget) right now. Try a wider budget, or tell me a style or colour you love."
        }
        let lines = results.map { "\($0.title) by \($0.artistName), $\(Int($0.price))" }.joined(separator: "\n")
        let lead = exact
            ? "Here \(results.count == 1 ? "is a piece" : "are \(results.count) pieces")\(budget) that fit:"
            : "I couldn't find an exact match, but these are available\(budget):"
        return "\(lead)\n\n\(lines)\n\nTap a card to see it up close."
    }

    /// The photo attached to the latest user message, if any. Earlier photos are not resent.
    private var latestImage: Data? {
        guard let lastUser = messages.last(where: { $0.role == .user }) else { return nil }
        return lastUser.imageData
    }

    /// Production path: the picasso-agent Edge Function holds the API key, searches real
    /// listings and returns recommended artworks plus any Buy buttons for the user to confirm.
    private func requestAgentReply() async {
        let history = contextMessages().map { ["role": $0.role.rawValue, "content": $0.content] }
        var body: [String: Any] = ["messages": history]
        if let image = latestImage { body["image_base64"] = image.base64EncodedString() }
        do {
            let response = try await SupabaseClient.shared.invokeFunction(
                "picasso-agent",
                body: body,
                type: PicassoAgentResponse.self
            )
            finish(PicassoChatMessage(
                role: .assistant,
                content: response.reply,
                requestID: response.requestId,
                artworks: response.artworks.map { $0.toArtwork() },
                checkoutActions: response.actions
            ))
        } catch SupabaseError.unauthorized {
            finishWithError("Your session expired. Sign in again to keep chatting.")
        } catch SupabaseError.http(let code, let body) {
            let serverMessage = (try? JSONDecoder().decode([String: String].self, from: Data(body.utf8)))?["error"]
            finishWithError(serverMessage ?? "Couldn't reach Picasso (\(code)). Please retry.")
        } catch {
            finishWithNetworkError(error)
        }
    }

    #if DEBUG
    /// Local testing path: the same agent and tools, run on device against the sample catalog.
    private func requestLocalAgentReply() async {
        do {
            let reply = try await PicassoLocalAgent.run(history: contextMessages(), image: latestImage)
            finish(PicassoChatMessage(
                role: .assistant,
                content: reply.text,
                artworks: reply.artworks,
                checkoutActions: reply.actions
            ))
        } catch let error as PicassoLocalAgent.AgentError {
            if case .missingKey = error {
                needsDeveloperKey = true
                await requestOfflineReply()
                return
            }
            finishWithError(error.localizedDescription)
        } catch {
            finishWithNetworkError(error)
        }
    }
    #endif

    private func finish(_ reply: PicassoChatMessage) {
        messages.append(reply)
        isLoading = false
        errorMessage = nil
        lastFailedUserText = nil
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private static func userID(fromJWT token: String) -> UUID? {
        let parts = token.split(separator: ".")
        guard parts.count > 1 else { return nil }
        var payload = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while payload.count % 4 != 0 { payload += "=" }
        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sub = json["sub"] as? String else { return nil }
        return UUID(uuidString: sub)
    }

    /// Scales a photo down to Claude's recommended size and compresses it.
    private static func jpegData(from image: UIImage) -> Data? {
        let maxDimension: CGFloat = 1568
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image.jpegData(compressionQuality: 0.72) }
        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: 0.72)
    }

    private func contextMessages() -> [PicassoChatMessage] {
        Array(
            messages
                .filter { !$0.isError }
                .suffix(contextLimit)
        )
    }

    private func finishWithNetworkError(_ error: Error) {
        if (error as NSError).domain == NSURLErrorDomain {
            finishWithError("Network issue — check your connection and retry.")
        } else {
            finishWithError("Something went wrong. Please retry.")
        }
    }

    private func finishWithError(_ message: String) {
        isLoading = false
        errorMessage = message
        messages.append(
            PicassoChatMessage(
                role: .assistant,
                content: message,
                isError: true,
                canRetry: true
            )
        )
    }
}

// MARK: - picasso-agent payloads

nonisolated private struct PicassoAgentResponse: Decodable, Sendable {
    let requestId: UUID
    let reply: String
    let artworks: [ListingRow]
    let actions: [PicassoCheckoutAction]
}

nonisolated private struct PicassoFeedbackRow: Encodable, Sendable {
    let userId: UUID
    let requestId: UUID
    let rating: Int
}
