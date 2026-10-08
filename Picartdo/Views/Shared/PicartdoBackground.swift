import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// PicartdoBackground
//
// One flat canvas color, no texture. Simple beats decorated — the cream and
// neon-red brand colors (from the app icon) do the work, not a stripe pattern.
// ─────────────────────────────────────────────────────────────────────────────

struct PicartdoBackground: View {

    var scrollOffset: CGFloat = 0

    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        (isDark ? Color.black : Color.picardoBackground)
    }
}

#Preview {
    PicartdoBackground()
        .ignoresSafeArea()
}
