import Foundation
import Supabase

@MainActor
final class ProfileService {
    private let client = SupabaseManager.shared.client

    /// Fetch profile for current authenticated user
    func fetchCurrentProfile() async throws -> Profile? {
        guard let userId = client.auth.currentUser?.id.uuidString else { return nil }
        let profiles: [Profile] = try await client
            .from("profile")
            .select()
            .eq("userId", value: userId)
            .limit(1)
            .execute()
            .value
        return profiles.first
    }

    /// Update profile fields
    func updateProfile(id: Int64, firstName: String, lastName: String, publicUserName: String, avatarName: String?) async throws {
        struct ProfileUpdate: Encodable {
            let firstName: String
            let lastName: String
            let publicUserName: String
            let avatarName: String?
        }

        try await client
            .from("profile")
            .update(ProfileUpdate(
                firstName: firstName,
                lastName: lastName,
                publicUserName: publicUserName,
                avatarName: avatarName
            ))
            .eq("id", value: String(id))
            .execute()
    }

    /// Fetch profile by ID
    func fetchProfile(id: Int64) async throws -> Profile {
        try await client
            .from("profile")
            .select()
            .eq("id", value: String(id))
            .single()
            .execute()
            .value
    }

    /// Fetch user's check-in rides with ride and park details
    func fetchCheckIns(profileId: Int64, limit: Int = 20) async throws -> [ProfileRide] {
        try await client
            .from("profileRide")
            .select("*, ride(*, park(*))")
            .eq("profileId", value: String(profileId))
            .order("createdDate", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Compute profile stats
    func fetchStats(profileId: Int64) async throws -> ProfileStats {
        // Get all check-ins with ride data
        let checkIns: [ProfileRide] = try await client
            .from("profileRide")
            .select("*, ride(*, park(*))")
            .eq("profileId", value: String(profileId))
            .execute()
            .value

        let coasterCount = checkIns.count
        let maxGForce = checkIns.compactMap { $0.ride?.gForce }.max() ?? 0
        let parksVisited = Set(checkIns.compactMap { $0.ride?.parkId }).count

        // Compute global rank (count profiles with more rides)
        let allProfiles: [Profile] = try await client
            .from("profile")
            .select()
            .execute()
            .value

        // For each profile, we need their ride count - simplified approach
        var rank = 1
        for profile in allProfiles where profile.id != profileId {
            let count: [ProfileRide] = try await client
                .from("profileRide")
                .select("id")
                .eq("profileId", value: String(profile.id))
                .execute()
                .value
            if count.count > coasterCount { rank += 1 }
        }

        return ProfileStats(
            coasterCount: coasterCount,
            maxGForce: maxGForce,
            parksVisited: parksVisited,
            globalRank: rank
        )
    }

    /// Fetch user's achievements
    func fetchAchievements(profileId: Int64) async throws -> [ProfileAchievement] {
        try await client
            .from("profileAchievement")
            .select("*, achievement(*)")
            .eq("profileId", value: String(profileId))
            .execute()
            .value
    }

    /// Fetch all available achievements
    func fetchAllAchievements() async throws -> [Achievement] {
        try await client
            .from("achievement")
            .select()
            .execute()
            .value
    }

    /// Fetch subscription type
    func fetchSubscription(id: Int64) async throws -> SubscriptionType {
        try await client
            .from("subscriptionType")
            .select()
            .eq("id", value: String(id))
            .single()
            .execute()
            .value
    }

    /// Fetch all subscription types
    func fetchAllSubscriptionTypes() async throws -> [SubscriptionType] {
        try await client
            .from("subscriptionType")
            .select()
            .execute()
            .value
    }

    /// Update a profile's subscription type
    func updateSubscriptionType(profileId: Int64, subscriptionTypeId: Int64) async throws {
        struct SubUpdate: Encodable { let subscriptionTypeId: Int64 }
        try await client
            .from("profile")
            .update(SubUpdate(subscriptionTypeId: subscriptionTypeId))
            .eq("id", value: String(profileId))
            .execute()
    }
}
