//
//  ScreenTimeManager.swift
//  timeflight
//
//  Created by bishoe01 on 9/19/25.
//

import FamilyControls
import ManagedSettings
import SwiftData
import SwiftUI

class ScreenTimeManager: ObservableObject {
    @Published var selection = FamilyActivitySelection()
    private let store = ManagedSettingsStore()

    func lockApps(with blockedApps: FamilyActivitySelection) {
        store.shield.applications = blockedApps.applicationTokens
        store.shield.applicationCategories = .specific(blockedApps.categoryTokens)
        store.shield.webDomains = blockedApps.webDomainTokens
    }

    func unlockApps() {
        store.clearAllSettings()
    }
}
