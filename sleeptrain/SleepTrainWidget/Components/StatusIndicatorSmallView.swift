//
//  StatusIndicatorSmallView.swift
//  sleeptrain
//
//  Created by 양시준 on 9/23/25.
//

import SwiftUI

struct StatusIndicatorSmallView: View {
    var targetDepartureTime: Date
    var targetArrivalTime: Date
    var status: JourneyStatus
    var currentTime: Date
    
    var body: some View {
//        Text(
//            getTimeMessage(
//                status: status,
//                targetDepartureTime: targetDepartureTime,
//                targetArrivalTime: targetArrivalTime,
//                currentTime: currentTime
//            )
//        )
        Text(targetDepartureTime, style: .timer)
            .monospacedDigit()
            .frame(width: 60)
    }
}
