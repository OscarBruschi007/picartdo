import SwiftUI

// MARK: - FeedView (artwork browse grid)

struct FeedView: View {
    let columns = [GridItem(.flexible(), spacing: 10),
                   GridItem(.flexible(), spacing: 10)]

    var body: some View {
        NavigationStack {
            ZStack {
                PicartdoBackground().ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(Artwork.samples) { artwork in
                            NavigationLink(value: artwork) {
                                GoatGridCard(artwork: artwork)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Artwork.self) { artwork in
                ArtworkDetailView(artwork: artwork)
            }
            .navigationDestination(for: Artist.self) { artist in
                ArtistStoreView(artist: artist)
            }
        }
    }
}

#Preview { FeedView() }
