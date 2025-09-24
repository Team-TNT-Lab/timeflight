//
//  NotificationManager.swift
//  sleeptrain
//
//  Created by 양시준 on 9/24/25.
//

import UserNotifications

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            #if DEBUG
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
            }
            #endif
        }
        UNUserNotificationCenter.current().delegate = self
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
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        LiveActivityManager.shared.startLiveActivity(
            targetDepartureTime: Date.now.addingTimeInterval(3600),
            targetArrivalTime: Date.now.addingTimeInterval(7200),
            departureDayString: "MON",
            arrivalDayString: "TUE"
        )
        completionHandler()
    }
}
