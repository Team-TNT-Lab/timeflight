//
//  UserSettings.swift
//  sleeptrain
//
//  Created by 양시준 on 9/22/25.
//

import FamilyControls
import Foundation
import SwiftData

@Model
final class UserSettings {
    var name: String
    var targetDepartureTime: Date
    var targetArrivalTime: Date
    var blockedApps: FamilyActivitySelection
    var isOnboardingCompleted: Bool
    var isGuestUser: Bool
    var isSleeping: Bool = false

    init(
        name: String = "굿나잇",
        targetDepartureTime: Date,
        targetArrivalTime: Date,
        blockedApps: FamilyActivitySelection = FamilyActivitySelection(),
        isOnboardingCompleted: Bool = false,
        isGuestUser: Bool = true,
        isSleeping: Bool = false
    ) {
        self.name = name
        self.targetDepartureTime = targetDepartureTime
        self.targetArrivalTime = targetArrivalTime
        self.blockedApps = blockedApps
        self.isOnboardingCompleted = isOnboardingCompleted
        self.isGuestUser = isGuestUser
        self.isSleeping = isSleeping
    }
}
