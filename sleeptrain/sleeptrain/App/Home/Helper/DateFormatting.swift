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
    
    /// 오늘 또는 지정한 날짜를 "M월 d일"로 반환
    public static func monthDayKoreanString(for date: Date = Date()) -> String {
        monthDayKoreanFormatter.string(from: date)
    }
}
