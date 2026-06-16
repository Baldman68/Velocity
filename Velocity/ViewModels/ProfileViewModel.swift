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

    // Map data
    var visitedParkPins: [MapParkPin] = []
    var bucketListPins: [MapParkPin] = []
    var bucketListParkIds: Set<Int64> = []
    var showMapVisited = true // toggle between visited / bucket list

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

    func toggleBucketList(parkId: Int64) async {
        guard let profileId = profile?.id else { return }
        do {
            if bucketListParkIds.contains(parkId) {
                try await profileService.removeFromBucketList(profileId: profileId, parkId: parkId)
                bucketListParkIds.remove(parkId)
            } else {
                try await profileService.addToBucketList(profileId: profileId, parkId: parkId)
                bucketListParkIds.insert(parkId)
            }
            await loadMapData(profileId: profileId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadMapData(profileId: Int64) async {
        do {
            // Visited parks from check-ins
            let allCheckIns = try await profileService.fetchAllCheckIns(profileId: profileId)
            var parkRideCounts: [Int64: (park: Park, count: Int)] = [:]
            for checkIn in allCheckIns {
                guard let park = checkIn.ride?.park, let parkId = checkIn.ride?.parkId else { continue }
                if let existing = parkRideCounts[parkId] {
                    parkRideCounts[parkId] = (park: existing.park, count: existing.count + 1)
                } else {
                    parkRideCounts[parkId] = (park: park, count: 1)
                }
            }

            visitedParkPins = parkRideCounts.compactMap { (parkId, data) in
                guard let lat = data.park.latitude.flatMap(Double.init),
                      let lon = data.park.longitude.flatMap(Double.init),
                      lat != 0, lon != 0 else { return nil }
                return MapParkPin(id: parkId, park: data.park, rideCount: data.count,
                                  latitude: lat, longitude: lon, isBucketList: false)
            }

            // Bucket list
            let bucketEntries = try await profileService.fetchBucketList(profileId: profileId)
            bucketListParkIds = Set(bucketEntries.map { $0.parkId })

            let bucketParkIds = bucketEntries.map { $0.parkId }.filter { !parkRideCounts.keys.contains($0) }
            if !bucketParkIds.isEmpty {
                let parks = try await profileService.fetchParks(ids: bucketParkIds)
                bucketListPins = parks.compactMap { park in
                    guard let lat = park.latitude.flatMap(Double.init),
                          let lon = park.longitude.flatMap(Double.init),
                          lat != 0, lon != 0 else { return nil }
                    return MapParkPin(id: park.id, park: park, rideCount: 0,
                                      latitude: lat, longitude: lon, isBucketList: true)
                }
            } else {
                bucketListPins = []
            }
        } catch {
            // Map data is non-critical
        }
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

                // Load map data
                await loadMapData(profileId: profileId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
