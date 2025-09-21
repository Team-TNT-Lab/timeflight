//
//  TimeSettingViewModel.swift
//  timeflight
//
//  Created by bishoe01 on 9/20/25.
//

import SwiftUI

final class TimeSettingViewModel: ObservableObject {
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var showingStartPicker: Bool = false
    @Published var showingEndPicker: Bool = false

    init(
        startDate: Date = Calendar.current.startOfDay(for: Date()),
        endDate: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    ) {
        self.startDate = startDate
        self.endDate = endDate
    }

    func setStartDate(_ newStart: Date) {
        startDate = newStart
        if endDate <= startDate {
            endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate.addingTimeInterval(24*60*60)
        }
    }

    func setEndDate(_ newEnd: Date) {
        endDate = newEnd
        if endDate <= startDate {
            endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate.addingTimeInterval(24*60*60)
        }
    }

    var sleepHoursText: String {
        let comps = Calendar.current.dateComponents([.minute], from: startDate, to: endDate)
        let minutes = (comps.minute ?? 0 + 24*60) % (24*60)
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 {
            return "\(hours)시간 수면"
        } else {
            return "\(hours)시간 \(mins)분 수면"
        }
    }
}
