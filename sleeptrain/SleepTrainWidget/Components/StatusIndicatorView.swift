//
//  StatusIndicatorView.swift
//  sleeptrain
//
//  Created by 양시준 on 9/23/25.
//

import SwiftUI

struct StatusIndicatorView: View {
    var targetDepartureTime: Date
    var targetArrivalTime: Date
    var status: JourneyStatus
    var currentTime: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(targetDepartureTime, style: .relative)
//            Text(
//                getTimeMessage(
//                    status: status,
//                    targetDepartureTime: targetDepartureTime,
//                    targetArrivalTime: targetArrivalTime,
//                    currentTime: currentTime
//                )
//            )
            .font(.system(size: 16, weight: .bold))
            
            Text(getStatusMessage(status: status))
                .font(.system(size: 14))
        }
        .foregroundStyle(getMessageColor(status: status))
    }
}
