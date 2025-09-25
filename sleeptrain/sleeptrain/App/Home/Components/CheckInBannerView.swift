//
//  CheckInBannerView.swift
//  sleeptrain
//
//  Created by Dean_SSONG on 9/24/25.
//

import SwiftUI

struct CheckInBannerView: View {
    let remainingTimeText: String
    let startTimeText: String
    let endTimeText: String
    let hasCheckedInToday: Bool
    let performCheckIn: () -> Void
    
    @StateObject private var nfcScanManager = NFCManager()
    @State private var showEmergencyStopAlert = false
    
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
                    // 운행 중: 비상 정지 확인 얼럿
                    showEmergencyStopAlert = true
                } else {
                    // 출발 전: NFC 스캔으로 체크인
                    nfcScanManager.startNFCScan(alertMessage: "기기를 기상 NFC 태그에 가까이 대세요") { message in
                        if message == "\u{02}enwake" {
                            performCheckIn()
                        }
                    }
                }
            }) {
                Text(hasCheckedInToday ? "비상 정지하기" : "지금 출발하기")
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
            .alert("비상 정지하시겠어요?", isPresented: $showEmergencyStopAlert) {
                Button("비상 정지하기", role: .none) {
                    // 확인을 누르면 NFC 태그 안내를 띄워 스캔을 시작합니다.
                    nfcScanManager.startNFCScan(alertMessage: "비상 정지를 위해 기기를 기상 NFC 태그에 가까이 대세요") { _ in
                        // 필요 시 스캔 성공 시점에 비상 정지 처리 로직을 연결하세요.
                        // 현재 NFCManager는 특정 페이로드("\u{02}enwake")에만 성공 콜백을 전달합니다.
                    }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("지금 멈추면 연속 기록이 사라져요.")
            }
        }
    }
}
