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
    @State var selection = FamilyActivitySelection()
    @EnvironmentObject var authManager: AuthorizationManager
    @State var isPickerPresented = false

    let store = ManagedSettingsStore()

    var body: some View {
        VStack {
            Text("TIME FLIGHT")

            Button("Open Picker") {
                isPickerPresented.toggle()
            }.familyActivityPicker(isPresented: $isPickerPresented, selection: $selection).onChange(of: selection) {
                store.shield.applicationCategories = .specific(selection.categoryTokens)
                store.shield.webDomains = selection.webDomainTokens
            }

        }.task {
            if !authManager.isAuthorized {
                authManager.requestAuthorization()
            }
        }
    }
}
