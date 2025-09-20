//
//  AppLockSettingView.swift
//  timeflight
//
//  Created by bishoe01 on 9/20/25.
//

import FamilyControls
import SwiftUI

struct AppLockSettingView: View {
    @EnvironmentObject var authManager: AuthorizationManager
    @StateObject private var screenTimeManager = ScreenTimeManager()
    var body: some View {
        FamilyActivityPicker(selection: $screenTimeManager.selection)
            .task {
                if !authManager.isAuthorized {
                    authManager.requestAuthorization()
                }
            }
    }
}
