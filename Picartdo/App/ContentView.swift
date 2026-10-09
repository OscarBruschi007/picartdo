import SwiftUI

/// Demo tab shell: Home · Services · Sell(+) · Explore · Profile
struct ContentView: View {
    @State private var showSellSheet = false
    @State private var hideTabBar = false
    @State private var selectedTab: Int
    @State private var visitedTabs: Set<Int>

    init() {
        let launch = Self.launchTab
        _selectedTab = State(initialValue: launch)
        _visitedTabs = State(initialValue: [launch])
    }

    private static var launchTab: Int {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--studio-tab") { return 3 }
        if args.contains("--explore-tab") { return 2 }
        return 0
    }

    var body: some View {
        ZStack(alignment: .bottom) {

            ZStack {
                if visitedTabs.contains(0) {
                    tabPage(0) {
                        if ProcessInfo.processInfo.arguments.contains("--artist-profile") {
                            NavigationStack { ArtistStoreView(artist: .oscar) }
                        } else {
                            HomeView(showSellSheet: $showSellSheet)
                        }
                    }
                }
                if visitedTabs.contains(1) {
                    tabPage(1) { DiscoverView() }
                }
                if visitedTabs.contains(2) {
                    tabPage(2) { ExploreView() }
                }
                if visitedTabs.contains(3) {
                    tabPage(3) { ProfileHomeView(onBack: { selectTab(0) }, hideTabBar: $hideTabBar) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .bottom)

            HStack(alignment: .center, spacing: 0) {
                tabItem(icon: "house.fill",      label: "Home",     tag: 0)
                tabItem(icon: "briefcase.fill",  label: "Services", tag: 1)

                Button { showSellSheet = true } label: {
                    ZStack {
                        Circle()
                            .fill(Color.picardoNeonRed)
                            .frame(width: 48, height: 48)
                            .shadow(color: Color.picardoNeonRed.opacity(0.4),
                                    radius: 10, x: 0, y: 4)
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(PicardoPressStyle())
                .frame(maxWidth: .infinity)

                tabItem(icon: "magnifyingglass", label: "Explore",  tag: 2)
                tabItem(icon: "person.fill",     label: "Profile",  tag: 3)
            }
            .padding(.horizontal, 12)
            .frame(height: 60)
            .glassEffect(.regular.interactive(), in: Capsule())
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
            .ignoresSafeArea(edges: .bottom)
            .offset(y: hideTabBar ? 140 : 0)
            .opacity(hideTabBar ? 0 : 1)
            .allowsHitTesting(!hideTabBar)
            .accessibilityHidden(hideTabBar)
            .animation(PicardoMotion.transition, value: hideTabBar)
        }
        .background(Color.picardoBackground)
        .environment(\.heroVideoEnabled, selectedTab == 1)
        .environment(\.feedVideoEnabled, selectedTab == 0)
        .onChange(of: selectedTab) { _, tab in
            if tab != 1 { HeroVideoControl.setEnabled(false) }
        }
        .fullScreenCover(isPresented: $showSellSheet) {
            SellArtView()
                .presentationBackground(.clear)
        }
    }

    @ViewBuilder
    private func tabPage<Content: View>(_ tag: Int, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(selectedTab == tag ? 1 : 0)
            .allowsHitTesting(selectedTab == tag)
            .zIndex(selectedTab == tag ? 1 : 0)
            .accessibilityHidden(selectedTab != tag)
    }

    private func selectTab(_ tag: Int) {
        visitedTabs.insert(tag)
        selectedTab = tag
    }

    private func tabTint(for tag: Int) -> Color {
        switch tag {
        case 0:  return Color(red: 1.00, green: 0.78, blue: 0.22)
        case 1:  return Color(red: 0.22, green: 0.78, blue: 1.00)
        case 2:  return Color(red: 0.82, green: 0.42, blue: 1.00)
        default: return Color(red: 1.00, green: 0.32, blue: 0.52)
        }
    }

    @ViewBuilder
    private func tabItem(icon: String, label: String, tag: Int) -> some View {
        let tint = tabTint(for: tag)
        let on = selectedTab == tag
        Button { selectTab(tag) } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 23, weight: on ? .bold : .semibold))
                    .foregroundStyle(tint)
                    .symbolRenderingMode(.monochrome)
                    .shadow(color: .black.opacity(0.55), radius: 3, y: 1)
                    .shadow(color: .white.opacity(0.35), radius: 0.5)
                Text(label)
                    .font(.system(size: 10, weight: on ? .bold : .semibold))
                    .foregroundStyle(tint)
                    .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
            }
            .opacity(on ? 1 : 0.88)
            .animation(PicardoMotion.quick, value: selectedTab)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview { ContentView() }
