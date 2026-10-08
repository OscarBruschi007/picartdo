import SwiftUI
import UIKit

/// Shared identity block for the Profile tab and every other artist profile.
struct ProfileGalleryPerson {
    var name: String
    var handle: String
    var location: String
    var bio: String
    var avatarAsset: String
    var coverAsset: String = ""
    var customAvatar: UIImage? = nil
    var verified: Bool
    var followers: String
    var following: String
    var rating: Double

    var starCount: Int {
        min(5, max(1, Int(rating.rounded())))
    }
}

enum ProfileAvatarShapeKind: Int, CaseIterable {
    case circle
    case roundedRect
    case squircle
    case capsule
    case diamond
    case hexagon
}

struct ProfileAvatarMask: Shape {
    var kind: ProfileAvatarShapeKind

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .circle:
            return Circle().path(in: rect)
        case .roundedRect:
            return RoundedRectangle(cornerRadius: 14, style: .continuous).path(in: rect)
        case .squircle:
            return RoundedRectangle(cornerRadius: rect.width * 0.32, style: .continuous).path(in: rect)
        case .capsule:
            return Capsule(style: .continuous).path(in: rect.insetBy(dx: rect.width * 0.12, dy: 0))
        case .diamond:
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
            return path
        case .hexagon:
            let inset = rect.width * 0.12
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + rect.height * 0.25))
            path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + rect.height * 0.75))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY + rect.height * 0.75))
            path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY + rect.height * 0.25))
            path.closeSubpath()
            return path
        }
    }
}

struct ProfileGalleryHeader: View {
    let person: ProfileGalleryPerson
    var personal: Bool = false
    var primaryTitle: String
    var onPrimary: () -> Void
    var secondaryTitle: String
    var onSecondary: () -> Void

    @State private var shapeKind: ProfileAvatarShapeKind = .circle
    @State private var nameColorIndex = 0

    /// Each profile remembers its own avatar shape and name color. Your own profile keeps
    /// the original keys so existing choices survive.
    private var shapeKey: String { personal ? "profile.avatarShape" : "profile.avatarShape.\(person.handle)" }
    private var colorKey: String { personal ? "profile.nameColor" : "profile.nameColor.\(person.handle)" }

    private let nameColors: [Color] = [
        Color.picardoText,
        Color.picardoNeonRed,
        PicardoEra.blue.color,
        PicardoEra.rose.color,
        PicardoEra.ochre.color,
        Color.picardoSupport,
        Color.picardoGoldDeep,
        Color.picardoGold,
    ]

    private let avatarSize: CGFloat = 96
    private let coverHeight: CGFloat = 270
    private var avatarKind: ProfileAvatarShapeKind { shapeKind }
    private var coverShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
    }

    var body: some View {
        // LinkedIn-style: full-width banner, photo overlapping its bottom-left edge,
        // left-aligned identity, pill buttons.
        VStack(alignment: .leading, spacing: 0) {
            coverCard

            VStack(alignment: .leading, spacing: 6) {
                Text(person.bio)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text("@\(person.handle) · \(person.location)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Text("\(person.followers) followers")
                    Text("·")
                    Text("\(person.following) following")
                    Text("·")
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= person.starCount ? "star.fill" : "star")
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(person.starCount) out of 5 stars")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.picardoGold)

                HStack(spacing: 8) {
                    pillButton(primaryTitle, filled: true, action: onPrimary)
                    pillButton(secondaryTitle, filled: false, action: onSecondary)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            shapeKind = ProfileAvatarShapeKind(rawValue: UserDefaults.standard.integer(forKey: shapeKey)) ?? .circle
            nameColorIndex = UserDefaults.standard.integer(forKey: colorKey)
        }
    }

    private func pillButton(_ title: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(title.capitalized)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(filled ? Color.picardoBackground : Color.picardoGold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background {
                    if filled {
                        Capsule().fill(Color.picardoGold)
                    } else {
                        Capsule().strokeBorder(Color.picardoGold, lineWidth: 1.5)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(PicardoPressStyle())
    }

    @ViewBuilder
    private var coverCard: some View {
        // Tall liquid-glass card: cover photo behind, photo and name centered on top.
        ZStack {
            ArtworkImage(imageName: person.coverAsset, contentMode: .fill, maxDimension: 1200)
            LinearGradient(
                colors: [.black.opacity(0.05), .black.opacity(0.25), .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(spacing: 12) {
                avatarButton
                nameRow
                    .shadow(color: .black.opacity(0.5), radius: 6, y: 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: coverHeight)
        .clipShape(coverShape)
        .padding(6)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var nameRow: some View {
        let label = HStack(spacing: 8) {
            Text(person.name)
                .font(.system(size: 26, weight: .black, design: .serif))
                .foregroundStyle(nameColors[safe: nameColorIndex] ?? Color.picardoText)
                .multilineTextAlignment(.center)
            if person.verified {
                Image(systemName: "paintbrush.pointed.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Color.picardoNeonRed, in: Circle())
                    .accessibilityLabel("Verified artist")
            }
        }

        Button {
            Haptics.select()
            withAnimation(PicardoMotion.quick) {
                nameColorIndex = (nameColorIndex + 1) % nameColors.count
                UserDefaults.standard.set(nameColorIndex, forKey: colorKey)
            }
        } label: {
            label
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(person.name)\(person.verified ? ", verified artist" : ""), tap to change color")
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var avatarButton: some View {
        Button {
            Haptics.tap()
            withAnimation(PicardoMotion.press) {
                let next = (shapeKind.rawValue + 1) % ProfileAvatarShapeKind.allCases.count
                shapeKind = ProfileAvatarShapeKind(rawValue: next) ?? .circle
                UserDefaults.standard.set(shapeKind.rawValue, forKey: shapeKey)
            }
        } label: {
            Group {
                if let custom = person.customAvatar {
                    Image(uiImage: custom).resizable().scaledToFill()
                } else {
                    ArtworkImage(imageName: person.avatarAsset, contentMode: .fill, maxDimension: 600)
                }
            }
            .frame(width: avatarSize, height: avatarSize, alignment: .center)
            .clipShape(ProfileAvatarMask(kind: avatarKind))
            .padding(4)
            .background(ProfileAvatarMask(kind: avatarKind).fill(Color.picardoBackground))
            .overlay(
                ProfileAvatarMask(kind: avatarKind)
                    .stroke(Color.picardoNeonRed.opacity(0.85), lineWidth: 2)
                    .padding(4)
            )
            .contentShape(ProfileAvatarMask(kind: avatarKind))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(person.name) photo, tap to change shape")
    }
}

struct ProfileHighlightsRow: View {
    let stories: [ArtistStory]
    var onOpen: (ArtistStory) -> Void

    private let palette: [Color] = [
        Color(red: 0.93, green: 0.40, blue: 0.55),
        Color(red: 0.35, green: 0.62, blue: 0.95),
        Color(red: 0.85, green: 0.68, blue: 0.20),
        Color(red: 0.30, green: 0.72, blue: 0.48),
    ]

    var body: some View {
        HStack(spacing: 18) {
            ForEach(Array(stories.prefix(4).enumerated()), id: \.element.id) { index, story in
                let ring = palette[index % palette.count]
                Button {
                    Haptics.tap()
                    onOpen(story)
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(ring.opacity(0.22))
                            ArtworkImage(imageName: story.coverImage, contentMode: .fill, maxDimension: 240)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        }
                        .frame(width: 68, height: 68)
                        .overlay(Circle().strokeBorder(ring, lineWidth: 2.5))

                        Text(story.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    .frame(width: 76)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(story.title) story")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

struct ProfileFilterPills: View {
    @Binding var filter: GalleryFilter
    var options: [GalleryFilter] = [.all, .forSale, .collected]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options) { item in
                Button {
                    Haptics.select()
                    filter = item
                } label: {
                    Text(item.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(filter == item ? Color.picardoBackground : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            filter == item ? Color.picardoText : Color.picardoCard,
                            in: Capsule()
                        )
                        .overlay(
                            Capsule().strokeBorder(Color.black.opacity(filter == item ? 0 : 0.06), lineWidth: 1)
                        )
                }
                .buttonStyle(PicardoPressStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}

struct ProfileMoreLinks: View {
    var items: [(String, () -> Void)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Text("·")
                        .foregroundStyle(Color.picardoGold)
                        .padding(.horizontal, 12)
                }
                Button {
                    Haptics.tap()
                    item.1()
                } label: {
                    Text(item.0)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.picardoGold)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.0)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
