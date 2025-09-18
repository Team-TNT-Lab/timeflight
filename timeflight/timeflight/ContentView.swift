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

    let store = ManagedSettingsStore()

    var body: some View {
        Text("TIME FLIGHT")
        Button("AUTH") {
            if !authManager.isAuthorized {
                authManager.requestAuthorization()
            }
        }

        FamilyActivityPicker(selection: $selection)
        Button("HI") {
            print(selection.categories.count)
            store.shield.applicationCategories = .specific(selection.categoryTokens)
            store.shield.webDomains = selection.webDomainTokens
        }
    }
}

#Preview {
    ContentView()
}
