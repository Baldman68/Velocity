import Foundation
import Supabase

@MainActor
final class CheckInService {
    private let client = SupabaseManager.shared.client

    /// Create a new check-in
    func checkIn(profileId: Int64, rideId: Int64, comments: String? = nil, score: Int16? = nil, waitTime: Int16? = nil) async throws -> ProfileRide {
        struct NewCheckIn: Encodable {
            let profileId: Int64
            let rideId: Int64
            let comments: String?
            let score: Int16?
            let waitTime: Int16?
        }

        return try await client
            .from("profileRide")
            .insert(NewCheckIn(profileId: profileId, rideId: rideId, comments: comments, score: score, waitTime: waitTime))
            .select("*, ride(*, park(*))")
            .single()
            .execute()
            .value
    }

    /// Save or update a personal note on a ride
    func saveNote(profileId: Int64, rideId: Int64, note: String) async throws {
        struct NotePayload: Encodable {
            let profileId: Int64
            let rideId: Int64
            let note: String
            let updatedDate: Date
        }

        // Upsert based on profileId + rideId
        try await client
            .from("profileRideNote")
            .upsert(NotePayload(profileId: profileId, rideId: rideId, note: note, updatedDate: Date()))
            .execute()
    }

    /// Submit a review
    func submitReview(profileId: Int64, rideId: Int64, text: String, stars: Int16) async throws -> ProfileRideReview {
        struct NewReview: Encodable {
            let profileId: Int64
            let rideId: Int64
            let reviewText: String
            let stars: Int16
        }

        return try await client
            .from("profileRideReview")
            .insert(NewReview(profileId: profileId, rideId: rideId, reviewText: text, stars: stars))
            .select("*, profile(*)")
            .single()
            .execute()
            .value
    }

    /// Vote on a review
    func voteOnReview(profileId: Int64, reviewId: Int64, approve: Bool) async throws {
        struct Vote: Encodable {
            let profileId: Int64
            let profileRideReviewId: Int64
            let approve: Bool
        }

        try await client
            .from("profileRideReviewRating")
            .insert(Vote(profileId: profileId, profileRideReviewId: reviewId, approve: approve))
            .execute()
    }
}
