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
            // 스캔 불가 환경(시뮬레이터 등)에서는 실패 콜백
            completion(nil)
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
                self.completion?(nil)
            }
            session.invalidate()
            return
        }

        let messageText = String(data: record.payload, encoding: .utf8) ?? NfcError.invalidMessage.localizedDescription
        DispatchQueue.main.async {
            self.nfcMessage = messageText
            // 특정 페이로드만 성공으로 간주
            if messageText == "\u{02}enwake" {
                self.completion?(messageText)
            } else {
                self.completion?(nil)
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
            // 취소/실패 모두 상위에 알림
            self.completion?(nil)
        }
    }
}

