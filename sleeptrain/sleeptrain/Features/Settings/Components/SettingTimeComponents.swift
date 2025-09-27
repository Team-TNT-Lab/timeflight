//
//  SettingTimeComponents.swift
//  timeflight
//
//  Created by bishoe01 on 9/20/25.
//

import SwiftUI

struct TimeField: View {
    var date: Date

    var body: some View {
        Text(date, style: .time)
            .font(.system(size: 24, weight: .semibold))
            .padding(10)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TimePickerSheet: View {
    @Binding var date: Date
    @Binding var isPresented: Bool
    var isForBedTime: Bool = false
    var isForWakeTime: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            DatePicker("", selection: Binding(
                get: { date },
                set: { newDate in
                    if isForBedTime {
                        if SleepTimeCalculator.isTimeInBedTimeRange(newDate) {
                            date = newDate
                        } else {
                            // 시간 범위 벗어나면 11시 취침
                            let calendar = Calendar.current

                            date = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: newDate) ?? newDate
                        }
                    } else if isForWakeTime {
                        if SleepTimeCalculator.isTimeInWakeTimeRange(newDate) {
                            date = newDate
                        } else {
                            // 시간 범위 벗어나면 7시 기상
                            let calendar = Calendar.current
                            date = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: newDate) ?? newDate
                        }
                    } else {
                        date = newDate
                    }
                }
            ), displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.top, 10)

            Button(action: { isPresented = false }) {
                Text("완료")
                    .font(.subTitle)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .contentShape(Capsule())
            }
            .background(Color.white)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
    }
}

struct TimePickerSheetWrapper: View {
    let isPresented: Binding<Bool>
    let date: Date
    let setDate: (Date) -> Void
    var isForBedTime: Bool = false
    var isForWakeTime: Bool = false

    var body: some View {
        let binding = Binding<Date>(
            get: { date },
            set: { setDate($0) }
        )
        TimePickerSheet(date: binding, isPresented: isPresented, isForBedTime: isForBedTime, isForWakeTime: isForWakeTime)
    }
}
