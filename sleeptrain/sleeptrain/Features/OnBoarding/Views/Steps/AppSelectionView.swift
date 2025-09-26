//
//  AppSelectionView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/23/25.
//

import FamilyControls
import SwiftData
import SwiftUI

struct AppSelectionView: View {
    let onNext: () -> Void
    let showNextButton: Bool
    let hideTabBar: Bool

    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    @StateObject private var userSettingsManager = UserSettingsManager()
    @StateObject private var authManager = AuthorizationManager()
    @EnvironmentObject var screenTimeManager: ScreenTimeManager

    init(_ onNext: @escaping () -> Void, showNextButton: Bool = true, hideTabBar: Bool = false) {
        self.onNext = onNext
        self.showNextButton = showNextButton
        self.hideTabBar = hideTabBar
    }

    var body: some View {
        FamilyActivityPicker(selection: $screenTimeManager.selection)
            .safeAreaInset(edge: .bottom, content: {
                if showNextButton {
                    PrimaryButton(buttonText: "다음") {
                        saveSelectedAppsAndNext()
                    }
                }
            })
            .toolbar(hideTabBar ? .hidden : .visible, for: .tabBar)
            .onAppear {
                loadExistingSelection()
            }
            .onDisappear {
                if !showNextButton {
                    saveSelectedApps()
                }
            }
            .task {
                if !authManager.isAuthorized {
                    authManager.requestAuthorization()
                }
            }
    }

    private func loadExistingSelection() {
        if let settings = userSettings.first {
            screenTimeManager.selection = settings.blockedApps
        }
    }

    private func saveSelectedApps() {
        do {
            try userSettingsManager.saveBlockedApps(
                screenTimeManager.selection,
                context: modelContext,
                userSettings: userSettings
            )
        } catch {
            print(error)
        }
    }

    private func saveSelectedAppsAndNext() {
        do {
            try userSettingsManager.saveBlockedApps(
                screenTimeManager.selection,
                context: modelContext,
                userSettings: userSettings
            )
            onNext()
        } catch {
            print(error)
        }
    }
}

#Preview {
    AppSelectionView { print("HI") }
}
