//
//  TimeModels.swift
//  timeflight
//
//  Created by bishoe01 on 9/19/25.
//

import Foundation

struct TimeRange {
    var start: Date
    var end: Date

    var isValid: Bool {
        end > start
    }

    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }

    var durationText: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return "\(hours)시간 \(minutes)분"
    }

    mutating func adjustEndTime() {
        if end <= start {
            end = Calendar.current.date(byAdding: .hour, value: 1, to: start) ?? start
        }
    }
}


