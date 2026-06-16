import SwiftUI

struct ParkPlannerView: View {
    let park: Park
    @State private var viewModel = ParkPlannerViewModel()
    @State private var subscriptionService = SubscriptionService()
    @State private var showSubscription = false
    @State private var profileId: Int64?
    @Environment(\.dismiss) private var dismiss

    private let profileService = ProfileService()
    private var isElite: Bool { subscriptionService.currentTier.tierLevel >= 2 }

    var body: some View {
        ScrollView {
            VStack(spacing: VelocitySpacing.xl) {
                header

                if !isElite {
                    eliteGate
                } else if viewModel.isLoading {
                    ProgressView().tint(Color.nitroBlue)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    planDetails
                    selectedRidesSection
                    availableRidesSection
                    actionButtons
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
                        Text("VELOCITY")
                            .font(.custom("ArchivoNarrow-Bold", size: 18))
                            .italic()
                    }
                    .foregroundStyle(Color.nitroBlue)
                }
            }
        }
        .toolbarBackground(Color.velocitySurface.opacity(0.8), for: .navigationBar)
        .task {
            await subscriptionService.refreshCurrentTier()
            if let profile = try? await profileService.fetchCurrentProfile() {
                profileId = profile.id
                await viewModel.loadPark(parkId: park.id, profileId: profile.id)
            }
        }
        .navigationDestination(isPresented: $showSubscription) {
            SubscriptionView()
        }
        .alert("Plan Saved!", isPresented: $viewModel.saveSuccess) {
            Button("OK", role: .cancel) { dismiss() }
        } message: {
            Text("Your visit plan for \(park.displayName) has been saved.")
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: VelocitySpacing.xs) {
            Text("PARK PLANNER")
                .font(.headlineHero())
                .foregroundStyle(Color.nitroBlue)
                .italic()
            Text(park.displayName.uppercased())
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(1.5)
                .lineLimit(1)
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
        .padding(.top, VelocitySpacing.md)
    }

    // MARK: - Plan Details
    private var planDetails: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: "pencil.and.list.clipboard")
                    .foregroundStyle(Color.nitroBlue)
                Text("PLAN DETAILS")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
                Spacer()
            }

            // Plan name
            VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
                Text("PLAN NAME")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)

                TextField("e.g. Summer Saturday Trip", text: $viewModel.planName)
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

            // Date picker
            VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
                Text("PLANNED DATE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)

                DatePicker("", selection: $viewModel.plannedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(Color.nitroBlue)
                    .colorScheme(.dark)
            }
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Selected Rides (reorderable)
    private var selectedRidesSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: "list.number")
                    .foregroundStyle(Color.pulseOrange)
                Text("YOUR PLAN")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
                Spacer()
                Text("\(viewModel.selectedRideIds.count) RIDES")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)
            }

            if viewModel.selectedRides.isEmpty {
                Text("Tap rides below to add them to your plan.")
                    .font(.bodySmall())
                    .foregroundStyle(Color.onSurfaceVariant.opacity(0.6))
                    .italic()
                    .padding(.vertical, VelocitySpacing.md)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.selectedRides.enumerated()), id: \.element.id) { index, ride in
                        HStack(spacing: VelocitySpacing.sm) {
                            // Order number
                            Text("\(index + 1)")
                                .font(.statValue())
                                .foregroundStyle(Color.pulseOrange)
                                .frame(width: 28)

                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.onSurfaceVariant.opacity(0.5))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(ride.name.uppercased())
                                    .font(.bodyMedium())
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.onSurface)
                                    .lineLimit(1)
                                if let speed = ride.speed {
                                    Text("\(speed) MPH")
                                        .font(.labelCaps())
                                        .foregroundStyle(Color.onSurfaceVariant)
                                }
                            }

                            Spacer()

                            // Remove button
                            Button {
                                viewModel.toggleRide(ride.id)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.onSurfaceVariant.opacity(0.5))
                            }
                        }
                        .padding(.vertical, VelocitySpacing.sm)
                        .padding(.horizontal, VelocitySpacing.md)

                        if index < viewModel.selectedRides.count - 1 {
                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 1)
                                .padding(.horizontal, VelocitySpacing.md)
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
                                .stroke(Color.pulseOrange.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Available Rides
    private var availableRidesSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: "mountain.2")
                    .foregroundStyle(Color.nitroBlue)
                Text("AVAILABLE COASTERS")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
                Spacer()
            }

            if viewModel.unselectedRides.isEmpty {
                Text("All coasters added to your plan!")
                    .font(.bodySmall())
                    .foregroundStyle(Color.onSurfaceVariant.opacity(0.6))
                    .italic()
                    .padding(.vertical, VelocitySpacing.md)
            } else {
                VStack(spacing: VelocitySpacing.xs) {
                    ForEach(viewModel.unselectedRides) { ride in
                        Button {
                            viewModel.toggleRide(ride.id)
                        } label: {
                            HStack(spacing: VelocitySpacing.sm) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.nitroBlue)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ride.name.uppercased())
                                        .font(.bodyMedium())
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.onSurface)
                                        .lineLimit(1)
                                    HStack(spacing: VelocitySpacing.sm) {
                                        if let speed = ride.speed {
                                            Text("\(speed) MPH")
                                                .font(.labelCaps())
                                                .foregroundStyle(Color.onSurfaceVariant)
                                        }
                                        if let manufacturer = ride.manufacturer, !manufacturer.isEmpty {
                                            Text(manufacturer)
                                                .font(.labelCaps())
                                                .foregroundStyle(Color.onSurfaceVariant)
                                                .lineLimit(1)
                                        }
                                    }
                                }

                                Spacer()
                            }
                            .padding(.vertical, VelocitySpacing.sm)
                            .padding(.horizontal, VelocitySpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: VelocityRadius.component)
                                    .fill(Color.velocitySurfaceContainerHigh)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: VelocitySpacing.sm) {
            // Save button
            Button {
                guard let profileId else { return }
                Task { await viewModel.savePlan(profileId: profileId, parkId: park.id) }
            } label: {
                HStack(spacing: VelocitySpacing.xs) {
                    if viewModel.isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 16))
                    }
                    Text(viewModel.existingPlan != nil ? "UPDATE PLAN" : "SAVE PLAN")
                        .font(.labelCaps())
                        .tracking(0.96)
                }
                .foregroundStyle(Color.onNitroBlueContainer)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: VelocityRadius.xl)
                        .fill(viewModel.selectedRideIds.isEmpty ? Color.velocitySurfaceContainerHighest : Color.nitroBlue)
                )
            }
            .disabled(viewModel.selectedRideIds.isEmpty || viewModel.isSaving)

            // Delete button (only if existing plan)
            if viewModel.existingPlan != nil {
                Button {
                    Task { await viewModel.deletePlan() }
                } label: {
                    Text("DELETE PLAN")
                        .font(.labelCaps())
                        .tracking(0.96)
                        .foregroundStyle(Color.pulseOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, VelocitySpacing.sm)
                }
            }
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - ELITE Gate
    private var eliteGate: some View {
        VStack(spacing: VelocitySpacing.lg) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.pulseOrange)

            Text("ELITE EXCLUSIVE")
                .font(.headlineMedium())
                .foregroundStyle(Color.pulseOrange)

            Text("The Park Visit Planner lets you build a custom ride itinerary, organize your day, and never miss a coaster.")
                .font(.bodyMedium())
                .foregroundStyle(Color.onSurfaceVariant)
                .multilineTextAlignment(.center)

            Button {
                showSubscription = true
            } label: {
                HStack(spacing: VelocitySpacing.xs) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                    Text("UPGRADE TO ELITE")
                        .font(.labelCaps())
                        .tracking(0.96)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: VelocityRadius.xl)
                        .fill(Color.pulseOrange)
                )
            }
        }
        .padding(VelocitySpacing.xl)
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }
}
