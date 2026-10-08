import SwiftUI

struct ThreadRow: View {
    let post: ThreadPost
    var replies: [ThreadPost] = []
    var onLike: () -> Void
    var onRepost: () -> Void
    var onShare: () -> Void
    var onReply: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            row(post, showsRail: !replies.isEmpty)
            ForEach(Array(replies.enumerated()), id: \.element.id) { index, reply in
                row(reply, showsRail: index < replies.count - 1, isReply: true)
            }
        }
    }

    private func row(_ post: ThreadPost, showsRail: Bool, isReply: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 0) {
                ArtworkImage(imageName: post.avatarImage, contentMode: .fill, maxDimension: 160)
                    .frame(width: isReply ? 32 : 40, height: isReply ? 32 : 40)
                    .clipShape(Circle())
                if showsRail {
                    Rectangle()
                        .fill(Color.picardoDivider)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(post.authorName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.picardoText)
                        .lineLimit(1)
                    Text("@\(post.handle)")
                        .font(.caption)
                        .foregroundStyle(Color.picardoTextSecondary)
                        .lineLimit(1)
                    Text("· \(post.timeAgo)")
                        .font(.caption)
                        .foregroundStyle(Color.picardoTextSecondary)
                    Spacer(minLength: 0)
                }

                Text(post.text)
                    .font(.body)
                    .foregroundStyle(Color.picardoText)
                    .fixedSize(horizontal: false, vertical: true)

                if let image = post.artworkImageName {
                    ArtworkImage(imageName: image, contentMode: .fill, maxDimension: 900)
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall, style: .continuous))
                }

                HStack(spacing: 22) {
                    action("bubble.right", post.replyCount, "Reply", onReply)
                    action("arrow.2.squarepath", post.repostCount, "Repost", onRepost)
                    action(post.liked ? "heart.fill" : "heart", post.likeCount, "Like", onLike, tint: post.liked ? Color.brand : Color.picardoTextSecondary)
                    action("square.and.arrow.up", nil, "Share", onShare)
                    Spacer(minLength: 0)
                }
                .padding(.top, 4)
                .padding(.bottom, 14)
            }
        }
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(post.authorName), \(post.text)")
    }

    private func action(_ icon: String, _ count: Int?, _ label: String, _ handler: @escaping () -> Void, tint: Color = Color.picardoTextSecondary) -> some View {
        Button {
            Haptics.tap()
            handler()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                if let count, count > 0 {
                    Text("\(count)")
                        .font(.caption)
                }
            }
            .foregroundStyle(tint)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
