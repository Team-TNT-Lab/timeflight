//
//  DateService.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/27/25.
//

import Foundation

final class DateService {
    private let calendar = Calendar.current

    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    // 주간 표시용 날짜 생성
    func generateDisplayDays() -> [StreakDay] {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        // 과거/미래 범위
        let pastDays = 21
        let futureDays = 14

        // 표시 범위의 시작/끝
        let rangeStart = calendar.date(byAdding: .day, value: -pastDays, to: startOfToday) ?? startOfToday
        let rangeEnd = calendar.date(byAdding: .day, value: futureDays, to: startOfToday) ?? startOfToday

        // 월요일 시작
        var cal = calendar
        cal.firstWeekday = 2
        let alignedStart = cal.dateInterval(of: .weekOfYear, for: rangeStart)?.start ?? rangeStart

        // alignedStart ~ rangeEnd 까지 1일 단위 생성
        var days: [StreakDay] = []
        var cursor = alignedStart
        while cursor <= rangeEnd {
            days.append(StreakDay(date: cursor, isCompleted: false))
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor
            if cursor == alignedStart { break }
        }
        return days
    }
}
