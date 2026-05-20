import SwiftUI

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VelocitySpacing.lg) {
                    // Search Bar
                    VelocitySearchBar(text: $viewModel.searchText) {
                        Task { await viewModel.search() }
                    }
                    .padding(.horizontal, VelocitySpacing.edgeMargin)

                    if viewModel.searchText.isEmpty {
                        mainContent
                    } else {
                        searchResultsContent
                    }
                }
                .padding(.top, VelocitySpacing.sm)
                .padding(.bottom, 100)
            }
            .background(Color.velocityBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("VELOCITY")
                        .font(.labelCaps())
                        .foregroundStyle(Color.nitroBlue)
                        .tracking(3)
                }
            }
            .toolbarBackground(Color.velocityBackground, for: .navigationBar)
            .task { await viewModel.loadInitialData() }
        }
    }

    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        // Quick Check-In Card
        quickCheckInCard

        // Trending Now
        trendingSection

        // Top Rated Worldwide
        topRatedSection
    }

    // MARK: - Quick Check-In
    private var quickCheckInCard: some View {
        GlassCard {
            HStack(spacing: VelocitySpacing.md) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.nitroGradient)
                        .frame(width: 44, height: 44)
                    Image(systemName: "location.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: VelocitySpacing.base) {
                    Text("Quick Check-In")
                        .font(.headlineMedium())
                        .foregroundStyle(Color.onSurface)
                    Text("Log your current ride session")
                        .font(.bodySmall())
                        .foregroundStyle(Color.onSurfaceVariant)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.nitroBlue)
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(VelocitySpacing.md)
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Trending Section
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            HStack {
                Text("Trending Now")
                    .font(.headlineLarge())
                    .foregroundStyle(Color.onSurface)
                Spacer()
                Button("See All") {}
                    .font(.labelCaps())
                    .foregroundStyle(Color.nitroBlue)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: VelocitySpacing.gutter) {
                    ForEach(viewModel.trendingRides) { ride in
                        NavigationLink(destination: CoasterDetailView(rideId: ride.id)) {
                            CoasterCard(ride: ride)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, VelocitySpacing.edgeMargin)
            }

            if viewModel.trendingRides.isEmpty && viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Color.nitroBlue)
                    Spacer()
                }
                .padding()
            }
        }
    }

    // MARK: - Top Rated Section
    private var topRatedSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            HStack(alignment: .center) {
                Text("Top Rated Worldwide")
                    .font(.headlineLarge())
                    .foregroundStyle(Color.onSurface)

                Spacer()

                Text("GLOBAL RANKS")
                    .font(.labelCaps())
                    .foregroundStyle(Color.nitroBlue)
                    .tracking(0.96)
                    .padding(.horizontal, VelocitySpacing.sm)
                    .padding(.vertical, VelocitySpacing.base)
                    .background(
                        Capsule().fill(Color.nitroBlue.opacity(0.15))
                    )
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.topRatedRides.enumerated()), id: \.element.id) { index, ride in
                    NavigationLink(destination: CoasterDetailView(rideId: ride.id)) {
                        TopRatedRow(ride: ride, rank: index + 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
        }
    }

    // MARK: - Search Results
    @ViewBuilder
    private var searchResultsContent: some View {
        if viewModel.isSearching {
            ProgressView()
                .tint(Color.nitroBlue)
                .padding(.top, 40)
        } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
            VStack(spacing: VelocitySpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.velocityOutlineVariant)
                Text("No coasters found")
                    .font(.bodyLarge())
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            .padding(.top, 60)
        } else {
            VStack(spacing: 0) {
                ForEach(viewModel.searchResults) { ride in
                    NavigationLink(destination: CoasterDetailView(rideId: ride.id)) {
                        TopRatedRow(ride: ride, rank: nil)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
        }
    }
}

// MARK: - Top Rated Row
struct TopRatedRow: View {
    let ride: Ride
    let rank: Int?

    var body: some View {
        HStack(spacing: VelocitySpacing.sm) {
            // Rank badge
            if let rank {
                Text("Global #\(rank)")
                    .font(.labelCaps())
                    .foregroundStyle(rank <= 3 ? Color.pulseOrange : Color.onSurfaceVariant)
                    .tracking(0.96)
                    .frame(width: 72, alignment: .leading)
            }

            // Ride image
            ZStack {
                RoundedRectangle(cornerRadius: VelocityRadius.component)
                    .fill(Color.velocitySurfaceContainerHighest)
                    .frame(width: 56, height: 56)

                if let url = ride.mainImageURL, let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "figure.roller.coaster")
                            .foregroundStyle(Color.nitroBlue.opacity(0.4))
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.component))
                } else {
                    Image(systemName: "figure.roller.coaster")
                        .foregroundStyle(Color.nitroBlue.opacity(0.4))
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                if let parkName = ride.park?.name {
                    Text(parkName.uppercased())
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(0.96)
                        .lineLimit(1)
                }
                Text(ride.name)
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
                    .lineLimit(1)
            }

            Spacer()

            // Star rating
            if ride.starRating > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.pulseOrange)
                    Text(String(format: "%.1f", ride.starRating))
                        .font(.statValue())
                        .foregroundStyle(Color.onSurface)
                }
            }
        }
        .padding(.vertical, VelocitySpacing.sm)
    }
}
