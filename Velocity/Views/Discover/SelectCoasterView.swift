import SwiftUI

struct SelectCoasterView: View {
    let park: Park
    @State private var rides: [Ride] = []
    @State private var isLoading = true
    @State private var selectedRide: Ride?
    @State private var showCheckIn = false
    @Environment(\.dismiss) private var dismiss

    private let rideService = RideService()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Park Header
                parkHeader

                // Quick Stats Row
                statsRow
                    .padding(.top, VelocitySpacing.lg)

                // Coaster List
                if isLoading {
                    ProgressView()
                        .tint(Color.nitroBlue)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if rides.isEmpty {
                    emptyState
                } else {
                    coasterList
                        .padding(.top, VelocitySpacing.lg)
                }
            }
            .padding(.bottom, 100)
        }
        .background(Color.velocityBackground)
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: VelocitySpacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("VELOCITY")
                                .font(.custom("ArchivoNarrow-Bold", size: 18))
                                .italic()
                            Text("Coaster Chaser")
                                .font(.system(size: 10, weight: .medium))
                                .opacity(0.7)
                        }
                    }
                    .foregroundStyle(Color.nitroBlue)
                }
            }
        }
        .toolbarBackground(Color.velocitySurface.opacity(0.8), for: .navigationBar)
        .task { await loadRides() }
        .navigationDestination(isPresented: $showCheckIn) {
            if let ride = selectedRide {
                CoasterCheckInView(ride: ride, park: park)
            }
        }
    }

    // MARK: - Park Header
    private var parkHeader: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
            // Park name hero
            Text(park.displayName.uppercased())
                .font(.headlineHero())
                .foregroundStyle(Color.nitroBlue)
                .italic()
                .tracking(-0.5)

            // Location + coaster count
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.onSurfaceVariant)
                Text("\(park.city ?? ""), \(park.state ?? "") • \(rides.count) Coasters Available")
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, VelocitySpacing.edgeMargin)
        .padding(.top, VelocitySpacing.lg)
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: VelocitySpacing.sm) {
                statChip(label: "Park Status", value: "Open", icon: "checkmark.circle.fill", color: .green)
                statChip(label: "Avg Wait", value: "45m", icon: "timer", color: Color.nitroBlue)
                statChip(label: "Weather", value: "72°F", icon: "sun.max.fill", color: Color.pulseOrange)
                statChip(label: "Crowd", value: "Moderate", icon: "person.3.fill", color: Color.onSurfaceVariant)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
        }
    }

    private func statChip(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: VelocitySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(value)
                .font(.statValue())
                .foregroundStyle(Color.onSurface)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)
        }
        .frame(width: 88, height: 88)
        .background(
            RoundedRectangle(cornerRadius: VelocityRadius.card)
                .fill(Color.velocitySurfaceContainerLow.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: VelocityRadius.card)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: VelocityRadius.card)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Coaster List
    private var coasterList: some View {
        VStack(spacing: VelocitySpacing.md) {
            // Featured card (first ride)
            if let featured = rides.first {
                featuredCard(ride: featured)
                    .padding(.horizontal, VelocitySpacing.edgeMargin)
            }

            // Remaining rides
            VStack(spacing: VelocitySpacing.sm) {
                ForEach(Array(rides.dropFirst())) { ride in
                    coasterRow(ride: ride)
                }
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
        }
    }

    // MARK: - Featured Card
    private func featuredCard(ride: Ride) -> some View {
        ZStack(alignment: .bottom) {
            // Background image
            RoundedRectangle(cornerRadius: VelocityRadius.xl)
                .fill(Color.velocitySurfaceContainerHighest)
                .frame(height: 280)
                .overlay(
                    Group {
                        if let url = ride.mainImageURL, let imageURL = URL(string: url) {
                            AsyncImage(url: imageURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Image(systemName: "figure.roller.coaster")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color.nitroBlue.opacity(0.2))
                            }
                        }
                    }
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))
                )

            // Gradient overlay
            LinearGradient(
                colors: [.clear, Color.velocityBackground.opacity(0.9), Color.velocityBackground],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))

            // "Recently Ridden" badge (top left)
            VStack {
                HStack {
                    Text("RECENTLY RIDDEN")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.pulseOrange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.pulseOrange.opacity(0.2))
                                .overlay(Capsule().stroke(Color.pulseOrange.opacity(0.3), lineWidth: 1))
                        )
                    Spacer()
                }
                .padding(VelocitySpacing.md)
                Spacer()
            }

            // Content
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    // Wait time badge
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 10))
                        Text("\(Int.random(in: 30...120)) min wait")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Color.pulseOrange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.pulseOrange.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.pulseOrange.opacity(0.3), lineWidth: 1)
                            )
                    )

                    Text(ride.name.uppercased())
                        .font(.headlineLarge())
                        .foregroundStyle(Color.onSurface)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    selectedRide = ride
                    showCheckIn = true
                } label: {
                    Text("SELECT")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.onNitroBlue)
                        .tracking(0.96)
                        .padding(.horizontal, VelocitySpacing.lg)
                        .padding(.vertical, VelocitySpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: VelocityRadius.component)
                                .fill(LinearGradient.nitroGradient)
                        )
                        .shadow(color: Color.nitroBlue.opacity(0.3), radius: 10)
                }
            }
            .padding(VelocitySpacing.lg)
        }
        .frame(height: 280)
    }

    // MARK: - Coaster Row
    private func coasterRow(ride: Ride) -> some View {
        HStack(spacing: VelocitySpacing.md) {
            // Thumbnail
            RoundedRectangle(cornerRadius: VelocityRadius.component)
                .fill(Color.velocitySurfaceContainerHighest)
                .frame(width: 72, height: 72)
                .overlay(
                    Group {
                        if let url = ride.mainImageURL, let imageURL = URL(string: url) {
                            AsyncImage(url: imageURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Image(systemName: "figure.roller.coaster")
                                    .foregroundStyle(Color.nitroBlue.opacity(0.3))
                            }
                        } else {
                            Image(systemName: "figure.roller.coaster")
                                .foregroundStyle(Color.nitroBlue.opacity(0.3))
                        }
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.component))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: VelocityRadius.component)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(ride.name.uppercased())
                    .font(.bodyLarge())
                    .fontWeight(.bold)
                    .foregroundStyle(Color.onSurface)
                    .lineLimit(1)

                // Wait time indicator
                HStack(spacing: 6) {
                    let waitMin = Int.random(in: 10...90)
                    Circle()
                        .fill(waitMin < 30 ? Color.green : waitMin < 60 ? Color.nitroBlue : Color.pulseOrange)
                        .frame(width: 8, height: 8)
                    Text("\(waitMin) min")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(0.96)
                }
            }

            Spacer()

            // SELECT button
            Button {
                selectedRide = ride
                showCheckIn = true
            } label: {
                Text("SELECT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.nitroBlue)
                    .tracking(0.96)
                    .padding(.horizontal, VelocitySpacing.md)
                    .padding(.vertical, VelocitySpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: VelocityRadius.component)
                            .stroke(Color.nitroBlue.opacity(0.4), lineWidth: 1)
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
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: VelocitySpacing.md) {
            Image(systemName: "figure.roller.coaster")
                .font(.system(size: 48))
                .foregroundStyle(Color.nitroBlue.opacity(0.3))
            Text("NO COASTERS FOUND")
                .font(.headlineMedium())
                .foregroundStyle(Color.onSurface)
            Text("This park doesn't have any coasters in our database yet.")
                .font(.bodyMedium())
                .foregroundStyle(Color.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .padding(VelocitySpacing.xl)
    }

    // MARK: - Data Loading
    private func loadRides() async {
        isLoading = true
        do {
            rides = try await rideService.fetchRidesForPark(parkId: park.id)
        } catch {
            rides = []
        }
        isLoading = false
    }
}
