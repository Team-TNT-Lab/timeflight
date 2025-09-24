//
//  OnBoardingView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/23/25.
//

import SwiftUI

struct OnBoardingView: View {
    @State private var navigationPath = NavigationPath()
    @State private var currentStep: OnBoardingStep = .welcome

    var body: some View {
        NavigationStack(path: $navigationPath) {
            OnBoardingStepView(step: .welcome, navigationPath: self.$navigationPath, currentStep: self.$currentStep)
                .navigationDestination(for: OnBoardingStep.self) { step in
                    OnBoardingStepView(step: step, navigationPath: self.$navigationPath, currentStep: self.$currentStep)
                }
        }
    }
}

struct OnBoardingStepView: View {
    let step: OnBoardingStep
    @Binding var navigationPath: NavigationPath
    @Binding var currentStep: OnBoardingStep

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

        case .appSelection:
            AppSelectionView(next)

        case .nfcIntro:
            NfcIntro(next)

        case .nfcTagExample:
            NfcTagExampleView(next)

        case .onBoardingComplete:
            OnboardingCompleteView()
        }
    }
}

#Preview {
    OnBoardingView()
}
