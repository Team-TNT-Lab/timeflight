//
//  OnboardingCompleteView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/24/25.
//

import SwiftUI

struct OnboardingCompleteView: View {
    @State private var isImageVisible: Bool = false
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 4) {
                Text("열차가 준비되었어요")
                    .font(.system(size: 24, weight: .bold))
                Text("이제 편안한 수면 여행을 시작해볼까요?").opacity(0.5)
            }
            .opacity(isImageVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeIn(duration: 1.0)) {
                    isImageVisible = true
                }
            }
            Spacer()
        }.safeAreaInset(edge: .bottom) {
            PrimaryButton(buttonText: "시작하기") {
                print("Ho")
            }
        }
    }
}

#Preview {
    OnboardingCompleteView()
}
