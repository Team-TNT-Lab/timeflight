//
//  SleepRecord.swift
//  sleeptrain
//
//  Created by 양시준 on 9/23/25.
//

import Foundation
import SwiftData

@Model
final class SleepRecord: Identifiable {
    var id: UUID
    var actualDepartureTime: Date
    var actualArrivalTime: Date?
    var status: JourneyStatus
    var targetDepartureTime: Date
    var targetArrivalTime: Date
    
    init(
        id: UUID = UUID(),
        actualDepartureTime: Date,
        actualArrivalTime: Date? = nil,
        status: JourneyStatus = .waitingToBoard,
        targetDepartureTime: Date,
        targetArrivalTime: Date
    ) {
        self.id = id
        self.actualDepartureTime = actualDepartureTime
        self.actualArrivalTime = actualArrivalTime
        self.status = status
        self.targetDepartureTime = targetDepartureTime
    }
}

enum JourneyStatus {
    case waitingToBoard
    case onTrack
    case arrived
    case delayed
    case emergencyStop
    case cancelled
}
