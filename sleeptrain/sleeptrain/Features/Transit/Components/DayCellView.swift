//
//  DayCellView.swift
//  sleeptrain
//
//  Created by Dean_SSONG on 9/24/25.
//

import SwiftUI
import SwiftData

// MARK: - 개별 요일 셀 뷰 (실데이터 기반)

/// 연속 체크인 주간 뷰에서 개별 날짜 셀을 표시
/// DailyCheckIn + UserSettings를 조회하여 상태 아이콘을 표시
struct DayCellView: View {
    let day: StreakDay
    
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    
    var body: some View {
        VStack(spacing: 4) {
            if day.date != Date.distantPast {
                Text("\(Calendar.current.component(.day, from: day.date))")
                    .font(.system(size: 14))
                    .fontWeight(day.isToday ? .semibold : .regular)
                    .foregroundColor(.white)
            } else {
                Text(" ")
                    .font(.system(size: 14))
            }
            
            if day.date != Date.distantPast {
                iconView(for: status)
            } else {
                Spacer()
                    .frame(width: 35, height: 35)
            }
        }
    }
    
    // MARK: - 상태 계산(실데이터)
    private var status: CheckInStatus {
        let daily = fetchCheckIn(for: day.date)
        if let settings = userSettings.first {
            return day.getCheckInStatus(daily: daily, userSettings: settings)
        } else {
            let template = Calendar.current.date(bySettingHour: 23, minute: 30, second: 0, of: Date()) ?? Date()
            return day.getCheckInStatus(daily: daily, departureTemplate: template)
        }
    }
    
    private func fetchCheckIn(for date: Date) -> DailyCheckIn? {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        let predicate = #Predicate<DailyCheckIn> { $0.date >= start && $0.date < end }
        let desc = FetchDescriptor<DailyCheckIn>(predicate: predicate)
        return (try? modelContext.fetch(desc))?.first
    }
    
    // MARK: - 아이콘 뷰
    @ViewBuilder
    private func iconView(for status: CheckInStatus) -> some View {
        switch status {
        case .completed:
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 35, height: 35)
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
            }
        case .lateCompleted:
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: 35, height: 35)
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
            }
        case .failed:
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: 35, height: 35)
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
            }
        case .available:
            ZStack {
                Circle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: 35, height: 35)
                Circle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 33, height: 33)
            }
        case .notReached, .future:
            Circle()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 35, height: 35)
        case .noRecord:
            Circle()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 35, height: 35)
        }
    }
}
