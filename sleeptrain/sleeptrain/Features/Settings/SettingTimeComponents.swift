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
                .padding(.top, 8)
            Button("완료") { isPresented = false }
                .font(.system(size: 18, weight: .semibold))
                .padding()
        }
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
