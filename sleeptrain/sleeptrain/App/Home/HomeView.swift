//
//  HomeView.swift
//  timeflight
//
//  Created by bishoe01 on 9/18/25.
//

import SwiftUI

// MARK: - 공용 배경 그라데이션 뷰 (Home/기록 등에서 재사용)
fileprivate struct BackgroundGradientLayer: View {
    var body: some View {
        let cssAngle = 177.0
        let r = cssAngle * .pi / 180.0
        let dx = sin(r)
        let dy = -cos(r)
        
        let start = UnitPoint(x: 0.5 - 0.5 * dx, y: 0.5 - 0.5 * dy)
        let end   = UnitPoint(x: 0.5 + 0.5 * dx, y: 0.5 + 0.5 * dy)
        
        let stops: [Gradient.Stop] = [
            .init(color: Color(red: 37.0/255.0, green: 61.0/255.0, blue: 87.0/255.0), location: 0.0452),
            .init(color: Color(red: 16.0/255.0, green: 41.0/255.0, blue: 68.0/255.0), location: 0.3129),
            .init(color: .black, location: 0.9638)
        ]
        
        return Rectangle()
            .fill(LinearGradient(gradient: Gradient(stops: stops), startPoint: start, endPoint: end))
            .ignoresSafeArea()
    }
}

// MARK: - 시간 파싱/포맷 유틸 (분리 가능)
// TODO: 다른 파일로 분리 시 fileprivate → internal 또는 유틸 타입의 static 메서드로 전환 필요.

/// 남은 시간 문자열("1시간 30분", "지연 15분" 등)을 분 단위(Int)로 변환
/// 지연된 경우 음수 값을 반환하며, 해석 불가한 경우 nil을 반환
fileprivate func parseRemainingTimeToMinutes(_ timeString: String) -> Int? {
    let isDelayed = timeString.contains("지연")

    var totalMinutes = 0
    let components = timeString.components(separatedBy: " ")

    for component in components {
        if component.contains("시간") {
            let hourString = component
                .replacingOccurrences(of: "지연", with: "")
                .replacingOccurrences(of: "시간", with: "")
            if let hours = Int(hourString) {
                totalMinutes += hours * 60
            }
        } else if component.contains("분") {
            let minuteString = component
                .replacingOccurrences(of: "분", with: "")
            if let minutes = Int(minuteString) {
                totalMinutes += minutes
            }
        }
    }

    // 숫자 토큰이 전혀 없을 경우, 문자열에서 숫자만 추출하여 첫 번째 값을 사용(예: "0분")
    if totalMinutes == 0 {
        let numbers = timeString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        if let first = numbers.first {
            totalMinutes = first
        }
    }

    // 여전히 숫자를 찾지 못했고 "0"도 포함하지 않는 경우 해석 불가로 처리
    if totalMinutes == 0 && !timeString.contains("0") {
        return nil
    }

    return isDelayed ? -totalMinutes : totalMinutes
}

/// 출발 시간 문자열("HH:mm")을 오늘 날짜의 Date 객체로 변환
/// 파싱에 실패하면 오늘 23:30을 반환
fileprivate func parseDepartureTime(_ timeString: String) -> Date {
    let calendar = Calendar.current
    let today = Date()

    let components = timeString.split(separator: ":")
    guard components.count == 2,
          let hour = Int(components[0]),
          let minute = Int(components[1]) else {

        return calendar.date(bySettingHour: 23, minute: 30, second: 0, of: today) ?? today
    }

    return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? today
}

// MARK: - 체크인 상태 타입 (분리 가능)
enum CheckInStatus {
    case notReached
    case available
    case completed
    case lateCompleted
    case failed
    case future
}

// MARK: - StreakDay + 체크인 상태 로직 (분리 가능)
// NOTE: checkInTime은 Mock 시나리오용입니다. #if DEBUG로 분리하거나 Mock 전용 파일로 이동 예정.

extension StreakDay {
    // 실제 체크인 시간 (Mock 데이터용) - 일관된 데이터를 위해 고정
    var checkInTime: Date? {
        // Mock 데이터: 일부 날짜에 체크인 시간 시뮬레이션
        guard isCompleted else { return nil }
        
        let calendar = Calendar.current
        let trainDepartureTime = calendar.date(bySettingHour: 23, minute: 30, second: 0, of: date)!
        
        // 날짜 기반으로 일관된 체크인 시간 생성 (랜덤이 아닌 고정)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let checkInScenarios: [TimeInterval] = [
            -25 * 60,    // 25분 전 (정상)
            -10 * 60,    // 10분 전 (정상)
            5 * 60,      // 5분 지연 (정상)
            20 * 60,     // 20분 지연 (정상)
            45 * 60,     // 45분 지연 (늦은 체크인)
            90 * 60,     // 90분 지연 (늦은 체크인)
            150 * 60     // 150분 지연 (실패)
        ]
        
        // 날짜 기반으로 일관된 인덱스 선택
        let scenarioIndex = dayOfYear % checkInScenarios.count
        let selectedOffset = checkInScenarios[scenarioIndex]
        
        return calendar.date(byAdding: .second, value: Int(selectedOffset), to: trainDepartureTime)
    }
    
    var trainDepartureTime: Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 23, minute: 30, second: 0, of: date) ?? date
    }
    
    /// 현재 시나리오에 따라 해당 날짜의 체크인 상태를 판별
    func getCheckInStatus(
        currentRemainingTime: String = "20분",
        hasCheckedInToday: Bool = true,
        todayCheckInTime: Date? = nil,
        departureTimeString: String = "23:30",
        parseRemainingTime: (String) -> Int?,
        parseDepartureTime: (String) -> Date
    ) -> CheckInStatus {
        let now = Date()
        let calendar = Calendar.current
        
        // 미래 날짜
        if calendar.startOfDay(for: date) > calendar.startOfDay(for: now) {
            return .future
        }
        
        // 실제 출발 시간을 파라미터 기반으로 계산
        let actualDepartureTime = parseDepartureTime(departureTimeString)
        
        // 오늘 날짜 처리
        if calendar.isDateInToday(date) {
            // 실제 체크인이 되었다면 체크인 시간을 기반으로 상태 결정
            if hasCheckedInToday, let actualCheckIn = todayCheckInTime {
                let timeDifference = actualCheckIn.timeIntervalSince(actualDepartureTime)
                
                if timeDifference >= -30 * 60 && timeDifference <= 30 * 60 {
                    return .completed
                } else if timeDifference > 30 * 60 && timeDifference <= 120 * 60 {
                    return .lateCompleted
                } else {
                    return .failed
                }
            }
            
            // 아직 체크인 안 했을 때 - TrainTicketView의 남은 시간 기반
            guard let remainingMinutes = parseRemainingTime(currentRemainingTime) else {
                return .notReached
            }
            
            if remainingMinutes > 30 {
                return .notReached
            } else if remainingMinutes < 0 && remainingMinutes >= -120 {
                return .available
            } else if remainingMinutes >= -30 {
                return .available
            } else {
                return .failed
            }
        }
        
        // 과거 날짜 - 실제 체크인 시간을 기반으로 상태 결정
        guard let actualCheckIn = checkInTime else {
            return .failed
        }
        
        let timeDifference = actualCheckIn.timeIntervalSince(actualDepartureTime)
        
        if timeDifference >= -30 * 60 && timeDifference <= 30 * 60 {
            return .completed
        } else if timeDifference > 30 * 60 && timeDifference <= 120 * 60 {
            return .lateCompleted
        } else {
            return .failed
        }
    }
}

// MARK: - 메인 뷰 (HomeView)

struct HomeView: View {
    @EnvironmentObject var authManager: AuthorizationManager
    @EnvironmentObject var screenTimeManager: ScreenTimeManager

    @StateObject private var nfcScanManager = NFCManager()
    @StateObject private var trainTicketViewModel = TrainTicketViewModel()
    @State private var weekDays: [StreakDay] = StreakDay.extendedStreakMock()
    @State private var hasCheckedInToday = false
    @State private var todayCheckInTime: Date?
    
    // 오늘 날짜 "M월 d일" 포맷
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: Date())
    }

    private func formatDuration(minutes: Int) -> String {
        let m = max(0, abs(minutes))
        let h = m / 60
        let min = m % 60
        if h > 0 && min > 0 {
            return "\(h)시간 \(min)분"
        } else if h > 0 {
            return "\(h)시간"
        } else {
            return "\(min)분"
        }
    }

    /// 다음 수면 시간(출발 시간, 다음날)까지 남은 분을 계산
    private func minutesUntilNextSleepTime() -> Int {
        let now = Date()
        let calendar = Calendar.current
        let todayStart = parseDepartureTime(trainTicketViewModel.startTimeText)
        let nextDayStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart
        let diff = Int(nextDayStart.timeIntervalSince(now) / 60)
        return max(diff, 0)
    }


    private var infoBannerText: String {
        guard let remainingMinutes = parseRemainingTimeToMinutes(trainTicketViewModel.remainingTimeText) else {
            return "열차 출발 정보를 불러오는 중이에요"
        }
        if remainingMinutes >= 1 {
            return "열차 출발까지 \(formatDuration(minutes: remainingMinutes)) 남았어요"
        } else if remainingMinutes >= -5 {
            return "열차가 출발할 시간이에요."
        } else if remainingMinutes >= -119 {
            return "열차 출발이 \(formatDuration(minutes: -remainingMinutes)) 지연됐어요"
        } else {
            let untilNext = minutesUntilNextSleepTime()
            return "열차 출발까지 \(formatDuration(minutes: untilNext)) 남았어요"
        }
    }
    
    private var infoSubText: String? {
        guard let remainingMinutes = parseRemainingTimeToMinutes(trainTicketViewModel.remainingTimeText) else {
            return nil
        }
        if remainingMinutes > 30 {
            return "미리 숙면에 취할 준비를 해주면 좋아요"
        } else if remainingMinutes >= 1 {
            return "지금부터는 미리 출발이 가능해요"
        } else if remainingMinutes >= -5 {
            return "지금 출발해야 최상의 수면을 할 수 있어요"
        } else if remainingMinutes >= -30 {
            let lost = abs(remainingMinutes)
            return "내일 아침의 \(lost)분이 사라지면 너무 슬플 거예요"
        } else if remainingMinutes >= -119 {
            return "2시간 넘게 지연되면 연속 기록이 사라져요"
        } else {
            return "좋은 하루 보내세요!"
        }
    }

    private var canCheckIn: Bool {
        guard let remainingMinutes = parseRemainingTimeToMinutes(trainTicketViewModel.remainingTimeText) else {
            return false
        }
        return (remainingMinutes <= 30 || remainingMinutes < 0) && !hasCheckedInToday
    }


    private func performCheckIn() {
        guard canCheckIn else { return }
        hasCheckedInToday = true
        todayCheckInTime = calculateCheckInTimeForCurrentScenario()
        if let todayIndex = weekDays.firstIndex(where: { $0.isToday }) {
            weekDays[todayIndex] = StreakDay(date: weekDays[todayIndex].date, isCompleted: true)
        }
        updateSleepCountBasedOnStreak()
    }


    private func updateSleepCountBasedOnStreak() {
        let today = Date()
        let calendar = Calendar.current
        if let todayStreak = weekDays.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            let checkInResult = todayStreak.getCheckInStatus(
                currentRemainingTime: trainTicketViewModel.remainingTimeText,
                hasCheckedInToday: hasCheckedInToday,
                todayCheckInTime: todayCheckInTime,
                departureTimeString: trainTicketViewModel.startTimeText,
                parseRemainingTime: parseRemainingTimeToMinutes,
                parseDepartureTime: parseDepartureTime
            )
            switch checkInResult {
            case .failed:
                trainTicketViewModel.sleepCount = 0
            case .completed, .lateCompleted:
                let currentStreak = calculateCurrentStreak()
                trainTicketViewModel.sleepCount = currentStreak
            default:
                break
            }
        }
    }

    /// 연속 체크인 성공 일수 계산
    private func calculateCurrentStreak() -> Int {
        let today = Date()
        let calendar = Calendar.current
        var streak = 0
        let sortedDays = weekDays.sorted { $0.date > $1.date }
        for day in sortedDays {
            if calendar.startOfDay(for: day.date) > calendar.startOfDay(for: today) {
                continue
            }
            let status = day.getCheckInStatus(
                currentRemainingTime: trainTicketViewModel.remainingTimeText,
                hasCheckedInToday: hasCheckedInToday,
                todayCheckInTime: todayCheckInTime,
                departureTimeString: trainTicketViewModel.startTimeText,
                parseRemainingTime: parseRemainingTimeToMinutes,
                parseDepartureTime: parseDepartureTime
            )
            switch status {
            case .completed, .lateCompleted:
                streak += 1
            case .failed:
                break
            case .notReached, .available:
                if calendar.isDateInToday(day.date) {
                    continue
                } else {
                    break
                }
            default:
                continue
            }
        }
        return streak
    }

    /// 남은 시간과 출발 시간을 기반으로 현재 시나리오의 체크인 시간 계산(데모용)
    private func calculateCheckInTimeForCurrentScenario() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let departureTime = parseDepartureTime(trainTicketViewModel.startTimeText)
        switch trainTicketViewModel.remainingTimeText {
        case "1시간":
            return calendar.date(byAdding: .minute, value: -60, to: departureTime) ?? today
        case "2시간 30분":
            return calendar.date(byAdding: .minute, value: -150, to: departureTime) ?? today
        case "30분":
            return calendar.date(byAdding: .minute, value: -30, to: departureTime) ?? today
        case "지연 15분":
            return calendar.date(byAdding: .minute, value: 15, to: departureTime) ?? today
        case "지연 45분":
            return calendar.date(byAdding: .minute, value: 45, to: departureTime) ?? today
        case "지연 2시간 30분":
            return calendar.date(byAdding: .minute, value: 150, to: departureTime) ?? today
        default:
            return today
        }
    }

    var body: some View {
        TabView {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("운행 일정")
                            .font(.custom("AppleSDGothicNeo-Bold", size: 29))
                            .foregroundColor(.white)
                        Text(todayDateString)
                            .font(.custom("AppleSDGothicNeo-Bold", size: 19))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // 티켓 카드
                    TrainTicketView()
                        .environmentObject(trainTicketViewModel)
                        .padding(.horizontal, 16)
                        .onTapGesture {
                            hasCheckedInToday = false
                            todayCheckInTime = nil
                        }

                    // 주간 스트릭
                    VStack(alignment: .leading, spacing: 24) {
                        StreakWeekView(
                            days: weekDays,
                            currentRemainingTime: trainTicketViewModel.remainingTimeText,
                            hasCheckedInToday: hasCheckedInToday,
                            todayCheckInTime: todayCheckInTime,
                            departureTimeString: trainTicketViewModel.startTimeText
                        )
                    }
                    .padding(.horizontal, 16)

                    // 안내 문구 + 버튼
                    VStack(spacing: 4) {
                        Text(infoBannerText)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(9.6)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 90)

                        if let sub = infoSubText {
                            Text(sub)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .lineSpacing(6.4)
                                .frame(maxWidth: .infinity)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button(action: performCheckIn) {
                            Text(hasCheckedInToday ? "비상 정지하기" : canCheckIn ? "지금 출발하기" : "지금 출발하기")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(canCheckIn && !hasCheckedInToday ? Color.white : Color.gray.opacity(0.3))
                                .foregroundColor(canCheckIn && !hasCheckedInToday ? .black : .secondary)
                                .cornerRadius(99)
                        }
                        .disabled(!canCheckIn || hasCheckedInToday)
                        .padding(.top, 90)
                        .padding(.horizontal, 16)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .safeAreaPadding(.bottom, 36)
            .onAppear {
                let currentStreak = calculateCurrentStreak()
                trainTicketViewModel.sleepCount = currentStreak
            }
            .task {
                if !authManager.isAuthorized {
                    authManager.requestAuthorization()
                }
            }
            .onChange(of: trainTicketViewModel.remainingTimeText) { _ in
                hasCheckedInToday = false
                todayCheckInTime = nil
                let currentStreak = calculateCurrentStreak()
                trainTicketViewModel.sleepCount = currentStreak
            }
            .onChange(of: trainTicketViewModel.startTimeText) { _ in
                // TODO: 추가 동기화가 필요하면 구현, 아니면 제거
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                // TODO: 주기적으로 반영할 상태가 없으면 제거
            }
            .background {
                BackgroundGradientLayer()
            }
            .tabItem {
                Label("비행", systemImage: "airplane")
            }
            
            StreakView()
                .tabItem {
                    Label("기록", systemImage: "bed.double.fill")
                }

            // 설정 탭
            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "ellipsis")
                }
        }
    }
}

// MARK: - 연속 체크인 진행 뷰 (분리 가능)

struct StreakWeekView: View {
    let days: [StreakDay]
    let currentRemainingTime: String
    let hasCheckedInToday: Bool
    let todayCheckInTime: Date?
    let departureTimeString: String

    @State private var currentWeekOffset = 0
    
    // 오늘 요일 인덱스 (월=0 ... 일=6) - 헤더 강조는 현재 페이지와 무관하게 유지
    private var todayWeekdayHeaderIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }
    
    var body: some View {
        VStack(spacing: 5) {
            // 요일 헤더: 오늘 요일에 회색 원 강조 (페이징과 무관하게 항상 같은 요일에 표시)
            HStack(spacing: 0) {
                let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, weekday in
                    let isToday = index == todayWeekdayHeaderIndex
                    ZStack {
                        if isToday {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 22, height: 22)
                        }
                        Text(weekday)
                            .font(.system(size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(isToday ? .white : .white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                }
            }
            
            // 스크롤 가능한 날짜와 상태 (주 단위 페이징)
            TabView(selection: $currentWeekOffset) {
                ForEach(Array(visibleWeekGroups.enumerated()), id: \.offset) { weekIndex, week in
                    HStack(spacing: 0) {
                        ForEach(week) { day in
                            DayCellView(
                                day: day,
                                currentRemainingTime: currentRemainingTime,
                                hasCheckedInToday: hasCheckedInToday,
                                todayCheckInTime: todayCheckInTime,
                                departureTimeString: departureTimeString
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .tag(weekIndex)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 80)
            .onAppear {
                currentWeekOffset = todayWeekIndex
            }
        }
    }
    
    private var todayWeekIndex: Int {
        visibleWeekGroups.firstIndex { week in
            week.contains { $0.isToday }
        } ?? 0
    }
    
    private var weekGroups: [[StreakDay]] {
        stride(from: 0, to: days.count, by: 7).map { startIndex in
            let endIndex = min(startIndex + 7, days.count)
            var week = Array(days[startIndex..<endIndex])
            
            while week.count < 7 {
                week.append(StreakDay(date: Date.distantPast, isCompleted: false))
            }
            return week
        }
    }
    
    // 미래 주를 제외한 실제 표시용 주 배열
    private var visibleWeekGroups: [[StreakDay]] {
        weekGroups.filter { !isFutureWeek($0) }
    }

    private func calculateProgress(for week: [StreakDay]) -> (progress: CGFloat, todayIndex: Int) {
        let realDays = week.filter { $0.date != Date.distantPast }
        guard !realDays.isEmpty else { return (0, 0) }
        
        if let todayIndex = week.firstIndex(where: { $0.isToday }) {
            let progress = (CGFloat(todayIndex) + 0.5) / 7.0
            return (progress, todayIndex)
        } else {
            if let lastCompletedIndex = week.lastIndex(where: { $0.isCompleted && $0.date != Date.distantPast }) {
                let progress = (CGFloat(lastCompletedIndex) + 0.5) / 7.0
                return (progress, lastCompletedIndex)
            } else {
                return (0, 0)
            }
        }
    }
    
    // 해당 주가 "미래 주(오늘 이후만 존재)"인지 판별
    private func isFutureWeek(_ week: [StreakDay]) -> Bool {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let realDays = week.filter { $0.date != Date.distantPast }
        guard !realDays.isEmpty else { return false }
        
        // 오늘을 포함하면 미래 주가 아님
        if realDays.contains(where: { calendar.isDateInToday($0.date) }) {
            return false
        }
        
        // 주 내 가장 이른 날짜가 오늘 이후면 "미래 주"
        let earliest = realDays.map { calendar.startOfDay(for: $0.date) }.min()!
        return earliest > todayStart
    }
}

// MARK: - 개별 요일 셀 뷰 (분리 가능)

/// 연속 체크인 주간 뷰에서 개별 날짜 셀을 표시
/// 날짜 숫자와 체크인 상태 아이콘을 보여줌
/// NOTE: 상태 계산은 전역 파서 함수(parseRemainingTimeToMinutes/parseDepartureTime)에 의존
private struct DayCellView: View {
    let day: StreakDay
    let currentRemainingTime: String
    let hasCheckedInToday: Bool
    let todayCheckInTime: Date?
    let departureTimeString: String
    
    var body: some View {
        VStack(spacing: 4) {
            if day.date != Date.distantPast {
                Text("\(Calendar.current.component(.day, from: day.date))")
                    .font(.system(size: 14))
                    .fontWeight(day.isToday ? .semibold : .regular)
                    .foregroundColor(.white)
            } else {
                Text(" ")
                    .font(.system(size: 14))
            }
            
            if day.date != Date.distantPast {
                iconView(for: status)
            } else {
                Spacer()
                    .frame(width: 35, height: 35)
            }
        }
    }
    
    private var status: CheckInStatus {
        day.getCheckInStatus(
            currentRemainingTime: currentRemainingTime,
            hasCheckedInToday: hasCheckedInToday,
            todayCheckInTime: todayCheckInTime,
            departureTimeString: departureTimeString,
            parseRemainingTime: parseRemainingTimeToMinutes,
            parseDepartureTime: parseDepartureTime
        )
    }
    
    @ViewBuilder
    private func iconView(for status: CheckInStatus) -> some View {
        switch status {
        case .completed:
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 35, height: 35)
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
            }
        case .lateCompleted:
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: 35, height: 35)
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
            }
        case .failed:
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: 35, height: 35)
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
            }
        case .available:
            ZStack {
                Circle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: 35, height: 35)
                Circle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 33, height: 33)
            }
        case .notReached, .future:
            Circle()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 35, height: 35)
        }
    }
}


// MARK: - 설정 화면 Placeholder
struct SettingsView: View {
    var body: some View {
        Text("설정 화면")
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                BackgroundGradientLayer()
            }
    }
}


struct StreakView: View {
    var body: some View {
        Text("기록 화면")
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                BackgroundGradientLayer()
            }
    }
}
