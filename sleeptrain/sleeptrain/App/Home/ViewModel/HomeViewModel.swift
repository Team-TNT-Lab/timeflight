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
                parseDepartureTime: parseDepartureTime
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
                parseDepartureTime: parseDepartureTime
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
    
    /// 티켓 카드/출발 시각 변경 등으로 스트릭 동기화
    func syncCurrentStreak(
        remainingTimeText: String,
        startTimeText: String
    ) -> Int {
        calculateCurrentStreak(
            remainingTimeText: remainingTimeText,
            startTimeText: startTimeText
        )
    }
}
