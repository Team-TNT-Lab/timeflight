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

    var body: some View {
        VStack(spacing: 0) {
            DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.top, 10)

            Button(action: { isPresented = false }) {
                Text("완료")
                    .font(.system(size: 18, weight: .semibold))
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

    var body: some View {
        let binding = Binding<Date>(
            get: { date },
            set: { setDate($0) }
        )
        TimePickerSheet(date: binding, isPresented: isPresented)
    }
}
