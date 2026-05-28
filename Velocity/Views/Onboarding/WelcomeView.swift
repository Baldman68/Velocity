import SwiftUI

struct WelcomeView: View {
    var onGetStarted: () -> Void
    var onLogin: () -> Void

    // Staggered animation states
    @State private var showBranding = false
    @State private var showCard = false
    @State private var showPills = false
    @State private var showButtons = false
    @State private var heroScale: CGFloat = 1.05

    var body: some View {
        ZStack {
            // MARK: - Full-screen hero background image
            GeometryReader { geo in
                Image("onboarding_welcome_hero")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(heroScale)
                    .brightness(-0.4)
                    .contrast(1.1)
                    .clipped()
            }
            .ignoresSafeArea()

            // Gradient overlay: transparent at top → background at bottom
            LinearGradient(
                colors: [
                    .clear,
                    Color.velocityBackground.opacity(0.4),
                    Color.velocityBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // MARK: - Diagonal speed lines (subtle decoration)
            speedLines
                .ignoresSafeArea()

            // MARK: - Content
            VStack(spacing: 0) {
                // Top branding: rocket icon + VELOCITY
                topBranding
                    .padding(.top, VelocitySpacing.xl)
                    .opacity(showBranding ? 1 : 0)
                    .offset(y: showBranding ? 0 : -20)

                Spacer()

                // Bottom glass card
                bottomCard
                    .padding(.horizontal, VelocitySpacing.edgeMargin)
                    .padding(.bottom, VelocitySpacing.xl)
                    .opacity(showCard ? 1 : 0)
                    .offset(y: showCard ? 0 : 40)
            }
        }
        .onAppear { runLaunchSequence() }
    }

    // MARK: - Top Branding
    private var topBranding: some View {
        HStack(spacing: VelocitySpacing.xs) {
            Image(systemName: "location.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.nitroBlue)

            Text("VELOCITY")
                .font(.headlineLarge())
                .foregroundStyle(Color.nitroBlue)
                .tracking(-0.5)
        }
    }

    // MARK: - Bottom Glass Card
    private var bottomCard: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            // "Launch Sequence" label
            Text("Launch Sequence")
                .font(.labelCaps())
                .foregroundStyle(Color.nitroBlue)
                .tracking(2.4)  // 0.2em

            // "FEEL THE RUSH" headline
            VStack(alignment: .leading, spacing: 0) {
                Text("FEEL THE")
                    .font(.headlineHero())
                    .foregroundStyle(Color.onSurface)
                Text("RUSH")
                    .font(.headlineHero())
                    .foregroundStyle(Color.nitroBlue)
            }

            // Description
            Text("The ultimate tracker for rollercoaster enthusiasts. Research, review, and compete with a global community of riders.")
                .font(.bodyLarge())
                .foregroundStyle(Color.onSurfaceVariant)
                .lineSpacing(4)

            // Feature pills — flow/wrap layout
            FlowLayout(spacing: VelocitySpacing.xs) {
                featurePill(icon: "chart.bar.fill", label: "TECH STATS")
                featurePill(icon: "trophy.fill", label: "LEADERBOARDS")
                featurePill(icon: "checkmark.shield.fill", label: "CREDITS")
            }
            .padding(.vertical, VelocitySpacing.xs)
            .opacity(showPills ? 1 : 0)

            // CTA section
            VStack(spacing: VelocitySpacing.md) {
                // GET STARTED button
                Button(action: onGetStarted) {
                    HStack(spacing: VelocitySpacing.xs) {
                        Text("GET STARTED")
                            .font(.labelCaps())
                            .tracking(0.96)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(Color.onNitroBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, VelocitySpacing.md)
                    .background(LinearGradient.nitroGradient)
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))
                    .shadow(color: Color.nitroBlue.opacity(0.4), radius: 16, y: 4)
                }

                // LOGIN
                Button("LOGIN", action: onLogin)
                    .font(.labelCaps())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, VelocitySpacing.sm)
            .opacity(showButtons ? 1 : 0)
            .offset(y: showButtons ? 0 : 12)
        }
        .padding(VelocitySpacing.lg)
        .background(
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
        )
    }

    // MARK: - Feature Pill
    private func featurePill(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.nitroBlue)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.onSurface)
                .tracking(0.8)
        }
        .padding(.horizontal, VelocitySpacing.sm)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.velocitySurfaceContainerHighest.opacity(0.4))
                .overlay(
                    Capsule().stroke(Color.velocityOutlineVariant.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Speed Lines (diagonal decorative lines)
    private var speedLines: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.nitroBlueLight.opacity(0.2), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .rotationEffect(.degrees(-5))
                    .offset(y: CGFloat([-200, -50, 100, 250][i]))
                    .offset(x: CGFloat([-20, -40, 20, -10][i]))
            }
        }
        .opacity(0.2)
    }

    // MARK: - Launch Sequence Animation
    private func runLaunchSequence() {
        withAnimation(.easeOut(duration: 0.6)) {
            showBranding = true
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2)) {
            showCard = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
            showPills = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
            showButtons = true
        }
        // Subtle hero zoom on appearance
        withAnimation(.easeOut(duration: 8).delay(0.3)) {
            heroScale = 1.12
        }
    }
}

// MARK: - FlowLayout (wrapping layout for pills)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layoutSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layoutSubviews(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            guard index < result.positions.count else { break }
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: .unspecified
            )
        }
    }

    private func layoutSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (
            size: CGSize(width: maxWidth, height: currentY + lineHeight),
            positions: positions
        )
    }
}
