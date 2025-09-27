import Foundation

public enum DateFormatting {
    /// "M월 d일" 한국어 표기를 위한 포맷터
    public static let monthDayKoreanFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter
    }()
    
    /// "HH:mm" 시간 포맷터
    public static let hourMinuteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    /// 오늘 또는 지정한 날짜를 "M월 d일"로 반환
    public static func monthDayKoreanString(for date: Date = Date()) -> String {
        monthDayKoreanFormatter.string(from: date)
    }
    
    /// 시간을 "HH:mm" 형태로 반환
    public static func hourMinuteString(from date: Date) -> String {
        hourMinuteFormatter.string(from: date)
    }
    
    /// 시간 문자열을 Date로 변환 (오늘 날짜 기준)
    public static func dateFromTimeString(_ timeString: String) -> Date? {
        let calendar = Calendar.current
        let today = Date()
        
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }
        
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today)
    }
    
    static func dayAbbrev(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    // 양수(출발 전) 남은 시간 문자열
    static func remainingTimeString(until target: Date) -> String {
        let now = Date()
        let interval = max(0, Int(target.timeIntervalSince(now)))
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)시간 \(minutes)분"
        } else if hours > 0 {
            return "\(hours)시간"
        } else {
            return "\(minutes)분"
        }
    }
    
    // 음수(출발 후) 지연 시간 문자열
    static func delayString(since departure: Date) -> String {
        let now = Date()
        let delay = max(0, Int(now.timeIntervalSince(departure)))
        let hours = delay / 3600
        let minutes = (delay % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "지연 \(hours)시간 \(minutes)분"
        } else if hours > 0 {
            return "지연 \(hours)시간"
        } else {
            return "지연 \(minutes)분"
        }
    }
    
    // 도착까지 남은 시간 계산(자정 넘김 고려)
    public static func remainingTimeToArrival(fromNow now: Date, endTimeText: String) -> String {
        let comps = endTimeText.split(separator: ":")
        guard comps.count == 2,
              let h = Int(comps[0]),
              let m = Int(comps[1]) else {
            return ""
        }
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: now)
        var arrival = cal.date(bySettingHour: h, minute: m, second: 0, of: startOfToday) ?? now
        if arrival <= now {
            arrival = cal.date(byAdding: .day, value: 1, to: arrival) ?? arrival
        }
        let diff = cal.dateComponents([.hour, .minute], from: now, to: arrival)
        let hours = max(0, diff.hour ?? 0)
        let minutes = max(0, diff.minute ?? 0)
        if hours > 0 && minutes > 0 {
            return "\(hours)시간 \(minutes)분"
        } else if hours > 0 {
            return "\(hours)시간"
        } else {
            return "\(minutes)분"
        }
    }
}
