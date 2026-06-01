import SwiftUI
import UIKit

struct EditProfileView: View {
    @State private var profile: Profile?
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var publicUserName = ""
    @State private var email = ""
    @State private var selectedAvatar: String = "avatar00"
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var saved = false
    @State private var errorMessage: String?
    @AppStorage("selectedAvatarName") private var storedAvatarName = "avatar00"
    @Environment(\.dismiss) private var dismiss

    private let profileService = ProfileService()

    // Available avatar asset names (matching onboarding)
    private let avatarNames = (0...11).map { String(format: "avatar%02d", $0) }

    var body: some View {
        ScrollView {
            VStack(spacing: VelocitySpacing.lg) {
                // Header
                VStack(spacing: VelocitySpacing.xs) {
                    Text("PILOT DOSSIER")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(1.5)
                    Text("EDIT PROFILE")
                        .font(.headlineHero())
                        .foregroundStyle(Color.nitroBlue)
                        .italic()
                }
                .frame(maxWidth: .infinity)
                .padding(.top, VelocitySpacing.sm)

                if isLoading {
                    ProgressView().tint(Color.nitroBlue)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    // Avatar Section
                    avatarSection

                    // Editable Fields
                    sectionLabel("PERSONAL INFO")
                    editableField(label: "FIRST NAME", icon: "person", text: $firstName)
                    editableField(label: "LAST NAME", icon: "person", text: $lastName)
                    editableField(label: "PUBLIC USERNAME", icon: "at", text: $publicUserName)

                    // Read-only Email
                    sectionLabel("ACCOUNT")
                    lockedField(label: "EMAIL", icon: "envelope", value: email)

                    // Error
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.bodySmall())
                            .foregroundStyle(Color.velocityError)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Save Button
                    saveButton

                    // Success indicator
                    if saved {
                        HStack(spacing: VelocitySpacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.green)
                            Text("Profile updated")
                                .font(.bodySmall())
                                .foregroundStyle(Color.onSurfaceVariant)
                        }
                    }
                }
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
            .padding(.bottom, VelocitySpacing.xl)
        }
        .background(Color.velocityBackground)
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: VelocitySpacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("VELOCITY")
                            .font(.custom("ArchivoNarrow-Bold", size: 18))
                            .italic()
                    }
                    .foregroundStyle(Color.nitroBlue)
                }
            }
        }
        .toolbarBackground(Color.velocitySurface.opacity(0.8), for: .navigationBar)
        .task { await loadProfile() }
    }

    // MARK: - Avatar Section
    private var avatarSection: some View {
        VStack(spacing: VelocitySpacing.md) {
            sectionLabel("CHOOSE AVATAR")

            // Current avatar preview
            ZStack {
                Circle()
                    .fill(Color.velocitySurfaceContainerHighest)
                    .frame(width: 80, height: 80)

                if let img = UIImage(named: selectedAvatar) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } else {
                    Text(firstName.prefix(1).uppercased())
                        .font(.headlineHero())
                        .foregroundStyle(Color.nitroBlue)
                }
            }
            .overlay(Circle().stroke(Color.nitroBlue, lineWidth: 2))

            // Avatar grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: VelocitySpacing.sm) {
                    ForEach(avatarNames, id: \.self) { name in
                        Button {
                            selectedAvatar = name
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.velocitySurfaceContainerHigh)
                                    .frame(width: 56, height: 56)

                                if let img = UIImage(named: name) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipShape(Circle())
                                }
                            }
                            .overlay(
                                Circle().stroke(
                                    selectedAvatar == name ? Color.nitroBlue : Color.clear,
                                    lineWidth: 2
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Editable Field
    private func editableField(label: String, icon: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.base) {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.nitroBlue)
                    .frame(width: 20)
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)
            }
            TextField(label.capitalized, text: text)
                .font(.bodyMedium())
                .foregroundStyle(Color.onSurface)
                .padding(VelocitySpacing.md)
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

    // MARK: - Locked Field (read-only)
    private func lockedField(label: String, icon: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.base) {
            HStack(spacing: VelocitySpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.onSurfaceVariant)
                    .frame(width: 20)
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            HStack {
                Text(value.isEmpty ? "Not set" : value)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurfaceVariant)
                Spacer()
            }
            .padding(VelocitySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: VelocityRadius.component)
                    .fill(Color.velocitySurfaceContainerLow)
                    .overlay(
                        RoundedRectangle(cornerRadius: VelocityRadius.component)
                            .stroke(Color.velocityOutlineVariant.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            HStack(spacing: VelocitySpacing.xs) {
                if isSaving {
                    ProgressView().tint(Color.onNitroBlueContainer)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                }
                Text("SAVE CHANGES")
                    .font(.labelCaps())
                    .tracking(0.96)
            }
            .foregroundStyle(Color.onNitroBlueContainer)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: VelocityRadius.xl)
                    .fill(LinearGradient.nitroGradient)
            )
            .shadow(color: Color.nitroBlue.opacity(0.3), radius: 16, y: 4)
        }
        .disabled(isSaving)
    }

    // MARK: - Helpers
    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.labelCaps())
            .foregroundStyle(Color.onSurfaceVariant)
            .tracking(0.96)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, VelocitySpacing.xs)
    }

    private func loadProfile() async {
        isLoading = true
        do {
            if let p = try await profileService.fetchCurrentProfile() {
                profile = p
                firstName = p.firstName ?? ""
                lastName = p.lastName ?? ""
                publicUserName = p.publicUserName ?? ""
                email = p.email ?? ""
                selectedAvatar = p.avatarName ?? storedAvatarName
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func save() async {
        guard let profile else { return }
        isSaving = true
        errorMessage = nil
        saved = false
        do {
            try await profileService.updateProfile(
                id: profile.id,
                firstName: firstName,
                lastName: lastName,
                publicUserName: publicUserName,
                avatarName: selectedAvatar
            )
            storedAvatarName = selectedAvatar
            withAnimation { saved = true }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
