//
//  TimerView.swift
//  timeflight
//
//  Created by bishoe01 on 9/18/25.
//

import CoreNFC
import SwiftUI

struct TimerView: View {
    @StateObject private var screenTimeManager = ScreenTimeManager()
    @StateObject private var nfcScanManager = NFCManager()
    @EnvironmentObject private var coordinator: Coordinator

    var body: some View {
        Text("TIMER VIEW")
        Button("해제하기") {
            nfcScanManager.startNFCScan(alertMessage: "긴급탈출하려면 태그하세요") { _ in
                screenTimeManager.unlockApps()
                coordinator.removeAll()
            }
        }
    }
}
