//
//  VelocityApp.swift
//  Velocity
//
//  Created by Michael Kacos on 5/12/26.
//

import SwiftUI

@main
struct VelocityApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
    }
}
