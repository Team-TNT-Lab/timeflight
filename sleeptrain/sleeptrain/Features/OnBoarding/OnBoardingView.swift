//
//  OnBoardingView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/23/25.
//

import SwiftUI

struct OnBoardingView: View {
    var body: some View {
        TabView {
            WelcomeView()
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

#Preview {
    OnBoardingView()
}
