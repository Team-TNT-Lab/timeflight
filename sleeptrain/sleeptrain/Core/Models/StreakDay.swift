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

// MARK: - 체크인 상태 타입
enum CheckInStatus {
    case notReached
    case available
    case completed
    case lateCompleted
    case failed
    case future
}

// MARK: - StreakDay + 체크인 상태 로직
// NOTE: checkInTime은 Mock 데이터용입니다. #if DEBUG로 분리하거나 Mock 전용 파일로 이동 예정.
extension StreakDay {
    // 실제 체크인 시간 (Mock 데이터용) - 일관된 데이터를 위해 고정
    var checkInTime: Date? {
        // Mock 데이터: 일부 날짜에 체크인 시간 시뮬레이션
        guard isCompleted else { return nil }
        
        let calendar = Calendar.current
        let trainDepartureTime = calendar.date(bySettingHour: 23, minute: 30, second: 0, of: date)!
        
        // 날짜 기반으로 일관된 체크인 시간 생성 (랜덤이 아닌 고정)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let checkInScenarios: [TimeInterval] = [
            -25 * 60,    // 25분 전 (정상)
            -10 * 60,    // 10분 전 (정상)
            5 * 60,      // 5분 지연 (정상)
            20 * 60,     // 20분 지연 (정상)
            45 * 60,     // 45분 지연 (늦은 체크인)
            90 * 60,     // 90분 지연 (늦은 체크인)
            150 * 60     // 150분 지연 (실패)
        ]
        
        // 날짜 기반으로 일관된 인덱스 선택
        let scenarioIndex = dayOfYear % checkInScenarios.count
        let selectedOffset = checkInScenarios[scenarioIndex]
        
        return calendar.date(byAdding: .second, value: Int(selectedOffset), to: trainDepartureTime)
    }
    
    var trainDepartureTime: Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 23, minute: 30, second: 0, of: date) ?? date
    }
    
    /// 현재 시나리오에 따라 해당 날짜의 체크인 상태를 판별
    func getCheckInStatus(
        currentTime: Date = Date(),
        currentRemainingTime: String = "20분",
        hasCheckedInToday: Bool = true,
        todayCheckInTime: Date? = nil,
        departureTimeString: String = "23:30",
        parseRemainingTime: (String) -> Int?,
        parseDepartureTime: (String, Date) -> Date
    ) -> CheckInStatus {
        let now = currentTime
        let calendar = Calendar.current
        
        // 미래 날짜
        if calendar.startOfDay(for: date) > calendar.startOfDay(for: now) {
            return .future
        }
        
        // 실제 출발 시간 계산
        // - 오늘: 현재 시간을 기준으로 실제 출발 시각을 계산
        // - 과거: 해당 날짜의 고정 출발 시각(23:30)을 사용
        let actualDepartureTime: Date = {
            if calendar.isDateInToday(date) {
                return parseDepartureTime(departureTimeString, now)
            } else {
                return trainDepartureTime
            }
        }()
        
        // 오늘 날짜 처리
        if calendar.isDateInToday(date) {
            // 실제 체크인이 되었다면 체크인 시간을 기반으로 상태 결정
            if hasCheckedInToday, let actualCheckIn = todayCheckInTime {
                let timeDifference = actualCheckIn.timeIntervalSince(actualDepartureTime)
                
                if timeDifference >= -30 * 60 && timeDifference <= 30 * 60 {
                    return .completed
                } else if timeDifference > 30 * 60 && timeDifference <= 120 * 60 {
                    return .lateCompleted
                } else {
                    return .failed
                }
            }
            
            // 아직 체크인 안 했을 때 - 남은 시간 기반
            guard let remainingMinutes = parseRemainingTime(currentRemainingTime) else {
                return .notReached
            }
            
            // 2시간 이상 지연 시 실패로 처리
            if remainingMinutes <= -120 {
                return .failed
            } else if remainingMinutes > 30 {
                return .notReached
            } else if remainingMinutes < 0 && remainingMinutes >= -120 {
                return .available
            } else if remainingMinutes >= -30 {
                return .available
            } else {
                return .failed
            }
        }
        
        // 과거 날짜 - 실제 체크인 시간을 기반으로 상태 결정
        guard let actualCheckIn = checkInTime else {
            return .failed
        }
        
        let timeDifference = actualCheckIn.timeIntervalSince(actualDepartureTime)
        
        if timeDifference >= -30 * 60 && timeDifference <= 30 * 60 {
            return .completed
        } else if timeDifference > 30 * 60 && timeDifference <= 120 * 60 {
            return .lateCompleted
        } else {
            return .failed
        }
    }
}

// MARK: - 실제 데이터 사용을 위한 헬퍼 함수 예시
extension StreakDay {
    /// 현재 시간을 기준으로 특정 출발 시각까지 남은 시간을 계산
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
        
        // 출발 시간이 이미 지났고 2시간 이내라면 다음 날로 설정
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
    
    /// 실제 데이터 사용 시를 위한 parseDepartureTime 클로저 예시
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
        
        // 출발 시간이 이미 지났고 2시간 이내라면 다음 날로 설정
        let maxDelay = departureDate.addingTimeInterval(2 * 3600)
        if currentTime > maxDelay {
            departureDate = calendar.date(byAdding: .day, value: 1, to: departureDate) ?? departureDate
        }
        
        return departureDate
    }
}
