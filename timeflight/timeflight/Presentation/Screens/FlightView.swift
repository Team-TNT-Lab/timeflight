//
//  FlightView.swift
//  timeflight
//
//  Created by bishoe01 on 9/20/25.
//

import SwiftUI

struct FlightView: View {
    @StateObject private var viewModel = FlightViewModel()

    var body: some View {
        // 날짜섹션

        // 현재 비행 현황
        TimelineView(.periodic(from: Date(), by: 60)) { _ in
            VStack(spacing: 10) {
                Image(systemName: "airplane")
                    .font(.system(size: 24))
                Text(viewModel.calculateTimeUntilSleep())
                    .font(.system(size: 24))
                Text(viewModel.calculateSleepStartTime())
                    .font(.system(size: 18))
                    .opacity(0.4)
                Spacer().frame(height: 18)
                Button(viewModel.isSleeping ? "비행 종료" : "비행 시작") {
                    if viewModel.isSleeping {
                        viewModel.stopSleep()
                    } else {
                        viewModel.startSleep()
                    }
                }.buttonStyle(.borderedProminent)
                    .tint(Color.buttongray)
                    .foregroundStyle(Color.black)
                    .controlSize(.large)
            }
        }
    }
}

#Preview {
    FlightView()
}
