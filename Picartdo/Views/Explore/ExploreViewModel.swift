import Foundation
import Observation

// MARK: - Explore View Model

@Observable
@MainActor
final class ExploreViewModel {

    // MARK: Phase

    enum Phase: Equatable {
        case loading
        case loaded
        case empty
        case error(String)
    }

    // MARK: Published State

    private(set) var artworks: [Artwork] = []
    private(set) var phase: Phase = .loading
    private(set) var isLoadingMore = false
    private(set) var recentSearches: [String] = []

    var searchText = ""
    var selectedBrowseCategory: ExploreBrowseCategory? = nil
    var filters = ExploreFilterCriteria()

    // MARK: Private

    private var currentPage = 0
    private var hasMore = true
    private let pageSize = 12
    private let service: any ArtworkServiceProtocol

    // MARK: Init (inject a real API client later — views never change)

    // Safe off the main actor: it only stores the service reference, so
    // `@State private var viewModel = ExploreViewModel()` can initialize
    // during a View's synchronous, nonisolated struct init.
    nonisolated init(service: any ArtworkServiceProtocol = MockArtworkService()) {
        self.service = service
    }

    // MARK: Derived

    /// Single source of truth for what the feed shows. Used as `.task(id:)`
    /// so any change (search, category, filters) reloads with cancellation.
    var query: ArtworkQuery {
        ArtworkQuery(searchText: searchText, browseCategory: selectedBrowseCategory, filters: filters)
    }

    var searchSummary: String {
        let what = searchText.isEmpty ? "Anything" : "“\(searchText)”"
        let style = selectedBrowseCategory?.rawValue ?? "Any style"
        let price = filters.priceBand == .any ? "Any price" : filters.priceBand.rawValue
        return [what, style, price].joined(separator: " · ")
    }

    // MARK: Loading

    func loadFirstPage() async {
        phase = .loading
        currentPage = 0
        hasMore = true
        do {
            let result = try await service.fetchArtworks(query: query, page: 0, pageSize: pageSize)
            guard !Task.isCancelled else { return }
            artworks = result.items
            hasMore = result.hasMore
            phase = artworks.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            // superseded by a newer query — ignore
        } catch {
            phase = .error("Something went wrong loading artworks. Please try again.")
        }
    }

    /// Infinite scroll: triggers when the 3rd-from-last card appears.
    func loadMoreIfNeeded(current artwork: Artwork) {
        guard phase == .loaded, hasMore, !isLoadingMore, artworks.count >= 3 else { return }
        let thresholdIndex = artworks.count - 3
        guard let index = artworks.firstIndex(of: artwork), index >= thresholdIndex else { return }
        Task { await loadNextPage() }
    }

    private func loadNextPage() async {
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let nextPage = currentPage + 1
            let result = try await service.fetchArtworks(query: query, page: nextPage, pageSize: pageSize)
            guard !Task.isCancelled else { return }
            currentPage = nextPage
            artworks.append(contentsOf: result.items)
            hasMore = result.hasMore
        } catch {
            hasMore = false // stop hammering a failing endpoint; pull-to-refresh recovers
        }
    }

    /// Pull-to-refresh: reloads without flashing the skeleton.
    func refresh() async {
        currentPage = 0
        do {
            let result = try await service.fetchArtworks(query: query, page: 0, pageSize: pageSize)
            guard !Task.isCancelled else { return }
            artworks = result.items
            hasMore = result.hasMore
            phase = artworks.isEmpty ? .empty : .loaded
        } catch is CancellationError {
        } catch {
            phase = .error("Couldn't refresh. Check your connection and try again.")
        }
    }

    // MARK: Search / Filters

    func clearAllFilters() {
        searchText = ""
        selectedBrowseCategory = nil
        filters = ExploreFilterCriteria()
    }

    func recordRecentSearch(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recentSearches.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        recentSearches.insert(trimmed, at: 0)
        if recentSearches.count > 5 { recentSearches.removeLast() }
    }

    /// Live result count for the filter sheet's "Show X artworks" button.
    func previewCount(filters draft: ExploreFilterCriteria) async -> Int {
        await service.count(
            matching: ArtworkQuery(searchText: searchText, browseCategory: selectedBrowseCategory, filters: draft)
        )
    }
}
