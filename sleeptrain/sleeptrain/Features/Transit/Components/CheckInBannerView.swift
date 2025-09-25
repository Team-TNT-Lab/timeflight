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
    let performEmergencyStop: (() -> Void)?
    
    @StateObject private var nfcScanManager = NFCManager()
    @State private var showEmergencyStopAlert = false
    @State private var didEmergencyStop: Bool = false
    
    private var timeUntilWakeUp: String {
        remainingTimeToArrival(fromNow: Date(), endTimeText: endTimeText)
    }
    
    init(
        remainingTimeText: String,
        startTimeText: String,
        endTimeText: String,
        hasCheckedInToday: Bool,
        performCheckIn: @escaping () -> Void,
        performEmergencyStop: (() -> Void)? = nil
    ) {
        self.remainingTimeText = remainingTimeText
        self.startTimeText = startTimeText
        self.endTimeText = endTimeText
        self.hasCheckedInToday = hasCheckedInToday
        self.performCheckIn = performCheckIn
        self.performEmergencyStop = performEmergencyStop
    }
    
    var body: some View {
        VStack(spacing: 4) {
            if hasCheckedInToday {
                // 운행 중: 현재시간 → 도착시간까지 남은 시간
                Text("열차 도착까지 \(timeUntilWakeUp) 남았어요")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(9.6)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 150)
                
                Text("잠이 오지 않으면 눈을 감고만 있어도 괜찮아요")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6.4)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                // 출발 전: 기존 방식 유지
                Text(makeInfoBannerText(
                    remainingTimeText: remainingTimeText,
                    startTimeText: startTimeText
                ))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(9.6)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)

                if let sub = makeInfoSubText(remainingTimeText: remainingTimeText, isEmergencyStop: didEmergencyStop) {
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
                    nfcScanManager.startNFCScan(alertMessage: "기기를 기상 NFC 태그에 가까이 대세요") { message in
                        if message == "\u{02}enwake" {
                            performCheckIn()
                        }
                    }
                }
            }) {
                Text(hasCheckedInToday ? "비상 정지하기" : "지금 출발하기")
                    .font(.system(size: 16, weight: .bold))
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
            .padding(.top, hasCheckedInToday ? 200 : 80)
            .padding(.horizontal, 16)
            .alert("비상 정지하시겠어요?", isPresented: $showEmergencyStopAlert) {
                Button("비상 정지하기", role: .none) {
                    nfcScanManager.startNFCScan(
                        alertMessage: "비상 정지를 위해 기기를 기상 NFC 태그에 가까이 대세요"
                    ) { message in
                        if message == "\u{02}enwake" {
                            didEmergencyStop = true
                            performEmergencyStop?()
                        }
                    }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("지금 멈추면 연속 기록이 사라져요.")
            }
        }
    }
}

// MARK: - 도착까지 남은 시간 계산(자정 넘김 고려)
private func remainingTimeToArrival(fromNow now: Date, endTimeText: String) -> String {
    let comps = endTimeText.split(separator: ":")
    guard comps.count == 2,
          let h = Int(comps[0]),
          let m = Int(comps[1]) else {
        return ""
    }
    let cal = Calendar.current
    let startOfToday = cal.startOfDay(for: now)
    var arrival = cal.date(bySettingHour: h, minute: m, second: 0, of: startOfToday) ?? now
    if arrival <= now {
        arrival = cal.date(byAdding: .day, value: 1, to: arrival) ?? arrival
    }
    let diff = cal.dateComponents([.hour, .minute], from: now, to: arrival)
    let hours = max(0, diff.hour ?? 0)
    let minutes = max(0, diff.minute ?? 0)
    if hours > 0 && minutes > 0 {
        return "\(hours)시간 \(minutes)분"
    } else if hours > 0 {
        return "\(hours)시간"
    } else {
        return "\(minutes)분"
    }
}

