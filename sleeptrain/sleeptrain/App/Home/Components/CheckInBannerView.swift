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
    let hasCheckedInToday: Bool
    let performCheckIn: () -> Void
    
    @StateObject private var nfcScanManager = NFCManager()
    
    var body: some View {
        VStack(spacing: 4) {
            // 이동 중(=오늘 체크인 완료)이면 도착 안내 문구로 전환
            if hasCheckedInToday {
                // infoBannerText
                Text("열차 도착까지 \(remainingTimeText) 남았어요")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(9.6)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 90)
                
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
                nfcScanManager.startNFCScan(alertMessage: "기기를 기상 NFC 태그에 가까이 대세요") { message in
                    if message == "\u{02}enwake" {
                        performCheckIn()
                    }
                }
            }) {
                Text(hasCheckedInToday ? "비상 정지하기" : "지금 출발하기")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canCheckIn(
                        remainingTimeText: remainingTimeText,
                        hasCheckedInToday: hasCheckedInToday
                    ) && !hasCheckedInToday ? Color.white : Color.gray.opacity(0.3))
                    .foregroundColor(canCheckIn(
                        remainingTimeText: remainingTimeText,
                        hasCheckedInToday: hasCheckedInToday
                    ) && !hasCheckedInToday ? .black : .secondary)
                    .cornerRadius(99)
            }
            .disabled(!canCheckIn(
                remainingTimeText: remainingTimeText,
                hasCheckedInToday: hasCheckedInToday
            ) || hasCheckedInToday)
            .padding(.top, 90)
            .padding(.horizontal, 16)
        }
    }
}
