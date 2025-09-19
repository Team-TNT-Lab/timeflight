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
        VStack {
            Text("TIMER VIEW")
            ZStack {
                Circle().fill(Color.black)
                    .aspectRatio(1, contentMode: .fit)
                Circle()
                    .fill(Color.gray)
                    .padding(.horizontal, Padding.innerCircleHorizontal)
                    .aspectRatio(1, contentMode: .fit)
            }.padding(.horizontal, Padding.outerCircleHorizontal)
        }
    }
}
