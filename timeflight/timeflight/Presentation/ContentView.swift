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
    @StateObject private var flightTimeManager = FlightTimeManager()
    var body: some View {
        VStack(spacing: 14) {
            Text("Dream Air").font(.system(size: 24))

            Button("집에 두고갈 짐 선택") {
                isPickerPresented.toggle()
            }.familyActivityPicker(isPresented: $isPickerPresented, selection: $screenTimeManager.selection)
            VStack(spacing: 12) {
                DatePicker("이륙 시간",
                           selection: Binding(
                               get: { flightTimeManager.timeRange.start },
                               set: { flightTimeManager.updateStartTime($0) }
                           ),
                           displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)

                DatePicker("착률 시간",
                           selection: Binding(
                               get: { flightTimeManager.timeRange.end },
                               set: { flightTimeManager.updateEndTime($0) }
                           ),
                           in: flightTimeManager.timeRange.start...,
                           displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)

                if !flightTimeManager.isValidTimeRange {
                    Text(flightTimeManager.errorMessage ?? "잘못된 시간 범위입니다")
                        .foregroundColor(.red)
                }

                Text("비행 시간: \(flightTimeManager.getFlightDuration())")
                    .font(.system(size: 24))

            }.padding()

            Button("잠그기") {
                nfcScanManager.startNFCScan(alertMessage: "항공권 스캔을 시작합니다") { _ in
                    screenTimeManager.lockApps()
                    coordinator.push(.timerView)
                }
            }

        }.task {
            if !authManager.isAuthorized {
                authManager.requestAuthorization()
            }
        }
    }
}
