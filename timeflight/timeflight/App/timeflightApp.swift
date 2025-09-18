//
//  timeflightApp.swift
//  timeflight
//
//  Created by bishoe01 on 9/18/25.
//

import SwiftUI

@main
struct timeflightApp: App {
    @StateObject private var coordinator = Coordinator()
    @StateObject private var authManager = AuthorizationManager()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coordinator.path) {
                ContentView()
                    .navigationDestination(for: Path.self) { path in
                        switch path {
                        case .timerView:
                            TimerView()
                        }
                    }
            }
        }.environmentObject(coordinator)
            .environmentObject(authManager)
    }
}
