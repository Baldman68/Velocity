import Foundation
import Supabase

// MARK: - Leaderboard Time Range
enum LeaderboardTimeRange: String, CaseIterable {
    case allTime = "All Time"
    case monthly = "Monthly"
    case weekly = "Weekly"

    /// Returns the start date for filtering, or nil for all-time
    var startDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .allTime: return nil
        case .monthly: return calendar.date(byAdding: .month, value: -1, to: now)
        case .weekly: return calendar.date(byAdding: .weekOfYear, value: -1, to: now)
        }
    }
}

@MainActor
final class LeaderboardService {
    private let client = SupabaseManager.shared.client

    /// Fetch global leaderboard with optional time range filter
    func fetchGlobalLeaderboard(limit: Int = 50, timeRange: LeaderboardTimeRange = .allTime) async throws -> [LeaderboardEntry] {
        // Fetch all profiles
        let profiles: [Profile] = try await client
            .from("profile")
            .select()
            .execute()
            .value

        // For each profile, count their rides (optionally filtered by date)
        var entries: [(Profile, Int, ProfileRide?)] = []
        for profile in profiles {
            let rides: [ProfileRide] = try await client
                .from("profileRide")
                .select("*, ride(*, park(*))")
                .eq("profileId", value: String(profile.id))
                .order("createdDate", ascending: false)
                .limit(1)
                .execute()
                .value

            var countQuery = client
                .from("profileRide")
                .select("id")
                .eq("profileId", value: String(profile.id))

            if let startDate = timeRange.startDate {
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                countQuery = countQuery.gte("createdDate", value: iso.string(from: startDate))
            }

            let count: [ProfileRide] = try await countQuery
                .execute()
                .value

            // Skip profiles with zero rides in the time range
            if count.count > 0 {
                entries.append((profile, count.count, rides.first))
            }
        }

        // Sort by ride count descending
        entries.sort { $0.1 > $1.1 }

        return entries.prefix(limit).enumerated().map { index, entry in
            LeaderboardEntry(
                id: entry.0.id,
                profile: entry.0,
                rideCount: entry.1,
                rank: index + 1,
                lastCheckIn: entry.2
            )
        }
    }

    /// Fetch friends leaderboard for a given profile with optional time range filter
    func fetchFriendsLeaderboard(profileId: Int64, timeRange: LeaderboardTimeRange = .allTime) async throws -> [LeaderboardEntry] {
        // Get the user's friends list
        let profile: Profile = try await client
            .from("profile")
            .select()
            .eq("id", value: String(profileId))
            .single()
            .execute()
            .value

        let friendIds = (profile.friends ?? []) + [profileId]

        // Fetch each friend's data
        var entries: [(Profile, Int, ProfileRide?)] = []
        for friendId in friendIds {
            let friendProfile: Profile = try await client
                .from("profile")
                .select()
                .eq("id", value: String(friendId))
                .single()
                .execute()
                .value

            let rides: [ProfileRide] = try await client
                .from("profileRide")
                .select("*, ride(*, park(*))")
                .eq("profileId", value: String(friendId))
                .order("createdDate", ascending: false)
                .limit(1)
                .execute()
                .value

            var countQuery = client
                .from("profileRide")
                .select("id")
                .eq("profileId", value: String(friendId))

            if let startDate = timeRange.startDate {
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                countQuery = countQuery.gte("createdDate", value: iso.string(from: startDate))
            }

            let count: [ProfileRide] = try await countQuery
                .execute()
                .value

            entries.append((friendProfile, count.count, rides.first))
        }

        entries.sort { $0.1 > $1.1 }

        return entries.enumerated().map { index, entry in
            LeaderboardEntry(
                id: entry.0.id,
                profile: entry.0,
                rideCount: entry.1,
                rank: index + 1,
                lastCheckIn: entry.2
            )
        }
    }
    /// Search profiles by public username
    func searchUsers(query: String) async throws -> [Profile] {
        try await client
            .from("profile")
            .select()
            .ilike("publicUserName", pattern: "%\(query)%")
            .limit(20)
            .execute()
            .value
    }

    /// Add a friend to the user's friends list
    func addFriend(profileId: Int64, friendId: Int64) async throws {
        // Fetch current friends list
        let profile: Profile = try await client
            .from("profile")
            .select()
            .eq("id", value: String(profileId))
            .single()
            .execute()
            .value

        var friends = profile.friends ?? []
        guard !friends.contains(friendId) else { return }
        friends.append(friendId)

        struct FriendsUpdate: Encodable { let friends: [Int64] }
        try await client
            .from("profile")
            .update(FriendsUpdate(friends: friends))
            .eq("id", value: String(profileId))
            .execute()
    }

    /// Remove a friend from the user's friends list
    func removeFriend(profileId: Int64, friendId: Int64) async throws {
        let profile: Profile = try await client
            .from("profile")
            .select()
            .eq("id", value: String(profileId))
            .single()
            .execute()
            .value

        var friends = profile.friends ?? []
        friends.removeAll { $0 == friendId }

        struct FriendsUpdate: Encodable { let friends: [Int64] }
        try await client
            .from("profile")
            .update(FriendsUpdate(friends: friends))
            .eq("id", value: String(profileId))
            .execute()
    }
}
