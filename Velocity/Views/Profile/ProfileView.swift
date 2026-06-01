import SwiftUI
import MapKit
import UIKit

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @AppStorage("selectedAvatarName") private var storedAvatarName = "avatar00"
    @AppStorage("usesCustomAvatar") private var usesCustomAvatar = false
    @AppStorage("customAvatarImageData") private var customAvatarImageData = Data()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VelocitySpacing.lg) {
                    headerSection
                    statsGrid
                    achievementsSection
                    mapSection
                    recentActivitySection
                }
                .padding(.top, VelocitySpacing.sm)
                .padding(.bottom, 100)
            }
            .background(Color.velocityBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PROFILE")
                        .font(.labelCaps())
                        .foregroundStyle(Color.nitroBlue)
                        .tracking(3)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Settings
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.onSurfaceVariant)
                    }
                }
            }
            .toolbarBackground(Color.velocityBackground, for: .navigationBar)
            .task { await viewModel.loadProfile() }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: VelocitySpacing.sm) {
            // PRO badge
            if viewModel.isPro {
                Text("PRO")
                    .font(.labelCaps())
                    .tracking(1.5)
                    .foregroundStyle(.white)
                    .padding(.horizontal, VelocitySpacing.sm)
                    .padding(.vertical, VelocitySpacing.base)
                    .background(
                        Capsule().fill(LinearGradient.nitroGradient)
                    )
            }

            // Avatar
            profileAvatar

            // Name
            Text(viewModel.profile?.displayName.uppercased() ?? "LOADING...")
                .font(.headlineLarge())
                .foregroundStyle(Color.onSurface)

            Text("Elite Coaster Enthusiast")
                .font(.bodyMedium())
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    private var profileAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.velocitySurfaceContainerHighest)
                .frame(width: 88, height: 88)

            if usesCustomAvatar, let image = UIImage(data: customAvatarImageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 88, height: 88)
                    .clipShape(Circle())
            } else if let image = UIImage(named: viewModel.profile?.avatarName ?? storedAvatarName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 88, height: 88)
                    .clipShape(Circle())
            } else {
                Text(viewModel.profile?.displayName.prefix(1).uppercased() ?? "?")
                    .font(.headlineHero())
                    .foregroundStyle(Color.nitroBlue)
            }
        }
        .overlay(
            Circle().stroke(Color.nitroBlue, lineWidth: 2)
        )
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: VelocitySpacing.gutter) {
            StatCard(
                label: "Coaster Count",
                value: "\(viewModel.stats?.coasterCount ?? 0)",
                icon: "mountain.2"
            )
            StatCard(
                label: "Max G-Force",
                value: String(format: "%.1f", viewModel.stats?.maxGForce ?? 0),
                icon: "speedometer"
            )
            StatCard(
                label: "Parks Visited",
                value: "\(viewModel.stats?.parksVisited ?? 0)",
                icon: "map"
            )
            StatCard(
                label: "Global Rank",
                value: "#\(viewModel.stats?.globalRank ?? 0)",
                icon: "trophy"
            )
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Achievements
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            HStack {
                Text("ACHIEVEMENTS")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)
                Spacer()
                Button("VIEW ALL") {}
                    .font(.labelCaps())
                    .foregroundStyle(Color.nitroBlue)
                    .tracking(0.96)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: VelocitySpacing.gutter) {
                    ForEach(viewModel.achievements) { achievement in
                        achievementBadge(
                            achievement: achievement,
                            earned: viewModel.earnedAchievementIds.contains(achievement.id)
                        )
                    }
                }
                .padding(.horizontal, VelocitySpacing.edgeMargin)
            }
        }
    }

    private func achievementBadge(achievement: Achievement, earned: Bool) -> some View {
        VStack(spacing: VelocitySpacing.xs) {
            ZStack {
                Circle()
                    .fill(earned ? Color.nitroBlue.opacity(0.2) : Color.velocitySurfaceContainerHigh)
                    .frame(width: 56, height: 56)

                Image(systemName: achievement.iconName)
                    .font(.system(size: 24))
                    .foregroundStyle(earned ? Color.nitroBlue : Color.velocityOutlineVariant)
            }

            Text(achievement.name.uppercased())
                .font(.labelCaps())
                .foregroundStyle(earned ? Color.onSurface : Color.velocityOutlineVariant)
                .tracking(0.96)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .opacity(earned ? 1 : 0.5)
    }

    // MARK: - Coaster Map
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            HStack {
                Text("COASTER MAP")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)
                Spacer()
                Text("LIVE TRACKING")
                    .font(.labelCaps())
                    .foregroundStyle(Color.pulseOrange)
                    .tracking(0.96)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            Map {
                // Markers would be added here based on visited parks
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: VelocityRadius.card)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .colorScheme(.dark)
            .padding(.horizontal, VelocitySpacing.edgeMargin)
        }
    }

    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            Text("RECENT ACTIVITY")
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, VelocitySpacing.edgeMargin)

            if viewModel.recentActivity.isEmpty && !viewModel.isLoading {
                Text("No check-ins yet. Start riding!")
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .padding(.horizontal, VelocitySpacing.edgeMargin)
            } else {
                VStack(spacing: VelocitySpacing.gutter) {
                    ForEach(viewModel.recentActivity) { checkIn in
                        recentActivityRow(checkIn: checkIn)
                    }
                }
                .padding(.horizontal, VelocitySpacing.edgeMargin)
            }
        }
    }

    private func recentActivityRow(checkIn: ProfileRide) -> some View {
        HStack(spacing: VelocitySpacing.sm) {
            // Ride image
            ZStack {
                RoundedRectangle(cornerRadius: VelocityRadius.component)
                    .fill(Color.velocitySurfaceContainerHighest)
                    .frame(width: 56, height: 56)

                Image("nearby_empty")
                    .foregroundStyle(Color.nitroBlue.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(checkIn.ride?.name ?? "Unknown Ride")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(checkIn.ride?.park?.name?.uppercased() ?? "")
                    if let date = checkIn.createdDate {
                        Text("•")
                        Text(date.relativeString)
                    }
                }
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)
                .lineLimit(1)
            }

            Spacer()

            // Highlight stat
            if let speed = checkIn.ride?.speed {
                VStack(spacing: 0) {
                    Text("\(speed) MPH")
                        .font(.statValue())
                        .foregroundStyle(Color.nitroBlue)
                    Text("TOP SPEED")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }
        }
        .padding(VelocitySpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: VelocityRadius.component)
                .fill(Color.velocitySurfaceContainerHigh)
        )
    }
}

// MARK: - Date Extension
extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
