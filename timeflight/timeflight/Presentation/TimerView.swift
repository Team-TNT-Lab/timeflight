//
//  TimerView.swift
//  timeflight
//
//  Created by bishoe01 on 9/18/25.
//

import CoreNFC
import SwiftUI

struct TimerView: View {
    @StateObject private var nfcScanManager = NFCManager()
    var body: some View {
        VStack {
            Text(nfcScanManager.nfcMessage)

            Button("스캔") {
                nfcScanManager.startNFCScanning()
            }
        }
    }
}
