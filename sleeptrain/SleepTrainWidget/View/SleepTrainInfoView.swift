//
//  SleepTrainInfoView.swift
//  sleeptrain
//
//  Created by 양시준 on 9/23/25.
//

import SwiftUI
import WidgetKit

struct SleepTrainInfoView: View {
    let context: ActivityViewContext<SleepTrainWidgetAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                StationTextView(stationString: context.attributes.departureDayString)
                
                VStack {
                    TrainProgressBarView(
                        progress: calculateJourneyProgress(
                            from: context.state.actualDepartureTime,
                            to: context.state.targetArrivalTime,
                            current: context.state.currentTime
                        )
                    )
                }
                
                StationTextView(stationString: context.attributes.arrivalDayString)
            }
            HStack {
                StatusIndicatorView(
                    targetDepartureTime: context.state.targetDepartureTime,
                    targetArrivalTime: context.state.targetArrivalTime,
                    status: context.state.status,
                    currentTime: context.state.currentTime
                )
                
                Spacer()
                
                // 수면 모드 스트릭
                SleepStreakLabelView(streak: 133)
            }
        }
    }
}
