import Foundation
import Observation

@Observable
@MainActor
final class LeaderboardViewModel {
    var entries: [LeaderboardEntry] = []
    var selectedTab: LeaderboardTab = .global
    var isLoading = false
    var errorMessage: String?
    var friendSearchText = ""
    var searchResults: [Profile] = []
    var isSearching = false
    var currentProfileId: Int64 = 1 // placeholder until auth
    var currentFriendIds: [Int64] = []
    var showAddFriendSheet = false
    var showFriendLimitAlert = false
    private var subscriptionServiceForGate = SubscriptionService()

    enum LeaderboardTab: String, CaseIterable {
        case global = "Global"
        case friends = "Friends"
    }

    private let service = LeaderboardService()
    private let profileService = ProfileService()

    var topThree: [LeaderboardEntry] {
        Array(entries.prefix(3))
    }

    var chasePack: [LeaderboardEntry] {
        Array(entries.dropFirst(3))
    }

    func loadLeaderboard() async {
        isLoading = true
        errorMessage = nil
        await subscriptionServiceForGate.refreshCurrentTier()
        do {
            // Load current profile's friends list
            if let profile = try await profileService.fetchCurrentProfile() {
                currentProfileId = profile.id
                currentFriendIds = profile.friends ?? []
            }

            switch selectedTab {
            case .global:
                entries = try await service.fetchGlobalLeaderboard()
            case .friends:
                entries = try await service.fetchFriendsLeaderboard(profileId: currentProfileId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func searchUsers() async {
        let query = friendSearchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        do {
            searchResults = try await service.searchUsers(query: query)
            // Filter out self
            searchResults.removeAll { $0.id == currentProfileId }
        } catch {
            searchResults = []
        }
        isSearching = false
    }

    func addFriend(friendId: Int64) async {
        // Enforce free tier friend limit
        if !subscriptionServiceForGate.currentTier.isPaid && currentFriendIds.count >= 10 {
            showFriendLimitAlert = true
            return
        }

        do {
            try await service.addFriend(profileId: currentProfileId, friendId: friendId)
            currentFriendIds.append(friendId)
            if selectedTab == .friends {
                await loadLeaderboard()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeFriend(friendId: Int64) async {
        do {
            try await service.removeFriend(profileId: currentProfileId, friendId: friendId)
            currentFriendIds.removeAll { $0 == friendId }
            if selectedTab == .friends {
                await loadLeaderboard()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isFriend(_ profileId: Int64) -> Bool {
        currentFriendIds.contains(profileId)
    }
}
