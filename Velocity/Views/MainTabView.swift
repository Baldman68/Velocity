import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .discover

    enum Tab: String {
        case discover, leaderboard, profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "safari")
                }
                .tag(Tab.discover)

            LeaderboardView()
                .tabItem {
                    Label("Ranks", systemImage: "trophy")
                }
                .tag(Tab.leaderboard)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(Tab.profile)
        }
        .tint(Color.nitroBlue)
        .onAppear {
            // Configure tab bar appearance for dark theme
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.velocitySurfaceContainerLowest)

            // Unselected items
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.velocityOutline)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(Color.velocityOutline)
            ]

            // Selected items
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.nitroBlue)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Color.nitroBlue)
            ]

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
