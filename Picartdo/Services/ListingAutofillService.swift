import Foundation
import UIKit

struct ListingAutofillDraft: Sendable {
    var title: String
    var caption: String
    var category: ArtCategory
    var medium: String
    var condition: String
    var askPrice: Int
}

/// Vision pass for Snap & List. Prefills sell-form guesses; never submits.
enum ListingAutofillService {
    private static let model = "claude-sonnet-5"
    private static let conditions: Set<String> = ["Mint", "Excellent", "Good", "Fair"]

    static func suggest(from image: UIImage) async -> ListingAutofillDraft? {
        guard let jpeg = jpegData(from: image) else { return nil }

        // Production: the listing-autofill Edge Function holds the API key.
        if AppConfig.isBackendConfigured, await SupabaseClient.shared.currentAccessToken() != nil {
            guard
                let data = try? await SupabaseClient.shared.invokeFunction(
                    "listing-autofill",
                    body: ["image_base64": jpeg.base64EncodedString()]
                ),
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let text = json["text"] as? String
            else { return nil }
            return parse(text)
        }

        #if DEBUG
        return await suggestDirect(jpeg: jpeg)
        #else
        return nil
        #endif
    }

    #if DEBUG
    /// Local testing without a backend, using a developer key from the scheme environment.
    private static func suggestDirect(jpeg: Data) async -> ListingAutofillDraft? {
        guard let apiKey = PicassoAPIKeyStore.resolve(), !apiKey.isEmpty else { return nil }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 45

        let prompt = """
        You are helping an artist list original work on Picartdo, a marketplace and social platform for artists.
        Look at this artwork photo and return ONLY compact JSON, no markdown, no extra keys:
        {
          "title": "short natural listing title",
          "caption": "1-2 sentences in the artist's voice",
          "category": "Painting",
          "medium": "Oil on canvas",
          "condition": "Excellent",
          "askPrice": 850
        }
        category must be one of: Painting, Photography, Sculpture, Digital, Drawing, Printmaking, Mixed Media.
        condition must be one of: Mint, Excellent, Good, Fair.
        askPrice is a USD integer based on category, medium, and visual complexity, in line with similar original work on Picartdo (typically 200–3500; larger or denser pieces can go higher).
        Never include dimensions, signature, or certificate — those stay manual.
        """

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 400,
            "messages": [[
                "role": "user",
                "content": [
                    [
                        "type": "image",
                        "source": [
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": jpeg.base64EncodedString(),
                        ],
                    ],
                    [
                        "type": "text",
                        "text": prompt,
                    ],
                ],
            ]],
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let blocks = json["content"] as? [[String: Any]]
            else { return nil }

            let text = blocks
                .compactMap { block -> String? in
                    guard (block["type"] as? String) == "text" else { return nil }
                    return block["text"] as? String
                }
                .joined()

            return parse(text)
        } catch {
            return nil
        }
    }
    #endif

    private static func parse(_ raw: String) -> ListingAutofillDraft? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            text = text.replacingOccurrences(of: "```json", with: "")
            text = text.replacingOccurrences(of: "```", with: "")
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let data = text.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        let title = (obj["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let caption = (obj["caption"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let medium = (obj["medium"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let categoryName = (obj["category"] as? String) ?? ""
        let conditionRaw = (obj["condition"] as? String) ?? "Excellent"
        let price: Int
        if let n = obj["askPrice"] as? Int {
            price = n
        } else if let n = obj["askPrice"] as? Double {
            price = Int(n.rounded())
        } else if let s = obj["askPrice"] as? String, let n = Double(s) {
            price = Int(n.rounded())
        } else {
            price = 0
        }

        guard !title.isEmpty, price > 0 else { return nil }

        let category = ArtCategory.allCases.first {
            $0.rawValue.compare(categoryName, options: .caseInsensitive) == .orderedSame
        } ?? .painting
        let condition = conditions.contains(conditionRaw) ? conditionRaw : "Excellent"

        return ListingAutofillDraft(
            title: title,
            caption: caption,
            category: category,
            medium: medium,
            condition: condition,
            askPrice: price
        )
    }

    private static func jpegData(from image: UIImage) -> Data? {
        let maxDim: CGFloat = 1568
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image.jpegData(compressionQuality: 0.72) }
        let scale = min(1, maxDim / max(size.width, size.height))
        let newSize = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return scaled.jpegData(compressionQuality: 0.72)
    }
}
