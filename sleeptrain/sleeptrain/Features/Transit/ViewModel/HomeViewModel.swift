import Foundation
import SwiftUI

final class HomeViewModel: ObservableObject {
    @Published var weekDays: [StreakDay] = StreakDay.extendedStreakMock()
    @Published var hasCheckedInToday: Bool = false
    @Published var todayCheckInTime: Date?

    // 시나리오(남은 시간/출발 시간) 변경 시 체크인 상태 초기화
    func resetForScenarioChange() {
        hasCheckedInToday = false
        todayCheckInTime = nil
    }
    
    // 데모용: 카드 탭 시 오늘 체크인 초기화
    func resetTodayCheckIn() {
        hasCheckedInToday = false
        todayCheckInTime = nil
    }

    // 2시간 이상 지연 시 스트릭 초기화 체크 및 sleepCount 업데이트
    func checkAndHandleFailedState(
        remainingTimeText: String,
        startTimeText: String,
        updateSleepCount: (Int) -> Void
    ) {
        guard let remainingMinutes = parseRemainingTimeToMinutes(remainingTimeText) else { return }
        
        // 2시간(120분) 이상 지연 시 즉시 sleepCount를 0으로 초기화
        if remainingMinutes <= -120 {
            updateSleepCount(0)
            return
        }
        
        // 일반적인 상황에서는 현재 스트릭 계산
        let currentStreak = calculateCurrentStreak(
            remainingTimeText: remainingTimeText,
            startTimeText: startTimeText
        )
        updateSleepCount(currentStreak)
    }

    // 체크인 수행: 외부에서 타임 문자열을 넘기고, sleepCount 갱신은 콜백으로 처리
    func performCheckIn(
        remainingTimeText: String,
        startTimeText: String,
        updateSleepCount: (Int) -> Void
    ) {
        guard canCheckIn(
            remainingTimeText: remainingTimeText,
            hasCheckedInToday: hasCheckedInToday
        ) else { return }
        
        hasCheckedInToday = true
        todayCheckInTime = calculateCheckInTimeForCurrentScenario(
            remainingTimeText: remainingTimeText,
            startTimeText: startTimeText
        )
        
        if let todayIndex = weekDays.firstIndex(where: { $0.isToday }) {
            weekDays[todayIndex] = StreakDay(date: weekDays[todayIndex].date, isCompleted: true)
        }
        
        if let newSleepCount = updateSleepCountBasedOnStreak(
            remainingTimeText: remainingTimeText,
            startTimeText: startTimeText
        ) {
            updateSleepCount(newSleepCount)
        }
    }
    
    // NFC 태그 시각 기반 체크인 수행
    func performCheckIn(
        taggedAt: Date,
        remainingTimeText: String,
        startTimeText: String,
        updateSleepCount: (Int) -> Void
    ) {
        guard !hasCheckedInToday else { return }
        
        let departureTime = parseDepartureTime(startTimeText)
        let diff = taggedAt.timeIntervalSince(departureTime) // 초 단위
        
        // 허용 범위: 출발 30분 전 ~ 출발 120분 후 (2시간 이상 지연 방지)
        let lowerBound: TimeInterval = -30 * 60
        let upperBound: TimeInterval = 120 * 60
        guard diff >= lowerBound && diff <= upperBound else {
            // 허용 시간대가 아니면 체크인하지 않음 (2시간 이상 지연 시 차단됨)
            return
        }
        
        hasCheckedInToday = true
        todayCheckInTime = taggedAt
        
        if let todayIndex = weekDays.firstIndex(where: { $0.isToday }) {
            weekDays[todayIndex] = StreakDay(date: weekDays[todayIndex].date, isCompleted: true)
        }
        
        if let newSleepCount = updateSleepCountBasedOnStreak(
            remainingTimeText: remainingTimeText,
            startTimeText: startTimeText
        ) {
            updateSleepCount(newSleepCount)
        } else {
            // 안전망: 직접 재계산
            let recalculated = calculateCurrentStreak(
                remainingTimeText: remainingTimeText,
                startTimeText: startTimeText
            )
            updateSleepCount(recalculated)
        }
    }

    // 오늘 상태에 따라 수면 스트릭 카운트를 계산해 반환(변경 없으면 nil)
    func updateSleepCountBasedOnStreak(
        remainingTimeText: String,
        startTimeText: String
    ) -> Int? {
        let today = Date()
        let calendar = Calendar.current
        if let todayStreak = weekDays.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            let checkInResult = todayStreak.getCheckInStatus(
                currentRemainingTime: remainingTimeText,
                hasCheckedInToday: hasCheckedInToday,
                todayCheckInTime: todayCheckInTime,
                departureTimeString: startTimeText,
                parseRemainingTime: parseRemainingTimeToMinutes,
                parseDepartureTime: { timeString, _ in parseDepartureTime(timeString) }
            )
            switch checkInResult {
            case .failed:
                return 0
            case .completed, .lateCompleted:
                return calculateCurrentStreak(
                    remainingTimeText: remainingTimeText,
                    startTimeText: startTimeText
                )
            default:
                return nil
            }
        }
        return nil
    }

    /// 연속 체크인 성공 일수 계산
    func calculateCurrentStreak(
        remainingTimeText: String,
        startTimeText: String
    ) -> Int {
        let today = Date()
        let calendar = Calendar.current
        var streak = 0
        let sortedDays = weekDays.sorted { $0.date > $1.date }
        
        for day in sortedDays {
            if calendar.startOfDay(for: day.date) > calendar.startOfDay(for: today) {
                continue
            }
            let status = day.getCheckInStatus(
                currentRemainingTime: remainingTimeText,
                hasCheckedInToday: hasCheckedInToday,
                todayCheckInTime: todayCheckInTime,
                departureTimeString: startTimeText,
                parseRemainingTime: parseRemainingTimeToMinutes,
                parseDepartureTime: { timeString, _ in parseDepartureTime(timeString) }
            )
            switch status {
            case .completed, .lateCompleted:
                streak += 1
            case .failed:
                // 실패를 만나면 연속이 끊김
                break
            case .notReached, .available:
                if calendar.isDateInToday(day.date) {
                    continue
                } else {
                    break
                }
            default:
                continue
            }
        }
        return streak
    }

    /// 남은 시간과 출발 시간을 기반으로 현재 시나리오의 체크인 시간 계산(데모용)
    /// - remainingTimeText 파싱 결과를 사용하여 일반화
    func calculateCheckInTimeForCurrentScenario(
        remainingTimeText: String,
        startTimeText: String
    ) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let departureTime = parseDepartureTime(startTimeText)
        
        guard let remainingMinutes = parseRemainingTimeToMinutes(remainingTimeText) else {
            return today
        }
        // 양수: 출발까지 남은 시간 -> 출발 시각으로부터 -remainingMinutes
        // 음수: 지연(이미 출발 시각 경과) -> 출발 시각으로부터 +abs(remainingMinutes)
        let offset = remainingMinutes >= 0 ? -remainingMinutes : abs(remainingMinutes)
        return calendar.date(byAdding: .minute, value: offset, to: departureTime) ?? today
    }
    /// 시작 시각과 도착 시각 문자열을 받아 남은 시간 문자열로 반환
    func calculateRemainingTime(from startDate: Date, to endTimeText: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let endTime = formatter.date(from: endTimeText) else { return nil }

        var calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        var combinedComponents = DateComponents()
        combinedComponents.year = startComponents.year
        combinedComponents.month = startComponents.month
        combinedComponents.day = startComponents.day
        combinedComponents.hour = endComponents.hour
        combinedComponents.minute = endComponents.minute

        guard var endDate = calendar.date(from: combinedComponents) else { return nil }

        if endDate < startDate {
            endDate = calendar.date(byAdding: .day, value: 1, to: endDate)!
        }

        let diff = calendar.dateComponents([.hour, .minute], from: startDate, to: endDate)
        let hours = diff.hour ?? 0
        let minutes = diff.minute ?? 0

        if hours > 0 && minutes > 0 {
            return "\(hours)시간 \(minutes)분"
        } else if hours > 0 {
            return "\(hours)시간"
        } else if minutes > 0 {
            return "\(minutes)분"
        } else {
            return "0분"
        }
    }
    /// 출발 시각 기준 체크인 시각과 도착 시각 문자열을 받아 남은 시간을 계산
    func calculateRemainingTimeFromCheckInToEnd(
        startTimeText: String,
        remainingTimeText: String,
        endTimeText: String
    ) -> String? {
        let checkInTime = calculateCheckInTimeForCurrentScenario(
            remainingTimeText: remainingTimeText,
            startTimeText: startTimeText
        )

        return calculateRemainingTime(from: checkInTime, to: endTimeText)
    }
    
    /// 티켓 카드/출발 시각 변경 등으로 스트릭 동기화 (2시간 이상 지연 시 즉시 0 반환)
    func syncCurrentStreak(
        remainingTimeText: String,
        startTimeText: String
    ) -> Int {
        guard let remainingMinutes = parseRemainingTimeToMinutes(remainingTimeText) else {
            return calculateCurrentStreak(remainingTimeText: remainingTimeText, startTimeText: startTimeText)
        }
        
        // 2시간(120분) 이상 지연 시 즉시 0 반환
        if remainingMinutes <= -120 {
            return 0
        }
        
        return calculateCurrentStreak(
            remainingTimeText: remainingTimeText,
            startTimeText: startTimeText
        )
    }
    
    /// 현재 시각부터 다음 출발 시각까지 남은 시간을 문자열로 반환
    func calculateRemainingTimeToDeparture(from currentTime: Date, targetDepartureTime: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let departureTimeToday = formatter.date(from: targetDepartureTime) else {
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
            departureDate = calendar.date(byAdding: .day, value: 1, to: departureDate)!
        }
        
        let diff = calendar.dateComponents([.hour, .minute], from: currentTime, to: departureDate)
        let hours = diff.hour ?? 0
        let minutes = diff.minute ?? 0
        
        if hours > 0 && minutes > 0 {
            return "\(hours)시간 \(minutes)분"
        } else if hours > 0 {
            return "\(hours)시간"
        } else if minutes > 0 {
            return "\(minutes)분"
        } else {
            return "0분"
        }
    }
//    /// 목데이터 기준 특정 시각부터 출발 시각까지 남은 시간을 계산
//    func calculateMockRemainingTimeToDeparture(from referenceDate: Date, startTimeText: String) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "HH:mm"
//
//        guard let departureTimeToday = formatter.date(from: startTimeText) else {
//            return ""
//        }
//
//        let calendar = Calendar.current
//        let referenceComponents = calendar.dateComponents([.year, .month, .day], from: referenceDate)
//        let departureComponents = calendar.dateComponents([.hour, .minute], from: departureTimeToday)
//
//        var combinedComponents = DateComponents()
//        combinedComponents.year = referenceComponents.year
//        combinedComponents.month = referenceComponents.month
//        combinedComponents.day = referenceComponents.day
//        combinedComponents.hour = departureComponents.hour
//        combinedComponents.minute = departureComponents.minute
//
//        guard var departureDate = calendar.date(from: combinedComponents) else {
//            return ""
//        }
//
//        let maxDelay = departureDate.addingTimeInterval(2 * 3600)
//        if referenceDate > maxDelay {
//            departureDate = calendar.date(byAdding: .day, value: 1, to: departureDate)!
//        }
//
//        let diff = calendar.dateComponents([.hour, .minute], from: referenceDate, to: departureDate)
//        let hours = diff.hour ?? 0
//        let minutes = diff.minute ?? 0
//
//        return "\(hours)시간 \(minutes)분"
//    }

    func performCheckOut() {
        hasCheckedInToday = false
        todayCheckInTime = nil
        
        // 오늘 날짜의 스트릭을 미완료로 변경
        if let todayIndex = weekDays.firstIndex(where: { $0.isToday }) {
            weekDays[todayIndex] = StreakDay(date: weekDays[todayIndex].date, isCompleted: false)
        }
    }
}
