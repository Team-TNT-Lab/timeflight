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
    
    var body: some View {
        VStack(spacing: 4) {
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

            Button(action: performCheckIn) {
                Text(hasCheckedInToday ? "비상 정지하기" : canCheckIn(
                    remainingTimeText: remainingTimeText,
                    hasCheckedInToday: hasCheckedInToday
                ) ? "지금 출발하기" : "지금 출발하기")
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
