import Foundation
import Supabase

@MainActor
final class LeaderboardService {
    private let client = SupabaseManager.shared.client

    /// Fetch global leaderboard
    func fetchGlobalLeaderboard(limit: Int = 50) async throws -> [LeaderboardEntry] {
        // Fetch all profiles
        let profiles: [Profile] = try await client
            .from("profile")
            .select()
            .execute()
            .value

        // For each profile, count their rides
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

            let count: [ProfileRide] = try await client
                .from("profileRide")
                .select("id")
                .eq("profileId", value: String(profile.id))
                .execute()
                .value

            entries.append((profile, count.count, rides.first))
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

    /// Fetch friends leaderboard for a given profile
    func fetchFriendsLeaderboard(profileId: Int64) async throws -> [LeaderboardEntry] {
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

            let count: [ProfileRide] = try await client
                .from("profileRide")
                .select("id")
                .eq("profileId", value: String(friendId))
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
}
