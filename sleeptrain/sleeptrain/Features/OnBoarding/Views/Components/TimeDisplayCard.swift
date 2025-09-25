//
//  TimeDisplayCard.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/23/25.
//


import SwiftUI

struct TimeDisplayCard: View {
    let time: Date

    var body: some View {
        Text(time.formatted(date: .omitted, time: .shortened))
            .font(.system(size: 36, weight: .bold))
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.30))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
            )
    }
}
