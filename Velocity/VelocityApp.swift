//
//  VelocityApp.swift
//  Velocity
//
//  Created by Michael Kacos on 5/12/26.
//

import SwiftUI

@main
struct VelocityApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .preferredColorScheme(.dark)
            } else {
                OnboardingContainerView(isOnboardingComplete: $hasCompletedOnboarding)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
