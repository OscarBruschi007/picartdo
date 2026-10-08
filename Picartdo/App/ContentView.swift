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
            .padding(.bottom, hideTabBar ? 0 : 82)

            VStack(spacing: 0) {
                Divider().opacity(0.3)

                HStack(alignment: .center, spacing: 0) {
                    tabItem(icon: "house.fill",      label: "Home",     tag: 0)
                    tabItem(icon: "briefcase.fill",  label: "Services", tag: 1)

                    Button { showSellSheet = true } label: {
                        ZStack {
                            Circle()
                                .fill(Color.picardoNeonRed)
                                .frame(width: 52, height: 52)
                                .shadow(color: Color.picardoNeonRed.opacity(0.4),
                                        radius: 10, x: 0, y: 4)
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .offset(y: -10)
                    }
                    .buttonStyle(PicardoPressStyle())
                    .frame(maxWidth: .infinity)

                    tabItem(icon: "magnifyingglass", label: "Explore",  tag: 2)
                    tabItem(icon: "person.fill",     label: "Profile",  tag: 3)
                }
                .padding(.horizontal, 4)
                .frame(height: 56)
                .padding(.bottom, 28)
                .background(.ultraThinMaterial)
            }
            .offset(y: hideTabBar ? 140 : 0)
            .opacity(hideTabBar ? 0 : 1)
            .allowsHitTesting(!hideTabBar)
            .accessibilityHidden(hideTabBar)
            .animation(PicardoMotion.transition, value: hideTabBar)
        }
        .background(Color.picardoBackground)
        .ignoresSafeArea(edges: .bottom)
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

    @ViewBuilder
    private func tabItem(icon: String, label: String, tag: Int) -> some View {
        Button { selectTab(tag) } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 21,
                                  weight: selectedTab == tag ? .semibold : .regular))
                    .foregroundStyle(selectedTab == tag
                        ? Color.picardoGold
                        : Color(.secondaryLabel))
                Text(label)
                    .font(.system(size: 10,
                                  weight: selectedTab == tag ? .semibold : .regular))
                    .foregroundStyle(selectedTab == tag
                        ? Color.picardoGold
                        : Color(.secondaryLabel))
            }
            .animation(PicardoMotion.quick, value: selectedTab)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview { ContentView() }
