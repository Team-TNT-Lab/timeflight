//
//  OnBoardingStep.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/24/25.
//

import SwiftUI

enum OnBoardingStep: Hashable, CaseIterable {
    case welcome
    case intro
    case nameInput
    case timeSetting
    case screenTimeRequest
    case appSelection
    case nfcIntro
    case nfcTagExample
    case onBoardingComplete

    var hideBackButton: Bool {
        switch self {
        case .welcome, .intro, .nameInput, .onBoardingComplete:
            return true
        default:
            return false
        }
    }

    var hideStatusBar: Bool {
        switch self {
        case .welcome, .intro, .nameInput:
            return true
        default:
            return false
        }
    }

    func nextStep() -> OnBoardingStep? {
        let allCases = OnBoardingStep.allCases
        guard let currentStep = allCases.firstIndex(of: self),
              currentStep < allCases.count - 1
        else {
            // MARK: 온보딩끝-홈뷰로이동

            return nil
        }
        return allCases[currentStep + 1]
    }
}
