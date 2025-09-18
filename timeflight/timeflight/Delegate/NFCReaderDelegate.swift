//
//  NFCReaderDelegate.swift
//  timeflight
//
//  Created by bishoe01 on 9/19/25.
//

import CoreNFC
import SwiftUI

class TimerViewNFCDelegate: NSObject, NFCNDEFReaderSessionDelegate {
    private let onMessageReceived: (String) -> Void

    init(onMessageReceived: @escaping (String) -> Void) {
        self.onMessageReceived = onMessageReceived
    }

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("HERE")
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let message = messages.first,
              let record = message.records.first
        else {
            onMessageReceived(nfcError.invalidMessage.localizedDescription)
            return
        }

        let messageText = String(data: record.payload, encoding: .utf8) ?? nfcError.invalidMessage.localizedDescription
        onMessageReceived(messageText)
        session.invalidate()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        if let nfcError = error as? NFCReaderError {
            if nfcError.code != .readerSessionInvalidationErrorUserCanceled {
                onMessageReceived(nfcError.localizedDescription)
            } else {
                onMessageReceived("스캔취소")
            }
        }
    }
}
