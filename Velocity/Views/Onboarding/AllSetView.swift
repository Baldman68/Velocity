import SwiftUI

struct AllSetView: View {
    var onEnterPark: () -> Void

    @State private var showCircle = false
    @State private var showBadge = false
    @State private var showText = false
    @State private var showButton = false
    @State private var sparks: [Spark] = []
    @State private var sparkTimer: Timer?

    var body: some View {
        ZStack {
            // Velocity diagonal pattern background
            diagonalPattern
                .ignoresSafeArea()

            // Gradient overlay
            LinearGradient(
                colors: [Color.velocityBackground, .clear, .clear, Color.velocityBackground],
                startPoint: .bottom,
                endPoint: .top
            )
            .opacity(0.8)
            .ignoresSafeArea()

            // Spark particles
            ForEach(sparks) { spark in
                Circle()
                    .fill(Color.nitroBlueDim)
                    .frame(width: spark.size, height: spark.size)
                    .blur(radius: 1)
                    .position(x: spark.x, y: spark.y)
                    .opacity(spark.opacity)
            }

            // Main content
            VStack(spacing: 0) {
                Spacer()

                // Large visual circle with coaster loop image
                visualCircle
                    .scaleEffect(showCircle ? 1 : 0.5)
                    .opacity(showCircle ? 1 : 0)

                Spacer().frame(height: VelocitySpacing.lg)

                // Typography
                VStack(spacing: VelocitySpacing.sm) {
                    Text("READY FOR LAUNCH")
                        .font(.headlineLarge())
                        .foregroundStyle(Color.nitroBlue)
                        .tracking(-0.5)

                    Text("Your profile is locked in. It's time to chase the coaster count.")
                        .font(.bodyLarge())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }
                .opacity(showText ? 1 : 0)
                .offset(y: showText ? 0 : 16)

                Spacer().frame(height: VelocitySpacing.xl)

                // Action area
                VStack(spacing: VelocitySpacing.md) {
                    Button(action: onEnterPark) {
                        HStack(spacing: VelocitySpacing.sm) {
                            Text("Enter the Park")
                                .font(.labelCaps())
                                .tracking(0.96)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(Color.onNitroBlueContainer)
                        .frame(maxWidth: 260)
                        .padding(.vertical, VelocitySpacing.md)
                        .background(Color.nitroBlue)
                        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))
                        .shadow(color: Color.nitroBlue.opacity(0.4), radius: 20)
                    }

                    // "System Optimal" with flanking dividers
                    HStack(spacing: VelocitySpacing.md) {
                        Rectangle()
                            .fill(Color.velocityOutlineVariant)
                            .frame(width: 32, height: 1)

                        Text("System Optimal")
                            .font(.labelCaps())
                            .foregroundStyle(Color.onSurfaceVariant)
                            .tracking(0.96)

                        Rectangle()
                            .fill(Color.velocityOutlineVariant)
                            .frame(width: 32, height: 1)
                    }
                    .opacity(0.6)
                }
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 20)

                Spacer()
            }
        }
        .onAppear { runCelebration() }
        .onDisappear { sparkTimer?.invalidate() }
    }

    // MARK: - Visual Circle (matches design: full circle, coaster loop image, screen blend, gradient tint, verified badge)
    private var visualCircle: some View {
        ZStack {
            // The large glassmorphic circle
            Circle()
                .fill(Color.velocitySurfaceContainerLow.opacity(0.4))
                .frame(width: 280, height: 280)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .overlay(
                    // Coaster loop image inside circle
                    Image("onboarding_allset_loop")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 280, height: 280)
                        .opacity(0.6)
                        .blendMode(.screen)
                        .clipShape(Circle())
                )
                .overlay(
                    // Gradient tint overlay
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.nitroBlue.opacity(0.2), .clear],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )
                )

            // "Profile Verified" badge — rotated 12deg, top-right
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                Text("Profile Verified")
                    .font(.labelCaps())
                    .tracking(0.96)
            }
            .foregroundStyle(Color.onNitroBlueContainer)
            .padding(.horizontal, VelocitySpacing.sm)
            .padding(.vertical, VelocitySpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: VelocityRadius.xl)
                    .fill(Color.nitroBlue)
                    .shadow(color: Color.nitroBlue.opacity(0.3), radius: 8, y: 4)
            )
            .rotationEffect(.degrees(12))
            .offset(x: 80, y: -110)
            .scaleEffect(showBadge ? 1 : 0)
        }
    }

    // MARK: - Diagonal Pattern
    private var diagonalPattern: some View {
        Canvas { context, size in
            let spacing: CGFloat = 100
            let lineWidth: CGFloat = 1
            let color = Color.white.opacity(0.03)

            var x: CGFloat = -size.height
            while x < size.width + size.height {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                context.stroke(path, with: .color(color), lineWidth: lineWidth)
                x += spacing
            }
        }
        .opacity(0.2)
    }

    // MARK: - Celebration Animation
    private func runCelebration() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.1)) {
            showCircle = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.5)) {
            showBadge = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            showText = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            showButton = true
        }

        // Continuous spark generation (matches design's JS spark-float animation)
        startSparks()
    }

    private func startSparks() {
        // Initial burst
        for _ in 0..<15 {
            addSpark()
        }
        // Continuous generation
        sparkTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            addSpark()
        }
    }

    private func addSpark() {
        let screenWidth = UIScreen.main.bounds.width
        let centerX = screenWidth / 2
        let centerY: CGFloat = 300 // approximate circle center

        let spark = Spark(
            id: UUID(),
            x: centerX + CGFloat.random(in: -140...140),
            y: centerY + CGFloat.random(in: -140...140),
            size: CGFloat.random(in: 3...6),
            opacity: 0
        )
        sparks.append(spark)

        let idx = sparks.count - 1
        let duration = 1.0 + Double.random(in: 0...2)

        // Animate: fade in, float up, fade out
        withAnimation(.easeOut(duration: duration * 0.5)) {
            if idx < sparks.count {
                sparks[idx].opacity = 1
            }
        }
        withAnimation(.easeIn(duration: duration * 0.5).delay(duration * 0.5)) {
            if idx < sparks.count {
                sparks[idx].y -= 100
                sparks[idx].opacity = 0
            }
        }

        // Remove after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            sparks.removeAll { $0.id == spark.id }
        }
    }
}

// MARK: - Spark Model
struct Spark: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
}
