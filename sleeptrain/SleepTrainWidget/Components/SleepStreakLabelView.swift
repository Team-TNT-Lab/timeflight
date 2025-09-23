//
//  SleepStreakLabelView.swift
//  sleeptrain
//
//  Created by 양시준 on 9/23/25.
//

import SwiftUI

struct SleepStreakLabelView: View {
    var streak: Int = 0
    
    var body: some View {
        Label(streak.description, systemImage: "bed.double.badge.checkmark.fill")
            .font(Font.system(size: 14, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
