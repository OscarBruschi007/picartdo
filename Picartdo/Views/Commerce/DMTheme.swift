import SwiftUI
import UIKit

// MARK: - Messages palette — Picardo tokens (era canvas, neon red, gold)

struct DMTheme {
    let background: Color
    let text: Color
    let secondary: Color
    let searchFill: Color
    let theirBubble: Color
    let unread: Color
    let chipUnselected: Color
    let hairline: Color
    let activeGreen: Color
    let cameraBlue: Color

    static let unreadBlue = Color.picardoNeonRed
    static let cameraCircle = Color.picardoNeonRed

    /// Screen-locked outgoing fill — neon red into deep red, same mechanic as a branded gradient.
    static var outgoingGradient: [Color] {
        [
            Color.picardoNeonRed,
            Color.picardoGoldDeep,
            Color(red: 0.55, green: 0.02, blue: 0.14),
        ]
    }

    static func resolve(_ scheme: ColorScheme) -> DMTheme {
        switch scheme {
        case .dark:
            return DMTheme(
                background: .black,
                text: .white,
                secondary: Color(white: 0.62),
                searchFill: Color.white.opacity(0.10),
                theirBubble: Color.white.opacity(0.12),
                unread: .picardoNeonRed,
                chipUnselected: Color.white.opacity(0.10),
                hairline: Color.white.opacity(0.14),
                activeGreen: Color.picardoSupport,
                cameraBlue: cameraCircle
            )
        default:
            return DMTheme(
                background: Color.picardoBackground,
                text: Color.picardoText,
                secondary: Color.picardoTextSecondary,
                searchFill: Color.picardoSurface,
                theirBubble: Color.picardoCard,
                unread: .picardoNeonRed,
                chipUnselected: Color.picardoCard,
                hairline: Color.picardoBorder,
                activeGreen: Color.picardoSupport,
                cameraBlue: cameraCircle
            )
        }
    }
}
