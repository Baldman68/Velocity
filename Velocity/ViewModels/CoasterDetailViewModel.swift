import Foundation
import CoreLocation
import Observation

enum CheckInLocationStatus: Equatable {
    case waitingForRide
    case checking
    case allowed
    case notNearPark(distanceMiles: Double)
    case locationPermissionNeeded
    case locationUnavailable
    case parkLocationUnavailable

    var canCheckIn: Bool {
        self == .allowed
    }
}

@Observable
@MainActor
final class CoasterDetailViewModel: NSObject, CLLocationManagerDelegate {
    var ride: Ride?
    var reviews: [ProfileRideReview] = []
    var userNote: ProfileRideNote?
    var isLoading = false
    var showCheckInSheet = false
    var showReviewSheet = false
    var showEditSheet = false
    var editSubmitted = false
    var errorMessage: String?
    var checkInLocationStatus: CheckInLocationStatus = .waitingForRide

    private let rideService = RideService()
    private let checkInService = CheckInService()
    private let locationManager = CLLocationManager()
    private let checkInRadiusMiles = 3.0

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func loadRide(id: Int64) async {
        isLoading = true
        do {
            ride = try await rideService.fetchRide(id: id)
            reviews = try await rideService.fetchReviews(rideId: id)
            refreshCheckInLocation()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func requestLocationPermission() {
        guard CLLocationManager.locationServicesEnabled() else {
            checkInLocationStatus = .locationUnavailable
            return
        }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            refreshCheckInLocation()
        case .denied, .restricted:
            checkInLocationStatus = .locationPermissionNeeded
        @unknown default:
            checkInLocationStatus = .locationPermissionNeeded
        }
    }

    func refreshCheckInLocation() {
        guard parkLocation != nil else {
            checkInLocationStatus = ride == nil ? .waitingForRide : .parkLocationUnavailable
            return
        }

        guard CLLocationManager.locationServicesEnabled() else {
            checkInLocationStatus = .locationUnavailable
            return
        }

        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            checkInLocationStatus = .checking
            locationManager.requestLocation()
        case .notDetermined, .denied, .restricted:
            checkInLocationStatus = .locationPermissionNeeded
        @unknown default:
            checkInLocationStatus = .locationPermissionNeeded
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            updateCheckInStatus(for: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            checkInLocationStatus = .locationUnavailable
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined else { return }

        Task { @MainActor in
            refreshCheckInLocation()
        }
    }

    func loadUserNote(rideId: Int64, profileId: Int64) async {
        do {
            userNote = try await rideService.fetchNote(rideId: rideId, profileId: profileId)
        } catch {
            // Note may not exist, that's fine
        }
    }

    var showCheckInLimitAlert = false

    func checkIn(profileId: Int64, rideId: Int64, comments: String?, score: Int16?, seatRow: String? = nil, isPaidUser: Bool = false) async {
        do {
            _ = try await checkInService.checkIn(
                profileId: profileId,
                rideId: rideId,
                comments: comments,
                score: score,
                seatRow: seatRow,
                isPaidUser: isPaidUser
            )
            showCheckInSheet = false
        } catch is CheckInLimitError {
            showCheckInLimitAlert = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Check in and return the new profileRide ID (for photo upload)
    func checkInAndReturnId(profileId: Int64, rideId: Int64, comments: String?, score: Int16?, seatRow: String? = nil, isPaidUser: Bool = false) async -> Int64? {
        do {
            let result = try await checkInService.checkIn(
                profileId: profileId,
                rideId: rideId,
                comments: comments,
                score: score,
                seatRow: seatRow,
                isPaidUser: isPaidUser
            )
            showCheckInSheet = false
            return result.id
        } catch is CheckInLimitError {
            showCheckInLimitAlert = true
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func submitReview(profileId: Int64, rideId: Int64, text: String, stars: Int16) async {
        do {
            let review = try await checkInService.submitReview(
                profileId: profileId,
                rideId: rideId,
                text: text,
                stars: stars
            )
            reviews.insert(review, at: 0)
            showReviewSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func voteOnReview(profileId: Int64, reviewId: Int64, approve: Bool) async {
        do {
            try await checkInService.voteOnReview(profileId: profileId, reviewId: reviewId, approve: approve)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submitEditRequest(
        profileId: Int64,
        name: String?,
        description: String?,
        streetAddress: String?,
        city: String?,
        state: String?,
        zip: String?,
        country: String?,
        phoneNumber: String?,
        website: String?,
        email: String?,
        mainImageURL: String?
    ) async {
        guard let ride else { return }
        do {
            try await rideService.submitRideUpdateRequest(
                profileId: profileId,
                originalRideId: ride.id,
                name: name,
                description: description,
                streetAddress: streetAddress,
                city: city,
                state: state,
                zip: zip,
                country: country,
                phoneNumber: phoneNumber,
                website: website,
                email: email,
                mainImageURL: mainImageURL
            )
            editSubmitted = true
            showEditSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var parkLocation: CLLocation? {
        guard let park = ride?.park,
              let latitude = park.latitude.flatMap(Double.init),
              let longitude = park.longitude.flatMap(Double.init),
              latitude != 0,
              longitude != 0 else {
            return nil
        }

        return CLLocation(latitude: latitude, longitude: longitude)
    }

    private func updateCheckInStatus(for userLocation: CLLocation) {
        guard let parkLocation else {
            checkInLocationStatus = .parkLocationUnavailable
            return
        }

        let distanceMiles = userLocation.distance(from: parkLocation) / 1609.344
        checkInLocationStatus = distanceMiles <= checkInRadiusMiles
            ? .allowed
            : .notNearPark(distanceMiles: distanceMiles)
    }
}
