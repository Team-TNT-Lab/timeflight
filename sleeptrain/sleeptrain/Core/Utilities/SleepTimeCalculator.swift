//
//  SleepTimeCalculator.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/23/25.
//

import Foundation

enum SleepTimeCalculator {
    static func calculateSleepDuration(bedTime: Date, wakeTime: Date) -> String {
        let calendar = Calendar.current

        // 자정을 넘겼을때
        let bedTimeComponents = calendar.dateComponents([.hour, .minute], from: bedTime)
        let wakeTimeComponents = calendar.dateComponents([.hour, .minute], from: wakeTime)

        let bedHour = bedTimeComponents.hour ?? 0
        let bedMinute = bedTimeComponents.minute ?? 0
        let wakeHour = wakeTimeComponents.hour ?? 0
        let wakeMinute = wakeTimeComponents.minute ?? 0

        let bedTotalMinutes = bedHour * 60 + bedMinute
        let wakeTotalMinutes = wakeHour * 60 + wakeMinute

        let sleepMinutes = wakeTotalMinutes >= bedTotalMinutes ?
            wakeTotalMinutes - bedTotalMinutes :
            (24 * 60) - bedTotalMinutes + wakeTotalMinutes

        let hours = sleepMinutes / 60
        let minutes = sleepMinutes % 60
        return minutes > 0 ?
            "\(hours)시간 \(minutes)분 자게 돼요" :
            "\(hours)시간 자게 돼요"
    }
}
