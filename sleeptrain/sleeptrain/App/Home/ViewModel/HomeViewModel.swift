import Foundation
import SwiftUI
import SwiftData

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

    // MARK: - DailyCheckIn 기반 헬퍼
    
    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
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
        let record = DailyCheckIn(date: startOfDay(date), status: .none, checkedInAt: nil)
        context.insert(record)
        return record
    }
    
    private func computeCurrentStreak(context: ModelContext) -> Int {
        // 오늘부터 과거로 연속 성공(completed/lateCompleted)만 카운트
        let cal = Calendar.current
        var cursor = startOfDay(Date())
        var streak = 0
        
        while true {
            if let rec = fetchCheckIn(for: cursor, context: context) {
                switch rec.status {
                case DailyStatus.completed, DailyStatus.lateCompleted:
                    streak += 1
                    guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { return streak }
                    cursor = startOfDay(prev)
                case DailyStatus.failed, DailyStatus.none:
                    return streak
                }
            } else {
                // 기록 없음은 실패로 간주(연속 끊김)
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

    // 2시간 이상 지연 시 실패 처리(오늘 failed로 마킹) + sleepCount 0 반영
    func checkAndHandleFailedState(
        remainingTimeText: String,
        startTimeText: String,
        context: ModelContext,
        updateSleepCount: (Int) -> Void
    ) {
        // remainingTimeText 파싱 대신 실제 시각 비교로 2시간 초과를 판정
        let departureTime = parseDepartureTime(startTimeText) // 오늘 날짜의 출발시각
        let now = Date()
        let diff = now.timeIntervalSince(departureTime) // 초
        
        // 이미 체크인 성공 상태면 아무 것도 하지 않음
        if let today = fetchCheckIn(for: now, context: context),
           today.status == DailyStatus.completed || today.status == DailyStatus.lateCompleted {
            return
        }
        
        // 2시간(120분) 이상 지연이면 실패로 마킹
        if diff > 120 * 60 {
            let rec = upsertCheckIn(for: now, context: context)
            if rec.status != DailyStatus.failed {
                rec.status = DailyStatus.failed
                rec.checkedInAt = nil
                try? context.save()
            }
            saveStreakToStats(0, context: context)
            updateSleepCount(0)
        }
    }

    // 체크인 수행(텍스트 기반): DailyCheckIn 저장 + streak 계산/반영
    func performCheckIn(
        remainingTimeText: String,
        startTimeText: String,
        context: ModelContext,
        updateSleepCount: (Int) -> Void
    ) {
        guard canCheckIn(
            remainingTimeText: remainingTimeText,
            hasCheckedInToday: hasCheckedInToday
        ) else { return }
        
        hasCheckedInToday = true
        let checkInTime = calculateCheckInTimeForCurrentScenario(
            remainingTimeText: remainingTimeText,
            startTimeText: startTimeText
        )
        todayCheckInTime = checkInTime
        
        // 상태 판정
        let departureTime = parseDepartureTime(startTimeText)
        let delta = checkInTime.timeIntervalSince(departureTime)
        let status: DailyStatus
        if delta >= -30 * 60 && delta <= 30 * 60 {
            status = DailyStatus.completed
        } else if delta > 30 * 60 && delta <= 120 * 60 {
            status = DailyStatus.lateCompleted
        } else {
            status = DailyStatus.failed
        }
        
        // 오늘 기록 upsert
        let rec = upsertCheckIn(for: checkInTime, context: context)
        rec.status = status
        rec.checkedInAt = checkInTime
        try? context.save()
        
        // streak 계산/반영
        let newStreak = computeCurrentStreak(context: context)
        saveStreakToStats(newStreak, context: context)
        updateSleepCount(newStreak)
        
        // UI용 today 상태 반영(주간 뷰 유지 중인 경우)
        if let todayIndex = weekDays.firstIndex(where: { $0.isToday }) {
            weekDays[todayIndex] = StreakDay(date: weekDays[todayIndex].date, isCompleted: true)
        }
    }
    
    // NFC 태그 시각 기반 체크인 수행
    func performCheckIn(
        taggedAt: Date,
        remainingTimeText: String,
        startTimeText: String,
        context: ModelContext,
        updateSleepCount: (Int) -> Void
    ) {
        guard !hasCheckedInToday else { return }
        
        let departureTime = parseDepartureTime(startTimeText)
        let diff = taggedAt.timeIntervalSince(departureTime) // 초 단위
        
        // 허용 범위: 출발 30분 전 ~ 출발 120분 후 (2시간 이상 지연 방지)
        let lowerBound: TimeInterval = -30 * 60
        let upperBound: TimeInterval = 120 * 60
        guard diff >= lowerBound && diff <= upperBound else {
            // 허용 시간대가 아니면 체크인하지 않음
            return
        }
        
        hasCheckedInToday = true
        todayCheckInTime = taggedAt
        
        // 상태 판정
        let status: DailyStatus
        if diff >= -30 * 60 && diff <= 30 * 60 {
            status = DailyStatus.completed
        } else if diff > 30 * 60 && diff <= 120 * 60 {
            status = DailyStatus.lateCompleted
        } else {
            status = DailyStatus.failed
        }
        
        // 오늘 기록 upsert
        let rec = upsertCheckIn(for: taggedAt, context: context)
        rec.status = status
        rec.checkedInAt = taggedAt
        try? context.save()
        
        // streak 계산/반영
        let newStreak = computeCurrentStreak(context: context)
        saveStreakToStats(newStreak, context: context)
        updateSleepCount(newStreak)
        
        if let todayIndex = weekDays.firstIndex(where: { $0.isToday }) {
            weekDays[todayIndex] = StreakDay(date: weekDays[todayIndex].date, isCompleted: true)
        }
    }

    // MARK: - (기존) Mock/도우미 로직: 주간 뷰 유지용
    
    // 오늘 상태에 따라 수면 스트릭 카운트를 계산해 반환(변경 없으면 nil)
    // NOTE: DailyCheckIn 기반으로 전환 후에는 사용하지 않아도 됩니다.
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

    /// (Mock) 연속 체크인 성공 일수 계산
    /// NOTE: 실제 streak은 DailyCheckIn 기반 computeCurrentStreak를 사용하세요.
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
    
    // 단순 시간 계산 유틸들(기존 유지)
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
    
    // (Deprecated in UI) Mock 동기화 메서드 - DailyCheckIn 기반으로 대체됨
    func syncCurrentStreak(
        remainingTimeText: String,
        startTimeText: String
    ) -> Int {
        guard let remainingMinutes = parseRemainingTimeToMinutes(remainingTimeText) else {
            return calculateCurrentStreak(remainingTimeText: remainingTimeText, startTimeText: startTimeText)
        }
        if remainingMinutes <= -120 {
            return 0
        }
        return calculateCurrentStreak(
            remainingTimeText: remainingTimeText,
            startTimeText: startTimeText
        )
    }
    
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
}
