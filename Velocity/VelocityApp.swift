//
//  VelocityApp.swift
//  Velocity
//
//  Created by Michael Kacos on 5/12/26.
//

import SwiftUI
import Supabase

@main
struct VelocityApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingContainerView(isOnboardingComplete: $hasCompletedOnboarding)
                }
            }
            .preferredColorScheme(.dark)
            .environment(authService)
            // Returning user: sign-in gate (shown when onboarding is done but no session)
            .fullScreenCover(
                isPresented: Binding(
                    get: { hasCompletedOnboarding && authService.authState == .signedOut },
                    set: { _ in }
                )
            ) {
                LoginView()
                    .environment(authService)
                    .interactiveDismissDisabled()
            }
            // Returning user: magic link sent — waiting for email click
            .fullScreenCover(
                isPresented: Binding(
                    get: { authService.authState == .awaitingMagicLink },
                    set: { _ in }
                )
            ) {
                MagicLinkSentView()
                    .environment(authService)
                    .interactiveDismissDisabled()
            }
            // Auth state listener — reacts to Supabase session changes
            .task {
                for await state in SupabaseManager.shared.client.auth.authStateChanges {
                    guard [.initialSession, .signedIn, .signedOut, .userUpdated]
                        .contains(state.event) else { continue }

                    guard state.session != nil else {
                        // No session — signed out
                        authService.authState = .signedOut
                        continue
                    }

                    // Live session — create profile from pending if this is a new user
                    if authService.hasPendingProfile {
                        await authService.createProfileFromPending()
                    }

                    authService.authState = hasCompletedOnboarding
                        ? .signedInFullyOnboarded
                        : .signedInProfileIncomplete
                }
            }
            // Handle magic link / OTP deep-link callbacks
            .onOpenURL { url in
                Task {
                    authService.authState = .magicLinkCallbackInProgress
                    do {
                        try await SupabaseManager.shared.client.auth.session(from: url)
                    } catch {
                        authService.authState = .signedOut
                    }
                }
            }
        }
    }
}
