import Foundation
import Observation

@Observable
@MainActor
final class DiscoverViewModel {
    var trendingRides: [Ride] = []
    var topRatedRides: [Ride] = []
    var searchResults: [Ride] = []
    var searchText: String = ""
    var isLoading = false
    var isSearching = false
    var errorMessage: String?

    private let rideService = RideService()

    func loadInitialData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let trending = rideService.fetchTrending(limit: 10)
            async let topRated = rideService.fetchTopRated(limit: 20)
            trendingRides = try await trending
            topRatedRides = try await topRated
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func search() async {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        do {
            searchResults = try await rideService.searchRides(query: searchText)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSearching = false
    }
}
