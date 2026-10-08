import SwiftUI

struct SellArtView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var category = "Painting"
    @State private var price = ""
    @State private var medium = ""
    @State private var dimensions = ""
    @State private var description = ""
    @State private var showConfirmation = false

    let categories = ["Painting", "Drawing", "Sculpture", "Digital", "Printmaking", "Mixed Media", "Photography"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Artwork Details") {
                    HStack {
                        TextField("Title", text: $title)
                        Spacer()
                        Picker("", selection: $category) {
                            ForEach(categories, id: \.self) { Text($0).tag($0) }
                        }
                        .labelsHidden()
                    }
                }

                Section("Pricing") {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Ask Price (USD)", text: $price)
                            .keyboardType(.numberPad)
                    }
                }

                Section("Specifications") {
                    TextField("Medium (e.g. Acrylic on canvas)", text: $medium)
                    TextField("Dimensions (e.g. 24 × 18 in)", text: $dimensions)
                }

                Section("Description") {
                    TextField("Tell the story behind this piece…", text: $description, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }

                Section {
                    Button {
                        showConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("List on Picardo — Free")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.picardoGold)
                }
            }
            .navigationTitle("List Your Artwork")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Listing Created!", isPresented: $showConfirmation) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your artwork \"\(title.isEmpty ? "Untitled" : title)\" has been submitted for review.")
            }
        }
    }
}

#Preview {
    SellArtView()
}
