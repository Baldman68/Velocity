import Foundation
import Supabase

@MainActor
final class AchievementService {
    private let client = SupabaseManager.shared.client

    struct AwardedAchievement: Sendable {
        let achievement: Achievement
    }

    /// Evaluate all achievement criteria for a profile and award any newly qualified ones.
    /// Returns the list of newly awarded achievements (for showing congratulatory UI).
    func evaluateAndAward(profileId: Int64, isElite: Bool = false) async -> [AwardedAchievement] {
        do {
            // Fetch all achievements and already-earned ones
            let allAchievements: [Achievement] = try await client
                .from("achievement")
                .select()
                .execute()
                .value

            let earned: [ProfileAchievement] = try await client
                .from("profileAchievement")
                .select("*, achievement(*)")
                .eq("profileId", value: String(profileId))
                .execute()
                .value

            let earnedIds = Set(earned.map(\.achievementId))

            // Fetch user's check-in data for evaluation
            let checkIns: [ProfileRide] = try await client
                .from("profileRide")
                .select("*, ride(*, park(*))")
                .eq("profileId", value: String(profileId))
                .execute()
                .value

            var newlyAwarded: [AwardedAchievement] = []

            for achievement in allAchievements {
                // Skip if already earned
                guard !earnedIds.contains(achievement.id) else { continue }

                // Skip elite-exclusive achievements for non-elite users
                if achievement.criteriaType.hasPrefix("elite_") && !isElite { continue }

                let qualified = evaluate(
                    achievement: achievement,
                    checkIns: checkIns,
                    profileId: profileId
                )

                if qualified {
                    // Award the achievement
                    struct NewAward: Encodable {
                        let profileId: Int64
                        let achievementId: Int64
                        let earnedDate: Date
                    }

                    try await client
                        .from("profileAchievement")
                        .insert(NewAward(
                            profileId: profileId,
                            achievementId: achievement.id,
                            earnedDate: Date()
                        ))
                        .execute()

                    newlyAwarded.append(AwardedAchievement(achievement: achievement))
                }
            }

            return newlyAwarded
        } catch {
            debugPrint("AchievementService evaluation error: \(error)")
            return []
        }
    }

    // MARK: - Criteria Evaluation

    private func evaluate(achievement: Achievement, checkIns: [ProfileRide], profileId: Int64) -> Bool {
        let criteriaValue = achievement.criteriaValue

        switch achievement.criteriaType {

        // --- Standard achievements ---

        case "ride_count":
            return checkIns.count >= criteriaValue

        case "park_count":
            let parks = Set(checkIns.compactMap { $0.ride?.parkId })
            return parks.count >= criteriaValue

        case "g_force":
            let maxG = checkIns.compactMap { $0.ride?.gForce }.max() ?? 0
            return maxG >= Float(criteriaValue)

        case "max_height":
            let maxHeight = checkIns.compactMap { $0.ride?.height }.max() ?? 0
            return Int(maxHeight) >= criteriaValue

        case "max_speed":
            let maxSpeed = checkIns.compactMap { $0.ride?.speed }.max() ?? 0
            return Int(maxSpeed) >= criteriaValue

        case "country_count":
            let countries = Set(checkIns.compactMap { $0.ride?.park?.country }.filter { !$0.isEmpty })
            return countries.count >= criteriaValue

        case "inversion_rides":
            let inversionRides = checkIns.filter { ($0.ride?.inversions ?? 0) > 0 }
            return inversionRides.count >= criteriaValue

        case "night_ride":
            // Check if any check-in was after 8 PM
            let calendar = Calendar.current
            return checkIns.contains { ci in
                guard let date = ci.createdDate else { return false }
                let hour = calendar.component(.hour, from: date)
                return hour >= 20 || hour < 5
            }

        // --- ELITE-exclusive achievements ---

        case "elite_inversions_day":
            // 10 coasters with inversions in a single day
            return hasDayWithCount(checkIns: checkIns, minCount: criteriaValue) { ci in
                (ci.ride?.inversions ?? 0) > 0
            }

        case "elite_speed_day":
            // 5 coasters over 70 MPH in a single day
            return hasDayWithCount(checkIns: checkIns, minCount: criteriaValue) { ci in
                (ci.ride?.speed ?? 0) >= 70
            }

        case "elite_rides_day":
            // 20 rides in a single day
            return hasDayWithCount(checkIns: checkIns, minCount: criteriaValue) { _ in true }

        case "elite_country_count":
            let countries = Set(checkIns.compactMap { $0.ride?.park?.country }.filter { !$0.isEmpty })
            return countries.count >= criteriaValue

        case "elite_ride_count":
            return checkIns.count >= criteriaValue

        default:
            return false
        }
    }

    /// Helper: check if there's any single calendar day where at least `minCount` check-ins pass the filter.
    private func hasDayWithCount(checkIns: [ProfileRide], minCount: Int, filter: (ProfileRide) -> Bool) -> Bool {
        let calendar = Calendar.current
        var dayGroups: [DateComponents: Int] = [:]

        for ci in checkIns where filter(ci) {
            guard let date = ci.createdDate else { continue }
            let dayKey = calendar.dateComponents([.year, .month, .day], from: date)
            dayGroups[dayKey, default: 0] += 1
        }

        return dayGroups.values.contains { $0 >= minCount }
    }
}
