import SwiftUI

struct LeaderboardView: View {
    @State private var viewModel = LeaderboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VelocitySpacing.lg) {
                    // Tab Toggle
                    segmentToggle

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
                }
                .padding(.top, VelocitySpacing.sm)
                .padding(.bottom, 100)
            }
            .background(Color.velocityBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("LEADERBOARD")
                        .font(.labelCaps())
                        .foregroundStyle(Color.nitroBlue)
                        .tracking(3)
                }
            }
            .toolbarBackground(Color.velocityBackground, for: .navigationBar)
            .task { await viewModel.loadLeaderboard() }
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
    }
}
