import SwiftUI

struct ProfileSetupView: View {
    var onContinue: () -> Void

    @State private var firstName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var showHeader = false
    @State private var showForm = false
    @State private var showButton = false
    @State private var avatarRingRotation: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: VelocitySpacing.lg) {
                Spacer().frame(height: VelocitySpacing.xl)

                // CREATE YOUR PILOT PROFILE
                Text("CREATE YOUR\nPILOT PROFILE")
                    .font(.headlineHero())
                    .foregroundStyle(Color.onSurface)
                    .multilineTextAlignment(.center)
                    .opacity(showHeader ? 1 : 0)
                    .offset(y: showHeader ? 0 : 16)

                Text("We'll send a magic link to your email to verify your account.")
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, VelocitySpacing.lg)
                    .opacity(showHeader ? 1 : 0)
                    .offset(y: showHeader ? 0 : 12)

                // Avatar chooser
                avatarSection
                    .opacity(showForm ? 1 : 0)
                    .scaleEffect(showForm ? 1.0 : 0.85)

                // Form fields
                formSection
                    .opacity(showForm ? 1 : 0)
                    .offset(y: showForm ? 0 : 20)

                // CONTINUE button
                Button(action: onContinue) {
                    HStack(spacing: VelocitySpacing.xs) {
                        Text("CONTINUE")
                            .font(.labelCaps())
                            .tracking(1.5)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, VelocitySpacing.md)
                    .background(LinearGradient.nitroGradient)
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.component))
                    .shadow(color: Color.nitroBlue.opacity(0.4), radius: 12, y: 4)
                }
                .padding(.horizontal, VelocitySpacing.edgeMargin)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 20)

                // Terms
                Text("BY CONTINUING, YOU AGREE TO THE COASTER CHASE PROTOCOL AND MISSION DIRECTIVES.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.velocityOutline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, VelocitySpacing.xl)
                    .opacity(showButton ? 1 : 0)

                Spacer().frame(height: VelocitySpacing.xl)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear { runEntrance() }
    }

    // MARK: - Avatar Section
    private var avatarSection: some View {
        VStack(spacing: VelocitySpacing.xs) {
            Text("CHOOSE YOUR AVATAR")
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)

            ZStack {
                // Animated dashed ring
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(colors: [Color.nitroBlue, Color.nitroBlue.opacity(0.2), Color.nitroBlue]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )
                    .frame(width: 96, height: 96)
                    .rotationEffect(.degrees(avatarRingRotation))

                // Avatar circle
                Circle()
                    .fill(Color.velocitySurfaceContainerHigh)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(Color.nitroBlue)
                    )
            }
        }
    }

    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: VelocitySpacing.md) {
            // First Name
            onboardingField(
                label: "FIRST NAME",
                icon: "person",
                text: $firstName,
                placeholder: "Enter your name"
            )

            // Public Username
            VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
                onboardingField(
                    label: "PUBLIC USERNAME",
                    icon: "at",
                    text: $username,
                    placeholder: "Choose a handle"
                )

                // Pro tip
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.nitroBlue)
                    Text("PRO TIP: USE A COOL HANDLE FOR THE LEADERBOARDS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.nitroBlue)
                        .tracking(0.5)
                }
                .padding(.horizontal, VelocitySpacing.edgeMargin)
            }

            // Email
            onboardingField(
                label: "EMAIL ADDRESS",
                icon: "envelope",
                text: $email,
                placeholder: "your@email.com"
            )
        }
    }

    // MARK: - Styled Input Field
    private func onboardingField(label: String, icon: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
            Text(label)
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)
                .padding(.horizontal, VelocitySpacing.edgeMargin)

            HStack(spacing: VelocitySpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.velocityOutline)
                    .frame(width: 20)

                TextField(placeholder, text: text)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurface)
            }
            .padding(.horizontal, VelocitySpacing.md)
            .padding(.vertical, VelocitySpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: VelocityRadius.component)
                    .fill(Color.velocitySurfaceContainerLowest)
                    .overlay(
                        RoundedRectangle(cornerRadius: VelocityRadius.component)
                            .stroke(Color.velocityOutline.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, VelocitySpacing.edgeMargin)
        }
    }

    // MARK: - Entrance Animation
    private func runEntrance() {
        withAnimation(.easeOut(duration: 0.5)) {
            showHeader = true
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
            showForm = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            showButton = true
        }
        // Continuous avatar ring spin
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false).delay(0.4)) {
            avatarRingRotation = 360
        }
    }
}
