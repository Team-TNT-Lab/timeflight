import SwiftUI
import SwiftData

struct RecordView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var trainTicketViewModel = TrainTicketViewModel()
    
    
    private var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        let startDate = Calendar.current.date(byAdding: .day, value: -23, to: Date()) ?? Date()
        let endDate = Date()
        return "\(formatter.string(from: startDate)) ~ \(formatter.string(from: endDate))"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            StreakWeekView(
                days: homeViewModel.weekDays,
                currentRemainingTime: trainTicketViewModel.remainingTimeText,
                hasCheckedInToday: homeViewModel.hasCheckedInToday,
                todayCheckInTime: homeViewModel.todayCheckInTime,
                departureTimeString: trainTicketViewModel.startTimeText
            )
            .background(Color.clear) // 투명 배경 추가했는데 작동이 안되네요...
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(completedSleepRecords) { record in
                        CompletedTrainTicketView(record: record)
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
        .background {
            BackgroundGradientLayer()
        }
        .onAppear {
            let current = homeViewModel.syncCurrentStreak(
                remainingTimeText: trainTicketViewModel.remainingTimeText,
                startTimeText: trainTicketViewModel.startTimeText
            )
            trainTicketViewModel.sleepCount = current
        }
    }
}

private extension RecordView {
    var headerSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("운행 기록")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            Text(dateRangeString)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

struct CompletedSleepRecord: Identifiable {
    let id = UUID()
    let startTime: String
    let endTime: String
    let startDay: String
    let endDay: String
    let sleepDuration: String
    let status: String
    let streakCount: Int
}

struct CompletedTrainTicketView: View {
    let record: CompletedSleepRecord
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(record.startTime)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text(record.endTime)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer().frame(height: 20)
            
            HStack(spacing: 0) {
                Text(record.startDay)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer().frame(width: 10)
                
                VStack(spacing: 0) {
                    Image(systemName: "train.side.front.car")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(10)
                }
                
                Spacer().frame(width: 10)
                
                Text(record.endDay)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 24)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.sleepDuration)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.blue)
                    
                    Text(record.status)
                        .font(.system(size: 14))
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "train.side.front.car")
                        .font(.system(size: 16))
                        .foregroundStyle(.black)
                    
                    Text("\(record.streakCount)")
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
    }
}

// Mock 데이터 넣어둠
private let completedSleepRecords = [
    CompletedSleepRecord(
        startTime: "23:30",
        endTime: "07:30",
        startDay: "MON",
        endDay: "TUE",
        sleepDuration: "8시간",
        status: "운행 완료",
        streakCount: 32
    ),
    CompletedSleepRecord(
        startTime: "23:30",
        endTime: "07:30",
        startDay: "SUN",
        endDay: "MON",
        sleepDuration: "8시간",
        status: "운행 완료",
        streakCount: 31
    ),
    CompletedSleepRecord(
        startTime: "23:30",
        endTime: "07:00",
        startDay: "SAT",
        endDay: "SUN",
        sleepDuration: "7시간 30분",
        status: "운행 완료",
        streakCount: 30
    ),
    CompletedSleepRecord(
        startTime: "23:30",
        endTime: "07:00",
        startDay: "SAT",
        endDay: "SUN",
        sleepDuration: "7시간 30분",
        status: "운행 완료",
        streakCount: 29
    )
]

#Preview {
    RecordView()
        .modelContainer(for: [UserSettings.self, Stats.self], inMemory: true)
}
