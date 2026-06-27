import SwiftUI

struct LeaderboardView: View {
    @State private var viewModel = LeaderboardViewModel()
    @State private var friendToRemove: LeaderboardEntry?
    @State private var showRemoveConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VelocitySpacing.lg) {
                    // Tab Toggle
                    segmentToggle

                    // Time Range Toggle
                    timeRangeToggle

                    // Top 3 Podium
                    if viewModel.topThree.count >= 3 {
                        podiumSection
                    } else if viewModel.isLoading {
                        ProgressView()
                            .tint(Color.nitroBlue)
                            .padding(.top, 40)
                    }

                    // Chase Pack
                    if !viewModel.chasePack.isEmpty {
                        chasePackSection
                    }

                    // Add Friends button (Friends tab only)
                    if viewModel.selectedTab == .friends {
                        addFriendsButton
                    }
                }
                .padding(.top, VelocitySpacing.sm)
                .padding(.bottom, 100)
            }
            .background(Color.velocityBackground)
            .safeAreaInset(edge: .bottom) {
                BannerAdView()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("LEADERBOARD")
                        .font(.labelCaps())
                        .foregroundStyle(Color.nitroBlue)
                        .tracking(3)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let url = URL(string: "https://www.micostechnologies.com/passport_suite_webview/index.html") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.nitroBlue)
                    }
                }
            }
            .toolbarBackground(Color.velocityBackground, for: .navigationBar)
            .task { await viewModel.loadLeaderboard() }
            .sheet(isPresented: $viewModel.showAddFriendSheet) {
                addFriendSheet
            }
            .alert("Friend Limit Reached", isPresented: $viewModel.showFriendLimitAlert) {
                Button("Upgrade to PRO", role: .none) { }
                Button("OK", role: .cancel) { }
            } message: {
                Text("Free accounts can add up to 10 friends. Upgrade to Velocity PRO for unlimited friends!")
            }
            .alert("Remove Friend", isPresented: $showRemoveConfirmation) {
                Button("Remove", role: .destructive) {
                    if let friend = friendToRemove {
                        Task {
                            await viewModel.removeFriend(friendId: friend.profile.id)
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Remove \(friendToRemove?.profile.displayName ?? "this user") from your friends list?")
            }
        }
    }

    // MARK: - Segment Toggle
    private var segmentToggle: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardViewModel.LeaderboardTab.allCases, id: \.self) { tab in
                Button {
                    viewModel.selectedTab = tab
                    Task { await viewModel.loadLeaderboard() }
                } label: {
                    Text(tab.rawValue)
                        .font(.labelCaps())
                        .tracking(0.96)
                        .foregroundStyle(viewModel.selectedTab == tab ? .white : Color.onSurfaceVariant)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, VelocitySpacing.sm)
                        .background(
                            viewModel.selectedTab == tab
                                ? AnyShapeStyle(LinearGradient.nitroGradient)
                                : AnyShapeStyle(Color.clear)
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(3)
        .background(
            Capsule().fill(Color.velocitySurfaceContainerHigh)
        )
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Time Range Toggle
    private var timeRangeToggle: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardTimeRange.allCases, id: \.self) { range in
                Button {
                    viewModel.selectedTimeRange = range
                    Task { await viewModel.loadLeaderboard() }
                } label: {
                    Text(range.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(viewModel.selectedTimeRange == range ? Color.nitroBlue : Color.onSurfaceVariant)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, VelocitySpacing.xs)
                        .background(
                            viewModel.selectedTimeRange == range
                                ? Color.nitroBlue.opacity(0.15)
                                : Color.clear
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(2)
        .background(
            Capsule().fill(Color.velocitySurfaceContainerHigh.opacity(0.5))
        )
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Podium (2nd - 1st - 3rd layout)
    private var podiumSection: some View {
        HStack(alignment: .bottom, spacing: VelocitySpacing.md) {
            // 2nd place
            if viewModel.topThree.count > 1 {
                podiumEntry(entry: viewModel.topThree[1], height: 100)
            }

            // 1st place (tallest)
            if !viewModel.topThree.isEmpty {
                podiumEntry(entry: viewModel.topThree[0], height: 140)
            }

            // 3rd place
            if viewModel.topThree.count > 2 {
                podiumEntry(entry: viewModel.topThree[2], height: 80)
            }
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
        .padding(.top, VelocitySpacing.md)
    }

    private func podiumEntry(entry: LeaderboardEntry, height: CGFloat) -> some View {
        VStack(spacing: VelocitySpacing.xs) {
            // Avatar
            ZStack {
                Circle()
                    .fill(entry.rank == 1 ? Color.pulseOrange : Color.velocitySurfaceContainerHighest)
                    .frame(width: entry.rank == 1 ? 72 : 60, height: entry.rank == 1 ? 72 : 60)

                Text(entry.profile.displayName.prefix(1).uppercased())
                    .font(entry.rank == 1 ? .headlineLarge() : .headlineMedium())
                    .foregroundStyle(entry.rank == 1 ? .white : Color.nitroBlue)
            }
            .overlay(alignment: .top) {
                if entry.rank == 1 {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.pulseOrange)
                        .offset(y: -12)
                }
            }

            // Rank number
            Text("\(entry.rank)")
                .font(.statValueLarge())
                .foregroundStyle(entry.rank == 1 ? Color.pulseOrange : Color.onSurface)

            // Name
            Text(entry.profile.displayName)
                .font(.bodySmall())
                .foregroundStyle(Color.onSurface)
                .lineLimit(1)

            // Ride count
            Text("\(entry.rideCount) RIDES")
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)

            // Podium bar
            RoundedRectangle(cornerRadius: VelocityRadius.component)
                .fill(
                    entry.rank == 1
                        ? AnyShapeStyle(LinearGradient.nitroGradient)
                        : AnyShapeStyle(Color.velocitySurfaceContainerHigh)
                )
                .frame(height: height)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Chase Pack
    private var chasePackSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            Text("CHASE PACK")
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)
                .padding(.horizontal, VelocitySpacing.edgeMargin)

            VStack(spacing: 0) {
                ForEach(viewModel.chasePack) { entry in
                    chasePackRow(entry: entry)
                }
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
        }
    }

    private func chasePackRow(entry: LeaderboardEntry) -> some View {
        HStack(spacing: VelocitySpacing.sm) {
            // Rank
            Text("\(entry.rank)")
                .font(.statValue())
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(width: 28, alignment: .center)

            // Avatar
            Circle()
                .fill(Color.velocitySurfaceContainerHighest)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(entry.profile.displayName.prefix(1).uppercased())
                        .font(.labelCaps())
                        .foregroundStyle(Color.nitroBlue)
                )

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.profile.displayName)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurface)

                if let lastRide = entry.lastCheckIn?.ride {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 10))
                        Text(lastRide.name)
                            .lineLimit(1)
                    }
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                }
            }

            Spacer()

            // Count
            Text("\(entry.rideCount)")
                .font(.statValue())
                .foregroundStyle(Color.onSurface)
        }
        .padding(.vertical, VelocitySpacing.sm)
        .contextMenu {
            if viewModel.selectedTab == .friends && entry.profile.id != viewModel.currentProfileId {
                Button(role: .destructive) {
                    friendToRemove = entry
                    showRemoveConfirmation = true
                } label: {
                    Label("Remove Friend", systemImage: "person.badge.minus")
                }
            }
        }
    }

    // MARK: - Add Friends Button
    private var addFriendsButton: some View {
        Button {
            viewModel.showAddFriendSheet = true
        } label: {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 16))
                Text("FIND & ADD FRIENDS")
                    .font(.labelCaps())
                    .tracking(0.96)
            }
            .foregroundStyle(Color.nitroBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, VelocitySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: VelocityRadius.xl)
                    .stroke(Color.nitroBlue.opacity(0.4), lineWidth: 1)
            )
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Add Friend Sheet
    private var addFriendSheet: some View {
        NavigationStack {
            VStack(spacing: VelocitySpacing.lg) {
                // Search bar
                HStack(spacing: VelocitySpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.onSurfaceVariant)
                    TextField("Search by username...", text: $viewModel.friendSearchText)
                        .font(.bodyMedium())
                        .foregroundStyle(Color.onSurface)
                        .onSubmit { Task { await viewModel.searchUsers() } }
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, VelocitySpacing.md)
                .padding(.vertical, VelocitySpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: VelocityRadius.xl)
                        .fill(Color.velocitySurfaceContainerLow)
                        .overlay(
                            RoundedRectangle(cornerRadius: VelocityRadius.xl)
                                .stroke(Color.velocityOutlineVariant, lineWidth: 1)
                        )
                )

                // Results
                if viewModel.isSearching {
                    ProgressView().tint(Color.nitroBlue)
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else if viewModel.searchResults.isEmpty && !viewModel.friendSearchText.isEmpty {
                    VStack(spacing: VelocitySpacing.sm) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.onSurfaceVariant.opacity(0.4))
                        Text("No users found")
                            .font(.bodyMedium())
                            .foregroundStyle(Color.onSurfaceVariant)
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)
                } else {
                    ScrollView {
                        VStack(spacing: VelocitySpacing.sm) {
                            ForEach(viewModel.searchResults) { profile in
                                searchResultRow(profile: profile)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
            .padding(.top, VelocitySpacing.md)
            .background(Color.velocityBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("FIND FRIENDS")
                        .font(.headlineMedium())
                        .foregroundStyle(Color.nitroBlue)
                        .italic()
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { viewModel.showAddFriendSheet = false }
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Color.velocityBackground)
    }

    private func searchResultRow(profile: Profile) -> some View {
        let alreadyFriend = viewModel.isFriend(profile.id)

        return HStack(spacing: VelocitySpacing.md) {
            // Avatar
            Circle()
                .fill(Color.velocitySurfaceContainerHighest)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(profile.displayName.prefix(1).uppercased())
                        .font(.labelCaps())
                        .foregroundStyle(Color.nitroBlue)
                )

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName)
                    .font(.bodyLarge())
                    .fontWeight(.bold)
                    .foregroundStyle(Color.onSurface)
                if let username = profile.publicUserName, !username.isEmpty {
                    Text("@\(username)")
                        .font(.bodySmall())
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }

            Spacer()

            // Add/Remove button
            Button {
                Task {
                    if alreadyFriend {
                        await viewModel.removeFriend(friendId: profile.id)
                    } else {
                        await viewModel.addFriend(friendId: profile.id)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: alreadyFriend ? "checkmark" : "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text(alreadyFriend ? "ADDED" : "ADD")
                        .font(.labelCaps())
                        .tracking(0.96)
                }
                .foregroundStyle(alreadyFriend ? Color.onSurfaceVariant : Color.onNitroBlueContainer)
                .padding(.horizontal, VelocitySpacing.md)
                .padding(.vertical, VelocitySpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: VelocityRadius.component)
                        .fill(alreadyFriend ? Color.velocitySurfaceContainerHighest : Color.nitroBlue)
                )
            }
        }
        .padding(VelocitySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: VelocityRadius.xl)
                .fill(Color.velocitySurfaceContainerLow.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: VelocityRadius.xl)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: VelocityRadius.xl)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
