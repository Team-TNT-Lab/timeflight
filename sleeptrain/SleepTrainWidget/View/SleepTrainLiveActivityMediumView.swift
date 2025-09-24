//
//  SleepTrainLiveActivityMediumView.swift
//  sleeptrain
//
//  Created by 양시준 on 9/23/25.
//

import SwiftUI
import WidgetKit

struct SleepTrainLiveActivityMediumView: View {
    @Environment(\.activityFamily) var activityFamily
    let context: ActivityViewContext<SleepTrainWidgetAttributes>
    
    var body: some View {
        VStack(spacing: 16) {
            // 상단 시간 표시
            HStack {
                TargetTimeTextView(time: context.attributes.targetDepartureTime)
                Spacer()
                TargetTimeTextView(time: context.attributes.targetArrivalTime)
            }
            
            SleepTrainInfoView(context: context)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 24)
        .background(.black)
        .activityBackgroundTint(.black)
        .activitySystemActionForegroundColor(.blue)
    }
}
