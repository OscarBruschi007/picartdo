import SwiftUI
import UIKit

/// Shared radii, surfaces, and brand color for Profile and Artist pages.
enum DesignTokens {
    static let radiusLarge: CGFloat = 22
    static let radiusMedium: CGFloat = 16
    static let radiusSmall: CGFloat = 10
    static let radiusChip: CGFloat = 8
    static let gridSpacing: CGFloat = 1.5
    static let storyAvatar: CGFloat = 92
    static let highlightSize: CGFloat = 74
}

extension Color {
    /// Primary brand mark — buy/CTA red, never drifts with the era.
    static var brand: Color { .picardoNeonRed }

    /// Elevated card fill that follows light/dark.
    static var cardSurface: Color {
        Color(uiColor: UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(red: 0.16, green: 0.16, blue: 0.17, alpha: 1)
            }
            return UIColor(red: 0.995, green: 0.99, blue: 0.98, alpha: 1)
        })
    }
}

extension View {
    func cardShadow() -> some View {
        shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
    }
}
