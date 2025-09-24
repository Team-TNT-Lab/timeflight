//
//  DayCellView.swift
//  sleeptrain
//
//  Created by Dean_SSONG on 9/24/25.
//

import SwiftUI

// MARK: - 개별 요일 셀 뷰 (분리 가능)

/// 연속 체크인 주간 뷰에서 개별 날짜 셀을 표시
/// 날짜 숫자와 체크인 상태 아이콘을 보여줌
/// NOTE: 상태 계산은 전역 파서 함수(parseRemainingTimeToMinutes/parseDepartureTime)에 의존
struct DayCellView: View {
    let day: StreakDay
    let currentRemainingTime: String
    let hasCheckedInToday: Bool
    let todayCheckInTime: Date?
    let departureTimeString: String
    
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
    
    private var status: CheckInStatus {
        day.getCheckInStatus(
            currentRemainingTime: currentRemainingTime,
            hasCheckedInToday: hasCheckedInToday,
            todayCheckInTime: todayCheckInTime,
            departureTimeString: departureTimeString,
            parseRemainingTime: parseRemainingTimeToMinutes,
            parseDepartureTime: parseDepartureTime
        )
    }
    
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
        }
    }
}

