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

    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    @StateObject private var userSettingsManager = UserSettingsManager()

    @EnvironmentObject var screenTimeManager: ScreenTimeManager

    init(_ onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    var body: some View {
        VStack {
            FamilyActivityPicker(selection: $screenTimeManager.selection)

        }.safeAreaInset(edge: .bottom) {
            PrimaryButton(buttonText: "다음") {
                saveSelectedApps()
            }
        }
        .onAppear {
            loadExistingSelection()
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
            onNext()
        } catch {
            print(error)
        }
    }
}

#Preview {
    AppSelectionView { print("HI") }
}
