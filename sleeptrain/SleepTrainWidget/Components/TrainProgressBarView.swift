//
//  TrainProgressBarView.swift
//  sleeptrain
//
//  Created by 양시준 on 9/23/25.
//

import SwiftUI

struct TrainProgressBarView: View {
    var progress: CGFloat = 0
    
    var body: some View {
        Color.clear
            .frame(height: 20)
            .overlay(
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(.clear)
                                .frame(maxWidth: geometry.size.width, maxHeight: 0)
                            Image(systemName: "train.side.front.car")
                                .font(.system(size: 20))
                                .frame(width: 30)
                                .foregroundStyle(.white)
                                .offset(x: calculateTrainOffset(width: geometry.size.width))
                        }
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width, height: 3)
                    }
                }
            )
    }
    
    private func calculateTrainOffset(width: CGFloat) -> CGFloat {
        let iconWidth: CGFloat = 30
        let trackWidth = width - iconWidth
        
        return trackWidth * progress
    }
}
