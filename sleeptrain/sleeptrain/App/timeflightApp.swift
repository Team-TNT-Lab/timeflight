//
//  timeflightApp.swift
//  timeflight
//
//  Created by bishoe01 on 9/18/25.
//

import SwiftUI
import SwiftData

@main
struct timeflightApp: App {
    @StateObject private var coordinator = Coordinator()
    @StateObject private var authManager = AuthorizationManager()
    @StateObject private var screenTimeManager = ScreenTimeManager()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coordinator.path) {
                HomeView()
//                    .navigationDestination(for: Path.self) { path in
//                        switch path {
//                        case .timerView:
//                            TimerView()
//                        }
//                    }
            }
        }
        .modelContainer(for: [UserSettings.self])
        .environmentObject(authManager)
        .environmentObject(screenTimeManager)
//            .environmentObject(coordinator)
    }
}
