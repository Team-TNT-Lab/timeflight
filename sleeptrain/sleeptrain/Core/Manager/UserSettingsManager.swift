//
//  UserSettingsManager.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/23/25.
//

import FamilyControls
import Foundation
import SwiftData

class UserSettingsManager: ObservableObject {
    private func getOrCreateSettings(context: ModelContext, userSettings: [UserSettings]) -> UserSettings {
        if let existingSettings = userSettings.first {
            return existingSettings
        }

        let defaultDepartureTime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        let defaultArrivalTime = Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date()

        let newSettings = UserSettings(
            targetDepartureTime: defaultDepartureTime,
            targetArrivalTime: defaultArrivalTime
        )
        context.insert(newSettings)

        try? context.save()
        return newSettings
    }

    func saveName(_ name: String, context: ModelContext, userSettings: [UserSettings]) throws {
        let settings = getOrCreateSettings(context: context, userSettings: userSettings)
        settings.name = name
        try context.save()
    }

    func saveSchedule(departureTime: Date, arrivalTime: Date, context: ModelContext, userSettings: [UserSettings]) throws {
        let settings = getOrCreateSettings(context: context, userSettings: userSettings)
        settings.targetDepartureTime = departureTime
        settings.targetArrivalTime = arrivalTime
        try context.save()
    }

    func saveBlockedApps(_ blockedApps: FamilyActivitySelection, context: ModelContext, userSettings: [UserSettings]) throws {
        let settings = getOrCreateSettings(context: context, userSettings: userSettings)
        settings.blockedApps = blockedApps
        try context.save()
    }

    func onboardingComplete(context: ModelContext, userSettings: [UserSettings]) throws {
        let settings = getOrCreateSettings(context: context, userSettings: userSettings)
        settings.isOnboardingCompleted = true
        try context.save()
    }

    func ToggleGuestUser(context: ModelContext, userSettings: [UserSettings]) throws {
        let settings = getOrCreateSettings(context: context, userSettings: userSettings)
        settings.isGuestUser.toggle()
        try context.save()
    }
}
