//
//  FlightViewModel.swift
//  timeflight
//
//  Created by bishoe01 on 9/21/25.
//

import Foundation
import SwiftUI

final class FlightViewModel: ObservableObject {
    func calculateTimeUntilSleep() -> String {
        guard let schedule = SleepScheduleStorage.load(), schedule.isEnabled else {
            return "수면 스케줄이 설정되지 않았어요"
        }

        let (sleepStart, _) = schedule.getTodaySchedule()
        let now = Date()

        // 이미 수면 시간이 지났다면 다음날 수면 시간 계산
        if now >= sleepStart {
            let calendar = Calendar.current
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: sleepStart) ?? sleepStart
            let timeInterval = tomorrow.timeIntervalSince(now)
            return formatTimeInterval(timeInterval)
        } else {
            let timeInterval = sleepStart.timeIntervalSince(now)
            return formatTimeInterval(timeInterval)
        }
    }

    func calculateSleepStartTime() -> String {
        guard let schedule = SleepScheduleStorage.load(), schedule.isEnabled else {
            return "설정에서 수면 시간을 설정해주세요"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let (sleepStart, _) = schedule.getTodaySchedule()
        let now = Date()

        if now >= sleepStart {
            // 이미 지났다면 내일 시간 표시
            let calendar = Calendar.current
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: sleepStart) ?? sleepStart
            return "내일 \(formatter.string(from: tomorrow))에 수면시작"
        } else {
            return "\(formatter.string(from: sleepStart))에 수면시작"
        }
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60

        if hours > 0 {
            return "비행까지 \(hours)시간 \(minutes)분 남았어요"
        } else {
            return "비행까지 \(minutes)분 남았어요"
        }
    }
}
