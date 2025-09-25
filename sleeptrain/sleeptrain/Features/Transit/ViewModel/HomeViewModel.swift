import Foundation
import SwiftUI
import SwiftData

final class HomeViewModel: ObservableObject {
    @Published var weekDays: [StreakDay] = HomeViewModel.generateDisplayDays()
    @Published var hasCheckedInToday: Bool = false
    @Published var todayCheckInTime: Date?

    // 표시용 날짜 갱신(필요 시 호출)
    func refreshDisplayDays() {
        weekDays = Self.generateDisplayDays()
    }

    // 오늘 DailyCheckIn을 조회해 UI 플래그 동기화
    func refreshTodayCheckInState(context: ModelContext) {
        let now = Date()
        if let rec = fetchCheckIn(for: now, context: context), let ts = rec.checkedInAt {
            hasCheckedInToday = true
            todayCheckInTime = ts
        } else {
            hasCheckedInToday = false
            todayCheckInTime = nil
        }
    }
//      테스트용으로 사용(탭하면 체크인 초기화)
//    // 시나리오(남은 시간/출발 시간) 변경 시 체크인 상태 초기화 (UI 상태만)
//    func resetForScenarioChange() {
//        hasCheckedInToday = false
//        todayCheckInTime = nil
//    }
//    
//    // 데모용: 카드 탭 시 오늘 체크인 초기화 (UI 상태만)
//    func resetTodayCheckIn() {
//        hasCheckedInToday = false
//        todayCheckInTime = nil
//    }

    // MARK: - 표시용 날짜 생성(실데이터용, 모크 미사용)
    static func generateDisplayDays(calendar: Calendar = .current) -> [StreakDay] {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        // 과거/미래 범위
        let pastDays = 21
        let futureDays = 14
        
        // 표시 범위의 시작/끝
        let rangeStart = calendar.date(byAdding: .day, value: -pastDays, to: startOfToday) ?? startOfToday
        let rangeEnd = calendar.date(byAdding: .day, value: futureDays, to: startOfToday) ?? startOfToday
        
        // 월요일 시작 정렬
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
                return streak
            }
        }
    }
    
    // 외부에서 호출 가능한 streak 계산 래퍼
    func getCurrentStreak(context: ModelContext) -> Int {
        computeCurrentStreak(context: context)
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
        let departureTime = parseDepartureTime(startTimeText)
        let now = Date()
        let diff = now.timeIntervalSince(departureTime)
        

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

            refreshTodayCheckInState(context: context)
            saveStreakToStats(0, context: context)
            updateSleepCount(0)
        }
    }

    // 체크인 수행(문자열 기반 호출의 호환 래퍼) - 실제 시각 기반으로 위임
    func performCheckIn(
        remainingTimeText: String,
        startTimeText: String,
        context: ModelContext,
        updateSleepCount: (Int) -> Void
    ) {
        performCheckIn(
            taggedAt: Date(),
            remainingTimeText: remainingTimeText,
            startTimeText: startTimeText,
            context: context,
            updateSleepCount: updateSleepCount
        )
    }
    
    // NFC 태그 시각 기반 체크인 수행(실제 경로)
    func performCheckIn(
        taggedAt: Date,
        remainingTimeText: String,
        startTimeText: String,
        context: ModelContext,
        updateSleepCount: (Int) -> Void
    ) {
        if let today = fetchCheckIn(for: taggedAt, context: context),
           today.checkedInAt != nil {
            hasCheckedInToday = true
            todayCheckInTime = today.checkedInAt
            return
        }
        
        let departureTime = parseDepartureTime(startTimeText)
        let diff = taggedAt.timeIntervalSince(departureTime) // 초 단위
        
        // 허용 범위: 출발 30분 전 ~ 출발 120분 후 (2시간 이상 지연 방지)
        let lowerBound: TimeInterval = -30 * 60
        let upperBound: TimeInterval = 120 * 60
        guard diff >= lowerBound && diff <= upperBound else {
            return
        }
        
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
        
        // UI 플래그/시간 동기화
        refreshTodayCheckInState(context: context)
        
        // streak 계산/반영
        let newStreak = computeCurrentStreak(context: context)
        saveStreakToStats(newStreak, context: context)
        updateSleepCount(newStreak)
        
        // UI용 today 상태 반영(주간 뷰 유지 중인 경우)
        if let todayIndex = weekDays.firstIndex(where: { $0.isToday }) {
            weekDays[todayIndex] = StreakDay(date: weekDays[todayIndex].date, isCompleted: true)
        }
    }

    // MARK: - 비상 정지: 오늘을 실패 처리하고 상태/통계 동기화
    func emergencyStopToday(
        context: ModelContext,
        updateSleepCount: (Int) -> Void
    ) {
        let now = Date()
        // 오늘 기록 upsert 후 실패로 마킹
        let rec = upsertCheckIn(for: now, context: context)
        rec.status = .failed
        rec.checkedInAt = nil
        try? context.save()
        
        // UI 플래그/시간 동기화(체크인 해제 → streakSection 노출)
        refreshTodayCheckInState(context: context)
        
        // streak 재계산 및 저장(실패 → 0)
        let newStreak = computeCurrentStreak(context: context)
        saveStreakToStats(newStreak, context: context)
        updateSleepCount(newStreak)
        
        // 표시용 weekDays의 오늘 셀은 미완료로 업데이트(실제 아이콘은 SwiftData 기반으로 failed 표시)
        if let todayIndex = weekDays.firstIndex(where: { $0.isToday }) {
            weekDays[todayIndex] = StreakDay(date: weekDays[todayIndex].date, isCompleted: false)
        }
    }

    // MARK: - 백필: 첫 기록 이후의 누락일을 failed로 채워 넣기
    // - 첫 설치(기록 0개)인 경우 아무 것도 하지 않음 → 비어있는 상태 유지
    // - 첫 기록이 생긴 이후부터 오늘 이전까지, 존재하지 않는 날짜는 failed로 저장
    func backfillMissedDays(context: ModelContext) {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        
        // 날짜 오름차순으로 모든 기록 조회
        let desc = FetchDescriptor<DailyCheckIn>(sortBy: [SortDescriptor(\.date, order: .forward)])
        guard let records = try? context.fetch(desc), !records.isEmpty else {
            return
        }
        
        // 존재하는 날짜 집합
        let existing = Set(records.map { cal.startOfDay(for: $0.date) })
        // 백필 시작일: 첫 기록의 날짜
        guard let firstDate = records.first.map({ cal.startOfDay(for: $0.date) }) else { return }
        
        var cursor = firstDate
        var inserted = 0
        
        while cursor < todayStart {
            if !existing.contains(cursor) {
                let missing = DailyCheckIn(date: cursor, status: .failed, checkedInAt: nil)
                context.insert(missing)
                inserted += 1
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = cal.startOfDay(for: next)
        }
        
        if inserted > 0 {
            try? context.save()
        }
    }

//    // MARK: - (기존) Mock/도우미 로직: 주간 뷰 유지용
//    // 아래 함수들은 더 이상 호출하지 않도록 HomeView/RecordView를 수정했습니다.
//    // 필요 시 나중에 제거하세요.
//    
//    func updateSleepCountBasedOnStreak(
//        remainingTimeText: String,
//        startTimeText: String
//    ) -> Int? { nil }
//
//    func calculateCurrentStreak(
//        remainingTimeText: String,
//        startTimeText: String
//    ) -> Int { 0 }
//
//    func syncCurrentStreak(
//        remainingTimeText: String,
//        startTimeText: String
//    ) -> Int { 0 }
}
