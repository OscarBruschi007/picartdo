import SwiftUI

struct ProfileHero: View {
    let coverImage: String
    let avatarImage: String
    var customAvatar: UIImage? = nil
    let name: String
    let handle: String
    let city: String
    var isOwnProfile: Bool = true
    var onPrimary: () -> Void
    var onMessage: () -> Void

    private let heroHeight: CGFloat = 360
    private let topBleed: CGFloat = 72
    private let avatar: CGFloat = 96

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geo in
                let minY = geo.frame(in: .named("profile-scroll")).minY
                let stretch = max(0, minY)
                ArtworkImage(imageName: coverImage, contentMode: .fill, maxDimension: 1600)
                    .frame(width: geo.size.width, height: heroHeight + topBleed + stretch)
                    .clipped()
                    .offset(y: minY > 0 ? -minY : minY * 0.35)
            }
            .frame(height: heroHeight + topBleed)
            .padding(.top, -topBleed)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .bottom, spacing: 14) {
                    avatarView
                        .offset(y: -avatar / 2.2)
                        .padding(.bottom, -avatar / 2.2)
                    Spacer(minLength: 0)
                    HStack(spacing: 8) {
                        Button(action: {
                            Haptics.tap()
                            onPrimary()
                        }) {
                            Text(isOwnProfile ? "Edit profile" : "Muse")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.picardoText, in: Capsule())
                                .foregroundStyle(Color.cardSurface)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isOwnProfile ? "Edit profile" : "Muse")

                        Button(action: {
                            Haptics.tap()
                            onMessage()
                        }) {
                            Text("Message")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .overlay(Capsule().strokeBorder(Color.picardoBorder, lineWidth: 1))
                                .foregroundStyle(Color.picardoText)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Message")
                    }
                    .offset(y: -8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(.title, design: .serif).weight(.bold))
                        .foregroundStyle(Color.picardoText)
                    Text("@\(handle)")
                        .font(.subheadline)
                        .foregroundStyle(Color.picardoTextSecondary)
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                        Text(city)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.picardoTextSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    private var avatarView: some View {
        Group {
            if let customAvatar {
                Image(uiImage: customAvatar).resizable().scaledToFill()
            } else {
                ArtworkImage(imageName: avatarImage, contentMode: .fill, maxDimension: 400)
            }
        }
        .frame(width: avatar, height: avatar)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color.picardoBackground, lineWidth: 4))
        .accessibilityHidden(true)
    }
}
