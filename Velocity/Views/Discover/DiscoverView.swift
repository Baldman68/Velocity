import SwiftUI

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel()
    @State private var showNoParkAlert = false
    @State private var showLocationRequiredAlert = false
    @State private var showSubmitCoaster = false
    @State private var showAddPark = false
    @State private var showEditProfile = false
    @State private var showSubscription = false
    @State private var subscriptionService = SubscriptionService()
    private let sectionTitleFont = Font.custom("ArchivoNarrow-Bold", size: 28)
    @AppStorage("selectedAvatarName") private var storedAvatarName = "avatar00"
    @AppStorage("usesCustomAvatar") private var usesCustomAvatar = false
    @AppStorage("customAvatarImageData") private var customAvatarImageData = Data()
    private var appMarketingVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "--"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VelocitySpacing.xl) {
                    // Search Input
                    searchField

                    if viewModel.searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        // Subscription upgrade banner
                        if subscriptionService.currentTier != .eliteMonthly && subscriptionService.currentTier != .eliteAnnual {
                            subscriptionBanner
                        }

                        // Location warning + Quick Action Card
                        VStack(spacing: VelocitySpacing.xs) {
                            if !viewModel.isLocationAuthorized {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.slash.fill")
                                        .font(.system(size: 11))
                                    Text("Enable Location Services to check in at parks and see nearby coasters.")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(Color.velocityError)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, VelocitySpacing.edgeMargin)
                            }

                            quickActionCard
                        }

                        // Nearby Rides
                        nearbySection

                        // Trending Now Carousel
                        trendingSection

                        // Top Rated Worldwide
                        topRatedSection
                    } else {
                        searchResultsSection
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Color.velocityBackground)
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                BannerAdView()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("VELOCITY")
                            .font(.custom("ArchivoNarrow-Bold", size: 20))
                            .italic()
                        Text("Coaster Chaser")
                            .font(.system(size: 10, weight: .medium))
                            .opacity(0.7)
                    }
                    .padding(.horizontal)
                    .foregroundStyle(Color.nitroBlue)
                    .fixedSize()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: VelocitySpacing.sm) {
                        Menu {
                            Button {
                                showSubmitCoaster = true
                            } label: {
                                Label("Suggest New Coaster", systemImage: "plus.circle")
                            }
                            Button {
                                showAddPark = true
                            } label: {
                                Label("Suggest New Park", systemImage: "mappin.circle")
                            }
                            Divider()
                            Button {
                                if let url = URL(string: "https://www.micostechnologies.com/passport_suite_webview/index.html") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Label("More Apps", systemImage: "square.grid.2x2")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.nitroBlue)
                        }

                        Button {
                            showEditProfile = true
                        } label: {
                            discoverAvatarButton
                        }
                    }
                }
            }
            .toolbarBackground(Color.velocitySurface.opacity(0.8), for: .navigationBar)
            .task {
                await viewModel.loadInitialData()
                await subscriptionService.refreshCurrentTier()
            }
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.onSearchTextChanged()
            }
            .alert("Not Near a Park", isPresented: $showNoParkAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You don't appear to be near any amusement parks. Head to a park to use Quick Check-In!")
            }
            .alert("Location Services Required", isPresented: $showLocationRequiredAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("Location Services are not turned on for Velocity. You'll need to allow location access before you can check in at a park.")
            }
            .navigationDestination(isPresented: $showSubmitCoaster) {
                SubmitCoasterView()
            }
            .navigationDestination(isPresented: $showAddPark) {
                AddParkView()
            }
            .navigationDestination(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .navigationDestination(isPresented: $showSubscription) {
                SubscriptionView()
            }
        }
    }

    // MARK: - Avatar Button
    private var discoverAvatarButton: some View {
        ZStack {
            Circle()
                .fill(Color.velocitySurfaceContainerHighest)
                .frame(width: 32, height: 32)

            if usesCustomAvatar, let img = UIImage(data: customAvatarImageData) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else if let img = UIImage(named: storedAvatarName) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
        .overlay(Circle().stroke(Color.nitroBlue.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Subscription Banner
    private var subscriptionBanner: some View {
        Button {
            showSubscription = true
        } label: {
            HStack(spacing: VelocitySpacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(subscriptionService.currentTier == .free ? Color.nitroBlue.opacity(0.15) : Color.pulseOrange.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: subscriptionService.currentTier == .free ? "bolt.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(subscriptionService.currentTier == .free ? Color.nitroBlue : Color.pulseOrange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(subscriptionService.currentTier == .free ? "UPGRADE TO PRO" : "UPGRADE TO ELITE")
                        .font(.labelCaps())
                        .foregroundStyle(subscriptionService.currentTier == .free ? Color.nitroBlue : Color.pulseOrange)
                        .tracking(0.96)
                    Text(subscriptionService.currentTier == .free
                         ? "Unlock unlimited check-ins, stats & more"
                         : "Get park planner, wait insights & exclusive perks")
                        .font(.bodySmall())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            .padding(VelocitySpacing.sm)
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
                            .stroke((subscriptionService.currentTier == .free ? Color.nitroBlue : Color.pulseOrange).opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, VelocitySpacing.edgeMargin)
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

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    viewModel.searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }
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

    // MARK: - Search Results
    private var searchResultsSection: some View {
        VStack(spacing: VelocitySpacing.sm) {
            if viewModel.isSearching {
                HStack { Spacer(); ProgressView().tint(Color.nitroBlue); Spacer() }
                    .frame(height: 200)
            } else if viewModel.searchResults.isEmpty {
                VStack(spacing: VelocitySpacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.onSurfaceVariant.opacity(0.5))
                    Text("NO RESULTS")
                        .font(.headlineMedium())
                        .foregroundStyle(Color.onSurface)
                    Text("Try a different coaster or park name")
                        .font(.bodySmall())
                        .foregroundStyle(Color.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, VelocitySpacing.xl)
            } else {
                ForEach(viewModel.searchResults) { ride in
                    NavigationLink(destination: CoasterDetailView(rideId: ride.id)) {
                        searchResultRow(ride: ride)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    private func searchResultRow(ride: Ride) -> some View {
        HStack(spacing: VelocitySpacing.md) {
            // Thumbnail
            RoundedRectangle(cornerRadius: VelocityRadius.component)
                .fill(Color.velocitySurfaceContainerHighest)
                .frame(width: 56, height: 56)
                .overlay(
                    CoasterImage(ride: ride)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.component))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(ride.name.uppercased())
                    .font(.bodyLarge())
                    .fontWeight(.bold)
                    .foregroundStyle(Color.onSurface)
                    .lineLimit(1)

                if let park = ride.park {
                    Text("\(park.displayName)\(park.state.map { ", \($0)" } ?? "")")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(0.96)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let speed = ride.speed {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(speed)")
                        .font(.statValue())
                        .foregroundStyle(Color.nitroBlue)
                    Text("MPH")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .padding(VelocitySpacing.md)
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

    // MARK: - Quick Action Card (gradient border)
    private var quickActionCard: some View {
        Group {
            if let park = viewModel.nearestPark {
                NavigationLink(destination: SelectCoasterView(park: park)) {
                    quickActionCardContent(parkName: park.displayName)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    if viewModel.isLocationAuthorized {
                        showNoParkAlert = true
                    } else {
                        showLocationRequiredAlert = true
                    }
                } label: {
                    quickActionCardContent(parkName: nil)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    private func quickActionCardContent(parkName: String?) -> some View {
        // Gradient border wrapper
        RoundedRectangle(cornerRadius: VelocityRadius.xl)
            .fill(
                LinearGradient(
                    colors: [Color.nitroBlue, Color(hex: "#00677f")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(minHeight: 128)
            .overlay(
                RoundedRectangle(cornerRadius: VelocityRadius.xl - 1)
                    .fill(Color.velocitySurfaceContainerLowest)
                    .padding(1)
                    .overlay(
                        HStack(alignment: .center, spacing: VelocitySpacing.md) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("LIVE ACTION")
                                    .font(.labelCaps())
                                    .foregroundStyle(Color.nitroBlue)
                                    .tracking(2)
                                Text("Quick Check-In")
                                    .font(.headlineMedium())
                                    .foregroundStyle(Color.onSurface)
                                if let parkName {
                                    Text(parkName)
                                        .font(.bodyMedium())
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.nitroBlue)
                                }
                                Text(parkName != nil ? "Tap to check in at this park" : "At the park? Log your current ride instantly.")
                                    .font(.bodySmall())
                                    .foregroundStyle(Color.onSurfaceVariant)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

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
    }

    // MARK: - Nearby Section
    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            HStack {
                HStack(spacing: VelocitySpacing.xs) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.nitroBlue)
                    Text("NEARBY")
                        .font(sectionTitleFont)
                        .foregroundStyle(Color.onSurface)
                        .italic()
                }
                Spacer()
                Text("WITHIN 200 MI")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            if viewModel.isLoadingNearby {
                HStack { Spacer(); ProgressView().tint(Color.nitroBlue); Spacer() }
                    .frame(height: 280)
            } else if viewModel.nearbyRides.isEmpty {
                // Empty state — single card with coaster image
                ScrollView(.horizontal, showsIndicators: false) {
                    nearbyEmptyCard
                        .padding(.horizontal, VelocitySpacing.edgeMargin)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: VelocitySpacing.md) {
                        ForEach(viewModel.nearbyRides) { nearby in
                            NavigationLink(destination: CoasterDetailView(rideId: nearby.ride.id)) {
                                nearbyCard(nearby: nearby)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, VelocitySpacing.edgeMargin)
                }
            }
        }
    }

    // MARK: - Nearby Empty Card
    private var nearbyEmptyCard: some View {
        ZStack(alignment: .bottom) {
            // Coaster background image
            RoundedRectangle(cornerRadius: VelocityRadius.xl)
                .fill(Color.velocitySurfaceContainerHighest)
                .frame(width: 280, height: 280)
                .overlay(
                    Image("nearby_empty")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.5)
                        .frame(width: 280, height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))
                )

            // Bottom gradient
            LinearGradient(
                colors: [.clear, Color.velocityBackground.opacity(0.9), Color.velocityBackground],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))

            // Content overlay
            VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
                Image(systemName: "location.slash")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.onSurfaceVariant)

                Text("NO COASTERS NEARBY!")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)

                Text("There are no coasters within 200 miles of your current location. Time for a road trip!")
                    .font(.bodySmall())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .multilineTextAlignment(.leading)
            }
            .padding(VelocitySpacing.lg)
            .frame(width: 280, alignment: .leading)
        }
        .frame(width: 280, height: 280)
    }

    // MARK: - Nearby Card (matches Stitch Discover card style with distance badge)
    private func nearbyCard(nearby: NearbyRide) -> some View {
        ZStack(alignment: .bottom) {
            // Background image
            RoundedRectangle(cornerRadius: VelocityRadius.xl)
                .fill(Color.velocitySurfaceContainerHighest)
                .frame(width: 220, height: 280)
                .overlay(
                    CoasterImage(ride: nearby.ride)
                    .frame(width: 220, height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))
                )

            // Bottom gradient
            LinearGradient(
                colors: [.clear, Color.velocityBackground.opacity(0.9), Color.velocityBackground],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))

            // Distance badge (top-right)
            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text(nearby.distanceLabel)
                            .font(.labelCaps())
                            .tracking(0.96)
                    }
                    .foregroundStyle(Color.nitroBlue)
                    .padding(.horizontal, VelocitySpacing.xs)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.velocitySurfaceContainerLowest.opacity(0.8))
                            .background(Capsule().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
                            .overlay(Capsule().stroke(Color.nitroBlue.opacity(0.2), lineWidth: 1))
                    )
                    .padding(VelocitySpacing.sm)
                }
                Spacer()
            }

            // Content overlay
            VStack(alignment: .leading, spacing: 4) {
                Text(nearby.ride.name.uppercased())
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

                if let park = nearby.ride.park {
                    Text("\(park.displayName), \(park.state ?? "")")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(0.96)
                        .lineLimit(1)
                }

                // Quick stats
                HStack(spacing: VelocitySpacing.sm) {
                    if let speed = nearby.ride.speed {
                        HStack(spacing: 3) {
                            Text("\(speed)")
                                .font(.statValue())
                                .foregroundStyle(Color.nitroBlue)
                            Text("MPH")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.onSurfaceVariant)
                        }
                    }
                    if nearby.ride.speed != nil && nearby.ride.height != nil {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 1, height: 20)
                    }
                    if let height = nearby.ride.height {
                        HStack(spacing: 3) {
                            Text("\(height)")
                                .font(.statValue())
                                .foregroundStyle(Color.nitroBlue)
                            Text("FT")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.onSurfaceVariant)
                        }
                    }
                }
                .padding(.top, 2)
            }
            .padding(VelocitySpacing.md)
            .frame(width: 220, alignment: .leading)
        }
        .frame(width: 220, height: 280)
    }

    // MARK: - Trending Now
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            HStack {
                Text("TRENDING NOW")
                    .font(sectionTitleFont)
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
                    CoasterImage(ride: ride)
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
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

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

                    if ride.speed != nil, (ride.height != nil || ride.inversions != nil) {
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
                .font(sectionTitleFont)
                .foregroundStyle(Color.onSurface)
                .italic()
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
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

            Text("Version \(appMarketingVersion)")
                .font(.bodySmall())
                .foregroundStyle(Color.onSurfaceVariant.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, VelocitySpacing.edgeMargin)
        }
    }

    // MARK: - Top Rated Card (glass card with rank number, thumbnail, name, stars, credits)
    private func topRatedCard(ride: Ride, rank: Int) -> some View {
        HStack(spacing: VelocitySpacing.md) {
            // Thumbnail
            RoundedRectangle(cornerRadius: VelocityRadius.component)
                .fill(Color.velocitySurfaceContainerHighest)
                .frame(width: 80, height: 80)
                .overlay(
                    CoasterImage(ride: ride)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.component))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: VelocityRadius.component)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    Text(String(format: "%02d", rank))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.onNitroBlue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.nitroBlue)
                                .shadow(color: Color.nitroBlue.opacity(0.35), radius: 8)
                        )
                        .padding(6)
                }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(ride.name.uppercased())
                    .font(.bodyLarge())
                    .fontWeight(.bold)
                    .foregroundStyle(Color.onSurface)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

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
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: VelocitySpacing.xs)

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
