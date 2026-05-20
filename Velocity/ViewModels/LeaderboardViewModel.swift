import Foundation
import Observation

@Observable
@MainActor
final class LeaderboardViewModel {
    var entries: [LeaderboardEntry] = []
    var selectedTab: LeaderboardTab = .global
    var isLoading = false
    var errorMessage: String?

    enum LeaderboardTab: String, CaseIterable {
        case global = "Global"
        case friends = "Friends"
    }

    private let service = LeaderboardService()

    var topThree: [LeaderboardEntry] {
        Array(entries.prefix(3))
    }

    var chasePack: [LeaderboardEntry] {
        Array(entries.dropFirst(3))
    }

    func loadLeaderboard(profileId: Int64? = nil) async {
        isLoading = true
        errorMessage = nil
        do {
            switch selectedTab {
            case .global:
                entries = try await service.fetchGlobalLeaderboard()
            case .friends:
                if let profileId {
                    entries = try await service.fetchFriendsLeaderboard(profileId: profileId)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
