import SwiftUI

enum ProfileMediaTab: String, CaseIterable, Identifiable {
    case posts, videos, threads, selling, liked, collection

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .posts:      return "square.grid.3x3"
        case .videos:     return "play.rectangle"
        case .threads:    return "text.bubble"
        case .selling:    return "tag"
        case .liked:      return "heart"
        case .collection: return "photo.artframe"
        }
    }

    var title: String {
        switch self {
        case .posts:      return "Images"
        case .videos:     return "Videos"
        case .threads:    return "Threads"
        case .selling:    return "Listings"
        case .liked:      return "Liked"
        case .collection: return "Collection"
        }
    }
}

struct ProfileTabBar: View {
    @Binding var tab: ProfileMediaTab
    var namespace: Namespace.ID
    var tabs: [ProfileMediaTab] = [.posts, .selling]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { item in
                Button {
                    Haptics.select()
                    withAnimation(PicardoMotion.quick) { tab = item }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .font(.system(size: 18, weight: tab == item ? .semibold : .regular))
                            .foregroundStyle(tab == item ? Color.picardoText : Color.picardoTextSecondary)
                            .frame(height: 22)
                        ZStack {
                            Color.clear.frame(height: 2)
                            if tab == item {
                                Capsule()
                                    .fill(Color.brand)
                                    .frame(width: 28, height: 2)
                                    .matchedGeometryEffect(id: "profile-tab-underline", in: namespace)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(tab == item ? [.isSelected] : [])
            }
        }
        .background(Color.picardoBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.picardoDivider).frame(height: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Profile sections")
    }
}
