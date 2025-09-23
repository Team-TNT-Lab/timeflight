//
//  OnBoardingView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/23/25.
//

import SwiftUI

struct OnBoardingView: View {
    @State private var step: Int = 0
    var body: some View {
        VStack {
            stepContent
        }.statusBarHidden(step == 1)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0:
            WelcomeView(onNext: { step += 1 })

        case 1:
            IntroView(onNext: { step += 1 }).ignoresSafeArea(.container, edges: .top)

        case 2:
            NameInputView()

        case 3:
            TimeSettingView()

        default:
            EmptyView()
        }
    }
}

#Preview {
    OnBoardingView()
}
