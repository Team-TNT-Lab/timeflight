//
//  timeflightApp.swift
//  timeflight
//
//  Created by bishoe01 on 9/18/25.
//

import SwiftUI

@main
struct timeflightApp: App {
    @StateObject private var authManager = AuthorizationManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.environmentObject(authManager)
    }
}
