import Foundation
import Observation

@Observable
@MainActor
final class ProfileViewModel {
    var profile: Profile?
    var stats: ProfileStats?
    var achievements: [Achievement] = []
    var earnedAchievementIds: Set<Int64> = []
    var recentActivity: [ProfileRide] = []
    var subscriptionName: String?
    var isLoading = false
    var errorMessage: String?

    private let profileService = ProfileService()

    var isPro: Bool {
        guard let name = subscriptionName?.lowercased() else { return false }
        return name.contains("pro") || name.contains("elite")
    }

    var isElite: Bool {
        guard let name = subscriptionName?.lowercased() else { return false }
        return name.contains("elite")
    }

    var tierLabel: String {
        if isElite { return "ELITE" }
        if isPro { return "PRO" }
        return "FREE"
    }

    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            profile = try await profileService.fetchCurrentProfile()

            if let profileId = profile?.id {
                async let statsTask = profileService.fetchStats(profileId: profileId)
                async let achievementsTask = profileService.fetchAllAchievements()
                async let earnedTask = profileService.fetchAchievements(profileId: profileId)
                async let activityTask = profileService.fetchCheckIns(profileId: profileId, limit: 10)

                stats = try await statsTask
                achievements = try await achievementsTask
                let earned = try await earnedTask
                earnedAchievementIds = Set(earned.compactMap { $0.achievementId })
                recentActivity = try await activityTask

                if let subId = profile?.subscriptionTypeId {
                    let sub = try await profileService.fetchSubscription(id: subId)
                    subscriptionName = sub.subscriptionName
                } else {
                    subscriptionName = nil
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
