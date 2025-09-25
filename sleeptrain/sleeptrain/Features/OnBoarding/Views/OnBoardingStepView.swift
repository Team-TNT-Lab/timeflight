//
//  OnBoardingStepView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/25/25.
//

import SwiftUI

struct OnBoardingStepView: View {
    let step: OnBoardingStep
    @Binding var navigationPath: NavigationPath
    @Binding var currentStep: OnBoardingStep
    var onComplete: () -> Void

    var body: some View {
        stepContent
            .navigationBarBackButtonHidden(step.hideBackButton)
            .statusBarHidden(step.hideStatusBar)
            .onAppear {
                self.currentStep = self.step
            }
    }

    @ViewBuilder
    private var stepContent: some View {
        let next = {
            if let nextStep = step.nextStep() {
                withAnimation {
                    self.navigationPath.append(nextStep)
                }
            }
        }
        switch step {
        case .welcome:
            WelcomeView(next)

        case .intro:
            IntroView(next)

        case .nameInput:
            NameInputView(next)

        case .timeSetting:
            TimeSettingView(next)

        case .screenTimeRequest:
            ScreenTimeRequestView(next)

        case .appSelection:
            AppSelectionView(next)

        case .nfcIntro:
            NfcIntro(next)

        case .nfcTagExample:
            NfcTagExampleView(next)

        case .onBoardingComplete:
            OnboardingCompleteView(onComplete: onComplete)
        }
    }
}

#Preview {
    OnBoardingView(onComplete: {})
}
