import SwiftUI

struct NotificationsPermissionView: View {
    var onEnable: () -> Void
    var onSkip: () -> Void

    @State private var showPhone = false
    @State private var showText = false
    @State private var showButtons = false
    @State private var phoneFloat: CGFloat = 0
    @State private var card1Pulse = false

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.nitroBlue)
                Spacer()
                Text("COASTER CHASE")
                    .font(.headlineMedium())
                    .foregroundStyle(Color.nitroBlue)
                    .tracking(-0.5)
                Spacer()
                Image(systemName: "person.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.nitroBlue)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
            .frame(height: 56)

            Spacer()

            // Floating phone mockup
            phoneMockup
                .scaleEffect(showPhone ? 1 : 0.85)
                .opacity(showPhone ? 1 : 0)
                .offset(y: phoneFloat)

            Spacer().frame(height: VelocitySpacing.xl)

            // STAY IN THE LOOP
            VStack(spacing: VelocitySpacing.sm) {
                Text("STAY IN THE LOOP")
                    .font(.headlineLarge())
                    .foregroundStyle(Color.nitroBlue)
                    .tracking(-0.5)

                Text("Get alerts for ride status changes, leaderboard updates, and friend challenges. Never miss a thrill.")
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, VelocitySpacing.lg)
            }
            .opacity(showText ? 1 : 0)
            .offset(y: showText ? 0 : 16)

            Spacer().frame(height: VelocitySpacing.xl)

            // Buttons
            VStack(spacing: VelocitySpacing.md) {
                Button(action: onEnable) {
                    HStack(spacing: VelocitySpacing.xs) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 18))
                        Text("Turn on Notifications")
                            .font(.headlineMedium())
                    }
                    .foregroundStyle(Color.onNitroBlueContainer)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, VelocitySpacing.md)
                    .background(Color.nitroBlue)
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))
                    .shadow(color: Color.nitroBlue.opacity(0.4), radius: 20)
                }

                Button("Skip for now", action: onSkip)
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)
                    .padding(.vertical, VelocitySpacing.xs)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
            .padding(.bottom, VelocitySpacing.xl)
            .opacity(showButtons ? 1 : 0)
            .offset(y: showButtons ? 0 : 20)
        }
        .onAppear { runEntrance() }
    }

    // MARK: - Phone Mockup (matches design: rounded-[40px], 6px border, notch, bg image, notification cards)
    private var phoneMockup: some View {
        ZStack {
            // Glow behind phone
            Circle()
                .fill(Color.nitroBlue.opacity(0.1))
                .blur(radius: 60)
                .frame(width: 300, height: 300)

            // Phone frame
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.velocitySurfaceContainerLowest)
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(Color.velocitySurfaceContainerHighest, lineWidth: 6)
                )
                .frame(width: 220, height: 420)
                .overlay(
                    ZStack {
                        // Background image inside phone
                        Image("onboarding_notifications_bg")
                            .resizable()
                            .scaledToFill()
                            .opacity(0.6)
                            .frame(width: 208, height: 408)
                            .clipShape(RoundedRectangle(cornerRadius: 34))

                        // Gradient overlay inside phone
                        LinearGradient(
                            colors: [.clear, Color.velocityBackground.opacity(0.4), Color.velocityBackground],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 34))

                        // Notch
                        VStack {
                            Capsule()
                                .fill(Color.velocitySurfaceContainerHighest)
                                .frame(width: 80, height: 24)
                                .offset(y: 6)
                            Spacer()
                        }

                        // Notification cards inside phone
                        VStack(spacing: 10) {
                            // Leaderboard Update card (with orange left border, pulsing)
                            notificationCard(
                                icon: "location.fill",
                                iconColor: Color.pulseOrange,
                                tag: "LEADERBOARD UPDATE",
                                tagColor: Color.onSurfaceVariant,
                                message: "You've been overtaken! **Racer_X** set a new record on Nitro Fury.",
                                accentBorder: Color.pulseOrange,
                                isPulsing: true
                            )
                            .opacity(card1Pulse ? 1 : 0.8)

                            // Ride Alert card (dimmer)
                            notificationCard(
                                icon: "bell",
                                iconColor: Color.nitroBlue,
                                tag: "RIDE ALERT",
                                tagColor: Color.onSurfaceVariant,
                                message: "Iron Menace wait time decreased to 15 mins.",
                                accentBorder: nil,
                                isPulsing: false
                            )
                            .opacity(0.6)
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 60)
                        .frame(width: 208, alignment: .top)

                        Spacer()
                    }
                    .frame(width: 208, height: 408)
                    .clipShape(RoundedRectangle(cornerRadius: 34))
                )
        }
    }

    // MARK: - Notification Card (inside phone)
    private func notificationCard(icon: String, iconColor: Color, tag: String, tagColor: Color, message: String, accentBorder: Color?, isPulsing: Bool) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(iconColor)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(tag)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(tagColor)
                    .tracking(0.6)

                Text(.init(message))  // Markdown bold support
                    .font(.system(size: 10))
                    .foregroundStyle(Color.onSurface)
                    .lineSpacing(1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.velocitySurfaceContainerLow.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .overlay(alignment: .leading) {
            if let border = accentBorder {
                Rectangle()
                    .fill(border)
                    .frame(width: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .padding(.vertical, 6)
            }
        }
    }

    // MARK: - Entrance
    private func runEntrance() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) {
            showPhone = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            showText = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            showButtons = true
        }
        // Floating phone
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true).delay(0.5)) {
            phoneFloat = -10
        }
        // Pulse first card
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.8)) {
            card1Pulse = true
        }
    }
}
