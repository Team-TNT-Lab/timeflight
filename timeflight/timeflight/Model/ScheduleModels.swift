//
//  ScheduleModels.swift
//  timeflight
//
//  Created by bishoe01 on 9/19/25.
//

import Foundation

struct SleepSchedule: Codable {
    let startTime: Date
    let endTime: Date
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
