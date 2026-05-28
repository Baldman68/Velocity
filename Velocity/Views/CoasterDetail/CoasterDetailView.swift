import SwiftUI

struct CoasterDetailView: View {
    let rideId: Int64
    @State private var viewModel = CoasterDetailViewModel()
    @State private var checkInComment = ""
    @State private var checkInScore: Int16 = 5
    @State private var reviewText = ""
    @State private var reviewStars: Int16 = 5

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                checkInOverlapButton
                statsGrid
                technicalDossier
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
    }

    // MARK: - Hero Section (530px tall, badges, title)
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Hero image
            ZStack {
                Rectangle().fill(Color.velocitySurfaceContainerHighest)
                if let url = viewModel.ride?.mainImageURL, let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "figure.roller.coaster")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.nitroBlue.opacity(0.2))
                    }
                }
            }
            .frame(height: 530)
            .clipped()

            // Gradient overlay
            LinearGradient(
                colors: [.clear, Color.velocityBackground.opacity(0.4), Color.velocityBackground],
                startPoint: .top,
                endPoint: .bottom
            )

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

                if let park = viewModel.ride?.park {
                    Text("\(park.displayName) • \(park.city ?? ""), \(park.state ?? "")")
                        .font(.bodyLarge())
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
            .padding(.bottom, VelocitySpacing.lg)
        }
        .frame(height: 530)
    }

    // MARK: - Check-In Overlap Button (overlaps hero bottom by -24px)
    private var checkInOverlapButton: some View {
        Button { viewModel.showCheckInSheet = true } label: {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                Text("Check-In to Ride")
                    .font(.labelCaps())
                    .tracking(0.96)
            }
            .foregroundStyle(Color.onNitroBlueContainer)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.nitroBlue)
            .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))
            .shadow(color: Color.nitroBlue.opacity(0.2), radius: 16, y: 4)
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
        .offset(y: -24)
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
