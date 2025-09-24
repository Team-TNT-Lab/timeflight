//
//  SleepTrainWidgetAttributes.swift
//  sleeptrain
//
//  Created by 양시준 on 9/24/25.
//

import Foundation
import ActivityKit

public struct SleepTrainWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var actualDepartureTime: Date?
        var currentTime: Date
        var status: JourneyStatus
    }

    var targetDepartureTime: Date
    var targetArrivalTime: Date
    var departureDayString: String
    var arrivalDayString: String
}
