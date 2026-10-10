import SwiftUI

/// Curated exhibitions — museum hang, not marketplace categories.
struct CollectionsView: View {
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 36)
                        .picardoReveal()

                    LazyVStack(spacing: 40) {
                        ForEach(Array(CuratedCollection.all.enumerated()), id: \.element.id) { index, collection in
                            NavigationLink(value: collection) {
                                CollectionCoverCard(collection: collection, asymmetric: index % 2 == 1)
                            }
                            .buttonStyle(PicardoPressStyle())
                            .picardoReveal(delay: Double(index) * 0.05)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                }
            }
            .background(Color.picardoBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: CuratedCollection.self) { collection in
                CollectionDetailView(collection: collection)
            }
            .navigationDestination(for: Artwork.self) { artwork in
                ArtworkDetailView(artwork: artwork)
            }
            .navigationDestination(for: Artist.self) { artist in
                ArtistStoreView(artist: artist)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            PicardoEyebrow(text: "Curated")
            Text("Exhibitions")
                .font(PicardoType.display(36))
                .foregroundStyle(Color.picardoText)
            Text("Selected hangings — not categories. Each room is a point of view.")
                .font(PicardoType.body(15))
                .foregroundStyle(Color.picardoTextSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Cover card

struct CollectionCoverCard: View {
    let collection: CuratedCollection
    var asymmetric: Bool = false

    var body: some View {
        VStack(alignment: asymmetric ? .trailing : .leading, spacing: 16) {
            ZStack(alignment: .bottomLeading) {
                Color.picardoSurface
                ArtworkImage(imageName: collection.coverImageName, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: asymmetric ? 280 : 340)
                    .clipped()
            }
            .picardoCard(radius: 22)

            VStack(alignment: asymmetric ? .trailing : .leading, spacing: 6) {
                Text(collection.yearLabel)
                    .picardoMetaStyle()
                    .foregroundStyle(Color.picardoTextSecondary)

                Text(collection.title)
                    .font(PicardoType.title(26))
                    .foregroundStyle(Color.picardoText)
                    .multilineTextAlignment(asymmetric ? .trailing : .leading)

                Text(collection.subtitle)
                    .font(PicardoType.body(14))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .multilineTextAlignment(asymmetric ? .trailing : .leading)

                Text("\(collection.artworks.count) WORKS")
                    .picardoMetaStyle(kerning: 1.2)
                    .foregroundStyle(Color.picardoAccent)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: asymmetric ? .trailing : .leading)
            .padding(.horizontal, asymmetric ? 8 : 4)
        }
    }
}

// MARK: - Exhibition detail

struct CollectionDetailView: View {
    let collection: CuratedCollection

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                ArtworkImage(imageName: collection.coverImageName, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)

                VStack(alignment: .leading, spacing: 10) {
                    PicardoEyebrow(text: "Exhibition · \(collection.yearLabel)")
                    Text(collection.title)
                        .font(PicardoType.display(32))
                        .foregroundStyle(Color.picardoText)
                    Text(collection.essay)
                        .font(PicardoType.body(16))
                        .italic()
                        .foregroundStyle(Color.picardoText.opacity(0.85))
                        .lineSpacing(6)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                Rectangle()
                    .fill(Color.picardoDivider)
                    .frame(height: 1)
                    .padding(.horizontal, 24)

                Text("Works")
                    .font(PicardoType.section(20))
                    .foregroundStyle(Color.picardoText)
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 16)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(collection.artworks) { artwork in
                        CollectionWorkTile(artwork: artwork)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
        }
        .background(Color.picardoBackground)
        .navigationBarTitleDisplayMode(.inline)
        .picardoPushedScreen()
    }
}

struct CollectionWorkTile: View {
    let artwork: Artwork

    var body: some View {
        ArtworkCard(artwork: artwork, variant: .collectionWork)
    }
}

#Preview { CollectionsView() }
