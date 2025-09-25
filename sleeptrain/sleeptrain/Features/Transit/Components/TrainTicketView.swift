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
    

    private var scheduleSignature: String {
        guard let settings = userSettings.first else { return "none" }
        let dep = DateFormatting.hourMinuteString(from: settings.targetDepartureTime)
        let arr = DateFormatting.hourMinuteString(from: settings.targetArrivalTime)
        return "\(dep)-\(arr)"
    }
    
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
                
                SegmentedTrainProgressBar(
                    progress: viewModel.progress,
                    segments: viewModel.segmentCount
                )
                
                Spacer().frame(width: 10)
                
                Text(viewModel.endDayText)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 24)
            

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // NFC 태그 전: remainingTimeText + "열차 출발까지"
                    // NFC 태그 후: 도착까지 남은 시간 + "열차 도착까지"
                    Text(viewModel.hasCheckedInToday ? viewModel.arrivalRemainingTimeText : viewModel.remainingTimeText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.blue)
                    
                    Text(viewModel.hasCheckedInToday ? "열차 도착까지" : "열차 출발까지")
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
            if let settings = userSettings.first {
                viewModel.setRealSchedule(
                    departureTemplate: settings.targetDepartureTime,
                    arrivalTemplate: settings.targetArrivalTime
                )
            }
            let currentStreak = stats.first?.streak ?? 0
            viewModel.setSleepCount(currentStreak)
            viewModel.updateTime()
        }
        .onChange(of: scheduleSignature) { _, _ in
            if let settings = userSettings.first {
                viewModel.setRealSchedule(
                    departureTemplate: settings.targetDepartureTime,
                    arrivalTemplate: settings.targetArrivalTime
                )
            }
            viewModel.updateTime()
        }
        .onChange(of: streakSignature) { _, _ in
            let currentStreak = stats.first?.streak ?? 0
            viewModel.setSleepCount(currentStreak)
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            // 매분 갱신: 5분 단위 틱이 바뀌는 시점에서만 애니메이션
            viewModel.updateTime()
        }
        // .onTapGesture {
        //     viewModel.switchToNextMock()
        // }
    }
}

// MARK: - 세그먼트 진행 바 + 이동 아이콘
private struct SegmentedTrainProgressBar: View {
    let progress: Double
    let segments: Int
    
    // 스타일 값
    let barHeight: CGFloat = 4
    let tickExtra: CGFloat = 8
    let iconSize: CGFloat = 20
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let barY = geo.size.height - barHeight / 2
            let clampedSegments = max(1, segments)
            let filledWidth = max(0, min(width, width * progress))
            let iconX = max(iconSize / 2, min(width - iconSize / 2, filledWidth))
            
            ZStack {
                // 바 배경
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: width, height: barHeight)
                    .position(x: width / 2, y: barY)
                
                // 채워진 바
                Capsule()
                    .fill(Color.blue)
                    .frame(width: filledWidth, height: barHeight)
                    .position(x: filledWidth / 2, y: barY)
                
                // 세그먼트 눈금 (시작/끝 포함)
//                if clampedSegments > 1 {
//                    ForEach(0...clampedSegments, id: \.self) { i in
//                        let x = width * CGFloat(i) / CGFloat(clampedSegments)
//                        Rectangle()
//                            .fill(Color.white.opacity(0.3))
//                            .frame(width: 1, height: barHeight + tickExtra)
//                            .position(x: x, y: barY)
//                    }
//                }
                
                Image(systemName: "train.side.front.car")
                    .font(.system(size: iconSize))
                    .foregroundStyle(.white.opacity(0.9))
                    .position(x: iconX, y: iconSize / 2)
            }
        }
        .frame(height: iconSize + barHeight + tickExtra)
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
    
    // 진행도(0~1), 세그먼트(시간 단위)
    @Published var progress: Double = 0.0
    @Published var segmentCount: Int = 1
    
    @Published private(set) var mode: Mode = .mock
    
    // 운행중 여부(체크인 완료 + 도착 전)
    @Published var isRideActive: Bool = false
    
    // 실제 스케줄(오늘 기준으로 구성된 Date)
    private var realDepartureDate: Date?
    private var realArrivalDate: Date?
    
    // 체크인(수면 시작) 시각
    private var checkInDate: Date?
    
    // 5분 단위 틱 애니메이션 제어용 (체크인 이후 경과 틱 수)
    private var lastProgressTick: Int = -1
    
    // 틱 간격(초) - 5분
    private static let tickSeconds: TimeInterval = 5 * 60
    
    // 도착 시간을 Date 객체로 반환하는 계산 속성 (문자열 기반 기본 구현 유지)
    var targetArrivalTime: Date {
        DateFormatting.dateFromTimeString(endTimeText) ?? Date()
    }
    
    // NFC 태그 여부(오늘 체크인 여부) 노출
    var hasCheckedInToday: Bool {
        checkInDate != nil
    }
    
    // 체크인 이후에는 "도착까지 남은 시간" 표기를 위해 사용
    var arrivalRemainingTimeText: String {
        guard let arr = realArrivalDate else { return "" }
        let now = Date()
        if now >= arr {
            return "운행 종료"
        }
        return Self.remainingTimeString(until: arr)
    }
    
    func setSleepCount(_ count: Int) {
        sleepCount = max(0, count)
    }
    
    func toggleSleepMode() {
        isSleepModeActive.toggle()
    }
    
    // 외부(HomeView 등)에서 체크인 시각을 주입
    func setCheckInDate(_ date: Date?) {
        checkInDate = date
        if let arr = realArrivalDate {
            if let start = checkInDate {
                segmentCount = Self.computeSegmentCount(from: start, to: arr)
            } else if let dep = realDepartureDate {
                segmentCount = Self.computeSegmentCount(from: dep, to: arr)
            }
        }
        updateTime()
        updateRideActive()
    }
    
    func updateTime() {
        switch mode {
        case .mock:
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
                remainingTimeText = "운행 종료"
            }
            updateProgress(now: now)
            updateRideActive(now: now)
        }
    }
    
    private func updateProgress(now: Date = Date()) {
        guard let arr = realArrivalDate else {
            progress = 0
            return
        }
        
        if segmentCount < 1 {
            if let dep = realDepartureDate {
                segmentCount = Self.computeSegmentCount(from: dep, to: arr)
            } else {
                segmentCount = 1
            }
        }
        
        guard let start = checkInDate else {
            progress = 0
            lastProgressTick = -1
            return
        }
        
        if now >= arr {
            progress = 1.0
            lastProgressTick = Int.max
            return
        }
        

        let totalSeconds = max(0, arr.timeIntervalSince(start))
        let totalTicks = max(1, Int(ceil(totalSeconds / Self.tickSeconds)))
        
        let elapsedSeconds = max(0, now.timeIntervalSince(start))
        let elapsedTicks = min(Int(floor(elapsedSeconds / Self.tickSeconds)), totalTicks)
        
        let newProgress = Double(elapsedTicks) / Double(totalTicks)
        
        if elapsedTicks != lastProgressTick {
            withAnimation(.easeInOut(duration: 0.4)) {
                progress = newProgress
            }
            lastProgressTick = elapsedTicks
        } else {
            progress = newProgress
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
        
        // 세그먼트(시간 단위) 재산정: 체크인 있으면 체크인→도착, 없으면 출발→도착
        if let start = checkInDate {
            segmentCount = Self.computeSegmentCount(from: start, to: arrToday)
        } else {
            segmentCount = Self.computeSegmentCount(from: depToday, to: arrToday)
        }
        
        // 현재 시각 기준으로 남은 시간/지연 텍스트 설정 + 진행도 초기화
        if now < depToday {
            remainingTimeText = Self.remainingTimeString(until: depToday)
        } else if now >= depToday && now < arrToday {
            remainingTimeText = Self.delayString(since: depToday)
        } else {
            remainingTimeText = "운행 종료"
        }
        updateProgress(now: now)
        updateRideActive(now: now)
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
    
    // 세그먼트(시간 단위) 계산: 올림 처리하여 "남은 시간 7.1시간 → 8칸"
    static func computeSegmentCount(from start: Date, to end: Date) -> Int {
        let seconds = max(0, end.timeIntervalSince(start))
        let hours = Int(ceil(seconds / 3600.0))
        return max(1, hours)
    }
    
    // 운행중 상태 갱신: 체크인 완료 + 도착 전
    private func updateRideActive(now: Date = Date()) {
        if let arr = realArrivalDate {
            isRideActive = (checkInDate != nil) && (now < arr)
        } else {
            isRideActive = false
        }
    }
    
    // MARK: - 다음날 스케줄로 전환(비상정지 등에서 사용)
    func advanceToNextSchedule() {
        let calendar = Calendar.current
        let now = Date()
        
        if let dep = realDepartureDate, let arr = realArrivalDate {
            // 1) 현재 실스케줄이 있으면 +1일 전진
            let depNext = calendar.date(byAdding: .day, value: 1, to: dep) ?? dep
            let arrNext = calendar.date(byAdding: .day, value: 1, to: arr) ?? arr
            
            realDepartureDate = depNext
            realArrivalDate = arrNext
            mode = .real
            
            // 체크인 해제 + 진행도 초기화
            checkInDate = nil
            lastProgressTick = -1
            
            // 텍스트/요일 갱신
            startTimeText = DateFormatting.hourMinuteString(from: depNext)
            endTimeText = DateFormatting.hourMinuteString(from: arrNext)
            startDayText = Self.dayAbbrev(for: depNext)
            endDayText = Self.dayAbbrev(for: arrNext)
            
            // 세그먼트 갱신
            segmentCount = Self.computeSegmentCount(from: depNext, to: arrNext)
            
            // 남은 시간/지연 문자열 갱신
            if now < depNext {
                remainingTimeText = Self.remainingTimeString(until: depNext)
            } else if now >= depNext && now < arrNext {
                remainingTimeText = Self.delayString(since: depNext)
            } else {
                remainingTimeText = "운행 종료"
            }
            
            // 진행/상태 갱신
            updateProgress(now: now)
            updateRideActive(now: now)
        } else {
            // 2) 실스케줄이 없으면 템플릿 문자열 기반으로 '내일' 스케줄 구성
            let depTemplate = DateFormatting.dateFromTimeString(startTimeText) ?? now
            let arrTemplate = DateFormatting.dateFromTimeString(endTimeText) ?? now
            
            let depHour = calendar.component(.hour, from: depTemplate)
            let depMinute = calendar.component(.minute, from: depTemplate)
            let arrHour = calendar.component(.hour, from: arrTemplate)
            let arrMinute = calendar.component(.minute, from: arrTemplate)
            
            let base = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            let depNext = calendar.date(bySettingHour: depHour, minute: depMinute, second: 0, of: base) ?? base
            var arrNext = calendar.date(bySettingHour: arrHour, minute: arrMinute, second: 0, of: base) ?? base
            if arrNext <= depNext {
                arrNext = calendar.date(byAdding: .day, value: 1, to: arrNext) ?? arrNext
            }
            
            realDepartureDate = depNext
            realArrivalDate = arrNext
            mode = .real
            
            checkInDate = nil
            lastProgressTick = -1
            
            startTimeText = DateFormatting.hourMinuteString(from: depNext)
            endTimeText = DateFormatting.hourMinuteString(from: arrNext)
            startDayText = Self.dayAbbrev(for: depNext)
            endDayText = Self.dayAbbrev(for: arrNext)
            segmentCount = Self.computeSegmentCount(from: depNext, to: arrNext)
            
            if now < depNext {
                remainingTimeText = Self.remainingTimeString(until: depNext)
            } else if now >= depNext && now < arrNext {
                remainingTimeText = Self.delayString(since: depNext)
            } else {
                remainingTimeText = "운행 종료"
            }
            
            updateProgress(now: now)
            updateRideActive(now: now)
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

//#Preview {
//    let vm = TrainTicketViewModel()
//    return TrainTicketView()
//        .environmentObject(vm)
//        .modelContainer(for: [UserSettings.self, Stats.self], inMemory: true)
//        .background(Color.gray.opacity(0.1))
//}
