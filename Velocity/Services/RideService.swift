import Foundation
import Supabase

@MainActor
final class RideService {
    private let client = SupabaseManager.shared.client

    /// Fetch trending rides (highest rated with reviews)
    func fetchTrending(limit: Int = 10) async throws -> [Ride] {
        try await client
            .from("ride")
            .select("*, park(*)")
            .not("numberOfStars", operator: .is, value: "null")
            .not("numberOfReviews", operator: .is, value: "null")
            .order("numberOfStars", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Fetch top rated rides worldwide
    func fetchTopRated(limit: Int = 20) async throws -> [Ride] {
        try await client
            .from("ride")
            .select("*, park(*)")
            .not("numberOfStars", operator: .is, value: "null")
            .order("numberOfStars", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Search rides by name
    func searchRides(query: String, limit: Int = 20) async throws -> [Ride] {
        try await client
            .from("ride")
            .select("*, park(*)")
            .ilike("name", pattern: "%\(query)%")
            .limit(limit)
            .execute()
            .value
    }

    /// Fetch a single ride with full details
    func fetchRide(id: Int64) async throws -> Ride {
        try await client
            .from("ride")
            .select("*, park(*)")
            .eq("id", value: String(id))
            .single()
            .execute()
            .value
    }

    /// Fetch rides for a specific park
    func fetchRidesForPark(parkId: Int64) async throws -> [Ride] {
        try await client
            .from("ride")
            .select("*, park(*)")
            .eq("parkId", value: String(parkId))
            .order("name")
            .execute()
            .value
    }

    /// Fetch reviews for a ride
    func fetchReviews(rideId: Int64) async throws -> [ProfileRideReview] {
        try await client
            .from("profileRideReview")
            .select("*, profile(*)")
            .eq("rideId", value: String(rideId))
            .order("createdDate", ascending: false)
            .execute()
            .value
    }

    /// Fetch notes for a ride by current user
    func fetchNote(rideId: Int64, profileId: Int64) async throws -> ProfileRideNote? {
        let notes: [ProfileRideNote] = try await client
            .from("profileRideNote")
            .select()
            .eq("rideId", value: String(rideId))
            .eq("profileId", value: String(profileId))
            .limit(1)
            .execute()
            .value
        return notes.first
    }
}
