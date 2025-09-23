//
//  TrainTicketView.swift
//  sleeptrain
//
//  Created by go on 9/23/25.
//

import SwiftUI

struct TrainTicketView: View {
    @StateObject private var viewModel = TrainTicketViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 시간 표시
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
            
            // 중앙 기차 진행 바
            HStack(spacing: 0) {
                // 시작 요일
                Text(viewModel.startDayText)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer().frame(width: 10)
                
                // 기차 아이콘과 진행 바
                VStack(spacing: 0) {
                    // 기차 아이콘
                    Image(systemName: "train.side.front.car")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                    
                    // 진행 바
                    Rectangle()
                        .fill(Color.blue)
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(10)
                }
                
                Spacer().frame(width: 10)
                
                // 종료 요일
                Text(viewModel.endDayText)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 24)
            
            // 하단 정보
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
                
                // 수면 모드 스트릭
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
        .clipShape(RoundedRectangle(cornerRadius: 40))
        .onAppear {
            viewModel.loadSchedule()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            viewModel.updateTime()
        }
        .onTapGesture {
            viewModel.switchToNextMock()
        }
    }
}

class TrainTicketViewModel: ObservableObject {
    @Published var isSleepModeActive = false
    @Published var sleepCount = 32
    @Published var startTimeText = "23:30"
    @Published var endTimeText = "07:30"
    @Published var startDayText = "MON"
    @Published var endDayText = "TUE"
    @Published var remainingTimeText = "1시간"
    
    // 목업 데이터
    private let mockSchedules = [
        MockSchedule(startTime: "23:30", endTime: "07:30", startDay: "MON", endDay: "TUE", remainingTime: "1시간", sleepCount: 32),
        MockSchedule(startTime: "22:00", endTime: "06:00", startDay: "TUE", endDay: "WED", remainingTime: "2시간 30분", sleepCount: 28),
        MockSchedule(startTime: "00:00", endTime: "08:00", startDay: "WED", endDay: "THU", remainingTime: "30분", sleepCount: 45),
        MockSchedule(startTime: "23:45", endTime: "07:15", startDay: "THU", endDay: "FRI", remainingTime: "지연 15분", sleepCount: 18)
    ]
    
    private var currentMockIndex = 0
    
    func loadSchedule() {
        // 목업 데이터 로드
        updateMockDisplay()
    }
    
    func toggleSleepMode() {
        isSleepModeActive.toggle()
        if isSleepModeActive {
            sleepCount += 1
        }
    }
    
    func updateTime() {
        // 목업 데이터 업데이트 (다양한 시나리오 보여주기)
        updateMockDisplay()
    }
    
    func switchToNextMock() {
        currentMockIndex = (currentMockIndex + 1) % mockSchedules.count
        updateMockDisplay()
    }
    
    private func updateMockDisplay() {
        let mock = mockSchedules[currentMockIndex]
        
        startTimeText = mock.startTime
        endTimeText = mock.endTime
        startDayText = mock.startDay
        endDayText = mock.endDay
        remainingTimeText = mock.remainingTime
        sleepCount = mock.sleepCount
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
    TrainTicketView()
        .background(Color.gray.opacity(0.1))
}
