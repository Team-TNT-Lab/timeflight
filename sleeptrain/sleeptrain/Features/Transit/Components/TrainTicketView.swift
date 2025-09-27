import SwiftUI
import SwiftData

struct TrainTicketView: View {
    // MARK: - Environment 및 데이터 접근
    @EnvironmentObject var viewModel: TrainTicketViewModel
    @Query private var userSettings: [UserSettings]
    @Query private var stats: [Stats]
    
    // MARK: - 계산 프로퍼티
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
    
    private var didTrainArrive: Bool {
        let comps = viewModel.endTimeText.split(separator: ":")
        guard comps.count == 2,
              let h = Int(comps[0]),
              let m = Int(comps[1]) else {
            return false
        }
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())
        var arrivalTime = cal.date(bySettingHour: h, minute: m, second: 0, of: startOfToday)!

        if arrivalTime <= Date() {
            arrivalTime = cal.date(byAdding: .day, value: 1, to: arrivalTime)!
        }

        return Date() > arrivalTime
    }
    
    // MARK: - View Body
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
                
                // MARK: - Subviews
                VStack(alignment: .leading, spacing: 2) {
                    // 진행 바 + 기차 아이콘(GeometryReader로 너비 기반 위치 계산)
                    GeometryReader { geo in
                        let width = geo.size.width
                        let iconSize: CGFloat = 20
                        let clamped = max(0.0, min(1.0, viewModel.progress))
                        
                        ZStack(alignment: .leading) {
                            // 진행 바 배경
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 4)
                            
                            // 채워진 진행 바 (선택 사항: 진행 비율만큼 채우고 싶다면)
                            Capsule()
                                .fill(Color.blue)
                                .frame(width: max(0, width * clamped), height: 4)
                            
                            // 기차 아이콘
                            Image(systemName: "train.side.front.car")
                                .font(.system(size: iconSize))
                                .foregroundStyle(.white)
                                // 아이콘 중심이 바 위에 오도록 y를 조정
                                .position(
                                    x: max(iconSize / 2, min(width - iconSize / 2, width * clamped)),
                                    y: iconSize / 2
                                )
                        }
                    }
                    .frame(height: 24)
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
                    if viewModel.hasCheckedInToday && !didTrainArrive {
                        Text(remainingTimeToArrival(fromNow: Date(), endTimeText: viewModel.endTimeText))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.blue)
                        Text("열차 도착까지")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)
                    } else {
                        Text(viewModel.remainingTimeText)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.blue)
                        Text("열차 출발까지")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)
                    }
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
        // MARK: - onAppear / onChange / onReceive
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
    }
}


// MARK: - Mock 데이터 및 헬퍼 함수
// 목업 데이터 구조체
struct MockSchedule {
    let startTime: String
    let endTime: String
    let startDay: String
    let endDay: String
    let remainingTime: String
    let sleepCount: Int
}

// MARK: - 도착까지 남은 시간 계산(자정 넘김 고려)
private func remainingTimeToArrival(fromNow now: Date, endTimeText: String) -> String {
    let comps = endTimeText.split(separator: ":")
    guard comps.count == 2,
          let h = Int(comps[0]),
          let m = Int(comps[1]) else {
        return ""
    }
    let cal = Calendar.current
    let startOfToday = cal.startOfDay(for: now)
    var arrival = cal.date(bySettingHour: h, minute: m, second: 0, of: startOfToday) ?? now
    if arrival <= now {
        arrival = cal.date(byAdding: .day, value: 1, to: arrival) ?? arrival
    }
    let diff = cal.dateComponents([.hour, .minute], from: now, to: arrival)
    let hours = max(0, diff.hour ?? 0)
    let minutes = max(0, diff.minute ?? 0)
    if hours > 0 && minutes > 0 {
        return "\(hours)시간 \(minutes)분"
    } else if hours > 0 {
        return "\(hours)시간"
    } else {
        return "\(minutes)분"
    }
}

//#Preview {
//    let vm = TrainTicketViewModel()
//    return TrainTicketView()
//        .environmentObject(vm)
//        .modelContainer(for: [UserSettings.self, Stats.self], inMemory: true)
//        .background(Color.gray.opacity(0.1))
//}
