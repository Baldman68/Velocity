import SwiftUI

/// Shown as a fullScreenCover for returning users after a magic link OTP is sent
/// (`authState == .awaitingMagicLink`). Automatically dismissed when the auth state
/// transitions away (e.g. to `.signedInFullyOnboarded` after the link is clicked).
struct MagicLinkSentView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        ZStack {
            Color.velocityBackground.ignoresSafeArea()

            // Atmospheric glow
            Circle()
                .fill(Color.nitroBlue.opacity(0.06))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(y: -200)
                .ignoresSafeArea()

            VStack(spacing: VelocitySpacing.xl) {
                Spacer()

                // Envelope icon
                envelopeIcon

                // Copy
                copySection

                // Action buttons
                actionButtons

                Spacer()
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
        }
    }

    // MARK: - Envelope Icon

    private var envelopeIcon: some View {
        ZStack {
            Circle()
                .fill(Color.nitroBlue.opacity(0.1))
                .frame(width: 120, height: 120)

            Circle()
                .fill(LinearGradient.nitroGradient)
                .frame(width: 80, height: 80)
                .shadow(color: Color.nitroBlue.opacity(0.4), radius: 24)

            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 34))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Copy

    private var copySection: some View {
        VStack(spacing: VelocitySpacing.sm) {
            Text("CHECK YOUR EMAIL")
                .font(.headlineMedium())
                .foregroundStyle(Color.onSurface)
                .tracking(-0.5)

            if !authService.pendingEmail.isEmpty {
                VStack(spacing: 4) {
                    Text("We sent a magic link to")
                        .font(.bodyMedium())
                        .foregroundStyle(Color.onSurfaceVariant)

                    Text(authService.pendingEmail)
                        .font(.bodyMedium())
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.nitroBlue)
                }
            }

            Text("It may take a few minutes. Tap the link in that email to sign in — no password needed.")
                .font(.bodySmall())
                .foregroundStyle(Color.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, VelocitySpacing.lg)
                .padding(.top, VelocitySpacing.xs)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: VelocitySpacing.md) {
            // Resend
            Button(action: resend) {
                HStack(spacing: VelocitySpacing.sm) {
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.onNitroBlue)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(authService.isLoading ? "SENDING..." : "RESEND MAGIC LINK")
                        .font(.labelCaps())
                        .tracking(0.96)
                }
                .foregroundStyle(Color.onNitroBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, VelocitySpacing.md)
                .background(Color.nitroBlue)
                .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.component))
                .shadow(color: Color.nitroBlue.opacity(0.3), radius: 12, y: 4)
            }
            .disabled(authService.isLoading || authService.pendingEmail.isEmpty)

            // Cancel
            Button("Use a different email", action: cancel)
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)
                .padding(.top, VelocitySpacing.xs)
        }
    }

    // MARK: - Actions

    private func resend() {
        guard !authService.pendingEmail.isEmpty else { return }
        Task {
            await authService.requestMagicLink(
                email: authService.pendingEmail,
                isNewUser: false
            )
        }
    }

    private func cancel() {
        authService.pendingEmail = ""
        authService.authState = .signedOut
    }
}
