import SwiftUI

struct LocationAccessView: View {
    var onEnable: () -> Void
    var onSkip: () -> Void

    @State private var showMapArea = false
    @State private var showContent = false
    @State private var showButtons = false
    @State private var pinPulse = false
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Map preview area with floating elements
            mapPreviewArea
                .padding(.horizontal, VelocitySpacing.edgeMargin)
                .scaleEffect(showMapArea ? 1.0 : 0.9)
                .opacity(showMapArea ? 1 : 0)

            Spacer().frame(height: VelocitySpacing.xl)

            // FIND YOUR RIDE
            Text("FIND YOUR RIDE")
                .font(.headlineHero())
                .foregroundStyle(Color.onSurface)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 16)

            // Description
            Text("We use your location to automatically detect when you're at a park, enabling instant check-ins and live wait times.")
                .font(.bodyMedium())
                .foregroundStyle(Color.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, VelocitySpacing.sm)
                .padding(.horizontal, VelocitySpacing.lg)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 12)

            Spacer()

            // Buttons
            VStack(spacing: VelocitySpacing.md) {
                Button(action: onEnable) {
                    HStack(spacing: VelocitySpacing.xs) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16))
                        Text("Enable Location")
                            .font(.labelCaps())
                            .tracking(1.5)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, VelocitySpacing.md)
                    .background(LinearGradient.nitroGradient)
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.component))
                    .shadow(color: Color.nitroBlue.opacity(0.4), radius: 12, y: 4)
                }

                Button("Not Now", action: onSkip)
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(1)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
            .padding(.bottom, VelocitySpacing.xl)
            .opacity(showButtons ? 1 : 0)
            .offset(y: showButtons ? 0 : 20)
        }
        .onAppear { runEntrance() }
    }

    // MARK: - Map Preview Area
    private var mapPreviewArea: some View {
        ZStack {
            // Map background
            RoundedRectangle(cornerRadius: VelocityRadius.card)
                .fill(Color.velocitySurfaceContainerHigh)
                .frame(height: 240)
                .overlay(
                    RoundedRectangle(cornerRadius: VelocityRadius.card)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            // Subtle grid lines to simulate map
            VStack(spacing: 20) {
                ForEach(0..<6, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.velocityOutlineVariant.opacity(0.15))
                        .frame(height: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card))

            // Pulsing location pin
            VStack(spacing: 0) {
                ZStack {
                    // Pulse rings
                    Circle()
                        .stroke(Color.pulseOrange.opacity(0.2), lineWidth: 2)
                        .frame(width: 60, height: 60)
                        .scaleEffect(pinPulse ? 1.8 : 1.0)
                        .opacity(pinPulse ? 0 : 0.6)

                    Circle()
                        .stroke(Color.pulseOrange.opacity(0.3), lineWidth: 2)
                        .frame(width: 40, height: 40)
                        .scaleEffect(pinPulse ? 1.5 : 1.0)
                        .opacity(pinPulse ? 0 : 0.8)

                    // Pin dot
                    Circle()
                        .fill(Color.pulseOrange)
                        .frame(width: 16, height: 16)
                        .shadow(color: Color.pulseOrange.opacity(0.6), radius: 8)
                }
            }

            // Floating park card (top-left)
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Location")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.onSurfaceVariant)
                Text("Cedar Point")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurface)
                    .tracking(0.96)
            }
            .padding(.horizontal, VelocitySpacing.sm)
            .padding(.vertical, VelocitySpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: VelocityRadius.component)
                    .fill(Color.velocitySurfaceContainer)
                    .overlay(
                        RoundedRectangle(cornerRadius: VelocityRadius.component)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .offset(x: -70, y: -70)
            .offset(y: floatOffset)

            // Floating wait time chip (top-right)
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.pulseOrange)
                Text("5m Wait")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurface)
                    .tracking(0.96)
            }
            .padding(.horizontal, VelocitySpacing.sm)
            .padding(.vertical, VelocitySpacing.xs)
            .background(
                Capsule().fill(Color.velocitySurfaceContainer)
                    .overlay(Capsule().stroke(Color.pulseOrange.opacity(0.3), lineWidth: 1))
            )
            .offset(x: 80, y: -60)
            .offset(y: -floatOffset)

            // Floating ride chip (bottom)
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.nitroBlue)
                Text("Millennium Force")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurface)
                    .tracking(0.96)
            }
            .padding(.horizontal, VelocitySpacing.sm)
            .padding(.vertical, VelocitySpacing.xs)
            .background(
                Capsule().fill(Color.velocitySurfaceContainer)
                    .overlay(Capsule().stroke(Color.nitroBlue.opacity(0.3), lineWidth: 1))
            )
            .offset(x: 20, y: 80)
            .offset(y: floatOffset * 0.7)
        }
    }

    // MARK: - Entrance Animation
    private func runEntrance() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
            showMapArea = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            showContent = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            showButtons = true
        }
        // Continuous pin pulse
        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(0.5)) {
            pinPulse = true
        }
        // Gentle float for chips
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.8)) {
            floatOffset = 6
        }
    }
}
