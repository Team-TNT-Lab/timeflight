//
//  StreakWeekView.swift
//  sleeptrain
//
//  Created by Dean_SSONG on 9/24/25.
//

import SwiftUI

struct StreakWeekView: View {
    let days: [StreakDay]
    let currentRemainingTime: String
    let hasCheckedInToday: Bool
    let todayCheckInTime: Date?
    let departureTimeString: String

    @State private var currentWeekOffset = 0
    
    // 오늘 요일 인덱스 (월=0 ... 일=6) - 헤더 강조는 현재 페이지와 무관하게 유지
    private var todayWeekdayHeaderIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }
    
    var body: some View {
        VStack(spacing: 5) {
            // 요일 헤더: 오늘 요일에 회색 원 강조 (페이징과 무관하게 항상 같은 요일에 표시)
            HStack(spacing: 0) {
                let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, weekday in
                    let isToday = index == todayWeekdayHeaderIndex
                    ZStack {
                        if isToday {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 22, height: 22)
                        }
                        Text(weekday)
                            .font(.system(size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(isToday ? .white : .white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                }
            }
            
            // 스크롤 가능한 날짜와 상태 (주 단위 페이징)
            TabView(selection: $currentWeekOffset) {
                ForEach(Array(visibleWeekGroups.enumerated()), id: \.offset) { weekIndex, week in
                    HStack(spacing: 0) {
                        ForEach(week) { day in
                            DayCellView(
                                day: day,
                                currentRemainingTime: currentRemainingTime,
                                hasCheckedInToday: hasCheckedInToday,
                                todayCheckInTime: todayCheckInTime,
                                departureTimeString: departureTimeString
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .tag(weekIndex)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 80)
            .onAppear {
                currentWeekOffset = todayWeekIndex
            }
        }
    }
    
    private var todayWeekIndex: Int {
        visibleWeekGroups.firstIndex { week in
            week.contains { $0.isToday }
        } ?? 0
    }
    
    private var weekGroups: [[StreakDay]] {
        stride(from: 0, to: days.count, by: 7).map { startIndex in
            let endIndex = min(startIndex + 7, days.count)
            var week = Array(days[startIndex..<endIndex])
            
            while week.count < 7 {
                week.append(StreakDay(date: Date.distantPast, isCompleted: false))
            }
            return week
        }
    }
    
    // 미래 주를 제외한 실제 표시용 주 배열
    private var visibleWeekGroups: [[StreakDay]] {
        weekGroups.filter { !isFutureWeek($0) }
    }

    private func calculateProgress(for week: [StreakDay]) -> (progress: CGFloat, todayIndex: Int) {
        let realDays = week.filter { $0.date != Date.distantPast }
        guard !realDays.isEmpty else { return (0, 0) }
        
        if let todayIndex = week.firstIndex(where: { $0.isToday }) {
            let progress = (CGFloat(todayIndex) + 0.5) / 7.0
            return (progress, todayIndex)
        } else {
            if let lastCompletedIndex = week.lastIndex(where: { $0.isCompleted && $0.date != Date.distantPast }) {
                let progress = (CGFloat(lastCompletedIndex) + 0.5) / 7.0
                return (progress, lastCompletedIndex)
            } else {
                return (0, 0)
            }
        }
    }
    
    // 해당 주가 "미래 주(오늘 이후만 존재)"인지 판별
    private func isFutureWeek(_ week: [StreakDay]) -> Bool {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let realDays = week.filter { $0.date != Date.distantPast }
        guard !realDays.isEmpty else { return false }
        
        // 오늘을 포함하면 미래 주가 아님
        if realDays.contains(where: { calendar.isDateInToday($0.date) }) {
            return false
        }
        
        // 주 내 가장 이른 날짜가 오늘 이후면 "미래 주"
        let earliest = realDays.map { calendar.startOfDay(for: $0.date) }.min()!
        return earliest > todayStart
    }
}
