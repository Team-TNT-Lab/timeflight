//
//  SleepTrainLiveActivityView.swift
//  sleeptrain
//
//  Created by 양시준 on 9/23/25.
//

import SwiftUI
import WidgetKit

struct SleepTrainLiveActivityView: View {
    @Environment(\.activityFamily) var activityFamily
    let context: ActivityViewContext<SleepTrainWidgetAttributes>
    
    var body: some View {
        switch activityFamily {
        case .small:
            SleepTrainLiveActivitySmallView(context: context)
        case .medium:
            SleepTrainLiveActivityMediumView(context: context)
        @unknown default:
            SleepTrainLiveActivityMediumView(context: context)
        }
    }
}
