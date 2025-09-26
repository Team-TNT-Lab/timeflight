//
//  CheckInBannerView.swift
//  sleeptrain
//
//  Created by Dean_SSONG on 9/24/25.
//

import SwiftUI
import LocalAuthentication  // Face ID

struct CheckInBannerView: View {
    let remainingTimeText: String
    let startTimeText: String
    let endTimeText: String
    let hasCheckedInToday: Bool
    let performCheckIn: () -> Void
    let performCheckOut: () -> Void
    let isGuestUser: Bool
    
    @StateObject private var nfcScanManager = NFCManager()
    @State private var showEmergencyStopAlert = false
    @State private var showFaceIDAlert = false
    
    // 현재 시간부터 기상 시간까지 남은 시간 계산
    private var timeUntilWakeUp: String {
        calculateRemainingTimeToWakeUp(endTimeText: endTimeText)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // 이동 중(=오늘 체크인 완료)이면 도착 안내 문구로 전환
            if hasCheckedInToday {
                // infoBannerText - 현재 시간부터 기상 시간까지 남은 시간 계산
                Text("열차 도착까지 \(timeUntilWakeUp) 남았어요")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(9.6)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 130)
                
                // subText
                Text("잠이 오지 않으면 눈을 감고만 있어도 괜찮아요")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6.4)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(makeInfoBannerText(
                    remainingTimeText: remainingTimeText,
                    startTimeText: startTimeText
                ))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(9.6)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 90)

                if let sub = makeInfoSubText(remainingTimeText: remainingTimeText) {
                    Text(sub)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6.4)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button(action: {
                if hasCheckedInToday {
                    showEmergencyStopAlert = true
                } else {
                    if isGuestUser {
                        authenticateWithFaceID() // 게스트유저 Face ID 인증
                    } else {
                        nfcScanManager.startNFCScan(alertMessage: "기기를 드림카드에 태그해주세요") { message in
                            if message == "\u{02}enwake" {
                                performCheckIn()
                            }
                        }
                    }
                }
            }) {
                Text(hasCheckedInToday ? "운행 종료하기" : "지금 출발하기")
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        hasCheckedInToday
                        ? Color.white
                        : (canCheckIn(
                            remainingTimeText: remainingTimeText,
                            hasCheckedInToday: hasCheckedInToday
                        ) ? Color.white : Color.gray.opacity(0.3))
                    )
                    .foregroundColor(
                        hasCheckedInToday
                        ? .black
                        : (canCheckIn(
                            remainingTimeText: remainingTimeText,
                            hasCheckedInToday: hasCheckedInToday
                        ) ? .black : .secondary)
                    )
                    .cornerRadius(99)
            }
            // 운행 중에는 항상 활성화, 출발 전에는 가능 조건에 따라 비활성화
            .disabled(!hasCheckedInToday ? !canCheckIn(
                remainingTimeText: remainingTimeText,
                hasCheckedInToday: hasCheckedInToday
            ) : false)
            .padding(.top, hasCheckedInToday ? 200 : 90)
            .padding(.horizontal, 16)
            .alert("운행을 종료하시겠어요?", isPresented: $showEmergencyStopAlert) {
                Button("운행 종료하기", role: .none) {
                    if isGuestUser {
                        authenticateWithFaceIDForCheckOut()  // 게스트: Face ID
                    } else {
                        nfcScanManager.startNFCScan(alertMessage: "기기를 드림카드에 태그해주세요") { _ in
                            performCheckOut()  // NFC 성공 시 체크아웃
                        }
                    }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("지금 멈추면 연속 기록이 사라져요.")
            }
            .alert("Face ID 인증", isPresented: $showFaceIDAlert) {
                Button("확인") {
                    performCheckIn()
                }
                Button("취소", role: .cancel) { }
            }
        }
    }
    
    private func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "수면 체크인을 위해 Face ID 인증이 필요합니다."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        performCheckIn()
                    } else {
                        print("Face ID 인증 실패")
                    }
                }
            }
        } else {
            performCheckIn()
        }
    }

    private func authenticateWithFaceIDForCheckOut() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "운행 종료를 위해 Face ID 인증이 필요합니다."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        performCheckOut()
                    } else {
                        print("Face ID 인증 실패")
                    }
                }
            }
        } else {
            performCheckOut()
        }
    }
}
