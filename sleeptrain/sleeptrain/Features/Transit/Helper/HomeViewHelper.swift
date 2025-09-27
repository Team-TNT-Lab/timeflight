import Foundation
import SwiftUI

// MARK: - 시간 파싱 및 계산


internal func parseDepartureTime(_ timeString: String) -> Date {
    let calendar = Calendar.current
    let today = Date()
    
    if let date = DateFormatting.dateFromTimeString(timeString) {
        return date
    }
    
    let fmts = ["h:mma", "h:mm a"]
    for f in fmts {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = f
        if let parsed = formatter.date(from: timeString) {
            let comps = calendar.dateComponents([.hour, .minute], from: parsed)
            return calendar.date(bySettingHour: comps.hour ?? 23,
                                 minute: comps.minute ?? 30,
                                 second: 0,
                                 of: today) ?? today
        }
    }
    
    return calendar.date(bySettingHour: 23, minute: 30, second: 0, of: today) ?? today
}

/// 현재 시간부터 기상 시간까지 남은 시간 문자열 계산
internal func calculateRemainingTimeToWakeUp(endTimeText: String) -> String {
    let now = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    
    guard let wakeUpTimeToday = formatter.date(from: endTimeText) else {
        return "계산 중..."
    }
    
    let calendar = Calendar.current
    let currentComponents = calendar.dateComponents([.year, .month, .day], from: now)
    let wakeUpComponents = calendar.dateComponents([.hour, .minute], from: wakeUpTimeToday)
    
    var combinedComponents = DateComponents()
    combinedComponents.year = currentComponents.year
    combinedComponents.month = currentComponents.month
    combinedComponents.day = currentComponents.day
    combinedComponents.hour = wakeUpComponents.hour
    combinedComponents.minute = wakeUpComponents.minute
    
    guard var wakeUpDate = calendar.date(from: combinedComponents) else {
        return "계산 중..."
    }
    
    if wakeUpDate <= now {
        wakeUpDate = calendar.date(byAdding: .day, value: 1, to: wakeUpDate) ?? wakeUpDate
    }
    
    let diff = calendar.dateComponents([.hour, .minute], from: now, to: wakeUpDate)
    let hours = diff.hour ?? 0
    let minutes = diff.minute ?? 0
    
    if hours > 0 && minutes > 0 {
        return "\(hours)시간 \(minutes)분"
    } else if hours > 0 {
        return "\(hours)시간"
    } else if minutes > 0 {
        return "\(minutes)분"
    } else {
        return "곧"
    }
}


// MARK: - 문자열 포맷팅

/// "1시간 30분" 같은 문자열을 분 단위로 변환 (지연이면 음수)
private func parseRemainingTimeToMinutes(_ timeString: String) -> Int? {
    let isDelayed = timeString.contains("지연")

    var totalMinutes = 0
    let components = timeString.components(separatedBy: " ")

    for component in components {
        if component.contains("시간") {
            let hourString = component
                .replacingOccurrences(of: "지연", with: "")
                .replacingOccurrences(of: "시간", with: "")
            if let hours = Int(hourString) {
                totalMinutes += hours * 60
            }
        } else if component.contains("분") {
            let minuteString = component
                .replacingOccurrences(of: "분", with: "")
            if let minutes = Int(minuteString) {
                totalMinutes += minutes
            }
        }
    }

    // 숫자 토큰이 전혀 없을 경우, 문자열에서 숫자만 추출하여 첫 번째 값을 사용(예: "0분")
    if totalMinutes == 0 {
        let numbers = timeString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        if let first = numbers.first {
            totalMinutes = first
        }
    }

    // 여전히 숫자를 찾지 못했고 "0"도 포함하지 않는 경우 해석 불가로 처리
    if totalMinutes == 0 && !timeString.contains("0") {
        return nil
    }

    return isDelayed ? -totalMinutes : totalMinutes
}

/// 분 단위 시간을 "N시간 M분" 형태 문자열로 포맷
private func formatDuration(minutes: Int) -> String {
    let m = max(0, abs(minutes))
    let h = m / 60
    let min = m % 60
    if h > 0 && min > 0 {
        return "\(h)시간 \(min)분"
    } else if h > 0 {
        return "\(h)시간"
    } else {
        return "\(min)분"
    }
}

/// 다음 수면 시간까지 남은 시간(분)
private func minutesUntilNextSleepTime(startTimeText: String) -> Int {
    let now = Date()
    let calendar = Calendar.current

    let todayStart = parseDepartureTime(startTimeText)

    let nextStartTime: Date
    if todayStart > now {
        nextStartTime = todayStart
    } else {
        nextStartTime = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart
    }

    let diff = Int(nextStartTime.timeIntervalSince(now) / 60)
    return max(diff, 0)
}


// MARK: - Check-in 관련 로직

/// 체크인 가능 여부 판단
internal func canCheckIn(remainingTimeText: String, hasCheckedInToday: Bool) -> Bool {
    guard let remainingMinutes = parseRemainingTimeToMinutes(remainingTimeText) else {
        return false
    }
    
    // 지연시간이 2시간(120분)을 넘으면 체크인 불가
    if remainingMinutes <= -120 {
        return false
    }
    
    return (remainingMinutes <= 30 || remainingMinutes < 0) && !hasCheckedInToday
}


// MARK: - UI 텍스트 생성

/// 현재 남은 시간 텍스트로 인포 배너 문구 생성
internal func makeInfoBannerText(remainingTimeText: String, startTimeText: String) -> String {
    guard let remainingMinutes = parseRemainingTimeToMinutes(remainingTimeText) else {
        return "열차 출발 정보를 불러오는 중이에요"
    }
    if remainingMinutes >= 1 {
        return "열차 출발까지 \(formatDuration(minutes: remainingMinutes)) 남았어요"
    } else if remainingMinutes >= -5 {
        return "열차가 출발할 시간이에요."
    } else if remainingMinutes >= -119 {
        return "열차 출발이 \(formatDuration(minutes: -remainingMinutes)) 지연됐어요"
    } else {
        let untilNext = minutesUntilNextSleepTime(startTimeText: startTimeText)
        return "열차 출발까지 \(formatDuration(minutes: untilNext)) 남았어요"
    }
}

/// 인포 서브 텍스트 생성
internal func makeInfoSubText(remainingTimeText: String, isEmergencyStop: Bool = false) -> String? {
    if isEmergencyStop {
        return "좋은 하루 보내세요!"
    }
    guard let remainingMinutes = parseRemainingTimeToMinutes(remainingTimeText) else {
        return nil
    }
    if remainingMinutes > 30 {
        return "미리 숙면에 취할 준비를 해주면 좋아요"
    } else if remainingMinutes >= 1 {
        return "지금부터는 미리 출발이 가능해요"
    } else if remainingMinutes >= -5 {
        return "지금 출발해야 최상의 수면을 할 수 있어요"
    } else if remainingMinutes >= -30 {
        let lost = abs(remainingMinutes)
        return "내일 아침의 \(lost)분이 사라지면 너무 슬플 거예요"
    } else if remainingMinutes >= -119 {
        return "2시간 넘게 지연되면 연속 기록이 사라져요"
    } else {
        return "좋은 하루 보내세요!"
    }
}
