import SwiftUI

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VelocitySpacing.xl) {
                    // Search Input
                    searchField

                    // Quick Action Card
                    quickActionCard

                    // Trending Now Carousel
                    trendingSection

                    // Top Rated Worldwide
                    topRatedSection
                }
                .padding(.bottom, 100)
            }
            .background(Color.velocityBackground)
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("VELOCITY")
                        .font(.headlineMedium())
                        .foregroundStyle(Color.nitroBlue)
                        .italic()
                        .tracking(-0.5)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: VelocitySpacing.md) {
                        Button {
                            // TODO: focus search
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.nitroBlue)
                        }
                        Circle()
                            .fill(Color.velocitySurfaceContainerHighest)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.onSurfaceVariant)
                            )
                            .overlay(Circle().stroke(Color.nitroBlue.opacity(0.2), lineWidth: 1))
                    }
                }
            }
            .toolbarBackground(Color.velocitySurface.opacity(0.8), for: .navigationBar)
            .task { await viewModel.loadInitialData() }
        }
    }

    // MARK: - Search Field
    private var searchField: some View {
        HStack(spacing: VelocitySpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.onSurfaceVariant)
            TextField("Find your next rush...", text: $viewModel.searchText)
                .font(.bodyMedium())
                .foregroundStyle(Color.onSurface)
                .onSubmit { Task { await viewModel.search() } }
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
        .padding(.horizontal, VelocitySpacing.edgeMargin)
        .padding(.top, VelocitySpacing.lg)
    }

    // MARK: - Quick Action Card (gradient border)
    private var quickActionCard: some View {
        // Gradient border wrapper
        RoundedRectangle(cornerRadius: VelocityRadius.xl)
            .fill(
                LinearGradient(
                    colors: [Color.nitroBlue, Color(hex: "#00677f")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 120)
            .overlay(
                RoundedRectangle(cornerRadius: VelocityRadius.xl - 1)
                    .fill(Color.velocitySurfaceContainerLowest)
                    .padding(1)
                    .overlay(
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("LIVE ACTION")
                                    .font(.labelCaps())
                                    .foregroundStyle(Color.nitroBlue)
                                    .tracking(2)
                                Text("Quick Check-In")
                                    .font(.headlineMedium())
                                    .foregroundStyle(Color.onSurface)
                                Text("At the park? Log your current ride instantly.")
                                    .font(.bodyMedium())
                                    .foregroundStyle(Color.onSurfaceVariant)
                                    .lineLimit(2)
                                    .frame(maxWidth: 200, alignment: .leading)
                            }

                            Spacer()

                            // Nitro glow circle button
                            Circle()
                                .fill(Color.nitroBlue)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.system(size: 22))
                                        .foregroundStyle(Color.onNitroBlueContainer)
                                )
                                .shadow(color: Color.nitroBlue.opacity(0.3), radius: 15)
                        }
                        .padding(VelocitySpacing.lg)
                    )
            )
            .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Trending Now
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            HStack {
                Text("TRENDING NOW")
                    .font(.headlineLarge())
                    .foregroundStyle(Color.onSurface)
                    .italic()
                Spacer()
                Text("SEE ALL")
                    .font(.labelCaps())
                    .foregroundStyle(Color.nitroBlue)
                    .tracking(0.96)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            if viewModel.isLoading && viewModel.trendingRides.isEmpty {
                HStack { Spacer(); ProgressView().tint(Color.nitroBlue); Spacer() }
                    .frame(height: 400)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: VelocitySpacing.md) {
                        ForEach(viewModel.trendingRides) { ride in
                            NavigationLink(destination: CoasterDetailView(rideId: ride.id)) {
                                trendingCard(ride: ride)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, VelocitySpacing.edgeMargin)
                }
            }
        }
    }

    // MARK: - Trending Card (288w × 400h, full-bleed image, stats overlay)
    private func trendingCard(ride: Ride) -> some View {
        ZStack(alignment: .bottom) {
            // Background image
            RoundedRectangle(cornerRadius: VelocityRadius.xl)
                .fill(Color.velocitySurfaceContainerHighest)
                .frame(width: 288, height: 400)
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
                    .frame(width: 288, height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))
                )

            // Bottom gradient
            LinearGradient(
                colors: [.clear, Color.velocityBackground],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))

            // Content overlay
            VStack(alignment: .leading, spacing: 6) {
                // Wait badge
                if let speed = ride.speed {
                    let isFast = speed > 80
                    Text(isFast ? "HOT: \(speed) MPH" : "FAST: \(speed) MPH")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isFast ? Color.pulseOrange : Color.nitroBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill((isFast ? Color.pulseOrange : Color.nitroBlue).opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke((isFast ? Color.pulseOrange : Color.nitroBlue).opacity(0.3), lineWidth: 1)
                                )
                        )
                }

                Text(ride.name.uppercased())
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
                    .lineLimit(1)

                if let park = ride.park {
                    Text("\(park.displayName), \(park.state ?? "")")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(0.96)
                        .lineLimit(1)
                }

                // Stats row
                HStack(spacing: VelocitySpacing.md) {
                    if let speed = ride.speed {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(speed)")
                                .font(.statValue())
                                .foregroundStyle(Color.nitroBlue)
                            Text("MPH")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.onSurfaceVariant)
                        }
                    }

                    if let speed = ride.speed, (ride.height != nil || ride.inversions != nil) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 1, height: 32)
                    }

                    if let height = ride.height {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(height)")
                                .font(.statValue())
                                .foregroundStyle(Color.nitroBlue)
                            Text("FEET")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.onSurfaceVariant)
                        }
                    } else if let inversions = ride.inversions, inversions > 0 {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(inversions)")
                                .font(.statValue())
                                .foregroundStyle(Color.nitroBlue)
                            Text("INVERTS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.onSurfaceVariant)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding(VelocitySpacing.lg)
            .frame(width: 288, alignment: .leading)
        }
        .frame(width: 288, height: 400)
    }

    // MARK: - Top Rated Worldwide
    private var topRatedSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            Text("TOP RATED WORLDWIDE")
                .font(.headlineLarge())
                .foregroundStyle(Color.onSurface)
                .italic()
                .padding(.horizontal, VelocitySpacing.edgeMargin)

            VStack(spacing: VelocitySpacing.sm) {
                ForEach(Array(viewModel.topRatedRides.prefix(10).enumerated()), id: \.element.id) { index, ride in
                    NavigationLink(destination: CoasterDetailView(rideId: ride.id)) {
                        topRatedCard(ride: ride, rank: index + 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
        }
    }

    // MARK: - Top Rated Card (glass card with rank number, thumbnail, name, stars, credits)
    private func topRatedCard(ride: Ride, rank: Int) -> some View {
        HStack(spacing: VelocitySpacing.md) {
            // Large italic rank number at low opacity
            Text(String(format: "%02d", rank))
                .font(.headlineHero())
                .foregroundStyle(Color.onSurface.opacity(0.2))
                .italic()
                .frame(width: 48)

            // Thumbnail
            RoundedRectangle(cornerRadius: VelocityRadius.component)
                .fill(Color.velocitySurfaceContainerHighest)
                .frame(width: 80, height: 80)
                .overlay(
                    Group {
                        if let url = ride.mainImageURL, let imageURL = URL(string: url) {
                            AsyncImage(url: imageURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Image(systemName: "figure.roller.coaster")
                                    .foregroundStyle(Color.nitroBlue.opacity(0.3))
                            }
                        }
                    }
                    .frame(width: 80, height: 80)
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

                if let park = ride.park {
                    Text("\(park.displayName), \(park.state ?? "")")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(0.96)
                }

                if ride.starRating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.nitroBlue)
                        Text(String(format: "%.1f / 5.0", ride.starRating))
                            .font(.labelCaps())
                            .foregroundStyle(Color.nitroBlue)
                            .tracking(0.96)
                    }
                }
            }

            Spacer()

            // Credits / speed stat
            VStack(alignment: .trailing, spacing: 2) {
                Text("SPEED")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)
                if let speed = ride.speed {
                    Text("\(speed)")
                        .font(.statValue())
                        .foregroundStyle(Color.onSurface)
                }
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

// MARK: - TopRatedRow (kept for search results)
struct TopRatedRow: View {
    let ride: Ride
    let rank: Int?

    var body: some View {
        HStack(spacing: VelocitySpacing.sm) {
            if let rank {
                Text("#\(rank)")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .frame(width: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(ride.name)
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
                    .lineLimit(1)
                if let park = ride.park {
                    Text(park.displayName)
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(0.96)
                }
            }

            Spacer()

            if let speed = ride.speed {
                Text("\(speed) MPH")
                    .font(.statValue())
                    .foregroundStyle(Color.nitroBlue)
            }
        }
        .padding(.vertical, VelocitySpacing.sm)
    }
}
