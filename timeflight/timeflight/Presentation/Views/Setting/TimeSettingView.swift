//
//  TimeSettingView.swift
//  timeflight
//
//  Created by bishoe01 on 9/20/25.
//

import SwiftUI

// 1. 평일,주말 수면 시간 설정 여부
// 2. 평일 세팅
// 3. 주말 세팅
struct TimeSettingView: View {
    @StateObject private var viewModel = TimeSettingViewModel()

    var body: some View {
        VStack {
            Text("평일 수면 시간을 설정해주세요")
                .font(.system(size: 24))
            Text("평균 7시간 이상의 수면을 추천해요")
                .opacity(0.4)

            Spacer()

            SleepTimerSettingView(
                weekdayTitle: "월 화 수 목 금",
                startDate: viewModel.startDate,
                endDate: viewModel.endDate,
                sleepHoursText: viewModel.sleepHoursText,
                onTapStart: { viewModel.showingStartPicker = true },
                onTapEnd: { viewModel.showingEndPicker = true }
            )

            Spacer()
            Button(action: {
                print("E")
            }) {
                Text("다음")
                    .font(.system(size: 20))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
        }
        .padding(.all, 20)
        .sheet(isPresented: $viewModel.showingStartPicker) {
            TimePickerSheet(date: $viewModel.startDate, isPresented: $viewModel.showingStartPicker)
        }
        .sheet(isPresented: $viewModel.showingEndPicker) {
            TimePickerSheet(date: $viewModel.endDate, isPresented: $viewModel.showingEndPicker)
        }
    }
}

#Preview {
    TimeSettingView()
}
