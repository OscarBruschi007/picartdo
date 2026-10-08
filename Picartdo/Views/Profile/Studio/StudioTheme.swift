import SwiftUI

// MARK: - Studio theme
// Owner picks ONE accent and one material. Chrome stays ink / paper.

enum StudioAccent: String, Codable, CaseIterable, Identifiable {
    case vermillion, cadmium, oxblood, ink, cobalt, teal
    case olive, ochre, rust, plum, graphite, bone
    var id: String { rawValue }

    var color: Color {
        switch self {
        case .vermillion: return Color(red: 0.86, green: 0.18, blue: 0.16)
        case .cadmium:    return Color(red: 0.90, green: 0.42, blue: 0.10)
        case .oxblood:    return Color(red: 0.45, green: 0.09, blue: 0.12)
        case .ink:        return Color(red: 0.07, green: 0.07, blue: 0.07)
        case .cobalt:     return Color(red: 0.16, green: 0.28, blue: 0.55)
        case .teal:       return Color(red: 0.12, green: 0.36, blue: 0.38)
        case .olive:      return Color(red: 0.38, green: 0.40, blue: 0.22)
        case .ochre:      return Color(red: 0.72, green: 0.52, blue: 0.18)
        case .rust:       return Color(red: 0.62, green: 0.28, blue: 0.16)
        case .plum:       return Color(red: 0.38, green: 0.18, blue: 0.32)
        case .graphite:   return Color(red: 0.32, green: 0.33, blue: 0.34)
        case .bone:       return Color(red: 0.72, green: 0.68, blue: 0.58)
        }
    }

    var label: String { rawValue.uppercased() }
}

enum StudioMaterial: String, Codable, CaseIterable, Identifiable {
    case paper, canvas, grid, plain
    var id: String { rawValue }

    var fill: Color {
        switch self {
        case .paper:  return Color(red: 0.973, green: 0.973, blue: 0.965)
        case .canvas: return Color(red: 0.945, green: 0.933, blue: 0.902)
        case .grid:   return Color(red: 0.965, green: 0.965, blue: 0.958)
        case .plain:  return Color.white
        }
    }
}

enum StudioPaper: String, Codable, CaseIterable, Identifiable {
    case white, warm, kraft, concrete
    var id: String { rawValue }

    var fill: Color {
        switch self {
        case .white:    return .white
        case .warm:     return Color(red: 0.98, green: 0.96, blue: 0.92)
        case .kraft:    return Color(red: 0.82, green: 0.72, blue: 0.55)
        case .concrete: return Color(red: 0.86, green: 0.86, blue: 0.84)
        }
    }

    var ink: Color {
        self == .kraft ? Color(red: 0.16, green: 0.10, blue: 0.06) : Color(red: 0.067, green: 0.067, blue: 0.067)
    }
}

enum StudioBorder: String, Codable, CaseIterable, Identifiable {
    case none, hairline, rule, stamp
    var id: String { rawValue }
}

enum StudioCorner: String, Codable, CaseIterable, Identifiable {
    case sharp, soft, ticket
    var id: String { rawValue }

    var radius: CGFloat {
        switch self {
        case .sharp:  return 0
        case .soft:   return 18
        case .ticket: return 6
        }
    }
}

enum StudioShadow: String, Codable, CaseIterable, Identifiable {
    case none, low, mid, high
    var id: String { rawValue }

    var radius: CGFloat {
        switch self {
        case .none: return 0
        case .low:  return 4
        case .mid:  return 10
        case .high: return 18
        }
    }
}

enum StudioTypePair: String, Codable, CaseIterable, Identifiable {
    case exhibition, zine, ledger, atelier, telegram
    var id: String { rawValue }

    var display: Font { .system(.title, design: displayDesign).weight(.black) }
    var body: Font { .system(.body, design: bodyDesign) }
    var meta: Font { .system(.caption2, design: .monospaced).weight(.semibold) }

    private var displayDesign: Font.Design {
        switch self {
        case .exhibition, .atelier: return .serif
        case .zine, .telegram: return .default
        case .ledger: return .monospaced
        }
    }

    private var bodyDesign: Font.Design {
        switch self {
        case .exhibition, .atelier: return .serif
        default: return .default
        }
    }
}

enum StudioEntrance: String, Codable, CaseIterable, Identifiable {
    case curtain, spotlight, door, ink
    var id: String { rawValue }
}

enum StudioTemplate: String, Codable, CaseIterable, Identifiable {
    case galleryWall, zine, contactSheet, shopCounter, scrapbook, timeline
    var id: String { rawValue }

    var label: String {
        switch self {
        case .galleryWall:  return "GALLERY WALL"
        case .zine:         return "ZINE"
        case .contactSheet: return "CONTACT SHEET"
        case .shopCounter:  return "SHOP COUNTER"
        case .scrapbook:    return "SCRAPBOOK"
        case .timeline:     return "TIMELINE"
        }
    }
}

enum StudioBlockKind: String, Codable, CaseIterable, Identifiable {
    case hero, statement, nowWorking, processReel, contactSheet, shelf
    case commissions, guestbook, timeline, moodboard, ledger, signature
    var id: String { rawValue }

    var libraryLabel: String {
        switch self {
        case .hero:         return "HERO PIECE"
        case .statement:    return "ARTIST STATEMENT"
        case .nowWorking:   return "NOW WORKING ON"
        case .processReel:  return "PROCESS REEL"
        case .contactSheet: return "CONTACT SHEET"
        case .shelf:        return "SHELF"
        case .commissions:  return "COMMISSIONS"
        case .guestbook:    return "GUESTBOOK"
        case .timeline:     return "TIMELINE"
        case .moodboard:    return "MOODBOARD"
        case .ledger:       return "SOLD LEDGER"
        case .signature:    return "SIGNATURE"
        }
    }

    var defaultSpan: (cols: Int, rows: Int) {
        switch self {
        case .hero:         return (12, 14)
        case .statement:    return (12, 6)
        case .nowWorking:   return (12, 5)
        case .processReel:  return (12, 6)
        case .contactSheet: return (12, 10)
        case .shelf:        return (12, 9)
        case .commissions:  return (12, 8)
        case .guestbook:    return (12, 8)
        case .timeline:     return (12, 12)
        case .moodboard:    return (12, 10)
        case .ledger:       return (12, 8)
        case .signature:    return (12, 4)
        }
    }
}
