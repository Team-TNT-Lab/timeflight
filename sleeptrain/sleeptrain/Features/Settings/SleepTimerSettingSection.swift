//
//  SleepTimerSettingView.swift
//  timeflight
//
//  Created by bishoe01 on 9/20/25.
//

import SwiftUI

struct SleepTimerSettingView: View {
    let weekdayTitle: String
    let startDate: Date
    let endDate: Date
    let sleepHoursText: String
    let onTapStart: () -> Void
    let onTapEnd: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(weekdayTitle)

            Spacer().frame(height: 16)
            HStack(alignment: .center, spacing: 16) {
                Button(action: onTapStart) {
                    TimeField(date: startDate)
                }
                Text("–")
                    .font(.system(size: 20))
                    .opacity(0.2)

                Button(action: onTapEnd) {
                    TimeField(date: endDate)
                }
            }

            Text(sleepHoursText)
                .opacity(0.4)
        }
    }
}
