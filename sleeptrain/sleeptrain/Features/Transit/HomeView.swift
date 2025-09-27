import SwiftUI
import Foundation
import SwiftData

struct HomeView: View {
    @EnvironmentObject var authManager: AuthorizationManager
    @StateObject var screenTimeManager =  ScreenTimeManager()
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
            BackgroundGradientLayer()
                .ignoresSafeArea()
            
            if isCheckInModeActive {
                mainContentSection
            } else {
                TabView {
                    mainContentSection
                        .onAppear {
                            if !authManager.isAuthorized {
                                authManager.requestAuthorization()
                            }
                            refreshAll()
                        }
                        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
                            homeViewModel.checkAndHandleFailedState(
                                remainingTimeText: trainTicketViewModel.remainingTimeText,
                                startTimeText: trainTicketViewModel.startTimeText,
                                context: modelContext
                            ) { newSleepCount in
                                trainTicketViewModel.sleepCount = newSleepCount
                            }
                            refreshAll()
                        }
                        .onChange(of: trainTicketViewModel.startTimeText) { _, _ in
                            homeViewModel.refreshDisplayDays()
                            refreshAll()
                        }
                        .onChange(of: trainTicketViewModel.remainingTimeText) { _, _ in
                            refreshAll()
                        }
                        .background {
                            BackgroundGradientLayer()
                                .ignoresSafeArea()
                        }
                        .tabItem {
                            Label("운행", systemImage: "train.side.front.car")
                        }
                    
                    RecordView()
                        .tabItem {
                            Label("기록", systemImage: "bed.double.fill")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label("설정", systemImage: "ellipsis")
                        }
                }
            }
        }
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
    
    private var mainContentSection: some View {
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
        }
        // 개별 섹션에는 별도 .background를 두지 않습니다.
    }
    
    // MARK: - Helpers
    
    func refreshAll() {
        homeViewModel.refreshTodayCheckInState(context: modelContext)
        let current = homeViewModel.getCurrentStreak(context: modelContext)
        trainTicketViewModel.sleepCount = current
    }
}
