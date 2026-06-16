import SwiftUI
import MapKit

struct ParkDetailView: View {
    let park: Park
    @State private var rides: [Ride] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let rideService = RideService()
    private let profileService = ProfileService()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                bucketListButton
                    .padding(.top, VelocitySpacing.md)
                parkPlannerLink
                    .padding(.top, VelocitySpacing.sm)
                statsRow
                    .padding(.top, VelocitySpacing.md)
                parkIntelSection
                    .padding(.top, VelocitySpacing.xl)
                scheduleSection
                    .padding(.top, VelocitySpacing.xl)
                fleetInventorySection
                    .padding(.top, VelocitySpacing.xl)
                geospatialSection
                    .padding(.top, VelocitySpacing.xl)
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
        .task {
            await loadRides()
            await loadBucketListState()
        }
    }

    @State private var isOnBucketList = false
    @State private var bucketListLoading = false

    // MARK: - Bucket List Button
    private var bucketListButton: some View {
        Button {
            Task { await toggleBucketList() }
        } label: {
            HStack(spacing: VelocitySpacing.xs) {
                if bucketListLoading {
                    ProgressView().tint(isOnBucketList ? Color.pulseOrange : Color.nitroBlue)
                } else {
                    Image(systemName: isOnBucketList ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16))
                }
                Text(isOnBucketList ? "ON BUCKET LIST" : "ADD TO BUCKET LIST")
                    .font(.labelCaps())
                    .tracking(0.96)
            }
            .foregroundStyle(isOnBucketList ? Color.pulseOrange : Color.nitroBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, VelocitySpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: VelocityRadius.component)
                    .fill(isOnBucketList ? Color.pulseOrange.opacity(0.1) : Color.nitroBlue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: VelocityRadius.component)
                            .stroke((isOnBucketList ? Color.pulseOrange : Color.nitroBlue).opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .disabled(bucketListLoading)
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    private func loadBucketListState() async {
        do {
            guard let profile = try await profileService.fetchCurrentProfile() else { return }
            let list = try await profileService.fetchBucketList(profileId: profile.id)
            isOnBucketList = list.contains { $0.parkId == park.id }
        } catch {
            // Non-critical
        }
    }

    private func toggleBucketList() async {
        bucketListLoading = true
        do {
            guard let profile = try await profileService.fetchCurrentProfile() else { return }
            if isOnBucketList {
                try await profileService.removeFromBucketList(profileId: profile.id, parkId: park.id)
                isOnBucketList = false
            } else {
                try await profileService.addToBucketList(profileId: profile.id, parkId: park.id)
                isOnBucketList = true
            }
        } catch {
            // Non-critical
        }
        bucketListLoading = false
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Background image
            Rectangle()
                .fill(Color.velocitySurfaceContainerHighest)
                .frame(height: 320)
                .overlay(
                    Group {
                        if let url = park.mainImageURL, let imageURL = URL(string: url) {
                            AsyncImage(url: imageURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Image(systemName: "building.columns.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Color.nitroBlue.opacity(0.15))
                            }
                        } else {
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.nitroBlue.opacity(0.15))
                        }
                    }
                    .frame(height: 320)
                    .clipped()
                )

            // Gradient
            LinearGradient(
                colors: [.clear, Color.velocityBackground.opacity(0.6), Color.velocityBackground],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content
            VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
                // Status badge
                Text("LEGENDARY STATUS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.pulseOrange)
                    .tracking(1.5)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.pulseOrange.opacity(0.15))
                            .overlay(Capsule().stroke(Color.pulseOrange.opacity(0.3), lineWidth: 1))
                    )

                // Park name
                Text(park.displayName.uppercased())
                    .font(.headlineHero())
                    .foregroundStyle(Color.onSurface)
                    .italic()

                // Location
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                    Text("\(park.city ?? ""), \(park.state ?? "") • \(park.country ?? "")")
                        .font(.bodyMedium())
                }
                .foregroundStyle(Color.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, VelocitySpacing.edgeMargin)
            .padding(.bottom, VelocitySpacing.lg)
        }
        .frame(height: 320)
    }

    // MARK: - Park Planner Link
    private var parkPlannerLink: some View {
        NavigationLink(destination: ParkPlannerView(park: park)) {
            HStack(spacing: VelocitySpacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.pulseOrange.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "pencil.and.list.clipboard")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.pulseOrange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("PARK VISIT PLANNER")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurface)
                        .tracking(0.96)
                    Text("Build your ride itinerary")
                        .font(.bodySmall())
                        .foregroundStyle(Color.onSurfaceVariant)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("ELITE")
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(0.8)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.pulseOrange))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.onSurfaceVariant)
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
                            .stroke(Color.pulseOrange.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: VelocitySpacing.sm) {
            statChip(label: "COASTERS", value: "\(rides.count)", icon: "mountain.2")
            statChip(
                label: "STATUS",
                value: parkStatusLabel,
                icon: parkStatusIcon
            )
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    private enum ParkStatus { case open, closed, unknown }

    private var parkStatus: ParkStatus {
        let allHours = [park.mondayHours, park.tuesdayHours, park.wednesdayHours,
                        park.thursdayHours, park.fridayHours, park.saturdayHours, park.sundayHours]
        let hasAnyHours = allHours.contains { h in
            guard let h, !h.isEmpty, h != "null" else { return false }
            return true
        }
        guard hasAnyHours else { return .unknown }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let todayHours: String? = switch weekday {
        case 1: park.sundayHours
        case 2: park.mondayHours
        case 3: park.tuesdayHours
        case 4: park.wednesdayHours
        case 5: park.thursdayHours
        case 6: park.fridayHours
        case 7: park.saturdayHours
        default: nil
        }

        guard let hours = todayHours, !hours.isEmpty, hours != "null" else {
            return .closed
        }
        return .open
    }

    private var parkStatusLabel: String {
        switch parkStatus {
        case .open: "OPEN"
        case .closed: "CLOSED"
        case .unknown: "UNKNOWN"
        }
    }

    private var parkStatusIcon: String {
        switch parkStatus {
        case .open: "checkmark.circle"
        case .closed: "xmark.circle"
        case .unknown: "questionmark.circle"
        }
    }

    private func statChip(label: String, value: String, icon: String) -> some View {
        VStack(spacing: VelocitySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.nitroBlue)
            Text(value)
                .font(.statValue())
                .foregroundStyle(Color.onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .padding(.vertical, VelocitySpacing.md)
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

    // MARK: - Park Intel
    private var parkIntelSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            sectionHeader(title: "PARK INTEL", icon: "shield.checkered")

            VStack(alignment: .leading, spacing: VelocitySpacing.md) {
                if let desc = park.description, !desc.isEmpty, desc != "null" {
                    Text(desc)
                        .font(.bodyMedium())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .lineSpacing(4)
                } else {
                    Text("No intel available for this park yet.")
                        .font(.bodyMedium())
                        .foregroundStyle(Color.onSurfaceVariant.opacity(0.6))
                        .italic()
                }
            }
            .padding(VelocitySpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(glassCard)
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Mission Schedule (Hours)
    private var scheduleSection: some View {
        let days: [(label: String, hours: String?)] = [
            ("MONDAY", park.mondayHours),
            ("TUESDAY", park.tuesdayHours),
            ("WEDNESDAY", park.wednesdayHours),
            ("THURSDAY", park.thursdayHours),
            ("FRIDAY", park.fridayHours),
            ("SATURDAY", park.saturdayHours),
            ("SUNDAY", park.sundayHours),
        ]

        let hasAnyHours = days.contains { $0.hours != nil && $0.hours != "null" && !($0.hours ?? "").isEmpty }

        return VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            sectionHeader(title: "MISSION SCHEDULE", icon: "clock")

            VStack(spacing: 0) {
                if hasAnyHours {
                    ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                        HStack {
                            Text(day.label)
                                .font(.labelCaps())
                                .foregroundStyle(Color.onSurfaceVariant)
                                .tracking(0.96)
                                .frame(width: 110, alignment: .leading)
                            Spacer()
                            Text(day.hours ?? "Closed")
                                .font(.bodyMedium())
                                .foregroundStyle(day.hours != nil ? Color.onSurface : Color.onSurfaceVariant.opacity(0.5))
                        }
                        .padding(.vertical, VelocitySpacing.sm)
                        .padding(.horizontal, VelocitySpacing.lg)

                        if index < days.count - 1 {
                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 1)
                                .padding(.horizontal, VelocitySpacing.lg)
                        }
                    }
                } else {
                    Text("Hours not available")
                        .font(.bodyMedium())
                        .foregroundStyle(Color.onSurfaceVariant.opacity(0.6))
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(VelocitySpacing.lg)
                }
            }
            .frame(maxWidth: .infinity)
            .background(glassCard)
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Fleet Inventory (horizontal scroll like Nearby)
    private var fleetInventorySection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundStyle(Color.nitroBlue)
                Text("FLEET INVENTORY")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
                Spacer()
                Text("\(rides.count) COASTERS")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            if isLoading {
                HStack { Spacer(); ProgressView().tint(Color.nitroBlue); Spacer() }
                    .frame(height: 280)
            } else if rides.isEmpty {
                Text("No coasters registered at this park.")
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurfaceVariant.opacity(0.6))
                    .italic()
                    .padding(VelocitySpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(glassCard)
                    .padding(.horizontal, VelocitySpacing.edgeMargin)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: VelocitySpacing.md) {
                        ForEach(rides) { ride in
                            NavigationLink(destination: CoasterDetailView(rideId: ride.id)) {
                                fleetCard(ride: ride)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, VelocitySpacing.edgeMargin)
                }
            }
        }
    }

    private func fleetCard(ride: Ride) -> some View {
        ZStack(alignment: .bottom) {
            // Background image
            RoundedRectangle(cornerRadius: VelocityRadius.xl)
                .fill(Color.velocitySurfaceContainerHighest)
                .frame(width: 220, height: 280)
                .overlay(
                    CoasterImage(ride: ride)
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

            // Content overlay
            VStack(alignment: .leading, spacing: 4) {
                Text(ride.name.uppercased())
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

                if let manufacturer = ride.manufacturer, !manufacturer.isEmpty {
                    Text(manufacturer.uppercased())
                        .font(.labelCaps())
                        .foregroundStyle(Color.pulseOrange)
                        .tracking(0.96)
                        .lineLimit(1)
                }

                // Quick stats
                HStack(spacing: VelocitySpacing.sm) {
                    if let speed = ride.speed {
                        HStack(spacing: 3) {
                            Text("\(speed)")
                                .font(.statValue())
                                .foregroundStyle(Color.nitroBlue)
                            Text("MPH")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.onSurfaceVariant)
                        }
                    }
                    if ride.speed != nil && ride.height != nil {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 1, height: 20)
                    }
                    if let height = ride.height {
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

    // MARK: - Geospatial Coordinates
    private var geospatialSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            sectionHeader(title: "GEOSPATIAL COORDINATES", icon: "map")

            VStack(alignment: .leading, spacing: VelocitySpacing.md) {
                // Map
                if let lat = park.latitude.flatMap(Double.init),
                   let lon = park.longitude.flatMap(Double.init),
                   lat != 0, lon != 0 {
                    let region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                    Map(initialPosition: .region(region)) {
                        Marker(park.displayName, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                            .tint(Color.pulseOrange)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: VelocityRadius.card)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .colorScheme(.dark)

                    // Coordinates
                    HStack(spacing: VelocitySpacing.lg) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LATITUDE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.onSurfaceVariant)
                                .tracking(0.96)
                            Text(String(format: "%.4f° N", lat))
                                .font(.statValue())
                                .foregroundStyle(Color.nitroBlue)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LONGITUDE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.onSurfaceVariant)
                                .tracking(0.96)
                            Text(String(format: "%.4f° W", abs(lon)))
                                .font(.statValue())
                                .foregroundStyle(Color.nitroBlue)
                        }
                    }
                }

                // Address
                if let address = park.streetAddress, !address.isEmpty, address != "null" {
                    HStack(spacing: VelocitySpacing.xs) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.nitroBlue)
                        Text("\(address), \(park.city ?? ""), \(park.state ?? "") \(park.zip ?? "")")
                            .font(.bodySmall())
                            .foregroundStyle(Color.onSurfaceVariant)
                    }
                }

                // Action buttons
                HStack(spacing: VelocitySpacing.sm) {
                    // Navigate button
                    if let lat = park.latitude.flatMap(Double.init),
                       let lon = park.longitude.flatMap(Double.init),
                       lat != 0, lon != 0 {
                        Button {
                            let mapURL = URL(string: "maps://?daddr=\(lat),\(lon)")!
                            openURL(mapURL)
                        } label: {
                            HStack(spacing: VelocitySpacing.xs) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 14))
                                Text("NAVIGATE")
                                    .font(.labelCaps())
                                    .tracking(0.96)
                            }
                            .foregroundStyle(Color.onNitroBlueContainer)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, VelocitySpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: VelocityRadius.component)
                                    .fill(LinearGradient.nitroGradient)
                            )
                        }
                    }

                    // Website button
                    if let website = park.website, !website.isEmpty, website != "null",
                       let url = URL(string: website.hasPrefix("http") ? website : "https://\(website)") {
                        Button {
                            openURL(url)
                        } label: {
                            HStack(spacing: VelocitySpacing.xs) {
                                Image(systemName: "globe")
                                    .font(.system(size: 14))
                                Text("WEBSITE")
                                    .font(.labelCaps())
                                    .tracking(0.96)
                            }
                            .foregroundStyle(Color.nitroBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, VelocitySpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: VelocityRadius.component)
                                    .stroke(Color.nitroBlue.opacity(0.4), lineWidth: 1)
                            )
                        }
                    }
                }

                // Phone
                if let phone = park.phoneNumber, !phone.isEmpty, phone != "null" {
                    Button {
                        let cleaned = phone.replacingOccurrences(of: " ", with: "")
                        if let url = URL(string: "tel:\(cleaned)") {
                            openURL(url)
                        }
                    } label: {
                        HStack(spacing: VelocitySpacing.xs) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 14))
                            Text("SUPPORT")
                                .font(.labelCaps())
                                .tracking(0.96)
                        }
                        .foregroundStyle(Color.onSurfaceVariant)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, VelocitySpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: VelocityRadius.component)
                                .fill(Color.velocitySurfaceContainerHighest)
                        )
                    }
                }
            }
            .padding(VelocitySpacing.lg)
            .background(glassCard)
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Helpers
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: VelocitySpacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(Color.nitroBlue)
            Text(title)
                .font(.headlineMedium())
                .foregroundStyle(Color.onSurface)
            Spacer()
        }
    }

    private var glassCard: some View {
        RoundedRectangle(cornerRadius: VelocityRadius.xl)
            .fill(Color.velocitySurfaceContainerLow.opacity(0.6))
            .background(
                RoundedRectangle(cornerRadius: VelocityRadius.xl)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: VelocityRadius.xl)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }

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
