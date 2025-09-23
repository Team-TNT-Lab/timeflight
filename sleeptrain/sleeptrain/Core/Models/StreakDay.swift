//
//  StreakDay.swift
//  sleeptrain
//
//  Created by Dean_SSONG on 9/23/25.
//

import Foundation

/// 주간 스트릭(요일별 달성 상태)을 표현하는 가벼운 값 타입
struct StreakDay: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    var isCompleted: Bool

    /// 오늘 여부
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    /// "MON", "TUE" 같은 3글자 대문자 요일 약어
    var weekdayShortSymbol: String {
        let calendar = Calendar.current
        let index = calendar.component(.weekday, from: date) - 1 // 1...7 → 0...6
        let symbols = calendar.shortWeekdaySymbols // 로케일에 맞는 ["Sun","Mon",...]
        guard symbols.indices.contains(index) else { return "" }
        return symbols[index].uppercased()
    }

    /// "M", "T" 같은 1글자 요일 약어(로케일 기준)
    var weekdayOneLetterSymbol: String {
        String(weekdayShortSymbol.prefix(1))
    }
}

// MARK: - Mock / Factory
extension StreakDay {
    /// 오늘이 포함된 이번 주 7일 데이터를 생성합니다.
    /// - Rule: 오늘 이전 날짜는 완료(true), 오늘/미래는 미완료(false).
    static func currentWeekMock(calendar: Calendar = .current) -> [StreakDay] {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            // 실패 시 오늘부터 7일
            return (0..<7).compactMap { offset in
                guard let day = calendar.date(byAdding: .day, value: offset, to: startOfToday) else { return nil }
                let start = calendar.startOfDay(for: day)
                let isCompleted = start < startOfToday
                return StreakDay(date: day, isCompleted: isCompleted)
            }
        }

        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else { return nil }
            let start = calendar.startOfDay(for: day)
            let isCompleted = start < startOfToday
            return StreakDay(date: day, isCompleted: isCompleted)
        }
    }
    
    /// 과거 2주일부터 미래 1주일까지의 데이터를 월요일부터 시작하도록 정렬하여 생성합니다.
    /// - Rule: 체크인 상태는 고정된 패턴으로 결정됩니다.
    static func extendedStreakMock(calendar: Calendar = .current) -> [StreakDay] {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        // 과거 3주(21일) + 오늘 + 미래 2주(14일) = 총 36일
        let pastDays = 21
        let futureDays = 14
        
        var allDays: [StreakDay] = []
        
        // 고정된 패턴으로 과거 체크인 상태 생성 (일관된 스트릭 계산을 위해)
        let checkInPattern = [true, true, false, true, true, true, false, true, true, true] // 70% 성공률의 고정 패턴
        
        // 과거 날짜들
        for dayOffset in (-pastDays...(-1)) {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) else { continue }
            // 날짜 기반으로 일관된 체크인 상태 결정
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: day) ?? 1
            let patternIndex = (dayOfYear - 1) % checkInPattern.count
            let attemptedCheckIn = checkInPattern[patternIndex]
            allDays.append(StreakDay(date: day, isCompleted: attemptedCheckIn))
        }
        
        // 오늘
        allDays.append(StreakDay(date: startOfToday, isCompleted: false))
        
        // 미래 날짜들 (미완료)
        for dayOffset in 1...futureDays {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) else { continue }
            allDays.append(StreakDay(date: day, isCompleted: false))
        }
        
        // 가장 이른 월요일부터 시작하도록 조정
        guard let earliestDate = allDays.first?.date else { return allDays }
        
        // 해당 주의 월요일 찾기
        var adjustedCalendar = calendar
        adjustedCalendar.firstWeekday = 2 // 월요일을 주의 시작으로 설정
        
        guard let startOfWeek = adjustedCalendar.dateInterval(of: .weekOfYear, for: earliestDate)?.start else {
            return allDays
        }
        
        // 월요일부터 시작하도록 앞쪽에 빈 날짜들 추가 (필요한 경우)
        var adjustedDays: [StreakDay] = []
        var currentDate = startOfWeek
        
        while currentDate < allDays.first?.date ?? Date() {
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: currentDate) ?? 1
            let patternIndex = (dayOfYear - 1) % checkInPattern.count
            let attemptedCheckIn = checkInPattern[patternIndex]
            adjustedDays.append(StreakDay(date: currentDate, isCompleted: attemptedCheckIn))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        adjustedDays.append(contentsOf: allDays)
        
        return adjustedDays
    }
}
