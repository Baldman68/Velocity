import Foundation
import CoreLocation
import Observation

/// Holds a ride + its distance from the user for the Nearby section
struct NearbyRide: Identifiable, Sendable {
    var id: Int64 { ride.id }
    let ride: Ride
    let distanceMiles: Double

    var distanceLabel: String {
        if distanceMiles < 1 {
            return "< 1 MI"
        }
        return "\(Int(distanceMiles)) MI"
    }
}

@Observable
@MainActor
final class DiscoverViewModel: NSObject, CLLocationManagerDelegate {
    var trendingRides: [Ride] = []
    var topRatedRides: [Ride] = []
    var nearbyRides: [NearbyRide] = []
    var searchResults: [Ride] = []
    var searchText: String = ""
    var isLoading = false
    var isLoadingNearby = false
    var isSearching = false
    var errorMessage: String?

    private var searchTask: Task<Void, Never>?
    var nearestPark: Park?
    var nearestParkDistance: Double?
    var isLocationAuthorized = false

    private let rideService = RideService()
    private let locationManager = CLLocationManager()
    private var hasRequestedNearby = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
    }

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

        // Kick off nearby rides if we have location permission
        requestNearbyIfAuthorized()
    }

    func onSearchTextChanged() {
        searchTask?.cancel()

        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await search()
        }
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

    // MARK: - Nearby

    private func requestNearbyIfAuthorized() {
        let status = locationManager.authorizationStatus
        isLocationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)

        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if isLocationAuthorized {
            locationManager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            await fetchNearby(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location failed — just skip nearby silently
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let authorized = manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
        Task { @MainActor in
            isLocationAuthorized = authorized
        }
        if authorized {
            manager.requestLocation()
        }
    }

    private func fetchNearby(latitude: Double, longitude: Double) async {
        guard !hasRequestedNearby else { return }
        hasRequestedNearby = true
        isLoadingNearby = true
        do {
            async let nearbyResult = rideService.fetchNearby(
                latitude: latitude,
                longitude: longitude,
                radiusMiles: 200,
                limit: 20
            )
            async let parkResult = rideService.fetchNearestPark(
                latitude: latitude,
                longitude: longitude
            )

            let results = try await nearbyResult
            nearbyRides = results.map { NearbyRide(ride: $0.ride, distanceMiles: $0.distanceMiles) }

            if let nearest = try await parkResult, nearest.distanceMiles <= 3.0 {
                nearestPark = nearest.park
                nearestParkDistance = nearest.distanceMiles
            } else {
                nearestPark = nil
                nearestParkDistance = nil
            }
        } catch {
            // Nearby is best-effort, don't show error
            debugPrint(error)
        }
        isLoadingNearby = false
    }
}
