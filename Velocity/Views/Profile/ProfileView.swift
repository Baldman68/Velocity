import SwiftUI
import MapKit
import UIKit

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var showSubscription = false
    @State private var showJournal = false
    @AppStorage("selectedAvatarName") private var storedAvatarName = "avatar00"
    @AppStorage("usesCustomAvatar") private var usesCustomAvatar = false
    @AppStorage("customAvatarImageData") private var customAvatarImageData = Data()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VelocitySpacing.lg) {
                    headerSection
                    statsGrid
                    journalButton
                    achievementsSection
                    mapSection
                    recentActivitySection
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
                    Text("PROFILE")
                        .font(.labelCaps())
                        .foregroundStyle(Color.nitroBlue)
                        .tracking(3)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSubscription = true
                    } label: {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color.pulseOrange)
                    }
                }
            }
            .toolbarBackground(Color.velocityBackground, for: .navigationBar)
            .task { await viewModel.loadProfile() }
            .navigationDestination(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .navigationDestination(isPresented: $showJournal) {
                if let profileId = viewModel.profile?.id {
                    RideJournalView(profileId: profileId)
                }
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: VelocitySpacing.sm) {
            // Subscription badge
            Button {
                showSubscription = true
            } label: {
                Text(viewModel.tierLabel)
                    .font(.labelCaps())
                    .tracking(1.5)
                    .foregroundStyle(.white)
                    .padding(.horizontal, VelocitySpacing.sm)
                    .padding(.vertical, VelocitySpacing.base)
                    .background(
                        Capsule().fill(
                            viewModel.isElite
                                ? LinearGradient(colors: [Color.pulseOrange, Color(hex: "#cc4a00")], startPoint: .leading, endPoint: .trailing)
                                : viewModel.isPro
                                    ? LinearGradient.nitroGradient
                                    : LinearGradient(colors: [Color.velocitySurfaceContainerHighest, Color.velocitySurfaceContainerHigh], startPoint: .leading, endPoint: .trailing)
                        )
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

    // MARK: - Journal Button
    private var journalButton: some View {
        Button {
            showJournal = true
        } label: {
            HStack(spacing: VelocitySpacing.sm) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.nitroBlue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("RIDE JOURNAL")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurface)
                        .tracking(0.96)
                    Text("Stats, records & full ride history")
                        .font(.bodySmall())
                        .foregroundStyle(Color.onSurfaceVariant)
                }

                Spacer()

                Text("\(viewModel.stats?.coasterCount ?? 0) RIDES")
                    .font(.labelCaps())
                    .foregroundStyle(Color.nitroBlue)
                    .tracking(0.96)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.onSurfaceVariant)
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
                            .stroke(Color.nitroBlue.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, VelocitySpacing.edgeMargin)
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

                // Visited / Bucket List toggle
                HStack(spacing: 0) {
                    Button {
                        viewModel.showMapVisited = true
                    } label: {
                        Text("VISITED")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(viewModel.showMapVisited ? .white : Color.onSurfaceVariant)
                            .padding(.horizontal, VelocitySpacing.sm)
                            .padding(.vertical, 4)
                            .background(
                                viewModel.showMapVisited
                                    ? AnyShapeStyle(Color.nitroBlue)
                                    : AnyShapeStyle(Color.clear)
                            )
                            .clipShape(Capsule())
                    }
                    Button {
                        viewModel.showMapVisited = false
                    } label: {
                        Text("BUCKET LIST")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(!viewModel.showMapVisited ? .white : Color.onSurfaceVariant)
                            .padding(.horizontal, VelocitySpacing.sm)
                            .padding(.vertical, 4)
                            .background(
                                !viewModel.showMapVisited
                                    ? AnyShapeStyle(Color.pulseOrange)
                                    : AnyShapeStyle(Color.clear)
                            )
                            .clipShape(Capsule())
                    }
                }
                .padding(2)
                .background(Capsule().fill(Color.velocitySurfaceContainerHigh))
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            // Count badge
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: viewModel.showMapVisited ? "mappin.circle.fill" : "bookmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(viewModel.showMapVisited ? Color.nitroBlue : Color.pulseOrange)
                Text(viewModel.showMapVisited
                     ? "\(viewModel.visitedParkPins.count) PARKS VISITED"
                     : "\(viewModel.bucketListPins.count) ON BUCKET LIST")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)
                Spacer()
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            Map {
                let pins = viewModel.showMapVisited ? viewModel.visitedParkPins : viewModel.bucketListPins
                ForEach(pins) { pin in
                    Marker(
                        pin.park.displayName,
                        coordinate: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                    )
                    .tint(pin.isBucketList ? Color.pulseOrange : Color.nitroBlue)
                }
            }
            .frame(height: 240)
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
                    .resizable()
                    .scaledToFill()
                    .opacity(0.5)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.component))
                    .clipped()
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
