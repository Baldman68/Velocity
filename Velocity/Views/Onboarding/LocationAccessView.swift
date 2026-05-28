import SwiftUI

struct LocationAccessView: View {
    var onBack: () -> Void
    var onEnable: () -> Void
    var onSkip: () -> Void

    @State private var showIllustration = false
    @State private var showText = false
    @State private var showButtons = false
    @State private var pinPulse = false
    @State private var chipBounce: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.nitroBlue)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Text("COASTER CHASE")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.nitroBlue)
                    .tracking(-0.5)
                Spacer()
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.nitroBlue)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
            .frame(height: 56)

            Spacer()

            // Illustration container — square, rotated glass card with map image
            illustrationArea
                .padding(.horizontal, VelocitySpacing.edgeMargin)
                .scaleEffect(showIllustration ? 1.0 : 0.92)
                .opacity(showIllustration ? 1 : 0)

            Spacer().frame(height: VelocitySpacing.xl)

            // Text: FIND YOUR RIDE
            VStack(spacing: VelocitySpacing.md) {
                HStack(spacing: 8) {
                    Text("FIND YOUR")
                        .foregroundStyle(Color.onSurface)
                    Text("RIDE")
                        .foregroundStyle(Color.nitroBlue)
                }
                .font(.headlineLarge())
                .tracking(-0.5)

                Text("We use your location to automatically detect when you're at a park, enabling **instant check-ins** and **live wait times**.")
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, VelocitySpacing.lg)
            }
            .opacity(showText ? 1 : 0)
            .offset(y: showText ? 0 : 16)

            Spacer()

            // Actions
            VStack(spacing: VelocitySpacing.md) {
                Button(action: onEnable) {
                    HStack(spacing: VelocitySpacing.sm) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18))
                        Text("Enable Location")
                            .font(.labelCaps())
                            .tracking(2)
                    }
                    .foregroundStyle(Color.onNitroBlueContainer)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.nitroBlue)
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))
                    .shadow(color: Color.nitroBlue.opacity(0.2), radius: 12, y: 4)
                }

                Button("Not Now", action: onSkip)
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(2)
                    .frame(height: 48)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
            .padding(.bottom, VelocitySpacing.xl)
            .opacity(showButtons ? 1 : 0)
            .offset(y: showButtons ? 0 : 20)
        }
        .onAppear { runEntrance() }
    }

    // MARK: - Illustration Area
    private var illustrationArea: some View {
        ZStack {
            // Rotated glass card with map image
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.velocitySurfaceContainerLow.opacity(0.6))
                .overlay(
                    Image("onboarding_location_map")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.6)
                        .blendMode(.luminosity)
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                )
                .overlay(
                    // Bottom gradient
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, Color.velocityBackground],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .aspectRatio(1, contentMode: .fit)
                .rotationEffect(.degrees(3))
                .scaleEffect(0.95)

            // Current Location card (centered, offset up-left)
            HStack(spacing: VelocitySpacing.md) {
                // Pulsing marker
                ZStack {
                    Circle()
                        .fill(Color.nitroBlueDim.opacity(0.3))
                        .frame(width: 48, height: 48)
                        .scaleEffect(pinPulse ? 2.5 : 1)
                        .opacity(pinPulse ? 0 : 0.6)

                    Circle()
                        .fill(Color.nitroBlueLight)
                        .frame(width: 18, height: 18)
                        .shadow(color: Color.nitroBlueDim.opacity(0.8), radius: 10)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Location")
                        .font(.labelCaps())
                        .foregroundStyle(Color.nitroBlue)
                        .tracking(0.96)
                    Text("Cedar Point")
                        .font(.statValue())
                        .foregroundStyle(.white)
                }
            }
            .padding(VelocitySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.velocitySurfaceContainerLow.opacity(0.6))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.nitroBlue.opacity(0.2), lineWidth: 1)
                    )
            )
            .offset(x: -10, y: -20)

            // "5m Wait" chip (top-right)
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.nitroBlue)
                Text("5m Wait")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurface)
                    .tracking(0.96)
            }
            .padding(.horizontal, VelocitySpacing.sm)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.velocitySurfaceContainerLow.opacity(0.6))
                    .background(Capsule().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
                    .overlay(Capsule().stroke(Color.nitroBlue.opacity(0.1), lineWidth: 1))
            )
            .offset(x: 90, y: -100)
            .offset(y: chipBounce)

            // "Millennium Force" chip (bottom-left)
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.nitroBlue)
                Text("Millennium Force")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurface)
                    .tracking(0.96)
            }
            .padding(.horizontal, VelocitySpacing.sm)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.velocitySurfaceContainerLow.opacity(0.6))
                    .background(Capsule().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
                    .overlay(Capsule().stroke(Color.nitroBlue.opacity(0.1), lineWidth: 1))
            )
            .offset(x: -60, y: 110)
        }
    }

    // MARK: - Entrance
    private func runEntrance() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
            showIllustration = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            showText = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            showButtons = true
        }
        withAnimation(.easeOut(duration: 2.5).repeatForever(autoreverses: false).delay(0.5)) {
            pinPulse = true
        }
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(0.8)) {
            chipBounce = -8
        }
    }
}
