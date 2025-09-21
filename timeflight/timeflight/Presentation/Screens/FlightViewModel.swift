//
//  FlightViewModel.swift
//  timeflight
//
//  Created by bishoe01 on 9/21/25.
//

import Foundation
import SwiftUI

final class FlightViewModel: ObservableObject {
    @Published var isSleepModeActive: Bool = false

    func startSleep() {
        isSleepModeActive = true
    }

    func stopSleep() {
        isSleepModeActive = false
    }

    func calculateTimeUntilSleep() -> String {
        guard let schedule = SleepScheduleStorage.load(), schedule.isEnabled else {
            return "수면 스케줄이 설정되지 않았어요"
        }

        let (sleepStart, sleepEnd) = schedule.getTodaySchedule()
        let now = Date()

        if isSleepModeActive {
            // 수면시작했는지(NFC태그여부)
            if now <= sleepEnd {
                return "현재 수면 중"
            } else {
                // 수면 시간이후 자동으로 수면 모드 종료(notification로직필요)
                isSleepModeActive = false
                return "수면이 완료되었습니다"
            }
        } else {
            // 수면을시작하지않았을때(태그하지않음)
            if now >= sleepStart {
                let timeElapsed = now.timeIntervalSince(sleepStart)
                return formatOverdueTime(timeElapsed)
            } else {
                // 수면시작시간 전일때
                let timeInterval = sleepStart.timeIntervalSince(now)
                return formatTimeInterval(timeInterval)
            }
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

    private func formatOverdueTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60

        if hours > 0 {
            return "수면 시간에서 \(hours)시간 \(minutes)분 지연"
        } else {
            return "수면 시간에서 \(minutes)분 지연"
        }
    }
}
