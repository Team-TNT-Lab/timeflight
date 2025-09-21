//
//  FlightView.swift
//  timeflight
//
//  Created by bishoe01 on 9/20/25.
//

import SwiftUI

struct FlightView: View {
    var body: some View {
        // 날짜섹션

        // 현재 비행 현황
        VStack(spacing: 10) {
            Image(systemName: "airplane")
                .font(.system(size: 24))
            Text("비행까지 ?시간 남았어요")
                .font(.system(size: 24))
            Text("00:00에 수면시작").font(.system(size: 18))
                .opacity(0.4)
            Spacer().frame(height: 18)
            Button("비행 시작") {
                print("비행시작")
            }.buttonStyle(.borderedProminent)
                .tint(Color.buttongray)
                .foregroundStyle(Color.black)
                .controlSize(.large)
        }
    }
}

#Preview {
    FlightView()
}
