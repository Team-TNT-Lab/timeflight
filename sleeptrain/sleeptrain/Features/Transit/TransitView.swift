import Foundation
import SwiftData
import SwiftUI

struct TransitView: View {
    @EnvironmentObject var authManager: AuthorizationManager
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @Query private var userSettings: [UserSettings]

    @StateObject private var trainTicketViewModel = TrainTicketViewModel()
    @StateObject private var homeViewModel = HomeViewModel()
    @Environment(\.modelContext) private var modelContext
    
    @State private var isCheckInModeActive = false
    @State private var showAppUnlockToast = false
    
    private var todayDateString: String {
        DateFormatting.monthDayKoreanString()
    }
    
    // MARK: - View
    
    var body: some View {
        ZStack {
            Color.clear
                .background(.mainContainerBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                HStack {
                    Text("운행 일정")
                        .font(.mainTitle)
                        .foregroundColor(.white)
                    Text(todayDateString)
                        .font(.subTitle)
                        .foregroundColor(.white.opacity(0.6))
                    Spacer(minLength: 0)
                }.padding(.all, 12)
                
                TrainTicketView()
                    .environmentObject(trainTicketViewModel)
                    .padding(.horizontal, 16)
                
                if !homeViewModel.hasCheckedInToday {
                    streakSection
                }
                
                CheckInBannerView(
                    remainingTimeText: trainTicketViewModel.remainingTimeText,
                    startTimeText: trainTicketViewModel.startTimeText,
                    endTimeText: trainTicketViewModel.endTimeText,
                    hasCheckedInToday: homeViewModel.hasCheckedInToday,
                    performCheckIn: {
                        homeViewModel.performCheckIn(
                            remainingTimeText: trainTicketViewModel.remainingTimeText,
                            startTimeText: trainTicketViewModel.startTimeText,
                            context: modelContext
                        ) { newSleepCount in
                            trainTicketViewModel.sleepCount = newSleepCount
                            isCheckInModeActive = true
                        }
                    },
                    performCheckOut: {
                        homeViewModel.performCheckOut()
                        isCheckInModeActive = false
                    },
                    isGuestUser: userSettings.first?.isGuestUser ?? true
                )
            }
        }
    }
    
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            StreakWeekView(days: homeViewModel.weekDays)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Helpers
    
    func refreshAll() {
        homeViewModel.refreshTodayCheckInState(context: modelContext)
        let current = homeViewModel.getCurrentStreak(context: modelContext)
        trainTicketViewModel.sleepCount = current
    }
}
