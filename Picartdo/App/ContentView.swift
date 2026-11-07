import SwiftUI

/// Demo tab shell: Home · Services · Sell(+) · Explore · Profile
struct ContentView: View {
    @State private var showSellSheet = false
    @State private var hideTabBar = false
    @State private var selectedTab: Int
    @State private var visitedTabs: Set<Int>
    @State private var homeRootTick = 0
    @State private var identity = ProfileIdentity.load()
    @Namespace private var tabHighlight

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

                Button {
                    Haptics.tap()
                    showSellSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.picardoNeonRed, in: Circle())
                        .shadow(color: Color.picardoNeonRed.opacity(0.35), radius: 8, y: 3)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PicardoPressStyle())
                .accessibilityLabel("Sell or post")

                tabItem(icon: "magnifyingglass", label: "Explore",  tag: 2)
                profileTabItem
            }
            .padding(.horizontal, 6)
            .frame(height: 64)
            // Liquid glass, tinted with the page colour so icons read over any artwork.
            .glassEffect(.regular.tint(Color.picardoBackground.opacity(0.8)).interactive(), in: Capsule())
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
            identity = ProfileIdentity.load()
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


    /// Icon-only tabs, one ink colour. The selected tab is filled and sits on a soft
    /// rounded highlight that slides between tabs; the rest are quiet outlines.
    @ViewBuilder
    private func tabItem(icon: String, label: String, tag: Int) -> some View {
        let on = selectedTab == tag
        Button {
            if !on { Haptics.select() }
            withAnimation(PicardoMotion.quick) { selectTab(tag) }
        } label: {
            Image(systemName: on && icon != "magnifyingglass" ? "\(icon).fill" : icon)
                .font(.system(size: 22, weight: on ? .semibold : .regular))
                .foregroundStyle(Color.picardoText.opacity(on ? 1 : 0.78))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background { highlight(on) }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    /// Profile shows your own photo, ringed when selected.
    private var profileTabItem: some View {
        let on = selectedTab == 3
        return Button {
            if !on { Haptics.select() }
            withAnimation(PicardoMotion.quick) { selectTab(3) }
        } label: {
            Group {
                if let custom = identity.avatarImage {
                    Image(uiImage: custom).resizable().scaledToFill()
                } else {
                    ArtworkImage(imageName: identity.avatarAsset, contentMode: .fill, maxDimension: 120)
                }
            }
            .frame(width: 28, height: 28)
            .clipShape(Circle())
            .padding(2.5)
            .overlay(Circle().strokeBorder(Color.picardoText, lineWidth: on ? 1.75 : 0))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background { highlight(on) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Profile")
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    @ViewBuilder
    private func highlight(_ on: Bool) -> some View {
        if on {
            Capsule()
                .fill(Color.picardoText.opacity(0.14))
                .padding(.horizontal, 4)
                .matchedGeometryEffect(id: "tabHighlight", in: tabHighlight)
        }
    }
}

#Preview { ContentView() }
