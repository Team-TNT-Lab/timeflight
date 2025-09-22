//
//  ScheduleModels.swift
//  timeflight
//
//  Created by bishoe01 on 9/19/25.
//

import Foundation

struct SleepSchedule: Codable {
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let isEnabled: Bool // on/off 여부

    var startTime: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: today) ?? today
    }

    var endTime: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDate = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: today) ?? today

        // 시간 24시가 넘어가면 다음날로 간주
        if endDate <= startTime {
            return calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
        }
        return endDate
    }

    // 호출하는 시점의 날짜가 들어감- 9월22일에 호출하면 9.22기준으로 알람설정됨
    func getTodaySchedule() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayStart = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: today) ?? today

        return (start: todayStart, end: endTime)
    }
}

enum SleepScheduleStorage {
    private static let scheduleKey = "sleepSchedule"

    static func save(schedule: SleepSchedule) {
        if let data = try? JSONEncoder().encode(schedule) {
            UserDefaults.standard.set(data, forKey: scheduleKey)
        }
    }

    static func load() -> SleepSchedule? {
        guard let data = UserDefaults.standard.data(forKey: scheduleKey),
              let schedule = try? JSONDecoder().decode(SleepSchedule.self, from: data)
        else {
            return nil
        }
        return schedule
    }
}
