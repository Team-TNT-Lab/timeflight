//
//  TrainState.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/27/25.
//
import SwiftUI

enum TrainState {
    case preparing(remainingTime: String)
    case readyToDepart
    case departed(remainingTime: String)
    case delayed(delayedTime: String)
    case missed

    static func from(
        remainingTimeText: String,
        isTrainDeparted: Bool
    ) -> TrainState {
        if remainingTimeText.contains("지연") {
            return .delayed(delayedTime: remainingTimeText)
        } else if remainingTimeText == "운행 종료" {
            return .missed
        } else if isTrainDeparted {
            return .departed(remainingTime: remainingTimeText)
        } else if remainingTimeText == "출발 준비" {
            return .readyToDepart
        } else {
            return .preparing(remainingTime: remainingTimeText)
        }
    }

    var displayText: String {
        switch self {
        case .preparing(let time): return time
        case .readyToDepart: return "출발 준비"
        case .departed(let time): return time
        case .delayed(let time): return time
        case .missed: return "운행 종료"
        }
    }
}
