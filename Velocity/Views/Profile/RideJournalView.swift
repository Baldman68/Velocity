import SwiftUI

struct RideJournalView: View {
    let profileId: Int64
    @State private var viewModel = RideJournalViewModel()
    @State private var subscriptionService = SubscriptionService()
    @State private var showSubscription = false
    @State private var csvFileURL: URL?
    @State private var showShareSheet = false
    @Environment(\.dismiss) private var dismiss

    private var isPaid: Bool { subscriptionService.currentTier.isPaid }
    private let freePreviewLimit = 5

    var body: some View {
        ScrollView {
            VStack(spacing: VelocitySpacing.xl) {
                // Header stats
                headerStats

                // Personal Records
                if !viewModel.personalRecords.isEmpty {
                    personalRecordsSection
                }

                // Stats Breakdowns
                if !viewModel.allCheckIns.isEmpty {
                    breakdownsSection
                }

                // Search + Sort
                searchAndSort

                // Ride History List
                rideHistoryList
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
                        Text("VELOCITY")
                            .font(.custom("ArchivoNarrow-Bold", size: 18))
                            .italic()
                    }
                    .foregroundStyle(Color.nitroBlue)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isPaid && !viewModel.allCheckIns.isEmpty {
                    Button {
                        csvFileURL = generateCSV()
                        if csvFileURL != nil {
                            showShareSheet = true
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.nitroBlue)
                    }
                }
            }
        }
        .toolbarBackground(Color.velocitySurface.opacity(0.8), for: .navigationBar)
        .task {
            await subscriptionService.refreshCurrentTier()
            await viewModel.loadJournal(profileId: profileId)
        }
        .navigationDestination(isPresented: $showSubscription) {
            SubscriptionView()
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = csvFileURL {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: - Header Stats
    private var headerStats: some View {
        VStack(spacing: VelocitySpacing.md) {
            VStack(spacing: VelocitySpacing.xs) {
                Text("RIDE JOURNAL")
                    .font(.headlineHero())
                    .foregroundStyle(Color.nitroBlue)
                    .italic()
                Text("MISSION DOSSIER")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(1.5)
            }

            HStack(spacing: VelocitySpacing.sm) {
                headerStat(label: "TOTAL RIDES", value: "\(viewModel.totalRides)", icon: "checkmark.circle")
                headerStat(label: "UNIQUE COASTERS", value: "\(viewModel.uniqueCoasters)", icon: "mountain.2")
                headerStat(label: "PARKS", value: "\(viewModel.uniqueParks)", icon: "map")
            }
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
        .padding(.top, VelocitySpacing.md)
    }

    private func headerStat(label: String, value: String, icon: String) -> some View {
        VStack(spacing: VelocitySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.nitroBlue)
            Text(value)
                .font(.statValueLarge())
                .foregroundStyle(Color.onSurface)
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
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

    // MARK: - Personal Records
    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Color.pulseOrange)
                Text("PERSONAL RECORDS")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
                Spacer()
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: VelocitySpacing.sm) {
                    ForEach(viewModel.personalRecords) { record in
                        VStack(spacing: VelocitySpacing.xs) {
                            Image(systemName: record.icon)
                                .font(.system(size: 20))
                                .foregroundStyle(Color.pulseOrange)
                            Text(record.value)
                                .font(.statValueLarge())
                                .foregroundStyle(Color.onSurface)
                            Text(record.label)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color.onSurfaceVariant)
                                .tracking(0.96)
                            Text(record.rideName)
                                .font(.bodySmall())
                                .foregroundStyle(Color.nitroBlue)
                                .lineLimit(1)
                        }
                        .frame(width: 130)
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
                                        .stroke(Color.pulseOrange.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, VelocitySpacing.edgeMargin)
            }
        }
    }

    // MARK: - Breakdowns
    private var breakdownsSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.lg) {
            // By Park
            if !viewModel.byPark.isEmpty {
                breakdownList(title: "RIDES BY PARK", icon: "map", entries: Array(viewModel.byPark.prefix(5)))
            }

            // By Manufacturer
            if !viewModel.byManufacturer.isEmpty {
                breakdownList(title: "RIDES BY MANUFACTURER", icon: "wrench.and.screwdriver", entries: Array(viewModel.byManufacturer.prefix(5)))
            }

            // By Year
            if !viewModel.byYear.isEmpty {
                breakdownList(title: "RIDES BY YEAR", icon: "calendar", entries: viewModel.byYear)
            }
        }
    }

    private func breakdownList(title: String, icon: String, entries: [RideBreakdownEntry]) -> some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: icon)
                    .foregroundStyle(Color.nitroBlue)
                Text(title)
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)
                Spacer()
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    HStack {
                        Text(entry.name)
                            .font(.bodyMedium())
                            .foregroundStyle(Color.onSurface)
                            .lineLimit(1)
                        Spacer()
                        Text("\(entry.count)")
                            .font(.statValue())
                            .foregroundStyle(Color.nitroBlue)
                    }
                    .padding(.horizontal, VelocitySpacing.lg)
                    .padding(.vertical, VelocitySpacing.sm)

                    if index < entries.count - 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 1)
                            .padding(.horizontal, VelocitySpacing.lg)
                    }
                }
            }
            .background(
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
            )
            .padding(.horizontal, VelocitySpacing.edgeMargin)
        }
    }

    // MARK: - Search + Sort
    private var searchAndSort: some View {
        VStack(spacing: VelocitySpacing.sm) {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundStyle(Color.nitroBlue)
                Text("RIDE HISTORY")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
                Spacer()
                Text("\(viewModel.filteredCheckIns.count) ENTRIES")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            // Search bar
            HStack(spacing: VelocitySpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.onSurfaceVariant)
                TextField("Search rides, parks, manufacturers...", text: $viewModel.searchText)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurface)
            }
            .padding(.horizontal, VelocitySpacing.md)
            .padding(.vertical, VelocitySpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: VelocityRadius.component)
                    .fill(Color.velocitySurfaceContainerLowest)
                    .overlay(
                        RoundedRectangle(cornerRadius: VelocityRadius.component)
                            .stroke(Color.velocityOutlineVariant.opacity(0.5), lineWidth: 1)
                    )
            )
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            // Sort options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: VelocitySpacing.xs) {
                    ForEach(JournalSortOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.sortOption = option
                        } label: {
                            Text(option.rawValue.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(viewModel.sortOption == option ? Color.onNitroBlue : Color.onSurfaceVariant)
                                .padding(.horizontal, VelocitySpacing.md)
                                .padding(.vertical, VelocitySpacing.xs)
                                .background(
                                    Capsule()
                                        .fill(viewModel.sortOption == option ? Color.nitroBlue : Color.velocitySurfaceContainerHighest)
                                )
                        }
                    }
                }
                .padding(.horizontal, VelocitySpacing.edgeMargin)
            }
        }
    }

    // MARK: - Ride History List
    private var rideHistoryList: some View {
        let checkIns = viewModel.filteredCheckIns
        let visibleCheckIns = isPaid ? checkIns : Array(checkIns.prefix(freePreviewLimit))

        return VStack(spacing: VelocitySpacing.sm) {
            if viewModel.isLoading {
                ProgressView().tint(Color.nitroBlue)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if checkIns.isEmpty {
                VStack(spacing: VelocitySpacing.md) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.onSurfaceVariant.opacity(0.3))
                    Text("No rides logged yet")
                        .font(.bodyMedium())
                        .foregroundStyle(Color.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ForEach(visibleCheckIns) { checkIn in
                    journalRow(checkIn: checkIn)
                }

                // Free tier paywall
                if !isPaid && checkIns.count > freePreviewLimit {
                    paywallCard(remaining: checkIns.count - freePreviewLimit)
                }
            }
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    private func journalRow(checkIn: ProfileRide) -> some View {
        HStack(spacing: VelocitySpacing.md) {
            // Coaster image
            ZStack {
                RoundedRectangle(cornerRadius: VelocityRadius.component)
                    .fill(Color.velocitySurfaceContainerHighest)
                    .frame(width: 56, height: 56)
                if let ride = checkIn.ride {
                    CoasterImage(ride: ride)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.component))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(checkIn.ride?.name.uppercased() ?? "UNKNOWN")
                    .font(.bodyLarge())
                    .fontWeight(.bold)
                    .foregroundStyle(Color.onSurface)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let park = checkIn.ride?.park?.name {
                        Text(park.uppercased())
                            .lineLimit(1)
                    }
                    if let date = checkIn.createdDate {
                        Text("•")
                        Text(date.relativeString)
                    }
                }
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)

                // Details row
                HStack(spacing: VelocitySpacing.sm) {
                    if let score = checkIn.score {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.pulseOrange)
                            Text("\(score)")
                                .font(.labelCaps())
                                .foregroundStyle(Color.onSurfaceVariant)
                        }
                    }
                    if let wait = checkIn.waitTime {
                        Text("\(wait)m wait")
                            .font(.labelCaps())
                            .foregroundStyle(Color.onSurfaceVariant)
                    }
                    if let seat = checkIn.seatRow, !seat.isEmpty {
                        Text(seat)
                            .font(.labelCaps())
                            .foregroundStyle(Color.onSurfaceVariant)
                    }
                }
            }

            Spacer()

            if let speed = checkIn.ride?.speed {
                VStack(spacing: 0) {
                    Text("\(speed)")
                        .font(.statValue())
                        .foregroundStyle(Color.nitroBlue)
                    Text("MPH")
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

    // MARK: - Paywall Card
    private func paywallCard(remaining: Int) -> some View {
        VStack(spacing: VelocitySpacing.md) {
            Image(systemName: "lock.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.nitroBlue)

            Text("\(remaining) MORE RIDES")
                .font(.headlineMedium())
                .foregroundStyle(Color.onSurface)

            Text("Upgrade to PRO to see your full ride history, detailed stats, and personal records.")
                .font(.bodySmall())
                .foregroundStyle(Color.onSurfaceVariant)
                .multilineTextAlignment(.center)

            Button {
                showSubscription = true
            } label: {
                HStack(spacing: VelocitySpacing.xs) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                    Text("UPGRADE TO PRO")
                        .font(.labelCaps())
                        .tracking(0.96)
                }
                .foregroundStyle(Color.onNitroBlueContainer)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: VelocityRadius.xl)
                        .fill(LinearGradient.nitroGradient)
                )
                .shadow(color: Color.nitroBlue.opacity(0.3), radius: 12, y: 4)
            }
        }
        .padding(VelocitySpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: VelocityRadius.xl)
                .fill(Color.velocitySurfaceContainerLow.opacity(0.8))
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

    // MARK: - CSV Export
    private func generateCSV() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var csv = "Date,Coaster,Park,Speed (MPH),Height (FT),G-Force,Inversions,Wait Time (min),Seat Row,Score,Comments\n"

        for checkIn in viewModel.allCheckIns {
            let date = checkIn.createdDate.map { dateFormatter.string(from: $0) } ?? ""
            let coaster = escapeCSV(checkIn.ride?.name ?? "")
            let park = escapeCSV(checkIn.ride?.park?.name ?? "")
            let speed = checkIn.ride?.speed.map { "\($0)" } ?? ""
            let height = checkIn.ride?.height.map { "\($0)" } ?? ""
            let gForce = checkIn.ride?.gForce.map { String(format: "%.1f", $0) } ?? ""
            let inversions = checkIn.ride?.inversions.map { "\($0)" } ?? ""
            let waitTime = checkIn.waitTime.map { "\($0)" } ?? ""
            let seatRow = escapeCSV(checkIn.seatRow ?? "")
            let score = checkIn.score.map { "\($0)" } ?? ""
            let comments = escapeCSV(checkIn.comments ?? "")

            csv += "\(date),\(coaster),\(park),\(speed),\(height),\(gForce),\(inversions),\(waitTime),\(seatRow),\(score),\(comments)\n"
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("VelocityRideJournal.csv")
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

// MARK: - Share Sheet (UIKit wrapper)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
