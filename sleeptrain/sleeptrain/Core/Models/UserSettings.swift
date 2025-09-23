//
//  UserSettings.swift
//  sleeptrain
//
//  Created by 양시준 on 9/22/25.
//

import Foundation
import SwiftData
import FamilyControls

@Model
final class UserSettings {
    var name: String
    var targetDepartureTime: Date
    var targetArrivalTime: Date
    var blockedApps: FamilyActivitySelection
    var isOnboardingCompleted: Bool
    var isGuestUser: Bool
    
    init(
        name: String = "",
        targetDepartureTime: Date,
        targetArrivalTime: Date,
        blockedApps: FamilyActivitySelection = FamilyActivitySelection(),
        isOnboardingCompleted: Bool = false,
        isGuestUser: Bool = false
    ) {
        self.name = name
        self.targetDepartureTime = targetDepartureTime
        self.targetArrivalTime = targetArrivalTime
        self.blockedApps = blockedApps
        self.isOnboardingCompleted = isOnboardingCompleted
        self.isGuestUser = isGuestUser
    }
}
