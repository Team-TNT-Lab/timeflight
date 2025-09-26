//
//  TrainTicketView.swift
//  sleeptrain
//
//  Created by go on 9/23/25.
//

import SwiftUI
import SwiftData

struct TrainTicketView: View {
    @EnvironmentObject var viewModel: TrainTicketViewModel
    @Query private var userSettings: [UserSettings]
    @Query private var stats: [Stats]
    
    // UserSettings 변경 감지를 위해 시그니처(Equatable) 생성
    private var scheduleSignature: String {
        guard let settings = userSettings.first else { return "none" }
        let dep = DateFormatting.hourMinuteString(from: settings.targetDepartureTime)
        let arr = DateFormatting.hourMinuteString(from: settings.targetArrivalTime)
        return "\(dep)-\(arr)"
    }
    
    // Stats 변경 감지를 위한 시그니처(Equatable)
    private var streakSignature: String {
        if let first = stats.first {
            return "streak:\(first.streak)"
        } else {
            return "streak:0"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(viewModel.startTimeText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text(viewModel.endTimeText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer().frame(height: 20)
            
            HStack(spacing: 0) {
                Text(viewModel.startDayText)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer().frame(width: 10)
                
                VStack(alignment: .leading, spacing: 2) {
                    Image(systemName: "train.side.front.car")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .offset(x: viewModel.calculateTrainPosition())
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(10)
                }
                
                Spacer().frame(width: 10)
                
                Text(viewModel.endDayText)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 24)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.remainingTimeText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.blue)
                    
                    Text("열차 출발까지")
                        .font(.system(size: 14))
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "bed.double.badge.checkmark.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.black)
                    
                    Text("\(viewModel.sleepCount)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .onAppear {
            // 실제 스케줄 적용
            if let settings = userSettings.first {
                viewModel.setRealSchedule(
                    departureTemplate: settings.targetDepartureTime,
                    arrivalTemplate: settings.targetArrivalTime
                )
            }
            // 스트릭 카운트 적용 (Stats 없으면 0)
            let currentStreak = stats.first?.streak ?? 0
            viewModel.setSleepCount(currentStreak)
        }
        .onChange(of: scheduleSignature) { _, _ in
            // 설정 변경 시 실데이터 재적용
            if let settings = userSettings.first {
                viewModel.setRealSchedule(
                    departureTemplate: settings.targetDepartureTime,
                    arrivalTemplate: settings.targetArrivalTime
                )
            }
        }
        .onChange(of: streakSignature) { _, _ in
            // Stats 변경 시 카운트 동기화
            let currentStreak = stats.first?.streak ?? 0
            viewModel.setSleepCount(currentStreak)
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            viewModel.updateTime()
        }
        // .onTapGesture {
        //     viewModel.switchToNextMock()
        // }
    }
}



// 목업 데이터 구조체
struct MockSchedule {
    let startTime: String
    let endTime: String
    let startDay: String
    let endDay: String
    let remainingTime: String
    let sleepCount: Int
}

#Preview {
    let vm = TrainTicketViewModel()
    return TrainTicketView()
        .environmentObject(vm)
        .modelContainer(for: [UserSettings.self, Stats.self], inMemory: true)
        .background(Color.gray.opacity(0.1))
}

