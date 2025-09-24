//
//  StreakView.swift
//  sleeptrain
//
//  Created by Dean_SSONG on 9/24/25.
//
import SwiftUI

struct StreakView: View {
    var body: some View {
        Text("기록 화면")
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                BackgroundGradientLayer()
            }
    }
}
