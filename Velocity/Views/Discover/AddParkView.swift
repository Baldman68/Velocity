import SwiftUI
import CoreLocation

struct AddParkView: View {
    @State private var parkName = ""
    @State private var streetAddress = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var country = "United States"
    @State private var website = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var isSubmitting = false
    @State private var submitted = false
    @State private var errorMessage: String?
    @State private var isFetchingLocation = false
    @Environment(\.dismiss) private var dismiss

    private let rideService = RideService()
    private let locationManager = CLLocationManager()

    var body: some View {
        ScrollView {
            VStack(spacing: VelocitySpacing.lg) {
                // Header
                VStack(spacing: VelocitySpacing.xs) {
                    Text("NEW DATABASE ENTRY")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(1.5)
                    Text("ADD NEW PARK")
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
                    Text("Expanding the global grid. Provide details for the new park destination. Our team will review and add it if valid.")
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

                // Park Details
                sectionLabel("PARK DETAILS")
                formField(label: "PARK NAME", icon: "building.columns", text: $parkName, required: true)
                formField(label: "STREET ADDRESS", icon: "mappin.circle", text: $streetAddress)
                HStack(spacing: VelocitySpacing.sm) {
                    formField(label: "CITY", icon: "building.2", text: $city, required: true)
                    formField(label: "STATE", icon: "map", text: $state, required: true)
                        .frame(width: 100)
                }
                HStack(spacing: VelocitySpacing.sm) {
                    formField(label: "ZIP", icon: "number", text: $zip)
                        .frame(width: 120)
                    formField(label: "COUNTRY", icon: "globe", text: $country)
                }

                // Location
                sectionLabel("COORDINATES")
                imHereButton
                HStack(spacing: VelocitySpacing.sm) {
                    formField(label: "LATITUDE", icon: "location.north", text: $latitude)
                    formField(label: "LONGITUDE", icon: "location.north", text: $longitude)
                }

                // Contact
                sectionLabel("CONTACT")
                formField(label: "WEBSITE URL", icon: "link", text: $website)
                formField(label: "PHONE", icon: "phone", text: $phone)
                formField(label: "EMAIL", icon: "envelope", text: $email)

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
        .overlay {
            if submitted { successOverlay }
        }
    }

    // MARK: - "I'm at this park" Button
    private var imHereButton: some View {
        Button {
            fetchCurrentLocation()
        } label: {
            HStack(spacing: VelocitySpacing.xs) {
                if isFetchingLocation {
                    ProgressView().tint(Color.nitroBlue)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                }
                Text("I'M AT THIS PARK")
                    .font(.labelCaps())
                    .tracking(0.96)
            }
            .foregroundStyle(Color.nitroBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, VelocitySpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: VelocityRadius.component)
                    .fill(Color.nitroBlue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: VelocityRadius.component)
                            .stroke(Color.nitroBlue.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .disabled(isFetchingLocation)
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
                Text("Your park submission is under review.")
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
        !parkName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty &&
        !state.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.labelCaps())
            .foregroundStyle(Color.onSurfaceVariant)
            .tracking(0.96)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, VelocitySpacing.xs)
    }

    private func formField(label: String, icon: String, text: Binding<String>, required: Bool = false) -> some View {
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

    private func fetchCurrentLocation() {
        isFetchingLocation = true
        let delegate = LocationDelegate { location in
            latitude = String(format: "%.6f", location.coordinate.latitude)
            longitude = String(format: "%.6f", location.coordinate.longitude)
            isFetchingLocation = false
        } onError: {
            isFetchingLocation = false
        }
        // Hold reference via a static to prevent deallocation
        LocationDelegate.active = delegate
        locationManager.delegate = delegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        do {
            try await rideService.submitParkRequest(
                profileId: 1,
                name: parkName,
                city: city,
                state: state,
                zip: zip.isEmpty ? nil : zip,
                country: country.isEmpty ? nil : country,
                streetAddress: streetAddress.isEmpty ? nil : streetAddress,
                phoneNumber: phone.isEmpty ? nil : phone,
                website: website.isEmpty ? nil : website,
                email: email.isEmpty ? nil : email,
                latitude: latitude.isEmpty ? nil : latitude,
                longitude: longitude.isEmpty ? nil : longitude
            )
            withAnimation { submitted = true }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}

// MARK: - Location Delegate Helper
private class LocationDelegate: NSObject, CLLocationManagerDelegate {
    static var active: LocationDelegate?
    let onLocation: (CLLocation) -> Void
    let onError: () -> Void

    init(onLocation: @escaping (CLLocation) -> Void, onError: @escaping () -> Void) {
        self.onLocation = onLocation
        self.onError = onError
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            onLocation(location)
        }
        manager.delegate = nil
        Self.active = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onError()
        manager.delegate = nil
        Self.active = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}
