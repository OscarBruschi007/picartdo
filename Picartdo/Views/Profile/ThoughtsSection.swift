import SwiftUI

struct ThoughtsSection: View {
    let posts: [ThreadPost]
    var isOwnProfile: Bool
    var onSeeAll: () -> Void
    var onCompose: () -> Void
    var onLike: (UUID) -> Void
    var onRepost: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Thoughts")
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundStyle(Color.picardoText)
                Spacer()
                if isOwnProfile {
                    Button {
                        Haptics.tap()
                        onCompose()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.brand, in: Circle())
                    }
                    .accessibilityLabel("Write a thought")
                }
            }
            .padding(.horizontal, 20)

            if posts.isEmpty {
                Text("Quiet in here. The first note starts the conversation.")
                    .font(.subheadline)
                    .foregroundStyle(Color.picardoTextSecondary)
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(posts.prefix(3)) { post in
                        thoughtCard(post)
                    }
                }
                .padding(.horizontal, 16)

                Button {
                    Haptics.tap()
                    onSeeAll()
                } label: {
                    Text("See all thoughts")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium, style: .continuous)
                                .strokeBorder(Color.picardoBorder, lineWidth: 1)
                        )
                        .foregroundStyle(Color.picardoText)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .accessibilityLabel("See all thoughts")
            }
        }
    }

    private func thoughtCard(_ post: ThreadPost) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ArtworkImage(imageName: post.avatarImage, contentMode: .fill, maxDimension: 120)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text(post.authorName)
                        .font(.subheadline.weight(.semibold))
                    Text("\(post.timeAgo)")
                        .font(.caption)
                        .foregroundStyle(Color.picardoTextSecondary)
                }
                Spacer()
            }

            Text(post.text)
                .font(.body)
                .foregroundStyle(Color.picardoText)
                .fixedSize(horizontal: false, vertical: true)

            if let image = post.artworkImageName {
                ArtworkImage(imageName: image, contentMode: .fill, maxDimension: 900)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall, style: .continuous))
            }

            HStack(spacing: 18) {
                label("heart", post.likeCount) { onLike(post.id) }
                label("bubble.right", post.replyCount) {}
                label("arrow.2.squarepath", post.repostCount) { onRepost(post.id) }
                Spacer()
            }
            .foregroundStyle(Color.picardoTextSecondary)
        }
        .padding(16)
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: DesignTokens.radiusMedium, style: .continuous))
        .cardShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(post.text)
    }

    private func label(_ icon: String, _ count: Int, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text("\(count)")
                    .font(.caption)
            }
        }
        .buttonStyle(.plain)
    }
}
