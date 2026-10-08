import SwiftUI

struct ProfileStoryData: Hashable {
    var name: String
    var handle: String
    var avatarImage: String
    var location: String
    var sinceYear: Int
    var verified: Bool
    var piecesSold: String
    var collectors: String
    var rating: String
    var yearsActive: String
    var bio: String
    var medium: String
    var inspiredBy: String
    var studioCity: String

    static func oscar(_ identity: ProfileIdentity, sold: Int, collectors: String, rating: String) -> ProfileStoryData {
        ProfileStoryData(
            name: identity.name,
            handle: identity.handle,
            avatarImage: identity.avatarAsset,
            location: identity.location,
            sinceYear: identity.sinceYear,
            verified: true,
            piecesSold: "\(sold)",
            collectors: collectors,
            rating: rating,
            yearsActive: "\(max(1, Calendar.current.component(.year, from: Date()) - identity.sinceYear))",
            bio: identity.bio,
            medium: identity.specialties.joined(separator: " · "),
            inspiredBy: identity.inspiredBy,
            studioCity: identity.studioCity
        )
    }

    static func artist(_ artist: Artist) -> ProfileStoryData {
        ProfileStoryData(
            name: artist.name,
            handle: artist.name.lowercased().replacingOccurrences(of: " ", with: ""),
            avatarImage: artist.avatarImage,
            location: artist.location,
            sinceYear: 2018,
            verified: artist.verified,
            piecesSold: "\(max(artist.reviewCount / 2, 1))",
            collectors: artist.followers,
            rating: String(format: "%.1f", artist.rating),
            yearsActive: "8",
            bio: artist.bio,
            medium: artist.specialties.joined(separator: " · "),
            inspiredBy: artist.tagline,
            studioCity: artist.location
        )
    }
}

struct ProfileStoryCard: View {
    let story: ProfileStoryData
    var customAvatar: UIImage? = nil
    @State private var showMore = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                avatar
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(story.name)
                            .font(.system(.title2, design: .serif).weight(.bold))
                            .foregroundStyle(Color.picardoText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        if story.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color.picardoSupport)
                                .accessibilityLabel("Verified")
                        }
                    }
                    Text("@\(story.handle)")
                        .font(.subheadline)
                        .foregroundStyle(Color.picardoTextSecondary)
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                        Text(story.location)
                    }
                    .font(.footnote)
                    .foregroundStyle(Color.picardoTextSecondary)
                    Text("Artist since \(String(story.sinceYear))")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.picardoText)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 0) {
                storyStat(story.piecesSold, "Sold")
                divider
                storyStat(story.collectors, "Collectors")
                divider
                storyStat(story.rating, "Rating")
                divider
                storyStat(story.yearsActive, "Years")
            }
            .padding(.vertical, 10)

            about
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: DesignTokens.radiusLarge, style: .continuous))
        .cardShadow()
        .accessibilityElement(children: .contain)
    }

    private var avatar: some View {
        Group {
            if let customAvatar {
                Image(uiImage: customAvatar)
                    .resizable()
                    .scaledToFill()
            } else {
                ArtworkImage(imageName: story.avatarImage, contentMode: .fill, maxDimension: 400)
            }
        }
        .frame(width: DesignTokens.storyAvatar, height: DesignTokens.storyAvatar)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color.picardoPostFrame, lineWidth: 3))
        .accessibilityHidden(true)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.picardoDivider)
            .frame(width: 1, height: 28)
    }

    private func storyStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(.headline, design: .serif).weight(.bold))
                .foregroundStyle(Color.picardoText)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.picardoTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About me")
                .font(.headline)
                .foregroundStyle(Color.picardoText)

            Text(story.bio)
                .font(.body)
                .foregroundStyle(Color.picardoText.opacity(0.92))
                .lineSpacing(4)
                .lineLimit(showMore ? nil : 3)
                .fixedSize(horizontal: false, vertical: true)

            if showMore {
                aboutRow("paintpalette", "My medium", story.medium)
                aboutRow("sparkles", "Inspired by", story.inspiredBy)
                aboutRow("building.2", "Studio in \(story.studioCity)", story.location)
            }

            Button {
                Haptics.select()
                withAnimation(PicardoMotion.quick) { showMore.toggle() }
            } label: {
                Text(showMore ? "Show less" : "Show more")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brand)
            }
            .accessibilityLabel(showMore ? "Show less about me" : "Show more about me")
        }
    }

    private func aboutRow(_ icon: String, _ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.picardoAccent)
                .frame(width: 22)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.picardoText)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(Color.picardoTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
