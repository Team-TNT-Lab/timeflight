//
//  ContentView.swift
//  timeflight
//
//  Created by bishoe01 on 9/18/25.
//

import FamilyControls
import ManagedSettings
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthorizationManager
    @EnvironmentObject private var coordinator: Coordinator

    @State var isPickerPresented = false

    @StateObject private var screenTimeManager = ScreenTimeManager()

    var body: some View {
        VStack {
            Text("TIME FLIGHT")

            Button("Open Picker") {
                isPickerPresented.toggle()
            }.familyActivityPicker(isPresented: $isPickerPresented, selection: $screenTimeManager.selection)

            Button("HIHI") {
                screenTimeManager.lockApps()
            }
            Button("해제하기") {
                screenTimeManager.unlockApps()
            }
            Button("이동") {
                coordinator.push(.timerView)
            }

        }.task {
            if !authManager.isAuthorized {
                authManager.requestAuthorization()
            }
        }
    }
}
