//
//  FlightTimeManager.swift
//  timeflight
//
//  Created by bishoe01 on 9/19/25.
//

import Foundation
import SwiftUI

class FlightTimeManager: ObservableObject {
    @Published var timeRange: TimeRange
    @Published var isValidTimeRange: Bool = true
    @Published var errorMessage: String?

    init() {
        let now = Date()
        let defaultEnd = Calendar.current.date(byAdding: .hour, value: 2, to: now) ?? now

        self.timeRange = TimeRange(start: now, end: defaultEnd)
        validateTimeRange()
    }

    func updateStartTime(_ newTime: Date) {
        timeRange.start = newTime

        // end>start일때 +1시간
        if timeRange.end <= newTime {
            timeRange.end = Calendar.current.date(byAdding: .hour, value: 1, to: newTime) ?? newTime
        }

        validateTimeRange()
    }

    func updateEndTime(_ newTime: Date) {
        // 최소한 30분간격제공
        let minimumEnd = Calendar.current.date(byAdding: .minute, value: 30, to: timeRange.start) ?? timeRange.start
        timeRange.end = max(newTime, minimumEnd)

        validateTimeRange()
    }

    private func validateTimeRange() {
        isValidTimeRange = timeRange.isValid

        if !isValidTimeRange {
            errorMessage = TimeRangeError.endBeforeStart.localizedDescription
        } else {
            errorMessage = nil
        }
    }

    func getFlightDuration() -> String {
        return timeRange.durationText
    }

    func isInFlightTime() -> Bool {
        let now = Date()
        return now >= timeRange.start && now <= timeRange.end
    }
}
