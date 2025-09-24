//
//  NfcIntro.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/23/25.
//

import SwiftUI

struct NfcIntro: View {
    let onNext: () -> Void
    init(_ onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    @State private var isImageVisible = false
    var body: some View {
        ZStack {
            VStack {
                Image("NfcIntro")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 600)
                    .ignoresSafeArea()
                    .clipped()
                    .offset(y: 40)
                    .opacity(isImageVisible ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.0)) {
                            isImageVisible = true
                        }
                    }
            }.frame(width: 300)

            VStack {
                VStack(spacing: 12) {
                    Text("드림 카드에 아이폰을 태그하면\n수면 운행이 시작돼요")
                        .font(.system(size: 23, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    Text("수면 비행이 시작되면 선택한 앱이 잠기게 돼요.\n잠금은 설정한 기상 시간에 해제되거나 수동으로 풀 수 있어요.")
                        .font(.system(size: 13, weight: .thin))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                }
                .padding(.top, 40)

                Spacer()

                PrimaryButton(buttonText: "다음", action: { onNext() })
                    .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    NfcIntro { print("hi") }
}
