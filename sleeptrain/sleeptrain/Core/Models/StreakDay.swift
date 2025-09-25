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
}

// MARK: - Mock / Factory
extension StreakDay {
    static func currentWeekMock(calendar: Calendar = .current) -> [StreakDay] {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
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
    
    static func extendedStreakMock(calendar: Calendar = .current) -> [StreakDay] {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let pastDays = 21
        let futureDays = 14
        
        var allDays: [StreakDay] = []
        let checkInPattern = [true, true, false, true, true, true, false, true, true, true]
        
        for dayOffset in (-pastDays...(-1)) {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) else { continue }
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: day) ?? 1
            let patternIndex = (dayOfYear - 1) % checkInPattern.count
            let attemptedCheckIn = checkInPattern[patternIndex]
            allDays.append(StreakDay(date: day, isCompleted: attemptedCheckIn))
        }
        
        allDays.append(StreakDay(date: startOfToday, isCompleted: false))
        
        for dayOffset in 1...futureDays {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) else { continue }
            allDays.append(StreakDay(date: day, isCompleted: false))
        }
        
        guard let earliestDate = allDays.first?.date else { return allDays }
        
        var adjustedCalendar = calendar
        adjustedCalendar.firstWeekday = 2
        
        guard let startOfWeek = adjustedCalendar.dateInterval(of: .weekOfYear, for: earliestDate)?.start else {
            return allDays
        }
        
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

// MARK: - 체크인 상태 타입
enum CheckInStatus {
    case notReached
    case available
    case completed
    case lateCompleted
    case failed
    case future
    case noRecord
}

// MARK: - 실제 데이터 기반 상태 계산
extension StreakDay {
    static func departureDate(for day: Date, fromTemplate template: Date, calendar: Calendar = .current) -> Date {
        let h = calendar.component(.hour, from: template)
        let m = calendar.component(.minute, from: template)
        return calendar.date(
            bySettingHour: h, minute: m, second: 0,
            of: day
        ) ?? day
    }
    
    static func classify(departure: Date, checkIn: Date) -> CheckInStatus {
        let diff = checkIn.timeIntervalSince(departure) // 초
        switch diff {
        case (-30 * 60)...(30 * 60):
            return .completed
        case ((30 * 60) + 1)...(120 * 60):
            return .lateCompleted
        default:
            return .failed
        }
    }
    
    func getCheckInStatus(
        daily: DailyCheckIn?,
        departureTemplate: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> CheckInStatus {
        let startOfSelf = calendar.startOfDay(for: date)
        let startOfNow = calendar.startOfDay(for: now)
        
        // 미래 날짜
        if startOfSelf > startOfNow {
            return .future
        }
        
        // 해당 날짜의 출발 시각
        let departure = StreakDay.departureDate(for: startOfSelf, fromTemplate: departureTemplate, calendar: calendar)
        
        // 오늘 날짜 로직
        if startOfSelf == startOfNow {
            // 1) 먼저 저장된 status를 우선 반영 (비상정지 등)
            if let d = daily {
                switch d.status {
                case .failed:
                    return .failed
                case .completed, .lateCompleted:
                    if let checkIn = d.checkedInAt {
                        return StreakDay.classify(departure: departure, checkIn: checkIn)
                    } else {
                        // 상태는 완료지만 체크인 시간이 비어있다면 보수적으로 완료 취급
                        return d.status == .completed ? .completed : .lateCompleted
                    }
                case .none:
                    break
                }
            }
            // 2) 체크인 기록이 없거나 상태가 none이면 시간 기준으로 판정
            let minutesUntilDeparture = Int((departure.timeIntervalSince(now) / 60.0).rounded(.down))
            if minutesUntilDeparture > 30 {
                return .notReached
            } else if minutesUntilDeparture >= -120 {
                return .available
            } else {
                return .failed
            }
        }
        
        // 과거 날짜 로직
        if let d = daily {
            switch d.status {
            case .failed:
                return .failed
            case .completed, .lateCompleted:
                if let checkIn = d.checkedInAt {
                    return StreakDay.classify(departure: departure, checkIn: checkIn)
                } else {
                    return d.status == .completed ? .completed : .lateCompleted
                }
            case .none:
                return .noRecord
            }
        } else {
            return .noRecord
        }
    }
    
    func getCheckInStatus(
        daily: DailyCheckIn?,
        userSettings: UserSettings,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> CheckInStatus {
        return getCheckInStatus(
            daily: daily,
            departureTemplate: userSettings.targetDepartureTime,
            now: now,
            calendar: calendar
        )
    }
}

// MARK: - 기존(문자열 기반) 호출과의 호환 오버로드
extension StreakDay {
    func getCheckInStatus(
        currentTime: Date = Date(),
        currentRemainingTime: String,
        hasCheckedInToday: Bool,
        todayCheckInTime: Date?,
        departureTimeString: String,
        parseRemainingTime: (String) -> Int?,
        parseDepartureTime: (String, Date) -> Date
    ) -> CheckInStatus {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let nowStart = cal.startOfDay(for: currentTime)
        
        if dayStart > nowStart {
            return .future
        }
        
        func departureOnThisDay() -> Date {
            let comps = departureTimeString.split(separator: ":")
            if comps.count == 2, let h = Int(comps[0]), let m = Int(comps[1]) {
                return cal.date(bySettingHour: h, minute: m, second: 0, of: dayStart) ?? date
            } else {
                return cal.date(bySettingHour: 23, minute: 30, second: 0, of: dayStart) ?? date
            }
        }
        let departure = departureOnThisDay()
        
        if dayStart == nowStart {
            // 문자열 기반 경로는 저장 상태를 조회할 수 없으므로 기존 로직 유지
            if hasCheckedInToday, let checkIn = todayCheckInTime {
                return StreakDay.classify(departure: departure, checkIn: checkIn)
            }
            guard let remainingMinutes = parseRemainingTime(currentRemainingTime) else {
                return .notReached
            }
            if remainingMinutes <= -120 {
                return .failed
            } else if remainingMinutes > 30 {
                return .notReached
            } else {
                return .available
            }
        }
        
        return isCompleted ? .completed : .noRecord
    }
}

// MARK: - 실제 데이터 사용을 위한 헬퍼 함수 예시
extension StreakDay {
    static func calculateRemainingTimeToDeparture(from currentTime: Date, departureTimeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let departureTimeToday = formatter.date(from: departureTimeString) else {
            return ""
        }
        
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.year, .month, .day], from: currentTime)
        let departureComponents = calendar.dateComponents([.hour, .minute], from: departureTimeToday)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = currentComponents.year
        combinedComponents.month = currentComponents.month
        combinedComponents.day = currentComponents.day
        combinedComponents.hour = departureComponents.hour
        combinedComponents.minute = departureComponents.minute
        
        guard var departureDate = calendar.date(from: combinedComponents) else {
            return ""
        }
        
        let maxDelay = departureDate.addingTimeInterval(2 * 3600)
        if currentTime > maxDelay {
            departureDate = calendar.date(byAdding: .day, value: 1, to: departureDate) ?? departureDate
        }
        
        let diff = calendar.dateComponents([.hour, .minute], from: currentTime, to: departureDate)
        let hours = diff.hour ?? 0
        let minutes = diff.minute ?? 0
        
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else if minutes > 0 {
            return "\(minutes)분"
        } else if minutes < 0 {
            return "\(abs(minutes))분 지연"
        } else {
            return "출발 시간"
        }
    }
    
    static let realDataParseDepartureTime: (String, Date) -> Date = { departureTimeString, currentTime in
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let departureTimeToday = formatter.date(from: departureTimeString) else {
            return currentTime
        }
        
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.year, .month, .day], from: currentTime)
        let departureComponents = calendar.dateComponents([.hour, .minute], from: departureTimeToday)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = currentComponents.year
        combinedComponents.month = currentComponents.month
        combinedComponents.day = currentComponents.day
        combinedComponents.hour = departureComponents.hour
        combinedComponents.minute = departureComponents.minute
        
        guard var departureDate = calendar.date(from: combinedComponents) else {
            return currentTime
        }
        
        let maxDelay = departureDate.addingTimeInterval(2 * 3600)
        if currentTime > maxDelay {
            departureDate = calendar.date(byAdding: .day, value: 1, to: departureDate) ?? departureDate
        }
        
        return departureDate
    }
}
