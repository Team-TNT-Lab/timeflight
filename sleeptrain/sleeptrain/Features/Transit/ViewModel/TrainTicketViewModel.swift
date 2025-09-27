//
//  TrainTicketViewModel.swift
//  sleeptrain
//
//  Created by whatdolsa on 9/27/25.
//

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
    @Published var progress: Double = 0.0
    @Published var remainingTimeText = "1시간"
    @Published var hasCheckedInToday: Bool = false
    @Published var arrivalRemainingTimeText: String = "3시간 45분"
    
    @Published private(set) var mode: Mode = .mock
    
    private var realDepartureDate: Date?
    private var realArrivalDate: Date?
    
    var startTimeText: String {
        guard let realDepartureDate else { return "--:--" }
        return DateFormatting.hourMinuteString(from: realDepartureDate)
    }

    var endTimeText: String {
        guard let realArrivalDate else { return "--:--" }
        return DateFormatting.hourMinuteString(from: realArrivalDate)
    }

    var startDayText: String {
        guard let realDepartureDate else { return "---" }
        return DateFormatting.dayAbbrev(for: realDepartureDate)
    }

    var endDayText: String {
        guard let realArrivalDate else { return "---" }
        return DateFormatting.dayAbbrev(for: realArrivalDate)
    }
    
    var targetArrivalTime: Date {
        guard let realArrivalDate else { return Date() }
        return realArrivalDate
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
            remainingTimeText = DateFormatting.remainingTimeString(until: dep)
        } else if now >= dep, now < arr {
            remainingTimeText = DateFormatting.delayString(since: dep)
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
                arrivalRemainingTimeText = DateFormatting.remainingTimeString(until: arr)
            }
            updateRemainingTimeText(now: now, dep: dep, arr: arr)
                
            if now >= twoHoursAfterDeparture {
                let calendar = Calendar.current
                let nextDep = calendar.date(byAdding: .day, value: 1, to: dep)!
                let nextArr = calendar.date(byAdding: .day, value: 1, to: arr)!
                
                realDepartureDate = nextDep
                realArrivalDate = nextArr
                
                remainingTimeText = DateFormatting.remainingTimeString(until: nextDep)
            }
        }
    }
                
    // MARK: - 초기화 / 설정 메서드
                
    func configure(with settings: UserSettings) {
        setRealSchedule(departureTemplate: settings.targetDepartureTime, arrivalTemplate: settings.targetArrivalTime)
    }
                    
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
                    
        updateRemainingTimeText(now: now, dep: depToday, arr: arrToday)
    }
}
