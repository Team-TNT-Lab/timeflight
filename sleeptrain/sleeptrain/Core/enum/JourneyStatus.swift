//
//  JourneyStatus.swift
//  sleeptrain
//
//  Created by 양시준 on 9/23/25.
//

enum JourneyStatus: String, Codable {
    case waitingToBoard = "waitingToBoard"
    case onTrack = "onTrack"
    case arrived = "arrived"
    case delayed = "delayed"
    case tooMuchDelayed = "tooMuchDelayed"
    case emergencyStop = "emergencyStop"
    case cancelled = "cancelled"
}
