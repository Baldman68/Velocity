import SwiftUI

struct CoasterDetailView: View {
    let rideId: Int64
    @State private var viewModel = CoasterDetailViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    contentSection
                }
                .padding(.bottom, 100)
            }

            // Floating Check-In Button
            checkInButton
        }
        .background(Color.velocityBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .task { await viewModel.loadRide(id: rideId) }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Hero image
            ZStack {
                Rectangle()
                    .fill(Color.velocitySurfaceContainerHighest)
                    .frame(height: 320)

                if let url = viewModel.ride?.mainImageURL, let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "figure.roller.coaster")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.nitroBlue.opacity(0.3))
                    }
                    .frame(height: 320)
                    .clipped()
                } else {
                    Image(systemName: "figure.roller.coaster")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.nitroBlue.opacity(0.3))
                }
            }
            .frame(height: 320)

            // Gradient overlay
            LinearGradient.heroOverlay
                .frame(height: 200)

            // Title overlay
            VStack(alignment: .leading, spacing: VelocitySpacing.base) {
                if let parkName = viewModel.ride?.park?.name {
                    Text(parkName.uppercased())
                        .font(.labelCaps())
                        .foregroundStyle(Color.nitroBlue)
                        .tracking(0.96)
                }
                Text(viewModel.ride?.name ?? "Loading...")
                    .font(.headlineHero())
                    .foregroundStyle(Color.onSurface)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
            .padding(.bottom, VelocitySpacing.lg)
        }
    }

    // MARK: - Content Section
    private var contentSection: some View {
        VStack(spacing: VelocitySpacing.lg) {
            // Tech Specs Grid
            if let ride = viewModel.ride {
                techSpecsGrid(ride)
            }

            // Description
            if let desc = viewModel.ride?.description, !desc.isEmpty {
                VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
                    Text("ABOUT")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(0.96)
                    Text(desc)
                        .font(.bodyMedium())
                        .foregroundStyle(Color.onSurface)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, VelocitySpacing.edgeMargin)
            }

            // Reviews Section
            reviewsSection

            // Loading
            if viewModel.isLoading {
                ProgressView()
                    .tint(Color.nitroBlue)
                    .padding()
            }
        }
        .padding(.top, VelocitySpacing.lg)
    }

    // MARK: - Tech Specs
    private func techSpecsGrid(_ ride: Ride) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: VelocitySpacing.gutter) {
            if let speed = ride.speed {
                StatCard(label: "Top Speed", value: "\(speed) MPH", icon: "gauge.with.needle")
            }
            if let height = ride.height {
                StatCard(label: "Max Height", value: "\(height) FT", icon: "arrow.up.to.line")
            }
            if let gForce = ride.gForce {
                StatCard(label: "G-Force", value: String(format: "%.1f G", gForce), icon: "speedometer")
            }
            if let inversions = ride.inversions, inversions > 0 {
                StatCard(label: "Inversions", value: "\(inversions)", icon: "arrow.triangle.2.circlepath")
            }
            if let trackLength = ride.trackLength {
                StatCard(label: "Track", value: "\(trackLength) FT", icon: "point.topleft.down.to.point.bottomright.curvepath")
            }
            if let manufacturer = ride.manufacturer, !manufacturer.isEmpty {
                StatCard(label: "Maker", value: manufacturer, icon: "wrench.and.screwdriver")
            }
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Reviews
    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            HStack {
                Text("REVIEWS")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)

                if let ride = viewModel.ride, ride.starRating > 0 {
                    StarRating(rating: ride.starRating)
                    Text(String(format: "%.1f", ride.starRating))
                        .font(.statValue())
                        .foregroundStyle(Color.onSurface)
                }

                Spacer()

                Button {
                    viewModel.showReviewSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("REVIEW")
                    }
                    .font(.labelCaps())
                    .foregroundStyle(Color.nitroBlue)
                    .tracking(0.96)
                }
            }

            if viewModel.reviews.isEmpty {
                Text("No reviews yet. Be the first!")
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .padding(.vertical, VelocitySpacing.md)
            } else {
                ForEach(viewModel.reviews) { review in
                    ReviewCard(review: review)
                }
            }
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Floating Check-In Button
    private var checkInButton: some View {
        Button {
            viewModel.showCheckInSheet = true
        } label: {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                Text("CHECK IN")
                    .font(.labelCaps())
                    .tracking(1.5)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, VelocitySpacing.md)
            .background(LinearGradient.nitroGradient)
            .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.component))
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
        .padding(.bottom, VelocitySpacing.lg)
        .background(
            LinearGradient(
                colors: [Color.velocityBackground.opacity(0), Color.velocityBackground],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Review Card
struct ReviewCard: View {
    let review: ProfileRideReview

    var body: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
            HStack {
                // Avatar placeholder
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
                        .font(.bodySmall())
                        .foregroundStyle(Color.onSurface)

                    if let stars = review.stars {
                        StarRating(rating: Double(stars), size: 10)
                    }
                }

                Spacer()

                // Votes
                HStack(spacing: VelocitySpacing.sm) {
                    Label("\(review.upVotes ?? 0)", systemImage: "arrow.up")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                    Label("\(review.downVotes ?? 0)", systemImage: "arrow.down")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }

            Text(review.reviewText)
                .font(.bodyMedium())
                .foregroundStyle(Color.onSurface)
                .lineSpacing(2)
        }
        .padding(VelocitySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: VelocityRadius.component)
                .fill(Color.velocitySurfaceContainerHigh)
        )
    }
}
