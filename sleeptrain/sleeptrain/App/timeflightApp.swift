//
//  timeflightApp.swift
//  timeflight
//
//  Created by bishoe01 on 9/18/25.
//

import SwiftData
import SwiftUI

@main
struct timeflightApp: App {
    @StateObject private var coordinator = Coordinator()
    @StateObject private var authManager = AuthorizationManager()
    @StateObject private var screenTimeManager = ScreenTimeManager()

    @State private var isOnboardingCompleted: Bool

    init() {
        let userSettings = try? ModelContext(ModelContainer(for: UserSettings.self)).fetch(FetchDescriptor<UserSettings>())
        _isOnboardingCompleted = State(initialValue: userSettings?.first?.isOnboardingCompleted ?? false)
    }

    var body: some Scene {
        WindowGroup {
            if isOnboardingCompleted {
                HomeView()
            } else {
                OnBoardingView(onComplete: { isOnboardingCompleted = true })
            }
        }
        .modelContainer(for: [UserSettings.self])
        .environmentObject(authManager)
        .environmentObject(screenTimeManager)
    }
}
