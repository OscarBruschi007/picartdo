import SwiftUI

struct ArtworkDetailView: View {
    let artwork: Artwork
    @Binding var likedIDs: Set<Int>
    @Environment(\.dismiss) private var dismiss
    @State private var showBuyConfirmation = false
    @State private var showOfferSheet = false

    var isLiked: Bool { likedIDs.contains(artwork.id) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // ── Full artwork image ────────────────────────
                    Image(artwork.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))

                    VStack(alignment: .leading, spacing: 20) {

                        // ── Title + Price ─────────────────────────
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(artwork.title)
                                    .font(.title2.bold())
                                Text("by Oscar Bruschi")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(artwork.priceFormatted)
                                    .font(.title.weight(.heavy))
                                Text("Fixed Price")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Divider()

                        // ── Metadata grid ─────────────────────────
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            MetadataCell(label: "Medium", value: artwork.medium)
                            MetadataCell(label: "Dimensions", value: artwork.dimensions)
                            MetadataCell(label: "Category", value: artwork.category)
                            MetadataCell(label: "Likes", value: "\(artwork.likes + (isLiked ? 1 : 0))")
                        }

                        Divider()

                        // ── Description ───────────────────────────
                        Text(artwork.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)

                        // ── Certificate note ──────────────────────
                        HStack(spacing: 10) {
                            Image(systemName: "rosette")
                                .font(.title3)
                                .foregroundStyle(.picardoGold)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Certificate of Authenticity")
                                    .font(.subheadline.weight(.semibold))
                                Text("Included with every purchase")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .background(Color.picardoGoldDim)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.picardoGold.opacity(0.3), lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // ── Actions ───────────────────────────────
                        VStack(spacing: 10) {
                            Button {
                                showBuyConfirmation = true
                            } label: {
                                Text("Buy Now — \(artwork.priceFormatted)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            HStack(spacing: 10) {
                                Button {
                                    showOfferSheet = true
                                } label: {
                                    Text("Make an Offer")
                                        .font(.subheadline.weight(.bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }

                                Button {
                                    if isLiked { likedIDs.remove(artwork.id) }
                                    else { likedIDs.insert(artwork.id) }
                                } label: {
                                    Image(systemName: isLiked ? "heart.fill" : "heart")
                                        .font(.title3)
                                        .foregroundStyle(isLiked ? .red : .primary)
                                        .frame(width: 52, height: 52)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }

                            Button {
                                // Message artist
                            } label: {
                                Label("Message Artist", systemImage: "message")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.picardoGold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.picardoGoldDim)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.picardoGold.opacity(0.3), lineWidth: 0.5)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .alert("Confirm Purchase", isPresented: $showBuyConfirmation) {
                Button("Buy for \(artwork.priceFormatted)", role: .none) {}
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You're about to purchase \"\(artwork.title)\" by Oscar Bruschi.")
            }
            .sheet(isPresented: $showOfferSheet) {
                MakeOfferView(artwork: artwork)
            }
        }
    }
}

// MARK: - Metadata Cell

struct MetadataCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.tertiary)
                .tracking(0.8)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Make Offer View

struct MakeOfferView: View {
    let artwork: Artwork
    @Environment(\.dismiss) private var dismiss
    @State private var offerAmount = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Your offer", text: $offerAmount)
                            .keyboardType(.numberPad)
                    }
                } header: {
                    Text("Your Offer")
                } footer: {
                    Text("Listed at \(artwork.priceFormatted). The artist will respond within 24h.")
                }

                Section {
                    Button("Send Offer") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.picardoGold)
                    .fontWeight(.bold)
                }
            }
            .navigationTitle("Make an Offer")
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
    ArtworkDetailView(artwork: Artwork.all[14], likedIDs: .constant([]))
}
