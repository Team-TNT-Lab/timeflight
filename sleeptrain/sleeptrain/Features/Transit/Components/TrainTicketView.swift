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

class TrainTicketViewModel: ObservableObject {
    enum Mode {
        case mock
        case real
    }
    
    @Published var isSleepModeActive = false
    @Published var sleepCount = 0
    @Published var startTimeText = "23:30"
    @Published var endTimeText = "07:30"
    @Published var startDayText = "MON"
    @Published var endDayText = "TUE"
    @Published var remainingTimeText = "1시간"
    
    @Published private(set) var mode: Mode = .mock
    
    // 실제 스케줄(오늘 기준으로 구성된 Date)
    private var realDepartureDate: Date?
    private var realArrivalDate: Date?
    
    // 도착 시간을 Date 객체로 반환하는 계산 속성 (문자열 기반 기본 구현 유지)
    var targetArrivalTime: Date {
        DateFormatting.dateFromTimeString(endTimeText) ?? Date()
    }
    
    func setSleepCount(_ count: Int) {
        sleepCount = max(0, count)
    }
    
    func toggleSleepMode() {
        // 실제 카운트는 Stats 등 실제 데이터로 관리하므로 여기서 증가시키지 않습니다.
        isSleepModeActive.toggle()
    }
    
    func updateTime() {
        switch mode {
        case .mock:
            // 목업 데이터 업데이트 비활성화
            break
        case .real:
            guard let dep = realDepartureDate, let arr = realArrivalDate else { return }
            let now = Date()
            if now < dep {
                remainingTimeText = Self.remainingTimeString(until: dep)
            } else if now >= dep && now < arr {
                // 출발 이후: 지연 시간으로 표시 (체크인/지연 로직이 음수로 해석 가능)
                remainingTimeText = Self.delayString(since: dep)
            } else {
                // 운행 종료
                remainingTimeText = "운행 종료"
            }
        }
    }
    
    // MARK: - 실제 스케줄 적용
    func setRealSchedule(departureTemplate: Date, arrivalTemplate: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        let depHour = calendar.component(.hour, from: departureTemplate)
        let depMinute = calendar.component(.minute, from: departureTemplate)
        let arrHour = calendar.component(.hour, from: arrivalTemplate)
        let arrMinute = calendar.component(.minute, from: arrivalTemplate)
        
        // 오늘 날짜 기준으로 설정된 시각으로 구성
        let depToday = calendar.date(bySettingHour: depHour, minute: depMinute, second: 0, of: now) ?? now
        var arrToday = calendar.date(bySettingHour: arrHour, minute: arrMinute, second: 0, of: now) ?? now
        
        // 도착 시간이 출발 시간보다 이르면 다음 날 도착으로 간주
        if arrToday <= depToday {
            arrToday = calendar.date(byAdding: .day, value: 1, to: arrToday) ?? arrToday
        }
        
        realDepartureDate = depToday
        realArrivalDate = arrToday
        mode = .real
        
        // 텍스트 업데이트
        startTimeText = DateFormatting.hourMinuteString(from: depToday)
        endTimeText = DateFormatting.hourMinuteString(from: arrToday)
        startDayText = Self.dayAbbrev(for: depToday)
        endDayText = Self.dayAbbrev(for: arrToday)
        
        // 현재 시각 기준으로 남은 시간 또는 지연 시간으로 초기 세팅
        if now < depToday {
            remainingTimeText = Self.remainingTimeString(until: depToday)
        } else if now >= depToday && now < arrToday {
            remainingTimeText = Self.delayString(since: depToday)
        } else {
            remainingTimeText = "운행 종료"
        }
    }
    
    static func dayAbbrev(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    // 양수(출발 전) 남은 시간 문자열
    static func remainingTimeString(until target: Date) -> String {
        let now = Date()
        let interval = max(0, Int(target.timeIntervalSince(now)))
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)시간 \(minutes)분"
        } else if hours > 0 {
            return "\(hours)시간"
        } else {
            return "\(minutes)분"
        }
    }
    
    // 음수(출발 후) 지연 시간 문자열
    static func delayString(since departure: Date) -> String {
        let now = Date()
        let delay = max(0, Int(now.timeIntervalSince(departure)))
        let hours = delay / 3600
        let minutes = (delay % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "지연 \(hours)시간 \(minutes)분"
        } else if hours > 0 {
            return "지연 \(hours)시간"
        } else {
            return "지연 \(minutes)분"
        }
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

