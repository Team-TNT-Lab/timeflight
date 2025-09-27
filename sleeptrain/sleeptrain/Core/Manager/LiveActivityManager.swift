//
//  LiveActivityManager.swift
//  sleeptrain
//
//  Created by 양시준 on 9/24/25.
//

import Foundation
import ActivityKit
import Combine

class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    var isActivityEmpty: Bool {
        return Activity<SleepTrainWidgetAttributes>.activities.isEmpty
    }
    
    func startLiveActivity(
        targetDepartureTime: Date,
        targetArrivalTime: Date,
        departureDayString: String,
        arrivalDayString: String,
        actualDepartureTime: Date? = nil
    ) {
        let attributes = SleepTrainWidgetAttributes(
            departureDayString: departureDayString,
            arrivalDayString: arrivalDayString
        )
        let initialState = SleepTrainWidgetAttributes.ContentState(
            targetDepartureTime: targetDepartureTime,
            targetArrivalTime: targetArrivalTime,
            actualDepartureTime: actualDepartureTime,
            currentTime: Date(),
            status: .waitingToBoard
        )
        let activityContent = ActivityContent(
            state: initialState,
            staleDate: Date.now.advanced(by: 1),
//            relevanceScore: 100
        )
        
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
    
//    func startLiveActivityAt(
//        targetDepartureTime: Date,
//        targetArrivalTime: Date,
//        departureDayString: String,
//        arrivalDayString: String,
//        actualDepartureTime: Date? = nil,
//        start: Date
//    ) {
//        let attributes = SleepTrainWidgetAttributes(
//            departureDayString: departureDayString,
//            arrivalDayString: arrivalDayString
//        )
//        let initialState = SleepTrainWidgetAttributes.ContentState(
//            targetDepartureTime: targetDepartureTime,
//            targetArrivalTime: targetArrivalTime,
//            actualDepartureTime: actualDepartureTime,
//            currentTime: Date(),
//            status: .waitingToBoard
//        )
//        let activityContent = ActivityContent(state: initialState, staleDate: Date.now.advanced(by: 60))
//        
//        do {
//            let activity = try Activity<SleepTrainWidgetAttributes>.request(
//                attributes: attributes,
//                content: activityContent,
//                style: .standard,
//                alertConfiguration: AlertConfiguration(title: "sleep train", body: "test", sound: .default),
//                start: start
//            )
//            #if DEBUG
//            print("Live Activity Started: \(activity.id)")
//            #endif
//        } catch {
//            #if DEBUG
//            print("Failed to start live activity: \(error)")
//            #endif
//        }
//    }
    
    func updateLiveActivity() async {
//        var targetDepartureTime: Date
//        var targetArrivalTime: Date
//        var departureDayString: String
//        var arrivalDayString: String
        var actualDepartureTime: Date? = nil
        
        
        guard let activity = Activity<SleepTrainWidgetAttributes>.activities.first else { return }
        let newState = SleepTrainWidgetAttributes.ContentState(
            targetDepartureTime: activity.content.state.targetDepartureTime,
            targetArrivalTime: activity.content.state.targetArrivalTime,
            actualDepartureTime: actualDepartureTime,
            currentTime: Date(),
            status: .waitingToBoard
        )
        let newActivityContent = ActivityContent(state: newState, staleDate: Date.now.advanced(by: 60))
        
        await activity.update(newActivityContent)
    }
}
