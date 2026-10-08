import SwiftUI

struct ProfileView: View {
    @State private var selectedTab = "Listings"
    let tabs = ["Listings (26)", "Sold", "About"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // ── Banner ────────────────────────────────────
                    ZStack(alignment: .bottom) {
                        Image("art_15")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipped()
                            .opacity(0.7)

                        LinearGradient(
                            colors: [Color(.systemBackground), .clear],
                            startPoint: .bottom,
                            endPoint: .center
                        )
                    }
                    .frame(height: 220)

                    // ── Profile Info ──────────────────────────────
                    VStack(spacing: 0) {
                        HStack(alignment: .bottom) {
                            Image("profile")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(Color(.systemBackground), lineWidth: 4))
                                .shadow(radius: 8)
                                .offset(y: -50)
                                .padding(.bottom, -40)

                            Spacer()

                            HStack(spacing: 8) {
                                Button("Follow") {}
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                Button("Message") {}
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .padding(.bottom, 8)
                        }
                        .padding(.horizontal, 20)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text("Oscar Bruschi")
                                    .font(.title2.bold())
                                Text("VERIFIED")
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color.picardoGold)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            }

                            Text("Founder & Lead Artist · Picardo")
                                .font(.subheadline)
                                .foregroundStyle(.picardoGold)

                            Text("Curating beauty one piece at a time. Painter, sculptor & marketplace creator.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)

                            // Stats row
                            HStack(spacing: 24) {
                                ProfileStat(number: "26",   label: "Works")
                                ProfileStat(number: "1.4k", label: "Followers")
                                ProfileStat(number: "4.8 ★", label: "Rating")
                                ProfileStat(number: "$28k",  label: "In Sales")
                            }
                            .padding(.top, 6)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }

                    // ── Tabs ──────────────────────────────────────
                    HStack(spacing: 0) {
                        ForEach(tabs, id: \.self) { tab in
                            Button(tab) { selectedTab = tab }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .overlay(alignment: .bottom) {
                                    if selectedTab == tab {
                                        Rectangle()
                                            .fill(Color.picardoGold)
                                            .frame(height: 2)
                                    }
                                }
                        }
                    }
                    .overlay(alignment: .bottom) {
                        Divider()
                    }
                    .padding(.horizontal, 20)

                    // ── Content ───────────────────────────────────
                    if selectedTab == "Listings (26)" || selectedTab == "Sold" {
                        ArtworkGridContent(artworks: selectedTab == "Listings (26)" ? Artwork.all : [])
                    } else {
                        AboutContent()
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Artwork Grid Content

struct ArtworkGridContent: View {
    let artworks: [Artwork]
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        if artworks.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "bag")
                    .font(.system(size: 44))
                    .foregroundStyle(.tertiary)
                Text("No sold works yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        } else {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(artworks) { artwork in
                    Image(artwork.imageName)
                        .resizable()
                        .scaledToFill()
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                }
            }
            .padding(.top, 2)
        }
    }
}

// MARK: - About Content

struct AboutContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            InfoRow(icon: "paintpalette.fill", label: "Speciality", value: "Acrylic, Ink, Mixed Media")
            InfoRow(icon: "mappin.circle.fill",  label: "Location",   value: "Buenos Aires, Argentina")
            InfoRow(icon: "calendar",            label: "Member Since", value: "January 2024")
            InfoRow(icon: "star.fill",           label: "Rating",     value: "4.8 out of 5 (128 reviews)")
        }
        .padding(20)
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.picardoGold)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
            }
        }
    }
}

// MARK: - Profile Stat

struct ProfileStat: View {
    let number: String
    let label: String

    var body: some View {
        VStack(spacing: 1) {
            Text(number)
                .font(.headline.weight(.heavy))
            Text(label.uppercased())
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
                .tracking(0.5)
        }
    }
}

#Preview {
    ProfileView()
}
