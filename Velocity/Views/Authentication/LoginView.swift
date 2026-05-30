import SwiftUI

/// Sign-in screen for returning users. Sends a magic link OTP — no password required.
/// Shown as a fullScreenCover when `hasCompletedOnboarding && authState == .signedOut`.
struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var email = ""
    @FocusState private var isEmailFocused: Bool

    var body: some View {
        ZStack {
            Color.velocityBackground.ignoresSafeArea()

            // Atmospheric glow
            Circle()
                .fill(Color.nitroBlue.opacity(0.06))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(x: 100, y: -200)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Brand header
                headerSection
                    .padding(.top, VelocitySpacing.xl)

                Spacer()

                // Form card
                formCard
                    .padding(.horizontal, VelocitySpacing.edgeMargin)

                Spacer()

                // "Don't have an account" footer
                Button(action: goToOnboarding) {
                    Text("I don't have an account")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(0.96)
                }
                .padding(.bottom, VelocitySpacing.xl)
            }
        }
        .task { isEmailFocused = true }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: VelocitySpacing.sm) {
            HStack(spacing: VelocitySpacing.xs) {
                Image("velocity_rocket")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(Color.nitroBlue)

                Text("VELOCITY")
                    .font(.headlineLarge())
                    .foregroundStyle(Color.nitroBlue)
                    .tracking(-0.5)
            }

            Text("WELCOME BACK, RIDER")
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(3)
        }
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.xl) {
            // Section header
            VStack(alignment: .center, spacing: VelocitySpacing.xs) {
                Text("SIGN IN")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)

                Text("Enter your email and we'll send you a magic link. No password needed.")
                    .font(.bodySmall())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            // Email field
            VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
                Text("EMAIL ADDRESS")
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)

                HStack(spacing: VelocitySpacing.sm) {
                    Image(systemName: "envelope")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.velocityOutline)
                        .frame(width: 20)

                    TextField("alex@velocity.com", text: $email)
                        .font(.bodyMedium())
                        .foregroundStyle(Color.onSurface)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isEmailFocused)
                        .onSubmit { sendMagicLink() }
                }
                .padding(.horizontal, VelocitySpacing.md)
                .padding(.vertical, VelocitySpacing.sm)
                .background(inputBackground)
            }

            // Error message
            if let error = authService.errorMessage {
                HStack(spacing: VelocitySpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                    Text(error)
                        .font(.bodySmall())
                }
                .foregroundStyle(Color.velocityError)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Send Magic Link button
            Button(action: sendMagicLink) {
                HStack(spacing: VelocitySpacing.sm) {
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.onNitroBlue)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))
                    }
                    Text(authService.isLoading ? "SENDING LINK..." : "SEND MAGIC LINK")
                        .font(.labelCaps())
                        .tracking(0.96)
                }
                .foregroundStyle(Color.onNitroBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, VelocitySpacing.md)
                .background(canSend ? Color.nitroBlue : Color.velocityOutlineVariant)
                .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.component))
                .shadow(color: canSend ? Color.nitroBlue.opacity(0.3) : .clear, radius: 12, y: 4)
            }
            .disabled(!canSend)
            .animation(.easeInOut(duration: 0.2), value: authService.isLoading)
        }
        .padding(VelocitySpacing.xl)
        .background(cardBackground)
    }

    // MARK: - Helpers

    private var canSend: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !authService.isLoading
    }

    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: VelocityRadius.component)
            .fill(Color.velocitySurfaceContainerLowest)
            .overlay(
                RoundedRectangle(cornerRadius: VelocityRadius.component)
                    .stroke(Color.velocityOutlineVariant.opacity(0.5), lineWidth: 1)
            )
    }

    private var cardBackground: some View {
        ZStack {
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

            // Glow blobs
            Circle()
                .fill(Color.nitroBlue.opacity(0.08))
                .frame(width: 200, height: 200)
                .blur(radius: 80)
                .offset(x: 80, y: -80)

            Circle()
                .fill(Color.pulseOrange.opacity(0.04))
                .frame(width: 160, height: 160)
                .blur(radius: 60)
                .offset(x: -80, y: 80)
        }
    }

    private func sendMagicLink() {
        guard canSend else { return }
        Task {
            await authService.requestMagicLink(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                isNewUser: false
            )
        }
    }

    private func goToOnboarding() {
        authService.clearPendingProfile()
        hasCompletedOnboarding = false
    }
}
