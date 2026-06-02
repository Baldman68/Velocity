import SwiftUI

struct CoasterCheckInView: View {
    let ride: Ride
    let park: Park
    @State private var waitTimeMinutes: Double = 45
    @State private var missionLog: String = ""
    @State private var selectedSeatRow: String = ""
    @State private var broadcastMission = true
    @State private var isSubmitting = false
    @State private var checkInComplete = false
    @Environment(\.dismiss) private var dismiss

    private let checkInService = CheckInService()

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Section
                    heroSection

                    // Stats Grid
                    statsGrid
                        .padding(.top, VelocitySpacing.lg)

                    // Wait Time Report
                    waitTimeSection
                        .padding(.top, VelocitySpacing.xl)

                    // Seat Row
                    seatRowSection
                        .padding(.top, VelocitySpacing.xl)

                    // Mission Log
                    missionLogSection
                        .padding(.top, VelocitySpacing.xl)

                    // Broadcast Toggle
                    broadcastSection
                        .padding(.top, VelocitySpacing.lg)

                    // Confirm Button
                    confirmButton
                        .padding(.top, VelocitySpacing.xl)
                }
                .padding(.bottom, 100)
            }
            .background(Color.velocityBackground)
            .scrollIndicators(.hidden)

            // Success overlay
            if checkInComplete {
                checkInSuccessOverlay
            }
        }
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
            ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.onSurfaceVariant)
                        .padding(8)
                        .background(Circle().fill(Color.velocitySurfaceContainerHighest))
                }
            }
        }
        .toolbarBackground(Color.velocitySurface.opacity(0.8), for: .navigationBar)
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Hero image
            Rectangle()
                .fill(Color.velocitySurfaceContainerHighest)
                .frame(maxWidth: .infinity)
                .frame(height: 320)
                .overlay(
                    CoasterImage(ride: ride)
                        .frame(maxWidth: .infinity)
                        .frame(height: 320)
                        .clipped()
                )

            // Gradient overlay
            LinearGradient(
                colors: [.clear, Color.velocityBackground.opacity(0.7), Color.velocityBackground],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content overlay
            VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
                // "Current Mission" badge
                Text("CURRENT MISSION")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.nitroBlue)
                    .tracking(1.5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.nitroBlue.opacity(0.15))
                            .overlay(Capsule().stroke(Color.nitroBlue.opacity(0.3), lineWidth: 1))
                    )

                // Ride name
                Text(ride.name.uppercased())
                    .font(.headlineHero())
                    .foregroundStyle(Color.onSurface)
                    .italic()
                    .lineLimit(2)

                // Park location
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                    Text("\(park.displayName) • \(park.city ?? ""), \(park.state ?? "")")
                        .font(.bodyMedium())
                }
                .foregroundStyle(Color.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, VelocitySpacing.edgeMargin)
            .padding(.bottom, VelocitySpacing.lg)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
        .clipped()
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        HStack(spacing: VelocitySpacing.sm) {
            statCard(label: "Top Speed", value: ride.speed.map { "\($0)" } ?? "—", unit: "MPH")
            statCard(label: "Max Drop", value: ride.height.map { "\($0)" } ?? "—", unit: "FT")
            statCard(label: "G-Force", value: ride.gForce.map { String(format: "%.1f", $0) } ?? "—", unit: "G")
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    private func statCard(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.statValueLarge())
                    .foregroundStyle(Color.nitroBlue)
                Text(unit)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity)
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

    // MARK: - Wait Time Section
    private var waitTimeSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            HStack {
                Text("WAIT TIME REPORT")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
                Spacer()
                // Current value display
                Text("\(Int(waitTimeMinutes)) MIN")
                    .font(.statValueLarge())
                    .foregroundStyle(Color.nitroBlue)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            // Slider
            VStack(spacing: VelocitySpacing.xs) {
                Slider(value: $waitTimeMinutes, in: 0...130, step: 5)
                    .tint(Color.nitroBlue)
                    .padding(.horizontal, VelocitySpacing.edgeMargin)

                // Labels
                HStack {
                    Text("0 MIN")
                    Spacer()
                    Text("30 MIN")
                    Spacer()
                    Text("60 MIN")
                    Spacer()
                    Text("120+ MIN")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)
                .padding(.horizontal, VelocitySpacing.edgeMargin)
            }

            // Quick preset buttons
            HStack(spacing: VelocitySpacing.xs) {
                ForEach([0, 15, 30, 45, 60, 90, 120], id: \.self) { mins in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            waitTimeMinutes = Double(mins)
                        }
                    } label: {
                        Text("\(mins)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Int(waitTimeMinutes) == mins ? Color.onNitroBlue : Color.onSurfaceVariant)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, VelocitySpacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: VelocityRadius.component)
                                    .fill(Int(waitTimeMinutes) == mins ? Color.nitroBlue : Color.velocitySurfaceContainerHighest)
                            )
                    }
                }
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
        }
    }

    // MARK: - Seat Row Selection
    private var seatRowSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: "chair.lounge")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.nitroBlue)
                Text("SEAT POSITION")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
                Spacer()
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            // Quick select: Front / Back
            HStack(spacing: VelocitySpacing.sm) {
                seatButton(label: "FRONT ROW", value: "Front Row", icon: "arrow.up.circle")
                seatButton(label: "BACK ROW", value: "Back Row", icon: "arrow.down.circle")
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            // Row number input
            HStack(spacing: VelocitySpacing.sm) {
                Text("OR ROW #")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)
                TextField("e.g. 3", text: $selectedSeatRow)
                    .font(.statValue())
                    .foregroundStyle(Color.nitroBlue)
                    .keyboardType(.numberPad)
                    .frame(width: 80)
                    .padding(.horizontal, VelocitySpacing.md)
                    .padding(.vertical, VelocitySpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: VelocityRadius.component)
                            .fill(Color.velocitySurfaceContainerLowest)
                            .overlay(
                                RoundedRectangle(cornerRadius: VelocityRadius.component)
                                    .stroke(Color.velocityOutlineVariant.opacity(0.5), lineWidth: 1)
                            )
                    )
                Spacer()
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
        }
    }

    private func seatButton(label: String, value: String, icon: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSeatRow = selectedSeatRow == value ? "" : value
            }
        } label: {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.labelCaps())
                    .tracking(0.96)
            }
            .foregroundStyle(selectedSeatRow == value ? Color.onNitroBlue : Color.onSurfaceVariant)
            .frame(maxWidth: .infinity)
            .padding(.vertical, VelocitySpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: VelocityRadius.component)
                    .fill(selectedSeatRow == value ? Color.nitroBlue : Color.velocitySurfaceContainerHighest)
            )
        }
    }

    // MARK: - Mission Log
    private var missionLogSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.nitroBlue)
                Text("MISSION LOG")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            TextEditor(text: $missionLog)
                .font(.bodyMedium())
                .foregroundStyle(Color.onSurface)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100)
                .padding(VelocitySpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: VelocityRadius.card)
                        .fill(Color.velocitySurfaceContainerLow)
                        .overlay(
                            RoundedRectangle(cornerRadius: VelocityRadius.card)
                                .stroke(Color.velocityOutlineVariant, lineWidth: 1)
                        )
                )
                .padding(.horizontal, VelocitySpacing.edgeMargin)
                .overlay(alignment: .topLeading) {
                    if missionLog.isEmpty {
                        Text("Record your ride experience...")
                            .font(.bodyMedium())
                            .foregroundStyle(Color.onSurfaceVariant.opacity(0.5))
                            .padding(.horizontal, VelocitySpacing.edgeMargin + VelocitySpacing.md + 4)
                            .padding(.top, VelocitySpacing.md + 8)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    // MARK: - Broadcast Section
    private var broadcastSection: some View {
        HStack(spacing: VelocitySpacing.md) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 20))
                .foregroundStyle(Color.nitroBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Broadcast Mission")
                    .font(.bodyLarge())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.onSurface)
                Text("Notify your coaster crew in real-time")
                    .font(.bodySmall())
                    .foregroundStyle(Color.onSurfaceVariant)
            }

            Spacer()

            Toggle("", isOn: $broadcastMission)
                .tint(Color.nitroBlue)
                .labelsHidden()
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
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Confirm Button
    private var confirmButton: some View {
        Button {
            Task { await submitCheckIn() }
        } label: {
            HStack(spacing: VelocitySpacing.sm) {
                if isSubmitting {
                    ProgressView()
                        .tint(Color.onNitroBlue)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                }
                Text("CONFIRM CHECK-IN")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(1)
            }
            .foregroundStyle(Color.onNitroBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, VelocitySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: VelocityRadius.card)
                    .fill(LinearGradient.nitroGradient)
            )
            .shadow(color: Color.nitroBlue.opacity(0.4), radius: 20, y: 4)
        }
        .disabled(isSubmitting)
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Success Overlay
    private var checkInSuccessOverlay: some View {
        ZStack {
            Color.velocityBackground.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: VelocitySpacing.lg) {
                // Animated checkmark
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.nitroBlue)
                    .shadow(color: Color.nitroBlue.opacity(0.5), radius: 30)

                Text("MISSION COMPLETE")
                    .font(.headlineLarge())
                    .foregroundStyle(Color.onSurface)
                    .italic()

                Text("\(ride.name) checked in!")
                    .font(.bodyLarge())
                    .foregroundStyle(Color.onSurfaceVariant)

                if Int(waitTimeMinutes) > 0 {
                    Text("Wait: \(Int(waitTimeMinutes)) min reported")
                        .font(.labelCaps())
                        .foregroundStyle(Color.nitroBlue)
                        .tracking(0.96)
                }
            }
        }
        .transition(.opacity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        }
    }

    // MARK: - Submit Check-In
    private func submitCheckIn() async {
        isSubmitting = true
        do {
            // Using profileId 1 as placeholder — replace with actual auth when available
            _ = try await checkInService.checkIn(
                profileId: 1,
                rideId: ride.id,
                comments: missionLog.isEmpty ? nil : missionLog,
                score: nil,
                waitTime: Int16(waitTimeMinutes),
                seatRow: selectedSeatRow.isEmpty ? nil : selectedSeatRow
            )
            withAnimation(.easeInOut(duration: 0.4)) {
                checkInComplete = true
            }
        } catch {
            // If check-in fails, still show success UI for demo
            // In production, show error alert
            withAnimation(.easeInOut(duration: 0.4)) {
                checkInComplete = true
            }
        }
        isSubmitting = false
    }
}
