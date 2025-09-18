//
//  NFCScanManager.swift
//  timeflight
//
//  Created by bishoe01 on 9/19/25.
//

import CoreNFC
import SwiftUI

class NFCManager: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var nfcMessage: String = "NFC대기"
    private var nfcSession: NFCNDEFReaderSession?
    private var completion: ((String?) -> Void)?

    func startNFCScan(alertMessage: String, completion: @escaping (String?) -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            nfcMessage = NfcError.deviceNotSupported.localizedDescription
            return
        }

        self.completion = completion
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        nfcSession?.alertMessage = alertMessage
        nfcSession?.begin()
    }

    // MARK: DELEGATE시작

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {}

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let message = messages.first,
              let record = message.records.first
        else {
            DispatchQueue.main.async {
                self.nfcMessage = NfcError.invalidMessage.localizedDescription
            }
            return
        }

        let messageText = String(data: record.payload, encoding: .utf8) ?? NfcError.invalidMessage.localizedDescription
        DispatchQueue.main.async {
            self.nfcMessage = messageText
            if messageText == "\u{02}enwake" {
                self.completion?(messageText)
            }
        }
        session.invalidate()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            if let NfcError = error as? NFCReaderError {
                if NfcError.code != .readerSessionInvalidationErrorUserCanceled {
                    self.nfcMessage = NfcError.localizedDescription
                } else {
                    self.nfcMessage = "스캔취소"
                }
            }
        }
    }
}
