import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .feed
    @State private var showSellSheet = false

    enum Tab {
        case feed, discover, sell, collections, profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            Tab("Browse", systemImage: "square.stack", value: .feed) {
                FeedView()
            }

            Tab("Discover", systemImage: "safari", value: .discover) {
                DiscoverView()
            }

            Tab("Sell", systemImage: "plus.circle.fill", value: .sell) {
                Color.clear
            }

            Tab("Collections", systemImage: "heart", value: .collections) {
                CollectionsView()
            }

            Tab("Profile", systemImage: "person.circle", value: .profile) {
                ProfileView()
            }
        }
        .tint(.picardoGold)
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .sell {
                showSellSheet = true
                selectedTab = .feed
            }
        }
        .sheet(isPresented: $showSellSheet) {
            SellArtView()
        }
    }
}

// MARK: - Collections placeholder

struct CollectionsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "heart.square.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.picardoGold)
                Text("Your Collections")
                    .font(.title2.bold())
                Text("Save artworks you love and build your personal gallery.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .navigationTitle("Collections")
        }
    }
}

#Preview {
    ContentView()
}
