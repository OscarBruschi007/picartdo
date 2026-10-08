import Foundation

/// Keyword search over the artwork catalog, with light synonyms and price limits.
/// Used by on-device Picasso (offline mode and the debug agent) in place of the
/// server's semantic search.
enum PicassoCatalogSearch {
    struct PriceRange: Equatable {
        var min: Double?
        var max: Double?
    }

    private static let stopWords: Set<String> = [
        "a", "an", "the", "for", "with", "and", "or", "of", "in", "my", "me", "some", "something",
        "piece", "pieces", "art", "artwork", "artworks", "under", "over", "below", "above", "find",
        "show", "want", "looking", "need", "can", "you", "get", "buy", "less", "than", "more", "around",
        "about", "like", "would", "please", "any", "this", "that", "what", "have", "dollars", "usd",
    ]

    private static let synonyms: [String: [String]] = [
        "abstract": ["forms", "shapes", "composition", "circular", "mandala"],
        "bold": ["vivid", "primary", "bright", "energy", "charged"],
        "calm": ["soft", "quiet", "meditative", "violet", "blue"],
        "peaceful": ["soft", "quiet", "meditative", "violet", "blue"],
        "moody": ["dark", "black", "night", "deep"],
        "warm": ["red", "orange", "yellow", "gold", "rust"],
        "portrait": ["face", "faces", "figure", "figures"],
        "colorful": ["color", "colors", "vivid", "palette", "bright"],
        "colourful": ["color", "colors", "vivid", "palette", "bright"],
        "bedroom": ["soft", "calm", "meditative"],
        "living": ["bold", "large", "wide"],
    ]

    /// Ranked matches. With only price or category limits (no descriptive words), returns
    /// everything that fits, most liked first. Sold pieces are never returned.
    static func search(
        _ query: String,
        price: PriceRange = PriceRange(),
        category: String? = nil,
        in catalog: [Artwork],
        limit: Int = 8
    ) -> (results: [Artwork], exact: Bool) {
        var terms = Set(
            query.lowercased()
                .split { !$0.isLetter }
                .map(String.init)
                .filter { $0.count > 2 && !stopWords.contains($0) }
        )
        for term in terms { synonyms[term].map { terms.formUnion($0) } }

        var scored: [(art: Artwork, score: Int)] = []
        for art in catalog where !art.isSold {
            if let max = price.max, art.price > max { continue }
            if let min = price.min, art.price < min { continue }
            if let category, art.category.rawValue.caseInsensitiveCompare(category) != .orderedSame { continue }
            let haystack = [art.title, art.description, art.medium, art.category.rawValue, art.artistName]
                .joined(separator: " ")
                .lowercased()
            scored.append((art, terms.filter { haystack.contains($0) }.count))
        }
        scored.sort { lhs, rhs in
            lhs.score != rhs.score ? lhs.score > rhs.score : lhs.art.likeCount > rhs.art.likeCount
        }

        let matches = terms.isEmpty ? scored : scored.filter { $0.score > 0 }
        let pool = matches.isEmpty ? scored : matches
        return (pool.prefix(limit).map(\.art), !matches.isEmpty)
    }

    /// Reads budgets like "under $500", "below 1,200", "over $800", "between 300 and 900".
    static func priceRange(in text: String) -> PriceRange {
        let lower = text.lowercased()
        var range = PriceRange()

        if let match = firstMatch(#"between\s*\$?\s*([\d,]+(?:\.\d+)?\s*k?)\s*(?:and|-|to)\s*\$?\s*([\d,]+(?:\.\d+)?\s*k?)"#, in: lower),
           match.count == 2 {
            range.min = number(match[0])
            range.max = number(match[1])
            return range
        }
        if let match = firstMatch(#"(?:under|below|less than|up to|max(?:imum)?|cheaper than|no more than|<)\s*\$?\s*([\d,]+(?:\.\d+)?\s*k?)"#, in: lower) {
            range.max = number(match[0])
        }
        if let match = firstMatch(#"(?:over|above|more than|at least|min(?:imum)?|>)\s*\$?\s*([\d,]+(?:\.\d+)?\s*k?)"#, in: lower) {
            range.min = number(match[0])
        }
        if range.min == nil, range.max == nil, let match = firstMatch(#"\$\s*([\d,]+(?:\.\d+)?\s*k?)"#, in: lower) {
            range.max = number(match[0])
        }
        return range
    }

    private static func firstMatch(_ pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let result = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              result.numberOfRanges > 1 else { return nil }
        return (1..<result.numberOfRanges).compactMap { index in
            Range(result.range(at: index), in: text).map { String(text[$0]) }
        }
    }

    /// "1,200" → 1200, "2k" / "2.5k" → 2000 / 2500.
    private static func number(_ raw: String) -> Double? {
        var text = raw.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
        var multiplier = 1.0
        if text.hasSuffix("k") {
            multiplier = 1000
            text = String(text.dropLast()).trimmingCharacters(in: .whitespaces)
        }
        return Double(text).map { $0 * multiplier }
    }
}
