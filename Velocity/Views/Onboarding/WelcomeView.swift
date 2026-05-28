import SwiftUI

struct WelcomeView: View {
    var onGetStarted: () -> Void
    var onLogin: () -> Void

    // Staggered animation states
    @State private var showRocket = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showFeatures = false
    @State private var showButtons = false
    @State private var rocketPulse = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Rocket icon with glow
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(Color.nitroBlue.opacity(0.08))
                    .frame(width: 140, height: 140)
                    .scaleEffect(rocketPulse ? 1.15 : 1.0)

                // Inner glow ring
                Circle()
                    .fill(Color.nitroBlue.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .scaleEffect(rocketPulse ? 1.1 : 1.0)

                // Icon circle
                Circle()
                    .fill(LinearGradient.nitroGradient)
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.nitroBlue.opacity(0.5), radius: rocketPulse ? 20 : 10)

                Image(systemName: "location.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(showRocket ? 1.0 : 0.3)
            .opacity(showRocket ? 1 : 0)
            .padding(.bottom, VelocitySpacing.lg)

            // VELOCITY title
            Text("VELOCITY")
                .font(.headlineHero())
                .foregroundStyle(Color.onSurface)
                .tracking(6)
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 12)

            // "Launch Sequence" subtitle
            Text("Launch Sequence")
                .font(.labelCaps())
                .foregroundStyle(Color.nitroBlue)
                .tracking(2)
                .padding(.top, VelocitySpacing.xs)
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 8)

            // FEEL THE RUSH
            Text("FEEL THE RUSH")
                .font(.headlineLarge())
                .foregroundStyle(Color.onSurface)
                .padding(.top, VelocitySpacing.xl)
                .opacity(showSubtitle ? 1 : 0)
                .offset(y: showSubtitle ? 0 : 16)

            // Description
            Text("The ultimate tracker for rollercoaster enthusiasts. Research, review, and compete with a global community of riders.")
                .font(.bodyMedium())
                .foregroundStyle(Color.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, VelocitySpacing.sm)
                .padding(.horizontal, VelocitySpacing.lg)
                .opacity(showSubtitle ? 1 : 0)
                .offset(y: showSubtitle ? 0 : 12)

            // Feature pills
            HStack(spacing: VelocitySpacing.sm) {
                featurePill(icon: "chart.bar.fill", label: "TECH STATS", delay: 0)
                featurePill(icon: "trophy.fill", label: "LEADERBOARDS", delay: 0.1)
                featurePill(icon: "checkmark.shield.fill", label: "CREDITS", delay: 0.2)
            }
            .padding(.top, VelocitySpacing.lg)
            .opacity(showFeatures ? 1 : 0)

            Spacer()

            // Buttons
            VStack(spacing: VelocitySpacing.md) {
                // GET STARTED
                Button(action: onGetStarted) {
                    HStack(spacing: VelocitySpacing.xs) {
                        Text("GET STARTED")
                            .font(.labelCaps())
                            .tracking(1.5)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, VelocitySpacing.md)
                    .background(LinearGradient.nitroGradient)
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.component))
                    .shadow(color: Color.nitroBlue.opacity(0.4), radius: 12, y: 4)
                }

                // LOGIN / PARK MAP
                HStack(spacing: VelocitySpacing.xl) {
                    Button("LOGIN", action: onLogin)
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(1)

                    Button("PARK MAP") {}
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(1)
                }
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
            .padding(.bottom, VelocitySpacing.xl)
            .opacity(showButtons ? 1 : 0)
            .offset(y: showButtons ? 0 : 20)
        }
        .onAppear { runLaunchSequence() }
    }

    // MARK: - Feature Pill
    private func featurePill(icon: String, label: String, delay: Double) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.nitroBlue)
            Text(label)
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)
        }
        .padding(.horizontal, VelocitySpacing.sm)
        .padding(.vertical, VelocitySpacing.xs)
        .background(
            Capsule().fill(Color.velocitySurfaceContainerHigh)
                .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }

    // MARK: - Launch Sequence Animation
    private func runLaunchSequence() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showRocket = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            showTitle = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            showSubtitle = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
            showFeatures = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(1.1)) {
            showButtons = true
        }
        // Start continuous rocket pulse after entrance
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(1.2)) {
            rocketPulse = true
        }
    }
}
