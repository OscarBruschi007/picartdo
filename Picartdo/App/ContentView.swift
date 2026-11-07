import SwiftUI

/// Demo tab shell: Home · Services · Sell(+) · Explore · Profile
struct ContentView: View {
    @State private var showSellSheet = false
    @State private var hideTabBar = false
    @State private var selectedTab: Int
    @State private var visitedTabs: Set<Int>
    @State private var homeRootTick = 0

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
                tabItem(icon: "house",           label: "Home",     tag: 0)
                tabItem(icon: "briefcase",       label: "Services", tag: 1)

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
                tabItem(icon: "person",          label: "Profile",  tag: 3)
            }
            .padding(.horizontal, 12)
            .frame(height: 60)
            // Tinted with the page colour so labels stay readable over any artwork.
            .glassEffect(.regular.tint(Color.picardoBackground.opacity(0.86)).interactive(), in: Capsule())
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
        .environment(\.homeRootTick, homeRootTick)
        .environment(\.heroVideoEnabled, selectedTab == 1)
        .environment(\.feedVideoEnabled, selectedTab == 0)
        .onChange(of: selectedTab) { _, tab in
            if tab != 1 { HeroVideoControl.setEnabled(false) }
        }
        .fullScreenCover(isPresented: $showSellSheet) {
            SellArtView(onViewStudio: {
                showSellSheet = false
                selectTab(3)
            })
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
        if tag == 0 {
            homeRootTick += 1
        }
        selectedTab = tag
    }


    /// One icon family, one ink colour: filled and bold when selected, outlined and
    /// quieter when not. The red + stays the only colour in the bar, so it stands out.
    @ViewBuilder
    private func tabItem(icon: String, label: String, tag: Int) -> some View {
        let on = selectedTab == tag
        Button {
            if !on { Haptics.select() }
            selectTab(tag)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: on && icon != "magnifyingglass" ? "\(icon).fill" : icon)
                    .font(.system(size: 21, weight: on ? .semibold : .regular))
                    .frame(height: 26)
                Text(label)
                    .font(.system(size: 10, weight: on ? .semibold : .medium))
            }
            .foregroundStyle(on ? Color.picardoText : Color.picardoTextSecondary)
            .animation(PicardoMotion.quick, value: selectedTab)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

#Preview { ContentView() }
