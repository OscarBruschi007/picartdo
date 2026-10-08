import SwiftUI

// MARK: - Picartdo Editorial Typography
//
// Magazine hierarchy: oversized serif display, quiet monospaced metadata,
// restrained body. Typography — not decoration — carries the brand.

enum PicardoType {

    /// Oversized exhibition titles (home hero, collection covers).
    static func display(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .black, design: .serif)
    }

    /// Artwork / artist titles.
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .black, design: .serif)
    }

    /// Section headers.
    static func section(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .black, design: .serif)
    }

    /// Brand wordmark.
    static func wordmark(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .black, design: .serif)
    }

    /// Serif body / story / biography.
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, design: .serif)
    }

    /// Small uppercase museum labels: ARTWORK, LIMITED, 2026.
    static func meta(_ size: CGFloat = 10) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }

    /// Understated CTA labels.
    static func cta(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .semibold)
    }
}

extension View {
    /// Uppercase tracking for placard metadata.
    func picardoMetaStyle(kerning: CGFloat = 1.4) -> some View {
        self
            .font(PicardoType.meta())
            .kerning(kerning)
            .textCase(.uppercase)
    }
}
