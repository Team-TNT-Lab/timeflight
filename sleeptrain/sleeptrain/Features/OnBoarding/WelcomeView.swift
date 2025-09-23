//
//  WelcomeView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/23/25.
//

import SwiftUI

struct WelcomeView: View {
    let onNext: () -> Void
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 25) {
                Text("SLEEP TRAIN")
                    .font(.custom("neurimboGothicRegular", size: 50))

                Text("꿈을 향해 달려가는 기차여행")
                    .font(.custom("116watermelon", size: 25))
            }
            Spacer()
            Spacer()
            VStack(spacing: 13) {
                PrimaryButton(buttonText: "시작하기", action: { onNext() })

                Text("Made by").font(.system(size: 13)).foregroundColor(Color.gray)
            }
        }.safeAreaInset(edge: .bottom) {
            HStack(spacing: 8) {
                Image("tnt")
                    .resizable()
                    .frame(width: 25, height: 25)
                Text("tntlab")
                    .font(.custom("Afacad-Bold", size: 31))
            }
        }
    }
}
