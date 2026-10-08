import SwiftUI

/// Profile tab entry — Home-styled header + featured-drop feed.
struct ProfileHomeView: View {
    var onBack: (() -> Void)? = nil
    var hideTabBar: Binding<Bool> = .constant(false)

    var body: some View {
        ProfileView(hideTabBar: hideTabBar)
    }
}

#Preview {
    ProfileHomeView()
        .environment(SessionStore())
        .environment(WishlistStore())
        .environment(MarketplaceStore())
        .environment(ThreadPostStore())
}
