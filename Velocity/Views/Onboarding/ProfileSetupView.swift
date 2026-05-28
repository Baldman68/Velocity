import SwiftUI
import Supabase

struct ProfileSetupView: View {
    var onContinue: () -> Void

    @State private var firstName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var selectedAvatar: Int? = nil
    @State private var showContent = false
    @State private var showForm = false
    @State private var showButton = false

    private let avatarNames = ["avatar00", "avatar01", "avatar02", "avatar03", "avatar04"]

    var body: some View {
        VStack(spacing: 0) {
            // Top brand header
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: "location.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.nitroBlue)
                Text("COASTER CHASE")
                    .font(.headlineLarge())
                    .foregroundStyle(Color.nitroBlue)
                    .tracking(-0.5)
            }
            .frame(height: 56)

            ScrollView {
                VStack(spacing: 0) {
                    // Glass form card
                    formCard
                        .padding(.horizontal, VelocitySpacing.edgeMargin)
                        .padding(.top, VelocitySpacing.lg)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)

                    // Footer
                    Text("ENCRYPTED END-TO-END DATA SYNC")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.velocityOutlineVariant.opacity(0.4))
                        .tracking(2)
                        .padding(.top, VelocitySpacing.lg)
                        .padding(.bottom, VelocitySpacing.xl)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showForm = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
                showButton = true
            }
        }
    }

    // MARK: - Form Card (glass-card with glow blobs)
    private var formCard: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.xl) {
            // Header
            VStack(alignment: .center, spacing: VelocitySpacing.xs) {
                Text("CREATE YOUR PILOT PROFILE")
                    .font(.headlineLarge())
                    .foregroundStyle(Color.nitroBlue)
                    .tracking(-0.5)

                Text("We'll send a magic link to your email to verify your account.")
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            // Avatar grid (4-5 columns matching design)
            avatarGrid
                .opacity(showForm ? 1 : 0)

            // Input fields
            VStack(spacing: VelocitySpacing.md) {
                inputField(label: "FIRST NAME", icon: "person", placeholder: "Alex", text: $firstName)
                VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
                    inputField(label: "PUBLIC USERNAME", icon: "at", placeholder: "Alex CoasterChaser", text: $username)
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.nitroBlue.opacity(0.6))
                        Text("PRO TIP: USE A COOL HANDLE FOR THE LEADERBOARDS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.nitroBlue.opacity(0.6))
                            .tracking(0.6)
                    }
                }
                inputField(label: "EMAIL ADDRESS", icon: "envelope", placeholder: "alex@velocity.com", text: $email)
            }
            .opacity(showForm ? 1 : 0)

            // CONTINUE button
            Button(action: {
                // Save to Supabase profile if authenticated
                onContinue()
            }) {
                HStack(spacing: VelocitySpacing.sm) {
                    Text("CONTINUE")
                        .font(.labelCaps())
                        .tracking(0.96)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                }
                .foregroundStyle(Color.onNitroBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, VelocitySpacing.md)
                .background(Color.nitroBlue)
                .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.component))
            }
            .padding(.top, VelocitySpacing.lg)
            .opacity(showButton ? 1 : 0)

            // Terms
            Text("BY CONTINUING, YOU AGREE TO THE COASTER CHASE PROTOCOL AND MISSION DIRECTIVES.")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.onSurfaceVariant.opacity(0.5))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(VelocitySpacing.xl)
        .background(
            ZStack {
                // Glass card background
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

                // Atmospheric glow blobs (top-right primary, bottom-left secondary)
                Circle()
                    .fill(Color.nitroBlue.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .blur(radius: 80)
                    .offset(x: 80, y: -120)

                Circle()
                    .fill(Color.pulseOrange.opacity(0.05))
                    .frame(width: 200, height: 200)
                    .blur(radius: 80)
                    .offset(x: -80, y: 120)
            }
        )
    }

    // MARK: - Avatar Grid (matches design: grid-cols-5, 56px circles, selected = nitro glow)
    private var avatarGrid: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            Text("CHOOSE YOUR AVATAR")
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: VelocitySpacing.md), count: 5), spacing: VelocitySpacing.md) {
                ForEach(0..<avatarNames.count, id: \.self) { index in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedAvatar = index
                        }
                    } label: {
                        Image(avatarNames[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        selectedAvatar == index ? Color.nitroBlue : Color.velocityOutlineVariant.opacity(0.3),
                                        lineWidth: 2
                                    )
                            )
                            .scaleEffect(selectedAvatar == index ? 1.1 : 1.0)
                            .shadow(color: selectedAvatar == index ? Color.nitroBlue.opacity(0.4) : .clear, radius: 12)
                    }
                    .buttonStyle(.plain)
                }

                // Upload button (dashed circle)
                Button {} label: {
                    Circle()
                        .strokeBorder(Color.velocityOutlineVariant, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.velocitySurfaceContainerLow))
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.nitroBlue)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Input Field (matches design: surface-container-lowest bg, outline-variant border, nitro glow on focus)
    private func inputField(label: String, icon: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
            Text(label)
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)

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
                            .stroke(Color.velocityOutlineVariant.opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }
}
