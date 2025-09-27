//
//  NotificationManager.swift
//  sleeptrain
//
//  Created by 양시준 on 9/24/25.
//

import UserNotifications

enum NotificationAuthorizationStatus {
    case authorized, denied, notDetermined
}

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            UNUserNotificationCenter.current().delegate = self
            print("Notification permission granted: \(granted)")
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    func scheduleNotification(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "수면 열차 출발 예정"
        content.body = "운행을 준비하세요!"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute, .second], from: date.addingTimeInterval(10)),
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "sleepTrainDailyNotification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Daily notification scheduled at \(date)")
            }
            #endif
        }
    }

    @MainActor
    func getCurrentNotificationStatus() async -> NotificationAuthorizationStatus {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        
        switch status {
        case .authorized:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .provisional:
            return .authorized
        case .ephemeral:
            return .authorized
        @unknown default:
            return .denied
        }
    }
    
//    func userNotificationCenter(
//        _ center: UNUserNotificationCenter,
//        didReceive response: UNNotificationResponse,
//        withCompletionHandler completionHandler: @escaping () -> Void
//    ) {
//        print("a")
//        if LiveActivityManager.shared.isActivityEmpty {
//            LiveActivityManager.shared.startLiveActivity(
//                targetDepartureTime: Date.now.addingTimeInterval(3600),
//                targetArrivalTime: Date.now.addingTimeInterval(7200),
//                departureDayString: "MON",
//                arrivalDayString: "TUE"
//            )
//        } else {
//            LiveActivityManager.shared.updateNotificationActivity(
//                targetDepartureTime: Date.now.addingTimeInterval(3600),
//                targetArrivalTime: Date.now.addingTimeInterval(7200),
//                departureDayString: "MON",
//                arrivalDayString: "TUE"
//            )
//        }
//        completionHandler()
//    }
}
