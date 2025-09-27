//
//  TransitViewModel.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/27/25.
//

import Foundation
import SwiftData
import SwiftUI

final class TransitViewModel: ObservableObject {
    @Published var weekDays: [StreakDay] = []
    @Published var hasCheckedInToday = false
    @Published var todayCheckInTime: Date?
    @Published var trainState: TrainState = .missed

    private let checkInService = CheckInService()
    private let dateService = DateService()

    init() {
        // 초기화 시 기본 날짜만 생성
        refreshDisplayDays()
    }

    func performCheckIn(with data: CheckInData) {
        let result = checkInService.performCheckIn(
            at: Date(),
            startTimeText: data.startTimeText,
            context: data.context
        )

        if result.success {
            hasCheckedInToday = true
            todayCheckInTime = Date()
            data.updateSleepCount(result.streak)

            // 주간 뷰 업데이트
            refreshDisplayDays(context: data.context)
        }
    }

    func wakeUp(context: ModelContext) {
        let success = checkInService.wakeUp(at: Date(), context: context)
        
        if success {
            hasCheckedInToday = false
            todayCheckInTime = nil
            
            // 주간 뷰 업데이트
            if let todayIndex = weekDays.firstIndex(where: { dateService.isToday($0.date) }) {
                weekDays[todayIndex] = StreakDay(date: weekDays[todayIndex].date, isCompleted: true)
            }
        }
    }
    
    func performCheckOut(context: ModelContext) {
        let success = checkInService.performManualCheckOut(at: Date(), context: context)
        
        if success {
            hasCheckedInToday = false
            todayCheckInTime = nil
            
            // 주간 뷰 업데이트
            if let todayIndex = weekDays.firstIndex(where: { dateService.isToday($0.date) }) {
                weekDays[todayIndex] = StreakDay(date: weekDays[todayIndex].date, isCompleted: false)
            }
        }
    }

    func updateTrainState(remainingTimeText: String, isTrainDeparted: Bool) {
        trainState = TrainState.from(
            remainingTimeText: remainingTimeText,
            isTrainDeparted: isTrainDeparted
        )
    }

    // 오늘 체크인 상태
    func refreshTodayCheckInState(context: ModelContext) {
        let status = checkInService.getTodayCheckInStatus(context: context)
        hasCheckedInToday = status.hasCheckedIn
        todayCheckInTime = status.checkedAt
    }

    // 스트릭 가져오기
    func getCurrentStreak(context: ModelContext) -> Int {
        return checkInService.getCurrentStreak(context: context)
    }

    // 날짜새로고침
    func refreshDisplayDays(context: ModelContext? = nil) {
        var baseDays = dateService.generateDisplayDays()

        // 실제 체크인 상태 반영
        if let context = context {
            baseDays = baseDays.map { day in
                let checkInStatus = checkInService.getCheckInStatusForDay(day.date, context: context)
                return StreakDay(date: day.date, isCompleted: checkInStatus.isCompleted)
            }
        }

        weekDays = baseDays
    }

    // 전체 새로고침
    func refreshAll(context: ModelContext, updateSleepCount: (Int) -> Void) {
        refreshTodayCheckInState(context: context)
        let currentStreak = getCurrentStreak(context: context)
        updateSleepCount(currentStreak)
        refreshDisplayDays(context: context)
    }
}
