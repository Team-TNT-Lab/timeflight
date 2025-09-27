//
//  CheckInService.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/27/25.
//

import Foundation
import SwiftData

final class CheckInService {
    func performCheckIn(at date: Date, startTimeText: String, context: ModelContext) -> CheckInResult {
        // 이미 체크인 했는지 확인
        if let today = fetchCheckIn(for: date, context: context),
           today.checkedInAt != nil
        {
            return CheckInResult(
                success: true,
                streak: computeCurrentStreak(context: context),
                alreadyCheckedIn: true
            )
        }

        let departureTime = parseDepartureTime(startTimeText)
        let diff = date.timeIntervalSince(departureTime)

        // 허용 범위 확인
        let lowerBound: TimeInterval = -30 * 60
        let upperBound: TimeInterval = 120 * 60
        guard diff >= lowerBound, diff <= upperBound else {
            return CheckInResult(success: false, streak: 0, alreadyCheckedIn: false)
        }

        // 상태 판정
        let status: DailyStatus
        if diff >= -30 * 60, diff <= 30 * 60 {
            status = .completed
        } else if diff > 30 * 60, diff <= 120 * 60 {
            status = .lateCompleted
        } else {
            status = .failed
        }

        let rec = upsertCheckIn(for: date, context: context)
        rec.status = status
        rec.checkedInAt = date
        try? context.save()

        // 스트릭 계산
        let newStreak = computeCurrentStreak(context: context)
        saveStreakToStats(newStreak, context: context)

        return CheckInResult(success: true, streak: newStreak, alreadyCheckedIn: false)
    }

    // 현재 스트릭 가져오기
    func getCurrentStreak(context: ModelContext) -> Int {
        return computeCurrentStreak(context: context)
    }

    // 오늘 체크인 상태 확인
    func getTodayCheckInStatus(context: ModelContext) -> (hasCheckedIn: Bool, checkedAt: Date?) {
        let today = fetchCheckIn(for: Date(), context: context)
        return (today?.checkedInAt != nil, today?.checkedInAt)
    }

    // 특정 날짜의 체크인 상태 확인
    func getCheckInStatusForDay(_ date: Date, context: ModelContext) -> (isCompleted: Bool, status: DailyStatus) {
        guard let checkIn = fetchCheckIn(for: date, context: context) else {
            return (false, .none)
        }

        let isCompleted = checkIn.status == .completed || checkIn.status == .lateCompleted
        return (isCompleted, checkIn.status)
    }

    // MARK: - Private Methods

    private func fetchCheckIn(for date: Date, context: ModelContext) -> DailyCheckIn? {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        let predicate = #Predicate<DailyCheckIn> { $0.date >= start && $0.date < end }
        let desc = FetchDescriptor<DailyCheckIn>(predicate: predicate)
        return (try? context.fetch(desc))?.first
    }

    private func upsertCheckIn(for date: Date, context: ModelContext) -> DailyCheckIn {
        if let existing = fetchCheckIn(for: date, context: context) {
            return existing
        }
        let record = DailyCheckIn(
            date: Calendar.current.startOfDay(for: date),
            status: .none,
            checkedInAt: nil
        )
        context.insert(record)
        return record
    }

    private func computeCurrentStreak(context: ModelContext) -> Int {
        let cal = Calendar.current
        var cursor = Calendar.current.startOfDay(for: Date())
        var streak = 0

        while true {
            if let rec = fetchCheckIn(for: cursor, context: context) {
                switch rec.status {
                case .completed, .lateCompleted:
                    streak += 1
                    guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { return streak }
                    cursor = Calendar.current.startOfDay(for: prev)
                case .failed, .none:
                    return streak
                }
            } else {
                return streak
            }
        }
    }

    private func saveStreakToStats(_ streak: Int, context: ModelContext) {
        let existing = try? context.fetch(FetchDescriptor<Stats>())
        if let stats = existing?.first {
            stats.streak = streak
        } else {
            context.insert(Stats(streak: streak))
        }
        try? context.save()
    }
}

struct CheckInResult {
    let success: Bool
    let streak: Int
    let alreadyCheckedIn: Bool
}
