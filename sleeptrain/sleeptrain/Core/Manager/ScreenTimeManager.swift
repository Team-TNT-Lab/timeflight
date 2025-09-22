//
//  ScreenTimeManager.swift
//  timeflight
//
//  Created by bishoe01 on 9/19/25.
//

import FamilyControls
import ManagedSettings
import SwiftUI

class ScreenTimeManager: ObservableObject {
    @Published var selection = FamilyActivitySelection()
    private let store = ManagedSettingsStore()

    func lockApps() {
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens
    }

    // 체크가 풀리진않고, 잠금만해제
    func unlockApps() {
        store.clearAllSettings()
    }
}
