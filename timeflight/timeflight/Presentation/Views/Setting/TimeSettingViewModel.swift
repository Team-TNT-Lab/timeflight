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

    init() {
        // userdefaults에서 가져오면서 저장된스케줄있는지확인
        if let savedSchedule = SleepScheduleStorage.load() {
            self.startDate = savedSchedule.startTime
            self.endDate = savedSchedule.endTime
        } else {
            self.startDate = Calendar.current.startOfDay(for: Date())
            self.endDate = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        }
    }

    func setStartDate(_ newStart: Date) {
        startDate = newStart
    }

    func setEndDate(_ newEnd: Date) {
        endDate = newEnd
    }

    func saveSchedule() {
        let schedule = SleepSchedule(
            startTime: normalizedStartDate,
            endTime: normalizedEndDate
        )
        SleepScheduleStorage.save(schedule: schedule)
    }

    var sleepHoursText: String {
        let calendar = Calendar.current
        let startHM = calendar.dateComponents([.hour, .minute], from: startDate)
        let endHM = calendar.dateComponents([.hour, .minute], from: endDate)

        let base = calendar.startOfDay(for: Date())
        let startSameDay = calendar.date(bySettingHour: startHM.hour ?? 0,
                                         minute: startHM.minute ?? 0,
                                         second: 0,
                                         of: base) ?? base
        let endSameDay = calendar.date(bySettingHour: endHM.hour ?? 0,
                                       minute: endHM.minute ?? 0,
                                       second: 0,
                                       of: base) ?? base

        let normalizedEnd: Date
        if endSameDay <= startSameDay {
            normalizedEnd = calendar.date(byAdding: .day, value: 1, to: endSameDay) ?? endSameDay.addingTimeInterval(24*60*60)
        } else {
            normalizedEnd = endSameDay
        }

        let interval = normalizedEnd.timeIntervalSince(startSameDay)
        let totalMinutes = max(0, Int(interval / 60))
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if mins == 0 {
            return "\(hours)시간 수면"
        } else {
            return "\(hours)시간 \(mins)분 수면"
        }
    }

    var normalizedStartDate: Date {
        let calendar = Calendar.current
        let hm = calendar.dateComponents([.hour, .minute], from: startDate)
        let base = calendar.startOfDay(for: startDate)
        return calendar.date(bySettingHour: hm.hour ?? 0,
                             minute: hm.minute ?? 0,
                             second: 0,
                             of: base) ?? startDate
    }

    var normalizedEndDate: Date {
        let calendar = Calendar.current
        let startHM = calendar.dateComponents([.hour, .minute], from: startDate)
        let endHM = calendar.dateComponents([.hour, .minute], from: endDate)

        let base = calendar.startOfDay(for: startDate)

        // 종료날은 일단 시작날짜랑 동일
        let startSameDay = calendar.date(bySettingHour: startHM.hour ?? 0,
                                         minute: startHM.minute ?? 0,
                                         second: 0,
                                         of: base) ?? base
        let endSameDay = calendar.date(bySettingHour: endHM.hour ?? 0,
                                       minute: endHM.minute ?? 0,
                                       second: 0,
                                       of: base) ?? base

        // 종료 시각이 시작시간보다 이전이면 한바퀴돌아서 다음날로 추정
        if endSameDay <= startSameDay {
            return calendar.date(byAdding: .day, value: 1, to: endSameDay) ?? endSameDay.addingTimeInterval(24*60*60)
        } else {
            return endSameDay
        }
    }
}
