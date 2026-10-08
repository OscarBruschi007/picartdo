import SwiftUI

// MARK: - Explore Search Sheet
// Airbnb's Where/When/Who, adapted to an art marketplace: What / Style / Budget.
// Draft state is local; nothing applies to the feed until "Search" is tapped.

struct ExploreSearchSheet: View {

    // MARK: Dependencies

    let viewModel: ExploreViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: Sections

    private enum SearchSection {
        case what, style, budget
    }

    // MARK: Draft State

    @State private var expanded: SearchSection = .what
    @State private var draftText = ""
    @State private var draftBrowseCategory: ExploreBrowseCategory? = nil
    @State private var draftBand: PriceBand = .any
    @FocusState private var searchFieldFocused: Bool

    private let gridColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    // MARK: Body

    var body: some View {
        ZStack {
            PicartdoBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        whatCard
                        styleCard
                        budgetCard
                    }
                    .padding(.horizontal, ExploreTokens.screenPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }

                bottomBar
            }
        }
        .onAppear {
            draftText = viewModel.searchText
            draftBrowseCategory = viewModel.selectedBrowseCategory
            draftBand = viewModel.filters.priceBand
        }
    }

    // MARK: Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.picardoSurface))
                    .overlay(Circle().strokeBorder(Color.picardoBorder.opacity(0.6)))
            }
            .accessibilityLabel("Close search")
            Spacer()
        }
        .padding(.horizontal, ExploreTokens.screenPadding)
        .padding(.vertical, 12)
    }

    // MARK: What Card

    @ViewBuilder
    private var whatCard: some View {
        if expanded == .what {
            expandedCard(title: "What are you looking for?") {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Titles, artists, mediums…", text: $draftText)
                        .focused($searchFieldFocused)
                        .submitLabel(.search)
                        .onSubmit { applyAndDismiss() }
                        .autocorrectionDisabled()
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.picardoCard))

                if !viewModel.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Recent searches")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 6)
                        ForEach(viewModel.recentSearches, id: \.self) { term in
                            Button {
                                draftText = term
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundStyle(.secondary)
                                    Text(term)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .onAppear { searchFieldFocused = true }
        } else {
            collapsedCard(section: .what, title: "What", summary: draftText.isEmpty ? "Anything" : draftText)
        }
    }

    // MARK: Style Card

    @ViewBuilder
    private var styleCard: some View {
        if expanded == .style {
            expandedCard(title: "What style?") {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(ExploreBrowseCategory.heroCategories) { category in
                        let isSelected = draftBrowseCategory == category
                        Button {
                            UISelectionFeedbackGenerator().selectionChanged()
                            withAnimation(ExploreTokens.snappy) {
                                draftBrowseCategory = isSelected ? nil : category
                            }
                        } label: {
                            VStack(spacing: 8) {
                                categoryThumb(for: category)
                                Text(category.rawValue)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Text(category.marketplaceHint)
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelected ? Color.picardoGoldLight : Color.picardoCard)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(isSelected ? Color.picardoGold : .clear, lineWidth: 2)
                            )
                            .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    }
                }
            }
        } else {
            collapsedCard(section: .style, title: "Style", summary: draftBrowseCategory?.rawValue ?? "Any style")
        }
    }

    @ViewBuilder
    private func categoryThumb(for category: ExploreBrowseCategory) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(category.tileColor)
            Image(systemName: category.iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 52, height: 52)
    }

    // MARK: Budget Card

    @ViewBuilder
    private var budgetCard: some View {
        if expanded == .budget {
            expandedCard(title: "What's your budget?") {
                PriceBandGrid(selection: $draftBand)
            }
        } else {
            collapsedCard(section: .budget, title: "Budget", summary: draftBand == .any ? "Any price" : draftBand.rawValue)
        }
    }

    // MARK: Card Builders

    private func expandedCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2.weight(.bold))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(cardBackground)
    }

    private func collapsedCard(section: SearchSection, title: String, summary: String) -> some View {
        Button {
            withAnimation(ExploreTokens.snappy) { expanded = section }
        } label: {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(summary)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            .padding(20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(cardBackground)
        .accessibilityHint("Expands \(title) options")
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: ExploreTokens.sheetCornerRadius)
            .fill(Color.picardoSurface)
            .shadow(color: .black.opacity(0.10), radius: 10, y: 2)
    }

    // MARK: Bottom Bar

    private var bottomBar: some View {
        HStack {
            Button {
                draftText = ""
                draftBrowseCategory = nil
                draftBand = .any
            } label: {
                Text("Clear all")
                    .font(.subheadline.weight(.semibold))
                    .underline()
                    .foregroundStyle(.primary)
            }
            .accessibilityHint("Resets search, style and budget")

            Spacer()

            Button {
                applyAndDismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .frame(height: 50)
                .background(Color.picardoGold, in: Capsule())
                .shadow(color: Color.picardoGold.opacity(0.35), radius: 8, y: 3)
            }
            .accessibilityHint("Applies your search and shows results")
        }
        .padding(.horizontal, ExploreTokens.screenPadding)
        .padding(.vertical, 12)
        .background(.bar)
    }

    // MARK: Apply

    private func applyAndDismiss() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        viewModel.searchText = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.selectedBrowseCategory = draftBrowseCategory
        viewModel.filters.priceBand = draftBand
        viewModel.recordRecentSearch(draftText)
        dismiss()
    }
}

// MARK: - Price Band Grid (shared with the filter sheet)

struct PriceBandGrid: View {
    @Binding var selection: PriceBand

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(PriceBand.allCases) { band in
                let isSelected = selection == band
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(ExploreTokens.snappy) { selection = band }
                } label: {
                    Text(band.rawValue)
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(isSelected ? Color.picardoGoldLight : Color.picardoCard))
                        .overlay(
                            Capsule().strokeBorder(isSelected ? Color.picardoGold : .clear, lineWidth: 2)
                        )
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ExploreSearchSheet(viewModel: ExploreViewModel())
}
