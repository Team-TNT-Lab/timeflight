//
//  HomeView.swift
//  timeflight
//
//  Created by bishoe01 on 9/18/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        TabView {
//            FlightView().tabItem {
//                Image(systemName: "airplane")
//                Text("비행")
//            }
//            SettingView()
//                .tabItem {
//                    Image(systemName: "ellipsis")
//                    Text("설정")
//                }
            Button("알림 설정") {
                NotificationManager.shared.scheduleNotification(at: Date.now.advanced(by: 5))
            }
            .onAppear {
                NotificationManager.shared.requestAuthorization()
            }
        }.task {
            if !authManager.isAuthorized {
                authManager.requestAuthorization()
            }
        }
    }
}
