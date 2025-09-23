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
        ZStack {
            self.stepContent
        }.statusBarHidden(self.step == 1)
    }

    @ViewBuilder
    private var stepContent: some View {
        let next = { withAnimation { self.step += 1 }}
        switch self.step {
        case 0:
            WelcomeView(next).onboardingTransition()

        case 1:
            IntroView(next).ignoresSafeArea(.container, edges: .top)
                .onboardingTransition()

        case 2:
            NameInputView(next)
                .onboardingTransition()

        case 3:
            TimeSettingView(next)
                .onboardingTransition()

        case 4:
            AppSelectionView(next)
                .onboardingTransition()

        case 5:
            NfcIntro(next)
                .onboardingTransition()

        default:
            EmptyView()
        }
    }
}

#Preview {
    OnBoardingView()
}

struct OnboardingTransitionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
    }
}

extension View {
    func onboardingTransition() -> some View {
        self.modifier(OnboardingTransitionModifier())
    }
}
