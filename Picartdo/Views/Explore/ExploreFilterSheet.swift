import SwiftUI

// MARK: - Explore Filter Sheet
// Draft state pattern: edits are local until "Show X artworks" is tapped.
// The result count live-updates via .task(id: draft) with automatic cancellation.

struct ExploreFilterSheet: View {

    // MARK: Dependencies

    let viewModel: ExploreViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: Draft State

    @State private var draft = ExploreFilterCriteria()
    @State private var previewCount: Int?

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    sortSection
                    Divider()
                    priceSection
                    Divider()
                    availabilitySection
                }
                .padding(20)
            }
            .background(Color.picardoBackground)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Close filters")
                }
            }
            .safeAreaInset(edge: .bottom) { bottomBar }
        }
        .onAppear { draft = viewModel.filters }
        .task(id: draft) {
            previewCount = await viewModel.previewCount(filters: draft)
        }
    }

    // MARK: Sort

    private var sortSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sort by")
                .font(.headline)
                .padding(.bottom, 6)
            ForEach(ExploreSort.allCases) { option in
                let isSelected = draft.sort == option
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    draft.sort = option
                } label: {
                    HStack {
                        Text(option.rawValue)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.picardoGold)
                        }
                    }
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
    }

    // MARK: Price

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price range")
                .font(.headline)
            PriceBandGrid(selection: $draft.priceBand)
        }
    }

    // MARK: Availability

    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Availability")
                .font(.headline)
            Toggle(isOn: $draft.includeSold) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Include sold artworks")
                        .font(.subheadline)
                    Text("Show pieces that have already found a home")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Color.picardoGold)
        }
    }

    // MARK: Bottom Bar

    private var bottomBar: some View {
        HStack {
            Button {
                draft = ExploreFilterCriteria()
            } label: {
                Text("Clear all")
                    .font(.subheadline.weight(.semibold))
                    .underline()
                    .foregroundStyle(.primary)
            }
            .accessibilityHint("Resets all filters to defaults")

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                viewModel.filters = draft
                dismiss()
            } label: {
                Text(showButtonTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 50)
                    .background(Color.picardoGold, in: Capsule())
                    .shadow(color: Color.picardoGold.opacity(0.35), radius: 8, y: 3)
                    .contentTransition(.numericText())
            }
            .accessibilityHint("Applies filters and shows results")
        }
        .padding(.horizontal, ExploreTokens.screenPadding)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private var showButtonTitle: String {
        guard let count = previewCount else { return "Show results" }
        return count == 1 ? "Show 1 artwork" : "Show \(count) artworks"
    }
}

// MARK: - Preview

#Preview {
    ExploreFilterSheet(viewModel: ExploreViewModel())
}
