//
//  HomeView.swift
//  timeflight
//
//  Created by bishoe01 on 9/18/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthorizationManager
//    @EnvironmentObject private var coordinator: Coordinator
    @State var isPickerPresented = false
    @State private var tab = 0

    @StateObject private var screenTimeManager = ScreenTimeManager()
    @StateObject private var nfcScanManager = NFCManager()
    var body: some View {
        TabView(selection: $tab) {
            FlightView().tabItem {
                Image(systemName: "airplane")
                Text("비행")
            }
            SettingView()
                .tabItem {
                    Image(systemName: "ellipsis")
                    Text("설정")
                }
        }
    }
}
