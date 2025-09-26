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
    var onComplete: () -> Void

    var body: some View {
        NavigationStack(path: $navigationPath) {
            OnBoardingStepView(step: .welcome, navigationPath: self.$navigationPath, currentStep: self.$currentStep, onComplete: onComplete)
                .navigationDestination(for: OnBoardingStep.self) { step in
                    OnBoardingStepView(step: step, navigationPath: self.$navigationPath, currentStep: self.$currentStep, onComplete: onComplete)
                }
        }
    }
}
