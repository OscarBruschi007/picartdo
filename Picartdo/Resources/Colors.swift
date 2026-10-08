import SwiftUI
import UIKit

// MARK: - Picartdo Color System
// Cream canvas + neon red accent — matches app icon (Times P on #FFF4C2).

extension Color {

    static let picardoCream   = Color(red: 1.000, green: 0.957, blue: 0.761) // #FFF4C2
    static let picardoNeonRed   = Color(red: 1.000, green: 0.027, blue: 0.227) // #FF073A

    /// General brand accent for UI chrome — links, focus rings, selected
    /// states, liked/saved icons, avatars. Rotates with the era, same as
    /// picardoGold. Money moments still point at picardoNeonRed directly.
    static var picardoAccent: Color { picardoEraAccent }

    /// The app's everyday brand color. Rotates with the season (see
    /// PicardoEra below) — this is what makes the whole app feel different
    /// era to era. Money moments (buy, price, checkout, pay) never read
    /// this token: they point at picardoNeonRed directly, always, so that
    /// signal never drifts no matter what era it is.
    static var picardoGold: Color { picardoEraAccent }
    static var picardoGoldLight: Color { picardoEraAccent.opacity(0.14) }
    static let picardoGoldDeep  = Color(red: 0.820, green: 0.020, blue: 0.180)

    /// Canvas, cards, borders, body text — the whole room, not just the
    /// accent. This is what makes an era a period and not a sticker.
    /// Money moments never touch these either: buy, price, checkout stay
    /// on picardoNeonRed + plain white/black, untouched by any of this.
    static var picardoBackground: Color { PicardoEra.current.background }
    static var picardoSurface: Color { PicardoEra.current.surface }
    static var picardoCard: Color { PicardoEra.current.card }
    /// Off-white mat + pure white inner border — keeps feed posts Polaroid-framed. Physical photo paper, so it never tints with the era.
    static let picardoPolaroidMat = Color(red: 0.960, green: 0.950, blue: 0.930)
    static let picardoPostFrame   = Color.white
    static var picardoCardMid: Color { PicardoEra.current.cardMid }

    static var picardoBorder: Color { PicardoEra.current.border }
    static var picardoDivider: Color { PicardoEra.current.border }

    static var picardoText: Color { PicardoEra.current.text }
    static var picardoTextSecondary: Color { PicardoEra.current.textSecondary }

    /// Quiet trust/status signal — verified badges, availability, shipped.
    /// Deliberately not red: red stays reserved for price, buy, and live moments.
    static let picardoSupport     = Color(red: 0.243, green: 0.361, blue: 0.306) // #3E5C4E
    static let picardoSupportSoft = Color(red: 0.894, green: 0.922, blue: 0.898) // #E4EBE3

    // MARK: Studio canvas chrome (Profile tab only)
    // One accent. No era drift, no second green, no gradients.
    // Canvas white / wall #F8F8F6 / ink #111 / mute #8C8C8C / hairline #EAEAEA.

    static let picardoStudioCanvas    = Color.white
    static let picardoStudioWall      = Color(red: 0.973, green: 0.973, blue: 0.965) // #F8F8F6
    static let picardoStudioInk       = Color(red: 0.067, green: 0.067, blue: 0.067) // #111111
    static let picardoStudioMute      = Color(red: 0.549, green: 0.549, blue: 0.549) // #8C8C8C
    static let picardoStudioHairline  = Color(red: 0.918, green: 0.918, blue: 0.918) // #EAEAEA
    static var picardoStudioAccent: Color { picardoNeonRed }

    /// The rotating decorative accent — featured tags, drop labels, mood
    /// moments only. Never buy, never price, never verified: those stay
    /// fixed so their meaning never drifts.
    static var picardoEraAccent: Color { PicardoEra.current.color }
}

// MARK: - Picartdo Eras
// Picasso never held one palette for long. He moved in periods, each one
// lasting years, each one unmistakably him. Picartdo borrows that idea for
// one accent only — a slow, seasonal mood shift. Four months per era,
// three eras a year, never random, never tied to how often someone opens
// the app.
enum PicardoEra: Int, CaseIterable {
    case blue   // Blue Period — calm, contemplative
    case rose   // Rose Period — warm, human, romantic
    case ochre  // Proto-Cubist, African-influenced Period — bold, grounded

    var color: Color {
        switch self {
        case .blue:  return Color(red: 0.122, green: 0.235, blue: 0.302) // #1F3C4D
        case .rose:  return Color(red: 0.788, green: 0.482, blue: 0.420) // #C97B6B
        case .ochre: return Color(red: 0.612, green: 0.420, blue: 0.243) // #9C6B3E
        }
    }

    /// The room itself — canvas, cards, dividers, body text. Each era is a
    /// full palette, not one accent dot, the same way a real Picasso period
    /// meant a whole different world on the canvas, not one brushstroke.
    var background: Color {
        switch self {
        case .blue:  return Color(red: 0.914, green: 0.945, blue: 0.961) // #E9F1F5
        case .rose:  return Color(red: 0.984, green: 0.918, blue: 0.898) // #FBEAE5
        case .ochre: return Color(red: 1.000, green: 0.957, blue: 0.761) // #FFF4C2
        }
    }

    var surface: Color {
        switch self {
        case .blue:  return Color(red: 0.945, green: 0.965, blue: 0.976) // #F1F6F9
        case .rose:  return Color(red: 0.992, green: 0.945, blue: 0.933) // #FDF1EE
        case .ochre: return Color(red: 1.000, green: 0.976, blue: 0.820) // #FFF9D1
        }
    }

    var card: Color {
        switch self {
        case .blue:  return Color(red: 0.969, green: 0.980, blue: 0.988) // #F7FAFC
        case .rose:  return Color(red: 0.996, green: 0.969, blue: 0.961) // #FEF7F5
        case .ochre: return Color(red: 1.000, green: 0.988, blue: 0.875) // #FFFCDF
        }
    }

    var cardMid: Color {
        switch self {
        case .blue:  return Color(red: 0.863, green: 0.910, blue: 0.933) // #DCE8EE
        case .rose:  return Color(red: 0.953, green: 0.851, blue: 0.820) // #F3D9D1
        case .ochre: return Color(red: 0.980, green: 0.945, blue: 0.730) // original cardMid
        }
    }

    var border: Color {
        switch self {
        case .blue:  return Color(red: 0.718, green: 0.788, blue: 0.824) // #B7C9D2
        case .rose:  return Color(red: 0.867, green: 0.698, blue: 0.655) // #DDB2A7
        case .ochre: return Color(red: 0.880, green: 0.820, blue: 0.620) // original border
        }
    }

    var text: Color {
        switch self {
        case .blue:  return Color(red: 0.043, green: 0.102, blue: 0.133) // #0B1A22
        case .rose:  return Color(red: 0.141, green: 0.063, blue: 0.035) // #241009
        case .ochre: return Color(red: 0.120, green: 0.080, blue: 0.060) // original text
        }
    }

    var textSecondary: Color {
        switch self {
        case .blue:  return Color(red: 0.298, green: 0.392, blue: 0.439) // #4C6470
        case .rose:  return Color(red: 0.431, green: 0.290, blue: 0.259) // #6E4A42
        case .ochre: return Color(red: 0.450, green: 0.380, blue: 0.320) // original secondary
        }
    }

    var label: String {
        switch self {
        case .blue:  return "Blue Period"
        case .rose:  return "Rose Period"
        case .ochre: return "Ochre Period"
        }
    }

    /// Four calendar months each, fixed and public — unless the wordmark on
    /// Home has been tapped by hand, in which case that pick wins until
    /// tapped again.
    static var current: PicardoEra {
        if let raw = EraOverrideStore.shared.overrideIndex, let era = PicardoEra(rawValue: raw) {
            return era
        }
        let month = Calendar.current.component(.month, from: Date()) // 1...12
        let index = (month - 1) / 4
        return PicardoEra(rawValue: index) ?? .blue
    }

    /// Tap the Home wordmark, the era steps forward by hand. Sticks across
    /// launches until tapped again — the calendar only resumes on its own
    /// if nothing has ever been picked.
    static func advance() {
        let next = (current.rawValue + 1) % allCases.count
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        EraOverrideStore.shared.overrideIndex = next
    }
}

/// Holds a manual era pick made by tapping the Home wordmark. nil means
/// "follow the calendar" — that's the default for everyone until they tap.
@Observable
final class EraOverrideStore {
    static let shared = EraOverrideStore()
    private static let key = "picardo.era.manualOverride"

    var overrideIndex: Int? {
        didSet { UserDefaults.standard.set(overrideIndex, forKey: Self.key) }
    }

    private init() {
        overrideIndex = UserDefaults.standard.object(forKey: Self.key) as? Int
    }
}
