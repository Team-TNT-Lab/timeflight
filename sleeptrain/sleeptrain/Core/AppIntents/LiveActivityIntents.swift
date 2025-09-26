//
//  LiveActivityIntents.swift
//  sleeptrain
//
//  Created by 양시준 on 9/25/25.
//

import AppIntents
import ActivityKit

struct StartLiveActivity: LiveActivityIntent {
    static var title: LocalizedStringResource = "Start Sleep Live Activity"
    
    func perform() async throws -> some IntentResult {
        LiveActivityManager.shared.startLiveActivity(
            targetDepartureTime: Date.now.addingTimeInterval(-3000),
            targetArrivalTime: Date.now.addingTimeInterval(7200),
            departureDayString: "MON",
            arrivalDayString: "TUE"
        )
        return .result()
    }
}
