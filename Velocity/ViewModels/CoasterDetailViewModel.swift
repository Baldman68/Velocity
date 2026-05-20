import Foundation
import Observation

@Observable
@MainActor
final class CoasterDetailViewModel {
    var ride: Ride?
    var reviews: [ProfileRideReview] = []
    var userNote: ProfileRideNote?
    var isLoading = false
    var showCheckInSheet = false
    var showReviewSheet = false
    var errorMessage: String?

    private let rideService = RideService()
    private let checkInService = CheckInService()

    func loadRide(id: Int64) async {
        isLoading = true
        do {
            ride = try await rideService.fetchRide(id: id)
            reviews = try await rideService.fetchReviews(rideId: id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadUserNote(rideId: Int64, profileId: Int64) async {
        do {
            userNote = try await rideService.fetchNote(rideId: rideId, profileId: profileId)
        } catch {
            // Note may not exist, that's fine
        }
    }

    func checkIn(profileId: Int64, rideId: Int64, comments: String?, score: Int16?) async {
        do {
            _ = try await checkInService.checkIn(
                profileId: profileId,
                rideId: rideId,
                comments: comments,
                score: score
            )
            showCheckInSheet = false
        } catch {
            errorMessage = error.localizedDescription
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
}
