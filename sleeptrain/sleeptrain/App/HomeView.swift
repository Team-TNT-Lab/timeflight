//
//  HomeView.swift
//  timeflight
//
//  Created by bishoe01 on 9/18/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthorizationManager

    @StateObject private var screenTimeManager = ScreenTimeManager()
    @StateObject private var nfcScanManager = NFCManager()
    var body: some View {
        TabView {
            FlightView().tabItem {
                Image(systemName: "airplane")
                Text("비행")
            }
            SettingView()
                .tabItem {
                    Image(systemName: "ellipsis")
                    Text("설정")
                }
        }.task {
            if !authManager.isAuthorized {
                authManager.requestAuthorization()
            }
        }
    }
}
