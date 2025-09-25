import Foundation
import SwiftData

enum DailyStatus: String, Codable {
    case none
    case completed
    case lateCompleted
    case failed
}

@Model
final class DailyCheckIn {
    // 해당 날짜의 시작 시각(00:00)으로 저장
    var date: Date
    var status: DailyStatus
    var checkedInAt: Date?
    
    init(date: Date, status: DailyStatus = .none, checkedInAt: Date? = nil) {
        self.date = date
        self.status = status
        self.checkedInAt = checkedInAt
    }
}
