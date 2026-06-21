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

    /// Search rides by name or park name
    func searchRides(query: String, limit: Int = 20) async throws -> [Ride] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)

        // Search rides by ride name
        async let byRideName: [Ride] = client
            .from("ride")
            .select("*, park(*)")
            .ilike("name", pattern: "%\(trimmed)%")
            .limit(limit)
            .execute()
            .value

        // Search parks by name
        async let matchingParks: [Park] = client
            .from("park")
            .select()
            .ilike("name", pattern: "%\(trimmed)%")
            .limit(5)
            .execute()
            .value

        let (rideResults, parkResults) = try await (byRideName, matchingParks)

        var allResults = rideResults

        if !parkResults.isEmpty {
            let parkIds = parkResults.map { String($0.id) }
            let byPark: [Ride] = try await client
                .from("ride")
                .select("*, park(*)")
                .in("parkId", values: parkIds)
                .limit(limit)
                .execute()
                .value
            allResults.append(contentsOf: byPark)
        }

        // Deduplicate by id
        var seen = Set<Int64>()
        return Array(allResults.filter { seen.insert($0.id).inserted }.prefix(limit))
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

    /// Submit a park request (suggest a new park)
    func submitParkRequest(
        profileId: Int64,
        name: String,
        city: String,
        state: String,
        zip: String?,
        country: String?,
        streetAddress: String?,
        phoneNumber: String?,
        website: String?,
        email: String?,
        latitude: String?,
        longitude: String?
    ) async throws {
        struct NewParkRequest: Encodable {
            let profileId: Int64
            let name: String
            let city: String
            let state: String
            let zip: String?
            let country: String?
            let streetAddress: String?
            let phoneNumber: String?
            let website: String?
            let email: String?
            let latitude: String?
            let longitude: String?
        }

        try await client
            .from("parkRequest")
            .insert(NewParkRequest(
                profileId: profileId,
                name: name,
                city: city,
                state: state,
                zip: zip,
                country: country,
                streetAddress: streetAddress,
                phoneNumber: phoneNumber,
                website: website,
                email: email,
                latitude: latitude,
                longitude: longitude
            ))
            .execute()
    }

    /// Submit a ride request (suggest a new coaster at an existing park)
    func submitRideRequest(
        profileId: Int64,
        parkId: Int64,
        name: String,
        description: String?,
        manufacturer: String?,
        gForce: Float?,
        trackLength: Int16?,
        height: Int16?,
        speed: Int16?,
        inversions: Int16?,
        mainImageURL: String?
    ) async throws {
        struct NewRideRequest: Encodable {
            let profileId: Int64
            let parkId: Int64
            let name: String
            let description: String?
            let manufacturer: String?
            let gForce: Float?
            let trackLength: Int16?
            let height: Int16?
            let speed: Int16?
            let inversions: Int16?
            let mainImageURL: String?
        }

        try await client
            .from("rideRequest")
            .insert(NewRideRequest(
                profileId: profileId,
                parkId: parkId,
                name: name,
                description: description,
                manufacturer: manufacturer,
                gForce: gForce,
                trackLength: trackLength,
                height: height,
                speed: speed,
                inversions: inversions,
                mainImageURL: mainImageURL
            ))
            .execute()
    }

    /// Fetch all parks (for park picker)
    func fetchAllParks() async throws -> [Park] {
        try await client
            .from("park")
            .select()
            .order("name")
            .execute()
            .value
    }

    /// Submit a ride update request
    func submitRideUpdateRequest(
        profileId: Int64,
        originalRideId: Int64,
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
    ) async throws {
        struct NewUpdateRequest: Encodable {
            let profileId: Int64
            let originalRideId: Int64
            let name: String?
            let description: String?
            let streetAddress: String?
            let city: String?
            let state: String?
            let zip: String?
            let country: String?
            let phoneNumber: String?
            let website: String?
            let email: String?
            let mainImageURL: String?
        }

        try await client
            .from("rideUpdateRequest")
            .insert(NewUpdateRequest(
                profileId: profileId,
                originalRideId: originalRideId,
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
            ))
            .execute()
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
