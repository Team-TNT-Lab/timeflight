//
//  IntroView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/23/25.
//

import SwiftUI

struct IntroView: View {
    let onNext: () -> Void
    init(_ onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    var body: some View {
        VStack(spacing: 0) {
            Image("IntroBackground")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 550)
                .clipped()

            VStack(alignment: .leading, spacing: 12) {
                Text("당신은 드림 라인의 기관사입니다.\n수면 운행을 준비해볼까요?")
                    .font(.system(size: 23, weight: .semibold))

                Text("목표한 수면 운행 일정에 맞게 출발하면\n성공적인 운행을 완료하게 돼요")
                    .font(.system(size: 13, weight: .thin))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 32)

            Spacer(minLength: 0)
        }.frame(maxWidth: .infinity)
            .ignoresSafeArea(.all, edges: .top)
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(buttonText: "다음", action: { onNext() })
            }
    }
}

#Preview {
    IntroView { print("HI") }
}
