// DateFormatting.swift

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
}
