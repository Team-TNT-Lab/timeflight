//
//  Gradients.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/25/25.
//

import SwiftUI

extension ShapeStyle where Self == LinearGradient {
    static var primaryBackground: LinearGradient {
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color("onboarding-gradient-1"), location: 0.0),
                .init(color: Color("onboarding-gradient-2"), location: 0.59),
                .init(color: Color("onboarding-gradient-3"), location: 0.99),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var onBoardingBackground1: LinearGradient {
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color("onboarding-gradient-1"), location: 0.0),
                .init(color: Color("onboarding-gradient-2"), location: 0.27),
                .init(color: Color("onboarding-gradient-3"), location: 0.59),
                .init(color: Color("onboarding-gradient-4"), location: 0.99),

            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var onBoardingBackground2: LinearGradient {
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color("screentime-background-1"), location: 0.0),
                .init(color: Color(Color.black), location: 0.6),
                .init(color: Color(Color.black), location: 0.9),

            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
