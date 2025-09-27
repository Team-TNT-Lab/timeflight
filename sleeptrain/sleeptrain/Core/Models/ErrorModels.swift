//
//  ErrorModels.swift
//  timeflight
//
//  Created by bishoe01 on 9/18/25.
//
import SwiftUI

enum AuthError: Error {
    case requestFailed
}

enum NfcError: Error {
    case deviceNotSupported
    case scanFailed
    case invalidMessage
}

enum TimeRangeError: Error {
    case invalidTimeRange
    case endBeforeStart
}

enum SettingsError: LocalizedError {
    case invalidBedTime
    case invalidWakeTime
    case insufficientSleepDuration

    var errorDescription: String? {
        switch self {
        case .invalidBedTime:
            return "자는 시간은 오후 8시부터 새벽 2시 사이에 설정해주세요."
        case .invalidWakeTime:
            return "일어나는 시간은 새벽 3시부터 오후 2시 사이에 설정해주세요."
        case .insufficientSleepDuration:
            return "최소 4시간 이상의 수면 시간이 필요해요."
        }
    }
}
