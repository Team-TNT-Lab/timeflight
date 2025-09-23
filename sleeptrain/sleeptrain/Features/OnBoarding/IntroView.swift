//
//  IntroView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/23/25.
//

import SwiftUI

struct IntroView: View {
    var body: some View {
        VStack(spacing: 0) {
            Image("IntroBackground")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 500)
                .clipped()

            VStack(alignment: .leading, spacing: 12) {
                Text("당신은 드림 라인의 기관사입니다. 수면 운행을 준비해볼까요?")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.leading)

                Text("목표한 수면 운행 일정에 맞게 출발하면 성공적인 운행을 완료하게 돼요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Spacer(minLength: 0)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(buttonText: "다음", action: { print("2") })
        }
    }
}
