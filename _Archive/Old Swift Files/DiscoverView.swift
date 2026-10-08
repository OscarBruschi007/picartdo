import SwiftUI

struct DiscoverView: View {
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedSegment) {
                    Text("Services").tag(0)
                    Text("Artists").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 10)

                if selectedSegment == 0 {
                    ServicesTab()
                } else {
                    ArtistsTab()
                }
            }
            .navigationTitle("Discover")
        }
    }
}

// MARK: - Services Tab

struct ServicesTab: View {
    @State private var showBookingFor: ServiceProvider? = nil
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Category grid
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(eyebrow: "Browse by Category", title: "What are you looking for?")
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(ServiceCategory.all) { cat in
                            ServiceCategoryCard(category: cat)
                        }
                    }
                    .padding(.horizontal)
                }

                Divider().padding(.horizontal)

                // Providers
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(eyebrow: "Top Rated", title: "Featured Providers", subtitle: "Verified artists available for booking")
                        .padding(.horizontal)

                    ForEach(ServiceProvider.all) { provider in
                        ServiceProviderCard(provider: provider, onBook: { showBookingFor = provider })
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .sheet(item: $showBookingFor) { provider in
            BookingView(provider: provider)
        }
    }
}

// MARK: - Artists Tab

struct ArtistsTab: View {
    @State private var following: Set<UUID> = []
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Artist.all) { artist in
                    ArtistCard(
                        artist: artist,
                        isFollowing: following.contains(artist.id),
                        onFollow: {
                            if following.contains(artist.id) { following.remove(artist.id) }
                            else { following.insert(artist.id) }
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Service Category Card

struct ServiceCategoryCard: View {
    let category: ServiceCategory

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(category.image)
                .resizable()
                .scaledToFill()
                .frame(height: 130)
                .clipped()

            LinearGradient(
                colors: [.black.opacity(0.75), .clear],
                startPoint: .bottom,
                endPoint: .center
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(category.icon)
                    .font(.title3)
                Text(category.name)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(category.count)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(12)

            Text(category.count)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.picardoGold.opacity(0.9))
                .clipShape(Capsule())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
}

// MARK: - Service Provider Card

struct ServiceProviderCard: View {
    let provider: ServiceProvider
    let onBook: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image(provider.portfolioImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .clipped()

            HStack(alignment: .top, spacing: 10) {
                Image(provider.avatarImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(.background, lineWidth: 2))
                    .offset(y: -20)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(provider.name)
                            .font(.subheadline.weight(.bold))
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.picardoGold)
                    }
                    Text(provider.type)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Stars
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Image(systemName: Double(i) < provider.rating ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundStyle(Double(i) < provider.rating ? .picardoGold : Color(.systemGray4))
                        }
                        Text(provider.starsFormatted)
                            .font(.caption.weight(.semibold))
                        Text("(\(provider.reviews))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 10) {
                Text(provider.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Starting from")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                        Text("$\(provider.startingFrom)")
                            .font(.subheadline.weight(.heavy))
                    }
                    Spacer()
                    Button("Book Now", action: onBook)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 9)
                        .background(Color.picardoGold)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 2)
    }
}

// MARK: - Artist Card

struct ArtistCard: View {
    let artist: Artist
    let isFollowing: Bool
    let onFollow: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Banner
            Image(artist.bannerImage)
                .resizable()
                .scaledToFill()
                .frame(height: 90)
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                // Avatar
                Image(artist.avatarImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color(.systemBackground), lineWidth: 3))
                    .shadow(radius: 4)
                    .offset(y: -26)
                    .padding(.bottom, -18)

                // Name + verified
                HStack(spacing: 5) {
                    Text(artist.name)
                        .font(.subheadline.weight(.heavy))
                        .lineLimit(1)
                    if artist.verified {
                        Text("✓")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.picardoGold)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }

                Text(artist.tagline)
                    .font(.caption)
                    .foregroundStyle(.picardoGold)
                    .lineLimit(1)

                Text(artist.bio)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Stats
                HStack(spacing: 0) {
                    ArtistStat(number: "\(artist.works)", label: "Works")
                    Divider().frame(height: 28)
                    ArtistStat(number: artist.followers, label: "Followers")
                    Divider().frame(height: 28)
                    ArtistStat(number: artist.sales, label: "Sales")
                }
                .padding(.vertical, 8)

                Button(isFollowing ? "Following" : "Follow", action: onFollow)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isFollowing ? .primary : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(isFollowing ? Color(.systemGray5) : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

struct ArtistStat: View {
    let number: String
    let label: String

    var body: some View {
        VStack(spacing: 1) {
            Text(number)
                .font(.subheadline.weight(.heavy))
            Text(label.uppercased())
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let eyebrow: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(eyebrow.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.picardoGold)
                .tracking(2)
            Text(title)
                .font(.title2.bold())
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Booking View

struct BookingView: View {
    let provider: ServiceProvider
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var projectDetails = ""
    @State private var budget = ""
    @State private var timeline = "Flexible"

    let timelines = ["ASAP", "1–2 weeks", "1 month", "Flexible"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Details") {
                    TextField("Full name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                Section("Project") {
                    TextField("Describe what you're looking for…", text: $projectDetails, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                    TextField("Budget (USD)", text: $budget)
                        .keyboardType(.numberPad)
                    Picker("Timeline", selection: $timeline) {
                        ForEach(timelines, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section {
                    Button("Send Booking Request") { dismiss() }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.picardoGold)
                        .fontWeight(.bold)
                }
            }
            .navigationTitle("Book \(provider.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    DiscoverView()
}
