//
//  ScreenTimeRequestView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/25/25.
//

import SwiftUI

struct ScreenTimeRequestView: View {
    let onNext: () -> Void
    init(_ onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    @State private var isImageVisible: Bool = false
    @EnvironmentObject var authManager: AuthorizationManager
    var body: some View {
        ZStack {
            Color.clear
                .background(.onBoardingBackground2)

            VStack(spacing: 55) {
                Image("ScreenTime")
                    .resizable()
                    .scaledToFit()
                    .opacity(isImageVisible ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.0)) {
                            isImageVisible = true
                        }
                    }

                VStack(alignment: .leading, spacing: 9) {
                    Text("스크린타임 권한을 허용해주세요")
                        .font(.mainTitle)
                    Text("앱의 모든 기능을 사용하기 위해\n스크린타임 권한 허용을 선택해주세요")
                        .font(.caption)
                }
                .padding(.leading, 30)
                .frame(maxWidth: .infinity, alignment: .leading)
                PrimaryButton(buttonText: "허용하기") {
                    if authManager.isAuthorized {
                        onNext()
                    }
                    else {
                        authManager.requestAuthorization()
                    }
                }
            }.onChange(of: authManager.isAuthorized) {
                if authManager.isAuthorized {
                    onNext()
                }
            }
        }
    }
}

#Preview {
    ScreenTimeRequestView { print("Hi") }
}
