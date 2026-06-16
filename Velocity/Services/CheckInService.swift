import Foundation
import Supabase

/// Error thrown when a free user exceeds their monthly check-in limit
struct CheckInLimitError: LocalizedError {
    let used: Int
    let limit: Int
    var errorDescription: String? {
        "You've used \(used)/\(limit) free check-ins this month. Upgrade to PRO for unlimited check-ins."
    }
}

@MainActor
final class CheckInService {
    private let client = SupabaseManager.shared.client
    static let freeMonthlyLimit = 5

    /// Count check-ins for a profile in the current calendar month
    func fetchCheckInsThisMonth(profileId: Int64) async throws -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        struct CountRow: Decodable { let id: Int64 }
        let rows: [CountRow] = try await client
            .from("profileRide")
            .select("id")
            .eq("profileId", value: String(profileId))
            .gte("createdDate", value: startOfMonth)
            .execute()
            .value
        return rows.count
    }

    /// Create a new check-in (enforces free tier limit)
    func checkIn(profileId: Int64, rideId: Int64, comments: String? = nil, score: Int16? = nil, waitTime: Int16? = nil, seatRow: String? = nil, isPaidUser: Bool = false) async throws -> ProfileRide {
        // Enforce free tier limit
        if !isPaidUser {
            let count = try await fetchCheckInsThisMonth(profileId: profileId)
            if count >= Self.freeMonthlyLimit {
                throw CheckInLimitError(used: count, limit: Self.freeMonthlyLimit)
            }
        }
        struct NewCheckIn: Encodable {
            let profileId: Int64
            let rideId: Int64
            let comments: String?
            let score: Int16?
            let waitTime: Int16?
            let seatRow: String?
        }

        return try await client
            .from("profileRide")
            .insert(NewCheckIn(profileId: profileId, rideId: rideId, comments: comments, score: score, waitTime: waitTime, seatRow: seatRow))
            .select("*, ride(*, park(*))")
            .single()
            .execute()
            .value
    }

    /// Average wait reports for the provided rides during the last hour.
    func fetchAverageWaitTimeForRecentCheckIns(rideIds: [Int64], withinLast seconds: TimeInterval = 3600) async throws -> Int? {
        guard !rideIds.isEmpty else { return nil }

        struct WaitTimeRow: Decodable {
            let waitTime: Int16?
        }

        let since = Date().addingTimeInterval(-seconds)
        let rows: [WaitTimeRow] = try await client
            .from("profileRide")
            .select("waitTime")
            .in("rideId", values: rideIds.map { String($0) as any PostgrestFilterValue })
            .gte("createdDate", value: since)
            .not("waitTime", operator: .is, value: "null")
            .execute()
            .value

        let waitTimes = rows.compactMap { $0.waitTime }.map(Int.init)
        guard !waitTimes.isEmpty else { return nil }

        let average = Double(waitTimes.reduce(0, +)) / Double(waitTimes.count)
        return Int(average.rounded())
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
