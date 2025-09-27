//
//  SleepTrainWidgetAttributes.swift
//  sleeptrain
//
//  Created by 양시준 on 9/24/25.
//

import Foundation
import ActivityKit
import WidgetKit

public struct SleepTrainWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, TimelineEntry {
        var targetDepartureTime: Date
        var targetArrivalTime: Date
        var actualDepartureTime: Date?
        var currentTime: Date
        var status: JourneyStatus
        
        public var date: Date {
            currentTime
        }
    }

    var departureDayString: String
    var arrivalDayString: String
}
