import Foundation
import SwiftUI

class TrainTicketViewModel: ObservableObject {
    enum Mode {
        case mock
        case real
    }
    
    // MARK: - Published 프로퍼티
    @Published var isSleepModeActive = false
    @Published var sleepCount = 0
    @Published var startTimeText = "23:30"
    @Published var endTimeText = "07:30"
    @Published var startDayText = "MON"
    @Published var endDayText = "TUE"
    @Published var progress: Double = 0.0
    @Published var remainingTimeText = "1시간"
    @Published var hasCheckedInToday: Bool = false
    @Published var arrivalRemainingTimeText: String = "3시간 45분"
    
    @Published private(set) var mode: Mode = .mock
    
    // MARK: - 상태 계산
    // 실제 스케줄(오늘 기준으로 구성된 Date)
    private var realDepartureDate: Date?
    private var realArrivalDate: Date?
    
    // 도착 시간을 Date 객체로 반환하는 계산 속성 (문자열 기반 기본 구현 유지)
    var targetArrivalTime: Date {
        DateFormatting.dateFromTimeString(endTimeText) ?? Date()
    }
    
    var isTrainDeparted: Bool {
        guard let dep = realDepartureDate else { return false }
        return Date() >= dep
    }
    
    // MARK: - 내부 계산 / 업데이트 메서드
    func calculateTrainPosition() -> CGFloat {
        guard let dep = realDepartureDate, let arr = realArrivalDate else { return 0 }
        let now = Date()
        
        if now < dep {
            return 0
        } else if now >= arr {
            return 200
        } else {
            // 출발 후 ~ 도착 전: 진행률에 따라 위치 계산
            let totalDuration = arr.timeIntervalSince(dep)
            guard totalDuration > 0 else { return 0 }
            let elapsed = now.timeIntervalSince(dep)
            let progress = elapsed / totalDuration
            return CGFloat(progress * 200)
        }
    }
    
    func setSleepCount(_ count: Int) {
        sleepCount = max(0, count)
    }
    
    func toggleSleepMode() {
        // 실제 카운트는 Stats 등 실제 데이터로 관리하므로 여기서 증가시키지 않습니다.
        isSleepModeActive.toggle()
    }
    
    private func updateRemainingTimeText(now: Date, dep: Date, arr: Date) {
        if now < dep {
            remainingTimeText = Self.remainingTimeString(until: dep)
        } else if now >= dep && now < arr {
            remainingTimeText = Self.delayString(since: dep)
        } else {
            remainingTimeText = "운행 종료"
        }
    }
    
    func updateTime() {
        switch mode {
        case .mock:
            break
        case .real:
            guard let dep = realDepartureDate, let arr = realArrivalDate else { return }
            let now = Date()
            let twoHoursAfterDeparture = dep.addingTimeInterval(2 * 60 * 60)

            if hasCheckedInToday {
                // 체크인한 경우: 현재부터 도착까지
                arrivalRemainingTimeText = Self.remainingTimeString(until: arr)
            }
            updateRemainingTimeText(now: now, dep: dep, arr: arr)

            if now >= twoHoursAfterDeparture {
                let calendar = Calendar.current
                let nextDep = calendar.date(byAdding: .day, value: 1, to: dep)!
                let nextArr = calendar.date(byAdding: .day, value: 1, to: arr)!

                realDepartureDate = nextDep
                realArrivalDate = nextArr

                startTimeText = DateFormatting.hourMinuteString(from: nextDep)
                endTimeText = DateFormatting.hourMinuteString(from: nextArr)
                startDayText = Self.dayAbbrev(for: nextDep)
                endDayText = Self.dayAbbrev(for: nextArr)

                remainingTimeText = Self.remainingTimeString(until: nextDep)
            }
        }
    }
    
    // MARK: - 초기화 / 설정 메서드
    // MARK: - 실제 스케줄 적용
    func setRealSchedule(departureTemplate: Date, arrivalTemplate: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        let depHour = calendar.component(.hour, from: departureTemplate)
        let depMinute = calendar.component(.minute, from: departureTemplate)
        let arrHour = calendar.component(.hour, from: arrivalTemplate)
        let arrMinute = calendar.component(.minute, from: arrivalTemplate)
        
        // 오늘 날짜 기준으로 설정된 시각으로 구성
        let depToday = calendar.date(bySettingHour: depHour, minute: depMinute, second: 0, of: now) ?? now
        var arrToday = calendar.date(bySettingHour: arrHour, minute: arrMinute, second: 0, of: now) ?? now
        
        // 도착 시간이 출발 시간보다 이르면 다음 날 도착으로 간주
        if arrToday <= depToday {
            arrToday = calendar.date(byAdding: .day, value: 1, to: arrToday) ?? arrToday
        }
        
        realDepartureDate = depToday
        realArrivalDate = arrToday
        mode = .real
        
        // 텍스트 업데이트
        startTimeText = DateFormatting.hourMinuteString(from: depToday)
        endTimeText = DateFormatting.hourMinuteString(from: arrToday)
        startDayText = Self.dayAbbrev(for: depToday)
        endDayText = Self.dayAbbrev(for: arrToday)
        
        updateRemainingTimeText(now: now, dep: depToday, arr: arrToday)
    }
    
    // MARK: - 외부 static 유틸 메서드
    static func dayAbbrev(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    // 양수(출발 전) 남은 시간 문자열
    static func remainingTimeString(until target: Date) -> String {
        let now = Date()
        let interval = max(0, Int(target.timeIntervalSince(now)))
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)시간 \(minutes)분"
        } else if hours > 0 {
            return "\(hours)시간"
        } else {
            return "\(minutes)분"
        }
    }
    
    // 음수(출발 후) 지연 시간 문자열
    static func delayString(since departure: Date) -> String {
        let now = Date()
        let delay = max(0, Int(now.timeIntervalSince(departure)))
        let hours = delay / 3600
        let minutes = (delay % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "지연 \(hours)시간 \(minutes)분"
        } else if hours > 0 {
            return "지연 \(hours)시간"
        } else {
            return "지연 \(minutes)분"
        }
    }
}
