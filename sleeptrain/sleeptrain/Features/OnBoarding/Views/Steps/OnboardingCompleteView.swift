//
//  OnboardingCompleteView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/24/25.
//

import SwiftData
import SwiftUI

struct OnboardingCompleteView: View {
    @State private var isImageVisible: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Query var userSettings: [UserSettings]
    @StateObject private var settingsManager = UserSettingsManager()
    var onComplete: () -> Void
    var body: some View {
        ZStack {
            Image("MainBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 4) {
                    Text("열차가 준비되었어요")
                        .font(.mainTitleEmphasized)
                    Text("이제 편안한 수면 여행을 시작해볼까요?")
                        .font(.subTitle)
                        .opacity(0.5)
                }
                .opacity(isImageVisible ? 1 : 0)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.0)) {
                        isImageVisible = true
                    }
                }
                Spacer()
                PrimaryButton(buttonText: "시작하기") {
                    do {
                        try settingsManager.onboardingComplete(
                            context: modelContext,
                            userSettings: userSettings
                        )
                        try modelContext.save()
                        onComplete()
                    } catch {
                        print("온보딩여부 저장에러", error)
                    }
                }
            }.padding(.bottom, 30)
        }
    }
}

#Preview {
    OnboardingCompleteView(onComplete: {})
}
