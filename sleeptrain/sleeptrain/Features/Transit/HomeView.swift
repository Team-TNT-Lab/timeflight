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
        VStack(spacing: 16) {
            headerSection
                
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
        }.background(.mainContainerBackground)
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("운행 일정")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            Text(todayDateString)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
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
