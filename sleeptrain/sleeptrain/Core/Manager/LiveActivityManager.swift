//
//  LiveActivityManager.swift
//  sleeptrain
//
//  Created by 양시준 on 9/24/25.
//

import Foundation
import ActivityKit

class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    func startLiveActivity(
        targetDepartureTime: Date,
        targetArrivalTime: Date,
        departureDayString: String,
        arrivalDayString: String,
        actualDepartureTime: Date? = nil
    ) {
        let attributes = SleepTrainWidgetAttributes(
            targetDepartureTime: targetDepartureTime,
            targetArrivalTime: targetArrivalTime,
            departureDayString: departureDayString,
            arrivalDayString: arrivalDayString
        )
        let initialState = SleepTrainWidgetAttributes.ContentState(
            actualDepartureTime: actualDepartureTime,
            currentTime: Date(),
            status: .waitingToBoard
        )
        let activityContent = ActivityContent(state: initialState, staleDate: Date.now.advanced(by: 60))
        
        do {
            let activity = try Activity<SleepTrainWidgetAttributes>.request(
                attributes: attributes,
                content: activityContent
            )
            #if DEBUG
            print("Live Activity Started: \(activity.id)")
            #endif
        } catch {
            #if DEBUG
            print("Failed to start live activity: \(error)")
            #endif
        }
    }
}
