import SwiftUI

struct AllSetView: View {
    var onEnterPark: () -> Void

    @State private var showCheck = false
    @State private var showRing1 = false
    @State private var showRing2 = false
    @State private var showContent = false
    @State private var showButton = false
    @State private var statusPulse = false
    @State private var particles: [Particle] = []

    var body: some View {
        ZStack {
            // Particle layer
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
            }

            VStack(spacing: 0) {
                Spacer()

                // Verified badge
                Text("Profile Verified")
                    .font(.labelCaps())
                    .foregroundStyle(Color.nitroBlue)
                    .tracking(1.5)
                    .padding(.horizontal, VelocitySpacing.md)
                    .padding(.vertical, VelocitySpacing.xs)
                    .background(
                        Capsule().fill(Color.nitroBlue.opacity(0.12))
                    )
                    .opacity(showContent ? 1 : 0)
                    .padding(.bottom, VelocitySpacing.lg)

                // Checkmark with radiating rings
                ZStack {
                    // Ring 2 (outer)
                    Circle()
                        .stroke(Color.nitroBlue.opacity(0.08), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(showRing2 ? 1.0 : 0.5)
                        .opacity(showRing2 ? 1 : 0)

                    // Ring 1 (inner)
                    Circle()
                        .stroke(Color.nitroBlue.opacity(0.15), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(showRing1 ? 1.0 : 0.5)
                        .opacity(showRing1 ? 1 : 0)

                    // Main check circle
                    ZStack {
                        Circle()
                            .fill(LinearGradient.nitroGradient)
                            .frame(width: 88, height: 88)
                            .shadow(color: Color.nitroBlue.opacity(0.5), radius: 20)

                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(showCheck ? 1.0 : 0)
                }
                .padding(.bottom, VelocitySpacing.xl)

                // READY FOR LAUNCH
                Text("READY FOR\nLAUNCH")
                    .font(.headlineHero())
                    .foregroundStyle(Color.onSurface)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 16)

                // Description
                Text("Your profile is locked in. It's time to chase the coaster count.")
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, VelocitySpacing.sm)
                    .padding(.horizontal, VelocitySpacing.lg)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 12)

                Spacer()

                // Enter the Park button
                Button(action: onEnterPark) {
                    HStack(spacing: VelocitySpacing.xs) {
                        Text("Enter the Park")
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
                .padding(.horizontal, VelocitySpacing.edgeMargin)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 20)

                // System Optimal status
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.nitroBlue)
                        .frame(width: 6, height: 6)
                        .opacity(statusPulse ? 1 : 0.4)

                    Text("System Optimal")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(0.96)
                }
                .padding(.top, VelocitySpacing.md)
                .padding(.bottom, VelocitySpacing.xl)
                .opacity(showButton ? 1 : 0)
            }
        }
        .onAppear { runCelebration() }
    }

    // MARK: - Celebration Animation
    private func runCelebration() {
        // Checkmark bounce in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.1)) {
            showCheck = true
        }
        // Inner ring expands
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
            showRing1 = true
        }
        // Outer ring expands
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.45)) {
            showRing2 = true
        }
        // Burst particles at peak
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            spawnParticles()
        }
        // Content fades in
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            showContent = true
        }
        // Button slides up
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            showButton = true
        }
        // Pulsing status dot
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(1.2)) {
            statusPulse = true
        }
    }

    // MARK: - Particle Burst
    private func spawnParticles() {
        let colors: [Color] = [.nitroBlue, .pulseOrange, .nitroBlueLight, .pulseOrangeLight]
        var newParticles: [Particle] = []

        for i in 0..<20 {
            let angle = Double(i) / 20.0 * 2 * .pi
            let distance = CGFloat.random(in: 60...140)
            newParticles.append(Particle(
                id: i,
                x: 0, y: 0,
                targetX: cos(angle) * distance,
                targetY: sin(angle) * distance,
                size: CGFloat.random(in: 4...8),
                color: colors.randomElement()!,
                opacity: 1
            ))
        }

        particles = newParticles

        // Animate particles outward
        withAnimation(.easeOut(duration: 0.6)) {
            particles = particles.map { p in
                var updated = p
                updated.x = p.targetX
                updated.y = p.targetY
                return updated
            }
        }

        // Fade particles out
        withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
            particles = particles.map { p in
                var updated = p
                updated.opacity = 0
                return updated
            }
        }

        // Remove particles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            particles = []
        }
    }
}

// MARK: - Particle Model
struct Particle: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    var targetX: CGFloat = 0
    var targetY: CGFloat = 0
    var size: CGFloat
    var color: Color
    var opacity: Double
}
