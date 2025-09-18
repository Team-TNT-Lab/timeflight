//
//  NFCManager.swift
//  timeflight
//
//  Created by bishoe01 on 9/19/25.
//


import CoreNFC
import SwiftUI
class NFCManager: ObservableObject {
    @Published var nfcMessage: String = "NFC대기"
    private var nfcSession: NFCNDEFReaderSession?
    private var nfcDelegate: TimerViewNFCDelegate?

    func startNFCScanning() {
        guard NFCNDEFReaderSession.readingAvailable else {
            nfcMessage = nfcError.deviceNotSupported.localizedDescription
            return
        }

        nfcDelegate = TimerViewNFCDelegate { message in
            DispatchQueue.main.async {
                self.nfcMessage = message
            }
        }

        nfcSession = NFCNDEFReaderSession(delegate: nfcDelegate!, queue: nil, invalidateAfterFirstRead: true)
        nfcSession?.alertMessage = "항공권 스캔을 시작합니다."
        nfcSession?.begin()
    }
}
