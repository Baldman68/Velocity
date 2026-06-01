import SwiftUI

struct SubmitCoasterView: View {
    @State private var coasterName = ""
    @State private var description = ""
    @State private var manufacturer = ""
    @State private var heightFt = ""
    @State private var speedMph = ""
    @State private var trackLengthFt = ""
    @State private var inversionsCount = ""
    @State private var gForceValue = ""
    @State private var imageURL = ""
    @State private var selectedPark: Park?
    @State private var parks: [Park] = []
    @State private var parkSearchText = ""
    @State private var isLoadingParks = true
    @State private var isSubmitting = false
    @State private var submitted = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let rideService = RideService()

    private var filteredParks: [Park] {
        if parkSearchText.isEmpty { return parks }
        let query = parkSearchText.lowercased()
        return parks.filter { ($0.name ?? "").lowercased().contains(query) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: VelocitySpacing.lg) {
                // Header
                VStack(spacing: VelocitySpacing.xs) {
                    Text("NEW DATABASE ENTRY")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(1.5)
                    Text("ADD COASTER")
                        .font(.headlineHero())
                        .foregroundStyle(Color.nitroBlue)
                        .italic()
                }
                .frame(maxWidth: .infinity)
                .padding(.top, VelocitySpacing.sm)

                // Info banner
                HStack(alignment: .top, spacing: VelocitySpacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.nitroBlue)
                        .padding(.top, 2)
                    Text("Help us expand the database. Provide as much technical data as possible for the mission record. Our team will review your submission.")
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

                // Park Picker
                sectionLabel("THEME PARK *")
                parkPicker

                // Coaster Info
                sectionLabel("COASTER INFO")
                formField(label: "COASTER NAME", icon: "mountain.2", text: $coasterName, required: true)
                formField(label: "DESCRIPTION", icon: "text.alignleft", text: $description, multiline: true)
                formField(label: "MANUFACTURER", icon: "wrench.and.screwdriver", text: $manufacturer)

                // Technical Stats
                sectionLabel("TECHNICAL STATS")
                HStack(spacing: VelocitySpacing.sm) {
                    numericField(label: "HEIGHT (FT)", icon: "arrow.up", text: $heightFt)
                    numericField(label: "SPEED (MPH)", icon: "gauge.with.needle", text: $speedMph)
                }
                HStack(spacing: VelocitySpacing.sm) {
                    numericField(label: "TRACK LENGTH (FT)", icon: "road.lanes", text: $trackLengthFt)
                    numericField(label: "INVERSIONS", icon: "arrow.triangle.2.circlepath", text: $inversionsCount)
                }
                numericField(label: "G-FORCE", icon: "scalemass", text: $gForceValue)

                // Image
                sectionLabel("MEDIA")
                formField(label: "IMAGE URL", icon: "photo", text: $imageURL)

                // Error
                if let errorMessage {
                    Text(errorMessage)
                        .font(.bodySmall())
                        .foregroundStyle(Color.velocityError)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Submit
                submitButton

                // Notice
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
        .task { await loadParks() }
        .overlay {
            if submitted { successOverlay }
        }
    }

    // MARK: - Park Picker
    private var parkPicker: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            // Selected park display
            if let park = selectedPark {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(park.displayName)
                            .font(.bodyLarge())
                            .fontWeight(.bold)
                            .foregroundStyle(Color.onSurface)
                        Text(park.locationString)
                            .font(.bodySmall())
                            .foregroundStyle(Color.onSurfaceVariant)
                    }
                    Spacer()
                    Button {
                        selectedPark = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.onSurfaceVariant)
                    }
                }
                .padding(VelocitySpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: VelocityRadius.component)
                        .fill(Color.nitroBlue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: VelocityRadius.component)
                                .stroke(Color.nitroBlue.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                // Search field
                HStack(spacing: VelocitySpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.onSurfaceVariant)
                    TextField("Search parks...", text: $parkSearchText)
                        .font(.bodyMedium())
                        .foregroundStyle(Color.onSurface)
                }
                .padding(VelocitySpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: VelocityRadius.component)
                        .fill(Color.velocitySurfaceContainerLowest)
                        .overlay(
                            RoundedRectangle(cornerRadius: VelocityRadius.component)
                                .stroke(Color.velocityOutlineVariant.opacity(0.5), lineWidth: 1)
                        )
                )

                // Park list (show when searching or loading)
                if isLoadingParks {
                    HStack { Spacer(); ProgressView().tint(Color.nitroBlue); Spacer() }
                        .padding(.vertical, VelocitySpacing.md)
                } else if !parkSearchText.isEmpty {
                    let results = filteredParks.prefix(8)
                    if results.isEmpty {
                        Text("No parks found matching \"\(parkSearchText)\"")
                            .font(.bodySmall())
                            .foregroundStyle(Color.onSurfaceVariant)
                            .padding(.vertical, VelocitySpacing.xs)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(results)) { park in
                                Button {
                                    selectedPark = park
                                    parkSearchText = ""
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(park.displayName)
                                                .font(.bodyMedium())
                                                .fontWeight(.semibold)
                                                .foregroundStyle(Color.onSurface)
                                            Text(park.locationString)
                                                .font(.system(size: 11))
                                                .foregroundStyle(Color.onSurfaceVariant)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.onSurfaceVariant)
                                    }
                                    .padding(.horizontal, VelocitySpacing.md)
                                    .padding(.vertical, VelocitySpacing.sm)
                                }
                                .buttonStyle(.plain)

                                if park.id != results.last?.id {
                                    Rectangle()
                                        .fill(Color.velocityOutlineVariant.opacity(0.2))
                                        .frame(height: 1)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: VelocityRadius.component)
                                .fill(Color.velocitySurfaceContainerLow)
                                .overlay(
                                    RoundedRectangle(cornerRadius: VelocityRadius.component)
                                        .stroke(Color.velocityOutlineVariant.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            HStack(spacing: VelocitySpacing.xs) {
                if isSubmitting {
                    ProgressView().tint(Color.onNitroBlueContainer)
                } else {
                    Image(systemName: "externaldrive.badge.plus")
                        .font(.system(size: 16))
                }
                Text("SUBMIT TO DATABASE")
                    .font(.labelCaps())
                    .tracking(0.96)
            }
            .foregroundStyle(Color.onNitroBlueContainer)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: VelocityRadius.xl)
                    .fill(canSubmit ? LinearGradient.nitroGradient : LinearGradient(colors: [Color.velocitySurfaceContainerHighest], startPoint: .leading, endPoint: .trailing))
            )
            .shadow(color: canSubmit ? Color.nitroBlue.opacity(0.3) : .clear, radius: 16, y: 4)
        }
        .disabled(!canSubmit || isSubmitting)
    }

    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            Color.velocityBackground.opacity(0.9).ignoresSafeArea()
            VStack(spacing: VelocitySpacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.nitroBlue)
                    .shadow(color: Color.nitroBlue.opacity(0.5), radius: 30)
                Text("SUBMITTED")
                    .font(.headlineLarge())
                    .foregroundStyle(Color.onSurface)
                    .italic()
                Text("Your coaster submission is under review.")
                    .font(.bodyLarge())
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
        .transition(.opacity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { dismiss() }
        }
    }

    // MARK: - Helpers
    private var canSubmit: Bool {
        selectedPark != nil &&
        !coasterName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.labelCaps())
            .foregroundStyle(Color.onSurfaceVariant)
            .tracking(0.96)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, VelocitySpacing.xs)
    }

    private func formField(label: String, icon: String, text: Binding<String>, required: Bool = false, multiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.base) {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.nitroBlue)
                    .frame(width: 20)
                Text(label + (required ? " *" : ""))
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
                    .background(fieldBackground)
            } else {
                TextField(label.capitalized, text: text)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurface)
                    .padding(VelocitySpacing.md)
                    .background(fieldBackground)
            }
        }
    }

    private func numericField(label: String, icon: String, text: Binding<String>) -> some View {
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
            TextField("0", text: text)
                .font(.statValue())
                .foregroundStyle(Color.nitroBlue)
                .keyboardType(.decimalPad)
                .padding(VelocitySpacing.md)
                .background(fieldBackground)
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: VelocityRadius.component)
            .fill(Color.velocitySurfaceContainerLowest)
            .overlay(
                RoundedRectangle(cornerRadius: VelocityRadius.component)
                    .stroke(Color.velocityOutlineVariant.opacity(0.5), lineWidth: 1)
            )
    }

    private func loadParks() async {
        isLoadingParks = true
        do {
            parks = try await rideService.fetchAllParks()
        } catch {
            parks = []
        }
        isLoadingParks = false
    }

    private func submit() async {
        guard let park = selectedPark else { return }
        isSubmitting = true
        errorMessage = nil
        do {
            try await rideService.submitRideRequest(
                profileId: 1,
                parkId: park.id,
                name: coasterName,
                description: description.isEmpty ? nil : description,
                manufacturer: manufacturer.isEmpty ? nil : manufacturer,
                gForce: Float(gForceValue),
                trackLength: Int16(trackLengthFt),
                height: Int16(heightFt),
                speed: Int16(speedMph),
                inversions: Int16(inversionsCount),
                mainImageURL: imageURL.isEmpty ? nil : imageURL
            )
            withAnimation { submitted = true }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
