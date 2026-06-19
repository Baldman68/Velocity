import Foundation
import Observation
import Supabase

// MARK: - AppAuthState

enum AppAuthState: Equatable, Sendable {
    case undetermined               // Initial state on launch
    case signedOut                  // No session exists
    case signingUp                  // New user: OTP sent during onboarding, awaiting click
    case awaitingMagicLink          // Returning user: OTP sent, awaiting click
    case magicLinkCallbackInProgress // URL opened, session(from:) running
    case signedInProfileIncomplete  // Authenticated, onboarding not yet finished
    case signedInFullyOnboarded     // Normal operational state
}

// MARK: - AuthService

@Observable
@MainActor
final class AuthService {
    private let client = SupabaseManager.shared.client

    // MARK: - State

    var authState: AppAuthState = .undetermined
    var pendingEmail: String = ""
    var isLoading = false
    var errorMessage: String?

    // MARK: - UserDefaults keys

    private enum DefaultsKey {
        static let pendingEmail      = "velocity_pendingEmail"
        static let pendingFirstName  = "velocity_pendingFirstName"
        static let pendingUsername   = "velocity_pendingUsername"
        static let pendingAvatarName = "velocity_pendingAvatarName"
    }

    // MARK: - Computed

    var isAuthenticated: Bool { client.auth.currentUser != nil }
    var currentUserId: String? { client.auth.currentUser?.id.uuidString }

    /// `true` when UserDefaults contains unsent pending profile data (firstName present).
    var hasPendingProfile: Bool {
        let firstName = UserDefaults.standard.string(forKey: DefaultsKey.pendingFirstName) ?? ""
        return !firstName.isEmpty
    }

    /// The email saved to UserDefaults during onboarding (survives app restarts).
    var savedPendingEmail: String {
        UserDefaults.standard.string(forKey: DefaultsKey.pendingEmail) ?? ""
    }

    // MARK: - Magic Link

    /// Sends a magic link OTP to `email`.
    ///
    /// For new users (`isNewUser == true`), the profile data is saved to UserDefaults before
    /// the link is clicked so it survives an app restart. Sets `authState` to `.signingUp`
    /// (new user) or `.awaitingMagicLink` (returning user) on success.
    func requestMagicLink(
        email: String,
        isNewUser: Bool,
        profileData: (firstName: String, username: String, avatarName: String)? = nil
    ) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        pendingEmail = trimmedEmail

        if isNewUser, let data = profileData {
            savePendingProfile(
                email: trimmedEmail,
                firstName: data.firstName,
                username: data.username,
                avatarName: data.avatarName
            )
        }

        let redirectURL = URL(
            string: "\(Bundle.main.bundleIdentifier?.lowercased() ?? "velocity")://login-callback/"
        )

        do {
            try await client.auth.signInWithOTP(
                email: trimmedEmail,
                redirectTo: redirectURL,
                shouldCreateUser: isNewUser
            )
            authState = isNewUser ? .signingUp : .awaitingMagicLink
        } catch {
            errorMessage = error.localizedDescription
            if isNewUser { clearPendingProfile() }
            pendingEmail = ""
        }
    }

    // MARK: - Profile Creation

    /// Creates the profile row from data stored in UserDefaults during onboarding.
    ///
    /// Called after the magic link callback confirms the new user's session. Reads
    /// the pending keys, inserts the profile row, then clears the pending data.
    func createProfileFromPending() async {
        let email      = UserDefaults.standard.string(forKey: DefaultsKey.pendingEmail)      ?? ""
        let firstName  = UserDefaults.standard.string(forKey: DefaultsKey.pendingFirstName)  ?? ""
        let username   = UserDefaults.standard.string(forKey: DefaultsKey.pendingUsername)   ?? ""
        let avatarName = UserDefaults.standard.string(forKey: DefaultsKey.pendingAvatarName) ?? "avatar00"

        guard !firstName.isEmpty else {
            clearPendingProfile()
            return
        }

        do {
            let currentUser = try await client.auth.session.user

            struct NewProfile: Encodable {
                let userId: String
                let email: String
                let firstName: String
                let publicUserName: String
                let avatarName: String
            }

            let payload = NewProfile(
                userId: currentUser.id.uuidString,
                email: email,
                firstName: firstName,
                publicUserName: username,
                avatarName: avatarName.isEmpty ? "avatar00" : avatarName
            )

            let _: Profile = try await client
                .from("profile")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

            clearPendingProfile()
        } catch {
            debugPrint("createProfileFromPending error: \(error)")
            // Non-fatal — a DB trigger may have already created the row
            clearPendingProfile()
        }
    }

    /// Clears all pending profile keys from UserDefaults.
    func clearPendingProfile() {
        UserDefaults.standard.removeObject(forKey: DefaultsKey.pendingEmail)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.pendingFirstName)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.pendingUsername)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.pendingAvatarName)
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Delete Account

    /// Permanently deletes the current user's profile row and signs them out.
    /// The Supabase auth user is removed by a database trigger or admin API.
    func deleteAccount() async throws {
        guard let userId = currentUserId else { return }

        // Delete the profile row (cascades to related data via FK constraints)
        try await client
            .from("profile")
            .delete()
            .eq("userId", value: userId)
            .execute()

        // Clear any pending onboarding data
        clearPendingProfile()

        // Sign out locally
        try await client.auth.signOut()
    }

    // MARK: - Private

    private func savePendingProfile(
        email: String,
        firstName: String,
        username: String,
        avatarName: String
    ) {
        UserDefaults.standard.set(email,       forKey: DefaultsKey.pendingEmail)
        UserDefaults.standard.set(firstName,   forKey: DefaultsKey.pendingFirstName)
        UserDefaults.standard.set(username,    forKey: DefaultsKey.pendingUsername)
        UserDefaults.standard.set(avatarName,  forKey: DefaultsKey.pendingAvatarName)
    }
}
