//
//  TimeStatusMessageHelper.swift
//  sleeptrain
//
//  Created by 양시준 on 9/23/25.
//

import Foundation
import SwiftUI

func timeRemaining(from currentTime: Date = Date.now, to time: Date) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .abbreviated
    
    formatter.calendar?.locale = Locale(identifier: "en_US")
    
    let interval = Int(time.timeIntervalSince(currentTime))
    
    if interval < 0 {
        return "완료"
    }
    if let formattedString = formatter.string(from: TimeInterval(interval)) {
        return formattedString
    }
    return ""
}

func timeDelayed(from currentTime: Date = Date.now, to time: Date) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    
    formatter.calendar?.locale = Locale(identifier: "en_US")
    
    let interval = Int(time.timeIntervalSince(currentTime))
    
    if interval > 0 {
        return "없음"
    }
    if let formattedString = formatter.string(from: TimeInterval(-interval)) {
        return formattedString
    }
    return ""
}

func getTimeMessage(status: JourneyStatus, targetDepartureTime: Date, targetArrivalTime: Date, currentTime: Date) -> String {
    switch status {
    case .waitingToBoard:
        return timeRemaining(from: currentTime, to: targetDepartureTime)
    case .delayed, .tooMuchDelayed:
        return "\(timeDelayed(from: currentTime, to: targetDepartureTime)) 지연"
    case .onTrack:
        return timeRemaining(from: currentTime, to: targetArrivalTime)
    case .cancelled:
        return "취소됨"
    case .arrived:
        return "도착"
    case .emergencyStop:
        return "비상 정차"
    }
}

func getStatusMessage(status: JourneyStatus) -> String {
    switch status {
    case .waitingToBoard, .delayed, .tooMuchDelayed:
        return "열차 출발까지"
    case .onTrack:
        return "열차 도착까지"
    case .arrived:
        return "운행 완료"
    case .cancelled, .emergencyStop:
        return "운행 중단"
    }
}

func getMessageColor(status: JourneyStatus) -> Color {
    switch status {
    case .waitingToBoard, .onTrack, .arrived:
        return .blue
    case .delayed:
        return .yellow
    case .tooMuchDelayed, .cancelled, .emergencyStop:
        return .red
    }
}

func calculateJourneyProgress(from start: Date?, to end: Date, current: Date) -> Double {
    guard let start = start else { return 0 }
    
    let totalSeconds = Int(end.timeIntervalSince(start))
    let remainingSeconds = Int(end.timeIntervalSince(current))
    
    if remainingSeconds <= 0 {
        return 1
    } else if remainingSeconds >= totalSeconds {
        return 0
    } else {
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }
}
