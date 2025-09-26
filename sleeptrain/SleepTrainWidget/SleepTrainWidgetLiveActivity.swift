//
//  SleepTrainWidgetLiveActivity.swift
//  SleepTrainWidget
//
//  Created by 양시준 on 9/23/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SleepTrainWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepTrainWidgetAttributes.self) { context in
            SleepTrainLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    TargetTimeTextView(time: context.state.targetDepartureTime)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TargetTimeTextView(time: context.state.targetArrivalTime)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    SleepTrainInfoView(context: context)
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "train.side.front.car")
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
            } compactTrailing: {
                StatusIndicatorSmallView(
                    targetDepartureTime: context.state.targetDepartureTime,
                    targetArrivalTime: context.state.targetArrivalTime,
                    status: context.state.status,
                    currentTime: context.state.currentTime
                )
//                Text(context.state.targetDepartureTime, style: .relative)
//                TimelineView(.everyMinute) { timeLineContext in
//                    Text(roundedRelativeString(for: context.state.targetDepartureTime, now: timeLineContext.date))
//                }
            } minimal: {
                Image(systemName: "train.side.front.car")
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(.black)
            .contentMargins(.horizontal, 30, for: .expanded)
            .contentMargins(.vertical, 24, for: .expanded)
        }
        .supplementalActivityFamilies([.small, .medium])
    }
    
}

func roundedRelativeString(for date: Date, now: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: now)
}

extension SleepTrainWidgetAttributes {
    fileprivate static var preview: SleepTrainWidgetAttributes {
        SleepTrainWidgetAttributes(
            departureDayString: "MON",
            arrivalDayString: "TUE"
        )
    }
}

extension SleepTrainWidgetAttributes.ContentState {
    fileprivate static var waitingToBoard: SleepTrainWidgetAttributes.ContentState {
        SleepTrainWidgetAttributes.ContentState(
            targetDepartureTime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!,
            targetArrivalTime:  Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date().addingTimeInterval(86_400))!,
            actualDepartureTime: nil as Date?,
            currentTime: Calendar.current.date(bySettingHour: 21, minute: 30, second: 0, of: Date())!,
            status: .waitingToBoard,
        )
     }
    
    fileprivate static var delayed: SleepTrainWidgetAttributes.ContentState {
        SleepTrainWidgetAttributes.ContentState(
            targetDepartureTime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!,
            targetArrivalTime:  Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date().addingTimeInterval(86_400))!,
            actualDepartureTime: nil as Date?,
            currentTime: Calendar.current.date(bySettingHour: 22, minute: 15, second: 0, of: Date())!,
            status: .delayed,
        )
     }
    
    fileprivate static var tooMuchDelayed: SleepTrainWidgetAttributes.ContentState {
        SleepTrainWidgetAttributes.ContentState(
            targetDepartureTime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!,
            targetArrivalTime:  Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date().addingTimeInterval(86_400))!,
            actualDepartureTime: nil as Date?,
            currentTime: Calendar.current.date(bySettingHour: 23, minute: 1, second: 0, of: Date())!,
            status: .tooMuchDelayed,
        )
     }
    
    fileprivate static var onTrack: SleepTrainWidgetAttributes.ContentState {
        SleepTrainWidgetAttributes.ContentState(
            targetDepartureTime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!,
            targetArrivalTime:  Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date().addingTimeInterval(86_400))!,
            actualDepartureTime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!,
            currentTime: Calendar.current.date(bySettingHour: 23, minute: 30, second: 0, of: Date())!,
            status: .onTrack,
        )
     }
}

#Preview("Notification", as: .content, using: SleepTrainWidgetAttributes.preview) {
   SleepTrainWidgetLiveActivity()
} contentStates: {
    SleepTrainWidgetAttributes.ContentState.waitingToBoard
    SleepTrainWidgetAttributes.ContentState.onTrack
    SleepTrainWidgetAttributes.ContentState.delayed
    SleepTrainWidgetAttributes.ContentState.tooMuchDelayed
}

#Preview("Dynamic Island", as: .dynamicIsland(.expanded), using: SleepTrainWidgetAttributes.preview) {
   SleepTrainWidgetLiveActivity()
} contentStates: {
    SleepTrainWidgetAttributes.ContentState.waitingToBoard
    SleepTrainWidgetAttributes.ContentState.onTrack
    SleepTrainWidgetAttributes.ContentState.delayed
    SleepTrainWidgetAttributes.ContentState.tooMuchDelayed
}

#Preview("Dynamic Island (Compact)", as: .dynamicIsland(.compact), using: SleepTrainWidgetAttributes.preview) {
   SleepTrainWidgetLiveActivity()
} contentStates: {
    SleepTrainWidgetAttributes.ContentState.waitingToBoard
    SleepTrainWidgetAttributes.ContentState.onTrack
    SleepTrainWidgetAttributes.ContentState.delayed
    SleepTrainWidgetAttributes.ContentState.tooMuchDelayed
}
