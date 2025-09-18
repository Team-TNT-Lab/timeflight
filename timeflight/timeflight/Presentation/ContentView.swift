//
//  ContentView.swift
//  timeflight
//
//  Created by bishoe01 on 9/18/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthorizationManager
    @EnvironmentObject private var coordinator: Coordinator

    @State var isPickerPresented = false

    @StateObject private var screenTimeManager = ScreenTimeManager()
    @StateObject private var nfcScanManager = NFCManager()
    var body: some View {
        VStack(spacing: 14) {
            Text("Dream Air").font(.system(size: 24))

            Button("Open Picker") {
                isPickerPresented.toggle()
            }.familyActivityPicker(isPresented: $isPickerPresented, selection: $screenTimeManager.selection)

            Button("잠그기") {
                nfcScanManager.startNFCScan(alertMessage: "항공권 스캔을 시작합니다") { _ in
                    screenTimeManager.lockApps()
                }
            }

        }.task {
            if !authManager.isAuthorized {
                authManager.requestAuthorization()
            }
        }
    }
}
