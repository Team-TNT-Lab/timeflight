//
//  SleepTrainLiveActivitySmallView.swift
//  sleeptrain
//
//  Created by 양시준 on 9/23/25.
//

import SwiftUI
import WidgetKit

struct SleepTrainLiveActivitySmallView: View {
    @Environment(\.activityFamily) var activityFamily
    let context: ActivityViewContext<SleepTrainWidgetAttributes>
    
    var body: some View {
        VStack(spacing: 10) {
            TrainProgressBarView(
                progress: calculateJourneyProgress(
                    from: context.state.actualDepartureTime,
                    to: context.attributes.targetArrivalTime,
                    current: context.state.currentTime
                )
            )
            StatusIndicatorSmallView(
                targetDepartureTime: context.attributes.targetDepartureTime,
                targetArrivalTime: context.attributes.targetArrivalTime,
                status: context.state.status,
                currentTime: context.state.currentTime
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(.black)
        .activityBackgroundTint(.black)
        .activitySystemActionForegroundColor(.blue)
    }
}
