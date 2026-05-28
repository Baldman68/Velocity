import SwiftUI

struct NotificationsPermissionView: View {
    var onEnable: () -> Void
    var onSkip: () -> Void

    @State private var showCard1 = false
    @State private var showCard2 = false
    @State private var showContent = false
    @State private var showButtons = false
    @State private var bellShake = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Preview notification cards
            VStack(spacing: VelocitySpacing.sm) {
                // Leaderboard Update card
                notificationCard(
                    icon: "location.fill",
                    iconColor: Color.nitroBlue,
                    tag: "LEADERBOARD UPDATE",
                    message: "You've been overtaken on the leaderboard! Racer_X just set a new record on Nitro Fury."
                )
                .offset(x: showCard1 ? 0 : -300)
                .opacity(showCard1 ? 1 : 0)

                // Ride Alert card
                notificationCard(
                    icon: "bell.fill",
                    iconColor: Color.pulseOrange,
                    tag: "RIDE ALERT",
                    message: "Iron Menace wait time decreased to 15 mins."
                )
                .offset(x: showCard2 ? 0 : 300)
                .opacity(showCard2 ? 1 : 0)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)

            Spacer().frame(height: VelocitySpacing.xl)

            // Bell icon with shake
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.nitroBlue)
                .rotationEffect(.degrees(bellShake ? 10 : 0), anchor: .top)
                .opacity(showContent ? 1 : 0)
                .padding(.bottom, VelocitySpacing.md)

            // STAY IN THE LOOP
            Text("STAY IN THE LOOP")
                .font(.headlineHero())
                .foregroundStyle(Color.onSurface)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 16)

            // Description
            Text("Get alerts for ride status changes, leaderboard updates, and friend challenges. Never miss a thrill.")
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
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 16))
                        Text("Turn on Notifications")
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

                Button("Skip for now", action: onSkip)
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

    // MARK: - Notification Card
    private func notificationCard(icon: String, iconColor: Color, tag: String, message: String) -> some View {
        HStack(alignment: .top, spacing: VelocitySpacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: VelocitySpacing.base) {
                Text(tag)
                    .font(.labelCaps())
                    .foregroundStyle(iconColor)
                    .tracking(0.96)

                Text(message)
                    .font(.bodySmall())
                    .foregroundStyle(Color.onSurface)
                    .lineSpacing(2)
            }
        }
        .padding(VelocitySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: VelocityRadius.card)
                .fill(Color.velocitySurfaceContainer)
                .overlay(
                    RoundedRectangle(cornerRadius: VelocityRadius.card)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Entrance Animation
    private func runEntrance() {
        // Card 1 slides in from left
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
            showCard1 = true
        }
        // Card 2 slides in from right
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.35)) {
            showCard2 = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            showContent = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
            showButtons = true
        }
        // Bell shake sequence after content appears
        runBellShake(after: 0.8)
    }

    private func runBellShake(after delay: Double) {
        let baseDelay = delay
        // Quick shake: right → left → right → center
        DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay) {
            withAnimation(.easeInOut(duration: 0.08)) { bellShake = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay + 0.08) {
            withAnimation(.easeInOut(duration: 0.08)) { bellShake = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay + 0.16) {
            withAnimation(.easeInOut(duration: 0.06)) { bellShake = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay + 0.22) {
            withAnimation(.easeInOut(duration: 0.12)) { bellShake = false }
        }
        // Repeat every 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay + 3.0) {
            runBellShake(after: 0)
        }
    }
}
