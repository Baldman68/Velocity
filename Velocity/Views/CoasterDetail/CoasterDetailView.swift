import SwiftUI

struct CoasterDetailView: View {
    let rideId: Int64
    @State private var viewModel = CoasterDetailViewModel()
    @State private var checkInComment = ""
    @State private var checkInScore: Int16 = 5
    @State private var reviewText = ""
    @State private var reviewStars: Int16 = 5

    // Edit sheet fields
    @State private var editName = ""
    @State private var editDescription = ""
    @State private var editStreetAddress = ""
    @State private var editCity = ""
    @State private var editState = ""
    @State private var editZip = ""
    @State private var editCountry = ""
    @State private var editWebsite = ""
    @State private var editPhone = ""
    @State private var editEmail = ""
    @State private var editImageURL = ""
    @State private var editReason = ""
    @State private var editParkName = ""
    @State private var isSubmittingEdit = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                checkInOverlapButton
                statsGrid
                technicalDossier
                suggestEditsButton
                missionReports
            }
            .padding(.bottom, 100)
        }
        .background(Color.velocityBackground)
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.velocitySurface.opacity(0.8), for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("VELOCITY")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.nitroBlue)
                    .italic()
                    .tracking(-0.5)
            }
        }
        .task { await viewModel.loadRide(id: rideId) }
        .sheet(isPresented: $viewModel.showCheckInSheet) { checkInSheet }
        .sheet(isPresented: $viewModel.showReviewSheet) { reviewSheet }
        .sheet(isPresented: $viewModel.showEditSheet) { editCoasterSheet }
    }

    // MARK: - Hero Section (530px tall, badges, title)
    private var heroSection: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                // Hero image
                ZStack {
                    Rectangle().fill(Color.velocitySurfaceContainerHighest)
                    if let ride = viewModel.ride {
                        CoasterImage(ride: ride)
                            .frame(width: proxy.size.width, height: 530)
                    }
                }
                .frame(width: proxy.size.width, height: 530)
                .clipped()

                // Gradient overlay
                LinearGradient(
                    colors: [.clear, Color.velocityBackground.opacity(0.4), Color.velocityBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: proxy.size.width, height: 530)

                // Title + badges
                VStack(alignment: .leading, spacing: VelocitySpacing.base) {
                    // Badges row
                    HStack(spacing: VelocitySpacing.xs) {
                        if let manufacturer = viewModel.ride?.manufacturer, !manufacturer.isEmpty {
                            Text(manufacturer.uppercased())
                                .font(.labelCaps())
                                .tracking(0.96)
                                .foregroundStyle(Color.onPulseOrange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.pulseOrange)
                                )
                        }

                        if let ride = viewModel.ride, ride.starRating > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                Text(String(format: "%.1f", ride.starRating))
                            }
                            .font(.labelCaps())
                            .foregroundStyle(Color.onSurface)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.velocitySurfaceContainerHighest.opacity(0.6))
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(.ultraThinMaterial)
                                            .environment(\.colorScheme, .dark)
                                    )
                            )
                        }
                    }

                    Text(viewModel.ride?.name.uppercased() ?? "LOADING...")
                        .font(.headlineHero())
                        .foregroundStyle(Color.onSurface)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let park = viewModel.ride?.park {
                        NavigationLink(destination: ParkDetailView(park: park)) {
                            HStack(spacing: 4) {
                                Text("\(park.displayName) • \(park.city ?? ""), \(park.state ?? "")")
                                    .font(.bodyLarge())
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(Color.nitroBlue)
                        }
                    }
                }
                .padding(.horizontal, VelocitySpacing.edgeMargin)
                .padding(.bottom, VelocitySpacing.xl + VelocitySpacing.lg)
                .frame(width: proxy.size.width, alignment: .leading)
            }
            .frame(width: proxy.size.width, height: 560)
        }
        .frame(height: 560)
    }
    // MARK: - Check-In Overlap Button (overlaps hero bottom by -24px)
    private var checkInOverlapButton: some View {
        VStack(spacing: VelocitySpacing.xs) {
            Button {
                guard viewModel.checkInLocationStatus.canCheckIn else { return }
                viewModel.showCheckInSheet = true
            } label: {
                HStack(spacing: VelocitySpacing.xs) {
                    Image(systemName: checkInButtonIcon)
                        .font(.system(size: 20))
                    Text("Check-In to Ride")
                        .font(.labelCaps())
                        .tracking(0.96)
                }
                .foregroundStyle(
                    viewModel.checkInLocationStatus.canCheckIn
                        ? Color.onNitroBlueContainer
                        : Color.onSurfaceVariant
                )
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    viewModel.checkInLocationStatus.canCheckIn
                        ? Color.nitroBlue
                        : Color.velocitySurfaceContainerHighest
                )
                .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))
                .shadow(
                    color: viewModel.checkInLocationStatus.canCheckIn
                        ? Color.nitroBlue.opacity(0.2)
                        : .clear,
                    radius: 16,
                    y: 4
                )
            }
            .disabled(!viewModel.checkInLocationStatus.canCheckIn)

            if let checkInLocationMessage {
                VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
                    HStack(alignment: .top, spacing: VelocitySpacing.xs) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.nitroBlue)
                            .padding(.top, 2)
                        Text(checkInLocationMessage)
                            .font(.bodySmall())
                            .foregroundStyle(Color.onSurfaceVariant)
                            .multilineTextAlignment(.leading)
                    }

                    if viewModel.checkInLocationStatus == .locationPermissionNeeded {
                        Button {
                            viewModel.requestLocationPermission()
                        } label: {
                            Text("ENABLE LOCATION")
                                .font(.labelCaps())
                                .tracking(0.96)
                                .foregroundStyle(Color.nitroBlue)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(VelocitySpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: VelocityRadius.card)
                        .fill(Color.velocitySurfaceContainerLow.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: VelocityRadius.card)
                                .stroke(Color.velocityOutlineVariant.opacity(0.4), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
        .offset(y: -24)
    }

    private var checkInButtonIcon: String {
        switch viewModel.checkInLocationStatus {
        case .allowed:
            "checkmark.circle.fill"
        case .checking:
            "location.fill"
        default:
            "lock.fill"
        }
    }

    private var checkInLocationMessage: String? {
        switch viewModel.checkInLocationStatus {
        case .waitingForRide:
            nil
        case .checking:
            "Checking your location before enabling ride check-in."
        case .allowed:
            nil
        case .notNearPark(let distanceMiles):
            "You need to be in or near \(viewModel.ride?.park?.displayName ?? "this park") to check in. You're about \(formattedDistance(distanceMiles)) away."
        case .locationPermissionNeeded:
            "Turn on Location Services for Velocity so we can confirm you're at the park before check-in."
        case .locationUnavailable:
            "We could not determine your location. Turn on Location Services and try again before checking in."
        case .parkLocationUnavailable:
            "This park does not have location data yet, so check-in is unavailable."
        }
    }

    private func formattedDistance(_ distanceMiles: Double) -> String {
        if distanceMiles < 10 {
            return String(format: "%.1f miles", distanceMiles)
        }

        return "\(Int(distanceMiles.rounded())) miles"
    }

    // MARK: - Stats Bento Grid (2-col glass cards)
    private var statsGrid: some View {
        Group {
            if let ride = viewModel.ride {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: VelocitySpacing.gutter) {
                    if let height = ride.height {
                        statCell(label: "HEIGHT", value: "\(height) FT")
                    }
                    if let speed = ride.speed {
                        statCell(label: "SPEED", value: "\(speed) MPH")
                    }
                    if let gForce = ride.gForce {
                        statCell(label: "G-FORCE", value: String(format: "%.1f G", gForce), accent: true)
                    }
                    if let inversions = ride.inversions {
                        statCell(label: "INVERSIONS", value: "\(inversions)")
                    }
                    if let trackLength = ride.trackLength {
                        statCell(label: "TRACK LENGTH", value: "\(trackLength) FT")
                    }
                }
                .padding(.horizontal, VelocitySpacing.edgeMargin)
            }
        }
    }

    private func statCell(label: String, value: String, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
            Text(label)
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)
            Text(value)
                .font(.statValue())
                .foregroundStyle(Color.nitroBlue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .overlay(alignment: .leading) {
            if accent {
                Rectangle()
                    .fill(Color.pulseOrange)
                    .frame(width: 2)
                    .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Technical Dossier
    private var technicalDossier: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: "gearshape.2")
                    .foregroundStyle(Color.nitroBlue)
                Text("Technical Dossier")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
            }

            VStack(alignment: .leading, spacing: VelocitySpacing.lg) {
                // Manufacturer row
                if let manufacturer = viewModel.ride?.manufacturer, !manufacturer.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: VelocitySpacing.base) {
                            Text("MANUFACTURER")
                                .font(.labelCaps())
                                .foregroundStyle(Color.onSurfaceVariant)
                                .tracking(0.96)
                            Text(manufacturer)
                                .font(.bodyLarge())
                                .fontWeight(.bold)
                                .foregroundStyle(Color.onSurface)
                        }
                        Spacer()
                    }
                }

                // Divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.onSurfaceVariant.opacity(0.2), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                // Description
                if let desc = viewModel.ride?.description, !desc.isEmpty {
                    Text(desc)
                        .font(.bodyMedium())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .lineSpacing(4)
                }
            }
            .padding(VelocitySpacing.lg)
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
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
        .padding(.top, VelocitySpacing.xl)
    }

    // MARK: - Suggest Edits Button
    private var suggestEditsButton: some View {
        Button {
            prepareEditFields()
            viewModel.showEditSheet = true
        } label: {
            HStack(spacing: VelocitySpacing.sm) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.nitroBlue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Suggest Edits")
                        .font(.bodyLarge())
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.onSurface)
                    Text("Help improve this coaster's data")
                        .font(.bodySmall())
                        .foregroundStyle(Color.onSurfaceVariant)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
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
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, VelocitySpacing.edgeMargin)
        .padding(.top, VelocitySpacing.lg)
    }

    private func prepareEditFields() {
        let ride = viewModel.ride
        let park = ride?.park
        editName = ride?.name ?? ""
        editDescription = ride?.description ?? ""
        editStreetAddress = park?.streetAddress ?? ""
        editCity = park?.city ?? ""
        editState = park?.state ?? ""
        editZip = park?.zip ?? ""
        editCountry = park?.country ?? ""
        editWebsite = park?.website ?? ""
        editPhone = park?.phoneNumber ?? ""
        editEmail = park?.email ?? ""
        editImageURL = ride?.mainImageURL ?? ""
        editParkName = ride?.park?.displayName ?? ""
        editReason = ""
        isSubmittingEdit = false
    }

    // MARK: - Mission Reports (Reviews)
    private var missionReports: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            HStack {
                HStack(spacing: VelocitySpacing.xs) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(Color.pulseOrange)
                    Text("Mission Reports")
                        .font(.headlineMedium())
                        .foregroundStyle(Color.onSurface)
                }
                Spacer()
                Button {
                    viewModel.showReviewSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Text("ADD REPORT")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .font(.labelCaps())
                    .foregroundStyle(Color.nitroBlue)
                    .tracking(0.96)
                }
            }

            if viewModel.reviews.isEmpty {
                Text("No mission reports yet. Be the first to file one!")
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .padding(.vertical, VelocitySpacing.lg)
            } else {
                VStack(spacing: VelocitySpacing.md) {
                    ForEach(viewModel.reviews) { review in
                        ReviewCard(review: review)
                    }
                }
            }
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
        .padding(.top, VelocitySpacing.xl)
    }

    // MARK: - Check-In Sheet
    private var checkInSheet: some View {
        NavigationStack {
            VStack(spacing: VelocitySpacing.lg) {
                Text("CHECK IN")
                    .font(.headlineLarge())
                    .foregroundStyle(Color.nitroBlue)

                Text(viewModel.ride?.name ?? "")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)

                // Score picker
                VStack(spacing: VelocitySpacing.xs) {
                    Text("YOUR SCORE")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(0.96)

                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                checkInScore = Int16(star)
                            } label: {
                                Image(systemName: star <= Int(checkInScore) ? "star.fill" : "star")
                                    .font(.system(size: 32))
                                    .foregroundStyle(star <= Int(checkInScore) ? Color.pulseOrange : Color.velocityOutlineVariant)
                            }
                        }
                    }
                }

                // Comment
                VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
                    Text("COMMENTS")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(0.96)

                    TextField("How was the ride?", text: $checkInComment, axis: .vertical)
                        .font(.bodyMedium())
                        .foregroundStyle(Color.onSurface)
                        .lineLimit(3...6)
                        .padding(VelocitySpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: VelocityRadius.component)
                                .fill(Color.velocitySurfaceContainerLowest)
                                .overlay(
                                    RoundedRectangle(cornerRadius: VelocityRadius.component)
                                        .stroke(Color.velocityOutlineVariant.opacity(0.5), lineWidth: 1)
                                )
                        )
                }

                Spacer()

                Button {
                    Task {
                        await viewModel.checkIn(
                            profileId: 1, // TODO: use actual profile ID
                            rideId: rideId,
                            comments: checkInComment.isEmpty ? nil : checkInComment,
                            score: checkInScore
                        )
                    }
                } label: {
                    HStack(spacing: VelocitySpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("CONFIRM CHECK-IN")
                            .font(.labelCaps())
                            .tracking(0.96)
                    }
                    .foregroundStyle(Color.onNitroBlueContainer)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.nitroBlue)
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))
                }
            }
            .padding(VelocitySpacing.edgeMargin)
            .background(Color.velocityBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.showCheckInSheet = false }
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.velocityBackground)
    }

    // MARK: - Review Sheet
    private var reviewSheet: some View {
        NavigationStack {
            VStack(spacing: VelocitySpacing.lg) {
                Text("FILE REPORT")
                    .font(.headlineLarge())
                    .foregroundStyle(Color.nitroBlue)

                // Star rating
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            reviewStars = Int16(star)
                        } label: {
                            Image(systemName: star <= Int(reviewStars) ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundStyle(star <= Int(reviewStars) ? Color.pulseOrange : Color.velocityOutlineVariant)
                        }
                    }
                }

                // Review text
                TextField("Write your mission report...", text: $reviewText, axis: .vertical)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurface)
                    .lineLimit(5...10)
                    .padding(VelocitySpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: VelocityRadius.component)
                            .fill(Color.velocitySurfaceContainerLowest)
                            .overlay(
                                RoundedRectangle(cornerRadius: VelocityRadius.component)
                                    .stroke(Color.velocityOutlineVariant.opacity(0.5), lineWidth: 1)
                            )
                    )

                Spacer()

                Button {
                    Task {
                        await viewModel.submitReview(
                            profileId: 1, // TODO: use actual profile ID
                            rideId: rideId,
                            text: reviewText,
                            stars: reviewStars
                        )
                    }
                } label: {
                    Text("SUBMIT REPORT")
                        .font(.labelCaps())
                        .tracking(0.96)
                        .foregroundStyle(Color.onNitroBlueContainer)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.nitroBlue)
                        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))
                }
            }
            .padding(VelocitySpacing.edgeMargin)
            .background(Color.velocityBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.showReviewSheet = false }
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Color.velocityBackground)
    }

    // MARK: - Edit Coaster Sheet
    private var editCoasterSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VelocitySpacing.lg) {
                    // Header with park + coaster name
                    VStack(spacing: VelocitySpacing.xs) {
                        if let park = viewModel.ride?.park {
                            Text(park.displayName.uppercased())
                                .font(.labelCaps())
                                .foregroundStyle(Color.onSurfaceVariant)
                                .tracking(0.96)
                        }
                        Text(viewModel.ride?.name.uppercased() ?? "")
                            .font(.headlineLarge())
                            .foregroundStyle(Color.nitroBlue)
                            .italic()
                        Text("ID: \(viewModel.ride.map { String($0.id) } ?? "—")")
                            .font(.labelCaps())
                            .foregroundStyle(Color.onSurfaceVariant)
                            .tracking(0.96)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, VelocitySpacing.sm)

                    // Explanation banner
                    HStack(alignment: .top, spacing: VelocitySpacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.nitroBlue)
                            .padding(.top, 2)
                        Text("Submit corrections or updated details for this coaster. Our team will review your changes and update the data if valid.")
                            .font(.bodySmall())
                            .foregroundStyle(Color.onSurfaceVariant)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(VelocitySpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: VelocityRadius.card)
                            .fill(Color.nitroBlue.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: VelocityRadius.card)
                                    .stroke(Color.nitroBlue.opacity(0.2), lineWidth: 1)
                            )
                    )

                    // Missing park callout
                    if viewModel.ride?.park == nil {
                        HStack(alignment: .top, spacing: VelocitySpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.pulseOrange)
                                .padding(.top, 2)
                            Text("This coaster isn't linked to a park yet. If you know which park it belongs to, enter the park name below to help us out!")
                                .font(.bodySmall())
                                .foregroundStyle(Color.onSurfaceVariant)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(VelocitySpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: VelocityRadius.card)
                                .fill(Color.pulseOrange.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: VelocityRadius.card)
                                        .stroke(Color.pulseOrange.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }

                    // Park suggestion
                    editSection(title: "PARK") {
                        editField(label: "PARK NAME", icon: "building.columns", text: $editParkName)
                    }

                    // Coaster Info section
                    editSection(title: "COASTER INFO") {
                        editField(label: "NAME", icon: "mountain.2", text: $editName)
                        editField(label: "DESCRIPTION", icon: "text.alignleft", text: $editDescription, multiline: true)
                        editField(label: "IMAGE URL", icon: "photo", text: $editImageURL)
                    }

                    // Park Location section
                    editSection(title: "PARK LOCATION") {
                        editField(label: "STREET ADDRESS", icon: "mappin.circle", text: $editStreetAddress)
                        HStack(spacing: VelocitySpacing.sm) {
                            editField(label: "CITY", icon: "building.2", text: $editCity)
                            editField(label: "STATE", icon: "map", text: $editState)
                                .frame(width: 100)
                        }
                        HStack(spacing: VelocitySpacing.sm) {
                            editField(label: "ZIP", icon: "number", text: $editZip)
                                .frame(width: 120)
                            editField(label: "COUNTRY", icon: "globe", text: $editCountry)
                        }
                    }

                    // Contact section
                    editSection(title: "CONTACT") {
                        editField(label: "WEBSITE", icon: "link", text: $editWebsite)
                        editField(label: "PHONE", icon: "phone", text: $editPhone)
                        editField(label: "EMAIL", icon: "envelope", text: $editEmail)
                    }

                    // Reason for edit
                    editSection(title: "REASON FOR EDIT") {
                        TextField("Why are you suggesting this change?", text: $editReason, axis: .vertical)
                            .font(.bodyMedium())
                            .foregroundStyle(Color.onSurface)
                            .lineLimit(3...6)
                            .padding(VelocitySpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: VelocityRadius.component)
                                    .fill(Color.velocitySurfaceContainerLowest)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: VelocityRadius.component)
                                            .stroke(Color.velocityOutlineVariant.opacity(0.5), lineWidth: 1)
                                    )
                            )
                    }

                    // Submit button
                    Button {
                        isSubmittingEdit = true
                        Task {
                            await viewModel.submitEditRequest(
                                profileId: 1,
                                name: editName.isEmpty ? nil : editName,
                                description: [
                                    editParkName.isEmpty ? nil : "Suggested Park: \(editParkName)",
                                    editDescription.isEmpty ? nil : editDescription,
                                    editReason.isEmpty ? nil : "Reason: \(editReason)"
                                ].compactMap { $0 }.joined(separator: " | "),
                                streetAddress: editStreetAddress.isEmpty ? nil : editStreetAddress,
                                city: editCity.isEmpty ? nil : editCity,
                                state: editState.isEmpty ? nil : editState,
                                zip: editZip.isEmpty ? nil : editZip,
                                country: editCountry.isEmpty ? nil : editCountry,
                                phoneNumber: editPhone.isEmpty ? nil : editPhone,
                                website: editWebsite.isEmpty ? nil : editWebsite,
                                email: editEmail.isEmpty ? nil : editEmail,
                                mainImageURL: editImageURL.isEmpty ? nil : editImageURL
                            )
                            isSubmittingEdit = false
                        }
                    } label: {
                        HStack(spacing: VelocitySpacing.xs) {
                            if isSubmittingEdit {
                                ProgressView().tint(Color.onNitroBlueContainer)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16))
                            }
                            Text("SUBMIT CHANGES")
                                .font(.labelCaps())
                                .tracking(0.96)
                        }
                        .foregroundStyle(Color.onNitroBlueContainer)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: VelocityRadius.xl)
                                .fill(LinearGradient.nitroGradient)
                        )
                        .shadow(color: Color.nitroBlue.opacity(0.3), radius: 16, y: 4)
                    }
                    .disabled(isSubmittingEdit)

                    // Admin review notice
                    HStack(spacing: VelocitySpacing.xs) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.onSurfaceVariant)
                        Text("Submissions are reviewed by the Velocity team.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.onSurfaceVariant)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, VelocitySpacing.edgeMargin)
                .padding(.bottom, VelocitySpacing.xl)
            }
            .background(Color.velocityBackground)
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SUGGEST EDITS")
                        .font(.headlineMedium())
                        .foregroundStyle(Color.nitroBlue)
                        .italic()
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.showEditSheet = false }
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Color.velocityBackground)
    }

    // MARK: - Edit Sheet Helpers
    private func editSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            Text(title)
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)
            content()
        }
    }

    private func editField(label: String, icon: String, text: Binding<String>, multiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.base) {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.nitroBlue)
                    .frame(width: 20)
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)
            }

            if multiline {
                TextField(label.capitalized, text: text, axis: .vertical)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurface)
                    .lineLimit(3...6)
                    .padding(VelocitySpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: VelocityRadius.component)
                            .fill(Color.velocitySurfaceContainerLowest)
                            .overlay(
                                RoundedRectangle(cornerRadius: VelocityRadius.component)
                                    .stroke(Color.velocityOutlineVariant.opacity(0.5), lineWidth: 1)
                            )
                    )
            } else {
                TextField(label.capitalized, text: text)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurface)
                    .padding(VelocitySpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: VelocityRadius.component)
                            .fill(Color.velocitySurfaceContainerLowest)
                            .overlay(
                                RoundedRectangle(cornerRadius: VelocityRadius.component)
                                    .stroke(Color.velocityOutlineVariant.opacity(0.5), lineWidth: 1)
                            )
                    )
            }
        }
    }
}

// MARK: - Review Card
struct ReviewCard: View {
    let review: ProfileRideReview

    var body: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            // Header: avatar + name + time + stars
            HStack {
                Circle()
                    .fill(Color.velocitySurfaceContainerHighest)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(review.profile?.displayName.prefix(1).uppercased() ?? "?")
                            .font(.labelCaps())
                            .foregroundStyle(Color.nitroBlue)
                    )

                VStack(alignment: .leading, spacing: 0) {
                    Text(review.profile?.displayName ?? "Anonymous")
                        .font(.bodyMedium())
                        .fontWeight(.bold)
                        .foregroundStyle(Color.onSurface)

                    if let date = review.createdDate {
                        Text(date.relativeString.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.onSurfaceVariant)
                            .tracking(0.6)
                    }
                }

                Spacer()

                // Stars
                if let stars = review.stars {
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: i < Int(stars) ? "star.fill" : "star")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.pulseOrange)
                        }
                    }
                }
            }

            // Review text (italic per design)
            Text("\"\(review.reviewText)\"")
                .font(.bodyMedium())
                .italic()
                .foregroundStyle(Color.onSurfaceVariant)
                .lineSpacing(2)
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
