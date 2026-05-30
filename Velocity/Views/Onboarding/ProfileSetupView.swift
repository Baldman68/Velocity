import SwiftUI
import PhotosUI
import Supabase
import UIKit

private enum ProfileSetupField: Hashable {
    case firstName
    case username
}

struct ProfileSetupView: View {
    var onBack: () -> Void
    var onContinue: (String, String, String, String) -> Void // firstName, username, email, avatarName

    @State private var firstName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var selectedAvatar: Int? = nil
    @State private var isCustomAvatarSelected = false
    @State private var customAvatarImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showAvatarSourceDialog = false
    @State private var showPhotoPicker = false
    @State private var showCameraPicker = false
    @State private var avatarSelectionError: String?
    @State private var showContent = false
    @State private var showForm = false
    @State private var showButton = false
    @State private var currentUsernameSuffix: String?
    @FocusState private var focusedField: ProfileSetupField?

    @AppStorage("selectedAvatarName") private var storedAvatarName = "avatar00"
    @AppStorage("usesCustomAvatar") private var usesCustomAvatar = false
    @AppStorage("customAvatarImageData") private var customAvatarImageData = Data()

    private let avatarNames = ["avatar00", "avatar01", "avatar02", "avatar03", "avatar04"]
    private let usernameSuffixes = [
        "CoasterChaser",
        "SkyDiver",
        "LoopDeLooper",
        "AirtimeAce",
        "DropZoneDynamo",
        "LaunchLunatic",
        "CorkscrewCaptain",
        "GForceGiggle",
        "LiftHillLegend",
        "InversionInspector",
        "BrakeRunBandit",
        "QueueSkipper",
        "TrackTornado",
        "LapBarHero",
        "ZeroGZigzagger"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Top brand header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.nitroBlue)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer()

                HStack(spacing: VelocitySpacing.xs) {
                    Image("velocity_rocket")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(Color.nitroBlue)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("VELOCITY")
                            .font(.headlineLarge())
                            .foregroundStyle(Color.nitroBlue)
                            .tracking(-0.5)
                        Text("COASTER CHASER")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.onSurfaceVariant)
                            .tracking(2)
                    }
                }

                Spacer()

                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
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
        .confirmationDialog("Choose Avatar Photo", isPresented: $showAvatarSourceDialog, titleVisibility: .visible) {
            Button("Choose from Camera Roll") {
                showPhotoPicker = true
            }

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Selfie") {
                    showCameraPicker = true
                }
            }

            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .fullScreenCover(isPresented: $showCameraPicker) {
            AvatarCameraPicker { image in
                applyCustomAvatar(image)
            }
            .ignoresSafeArea()
        }
        .alert(
            "Avatar Unavailable",
            isPresented: Binding(
                get: { avatarSelectionError != nil },
                set: { isPresented in
                    if !isPresented {
                        avatarSelectionError = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(avatarSelectionError ?? "")
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await loadSelectedPhoto(from: newItem)
            }
        }
        .onChange(of: focusedField) { oldValue, newValue in
            if oldValue == .firstName && newValue != .firstName {
                assignRandomUsername()
            }
        }
        .onAppear {
            loadStoredAvatar()

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
                firstNameField
                VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
                    publicUsernameField
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
                let avatarName = isCustomAvatarSelected ? "custom" : storedAvatarName
                onContinue(
                    firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                    username.trimmingCharacters(in: .whitespacesAndNewlines),
                    email.trimmingCharacters(in: .whitespacesAndNewlines),
                    avatarName
                )
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
            .disabled(!canContinue)
            .opacity(showButton ? (canContinue ? 1 : 0.5) : 0)
            .padding(.top, VelocitySpacing.lg)

            // Terms
            Text("BY CONTINUING, YOU AGREE TO THE VELOCITY PROTOCOL AND MISSION DIRECTIVES.")
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
                            isCustomAvatarSelected = false
                            storedAvatarName = avatarNames[index]
                            usesCustomAvatar = false
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
                Button {
                    showAvatarSourceDialog = true
                } label: {
                    customAvatarButtonContent
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Choose custom avatar photo")
            }
        }
    }

    private var customAvatarButtonContent: some View {
        Group {
            if let customAvatarImage {
                Image(uiImage: customAvatarImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                isCustomAvatarSelected ? Color.nitroBlue : Color.velocityOutlineVariant.opacity(0.3),
                                lineWidth: 2
                            )
                    )
                    .overlay(alignment: .bottomTrailing) {
                        Circle()
                            .fill(Color.nitroBlue)
                            .frame(width: 20, height: 20)
                            .overlay {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.onNitroBlue)
                            }
                    }
                    .scaleEffect(isCustomAvatarSelected ? 1.1 : 1.0)
                    .shadow(color: isCustomAvatarSelected ? Color.nitroBlue.opacity(0.4) : .clear, radius: 12)
            } else {
                Circle()
                    .strokeBorder(Color.velocityOutlineVariant, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.velocitySurfaceContainerLow))
                    .overlay(
                        Image(systemName: "plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(Color.nitroBlue)
                    )
            }
        }
    }

    private var firstNameField: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
            Text("FIRST NAME")
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)

            HStack(spacing: VelocitySpacing.sm) {
                Image(systemName: "person")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.velocityOutline)
                    .frame(width: 20)

                TextField("Alex", text: $firstName)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurface)
                    .focused($focusedField, equals: .firstName)
                    .submitLabel(.next)
                    .onSubmit {
                        assignRandomUsername()
                        focusedField = .username
                    }
            }
            .padding(.horizontal, VelocitySpacing.md)
            .padding(.vertical, VelocitySpacing.sm)
            .background(inputFieldBackground)
        }
    }

    private var publicUsernameField: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.xs) {
            Text("PUBLIC USERNAME")
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)

            HStack(spacing: VelocitySpacing.sm) {
                Image(systemName: "at")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.velocityOutline)
                    .frame(width: 20)

                TextField("Alex CoasterChaser", text: $username)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.onSurface)
                    .focused($focusedField, equals: .username)

                Button {
                    assignRandomUsername(excludingCurrentSuffix: true)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(firstNameTrimmed.isEmpty ? Color.velocityOutlineVariant : Color.nitroBlue)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .disabled(firstNameTrimmed.isEmpty)
                .accessibilityLabel("Refresh public username")
            }
            .padding(.horizontal, VelocitySpacing.md)
            .padding(.vertical, VelocitySpacing.sm)
            .background(inputFieldBackground)
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
            .background(inputFieldBackground)
        }
    }

    private var inputFieldBackground: some View {
        RoundedRectangle(cornerRadius: VelocityRadius.component)
            .fill(Color.velocitySurfaceContainerLowest)
            .overlay(
                RoundedRectangle(cornerRadius: VelocityRadius.component)
                    .stroke(Color.velocityOutlineVariant.opacity(0.5), lineWidth: 1)
            )
    }

    private var firstNameTrimmed: String {
        firstName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canContinue: Bool {
        !firstNameTrimmed.isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func assignRandomUsername(excludingCurrentSuffix: Bool = false) {
        guard !firstNameTrimmed.isEmpty else {
            username = ""
            currentUsernameSuffix = nil
            return
        }

        var suffixes = usernameSuffixes
        if excludingCurrentSuffix, let currentUsernameSuffix, suffixes.count > 1 {
            suffixes.removeAll { $0 == currentUsernameSuffix }
        }

        guard let suffix = suffixes.randomElement() else { return }
        currentUsernameSuffix = suffix
        username = "\(firstNameTrimmed) \(suffix)"
    }

    private func loadStoredAvatar() {
        if usesCustomAvatar, let image = UIImage(data: customAvatarImageData) {
            customAvatarImage = image
            selectedAvatar = nil
            isCustomAvatarSelected = true
            return
        }

        selectedAvatar = avatarNames.firstIndex(of: storedAvatarName)
        if !customAvatarImageData.isEmpty {
            customAvatarImage = UIImage(data: customAvatarImageData)
        }
        isCustomAvatarSelected = false
    }

    private func loadSelectedPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                avatarSelectionError = "That photo could not be loaded. Try a different image."
                return
            }

            applyCustomAvatar(image)
        } catch {
            avatarSelectionError = error.localizedDescription
        }

        selectedPhotoItem = nil
    }

    private func applyCustomAvatar(_ image: UIImage) {
        let avatarImage = preparedAvatarImage(from: image)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            customAvatarImage = avatarImage
            selectedAvatar = nil
            isCustomAvatarSelected = true
            usesCustomAvatar = true
            customAvatarImageData = avatarImage.jpegData(compressionQuality: 0.82) ?? Data()
        }
    }

    private func preparedAvatarImage(from image: UIImage) -> UIImage {
        let targetSize = CGSize(width: 512, height: 512)
        let scale = max(targetSize.width / image.size.width, targetSize.height / image.size.height)
        let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let origin = CGPoint(
            x: (targetSize.width - scaledSize.width) / 2,
            y: (targetSize.height - scaledSize.height) / 2
        )
        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: origin, size: scaledSize))
        }
    }
}

private struct AvatarCameraPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = true

        if UIImagePickerController.isCameraDeviceAvailable(.front) {
            picker.cameraDevice = .front
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage) -> Void

        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage

            if let image {
                onImagePicked(image)
            }

            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
