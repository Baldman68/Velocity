import Foundation
import CoreLocation
import Supabase

@MainActor
final class RideService {
    private let client = SupabaseManager.shared.client

    /// Fetch rides near a location within a given radius (miles), sorted by distance
    func fetchNearby(latitude: Double, longitude: Double, radiusMiles: Double = 200, limit: Int = 20) async throws -> [(ride: Ride, distanceMiles: Double)] {
        // Fetch all rides that have a park with coordinates
        let allRides: [Ride] = try await client
            .from("ride")
            .select("*, park(*)")
            .not("parkId", operator: .is, value: "null")
            .execute()
            .value

        let userLocation = CLLocation(latitude: latitude, longitude: longitude)

        // Compute distance for each ride and filter
        var nearby: [(ride: Ride, distanceMiles: Double)] = []

        for ride in allRides {
            guard let park = ride.park,
                  let latStr = park.latitude, let lonStr = park.longitude,
                  let parkLat = Double(latStr), let parkLon = Double(lonStr),
                  parkLat != 0, parkLon != 0 else { continue }

            let parkLocation = CLLocation(latitude: parkLat, longitude: parkLon)
            let distanceMeters = userLocation.distance(from: parkLocation)
            let distanceMiles = distanceMeters / 1609.344

            if distanceMiles <= radiusMiles {
                nearby.append((ride: ride, distanceMiles: distanceMiles))
            }
        }

        // Sort by distance, take limit
        nearby.sort { $0.distanceMiles < $1.distanceMiles }
        return Array(nearby.prefix(limit))
    }

    /// Fetch trending rides (fastest/tallest coasters with data)
    func fetchTrending(limit: Int = 10) async throws -> [Ride] {
        try await client
            .from("ride")
            .select("*, park(*)")
            .not("speed", operator: .is, value: "null")
            .order("speed", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Fetch top rated rides worldwide (by star rating, falling back to speed)
    func fetchTopRated(limit: Int = 20) async throws -> [Ride] {
        // First try rides with ratings
        let rated: [Ride] = try await client
            .from("ride")
            .select("*, park(*)")
            .not("numberOfStars", operator: .is, value: "null")
            .order("numberOfStars", ascending: false)
            .limit(limit)
            .execute()
            .value

        if !rated.isEmpty { return rated }

        // Fallback: fastest rides as proxy for "top"
        return try await client
            .from("ride")
            .select("*, park(*)")
            .not("speed", operator: .is, value: "null")
            .order("speed", ascending: false)
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

    /// Fetch nearest park to a given location
    func fetchNearestPark(latitude: Double, longitude: Double) async throws -> (park: Park, distanceMiles: Double)? {
        let allParks: [Park] = try await client
            .from("park")
            .select()
            .execute()
            .value

        let userLocation = CLLocation(latitude: latitude, longitude: longitude)
        var nearest: (park: Park, distanceMiles: Double)?

        for park in allParks {
            guard let latStr = park.latitude, let lonStr = park.longitude,
                  let parkLat = Double(latStr), let parkLon = Double(lonStr),
                  parkLat != 0, parkLon != 0 else { continue }

            let parkLocation = CLLocation(latitude: parkLat, longitude: parkLon)
            let distanceMiles = userLocation.distance(from: parkLocation) / 1609.344

            if nearest == nil || distanceMiles < nearest!.distanceMiles {
                nearest = (park: park, distanceMiles: distanceMiles)
            }
        }

        return nearest
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
