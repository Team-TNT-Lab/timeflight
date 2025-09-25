//
//  HomeView.swift
//
//
//  Created by bishoe01 on 9/18/25.
//

import SwiftUI
import Foundation
import SwiftData

struct HomeView: View {
    @EnvironmentObject var authManager: AuthorizationManager
    @StateObject var screenTimeManager =  ScreenTimeManager()
    @StateObject private var nfcScanManager = NFCManager()

    @StateObject private var trainTicketViewModel = TrainTicketViewModel()
    @StateObject private var homeViewModel = HomeViewModel()
    
    @Environment(\.modelContext) private var modelContext
    
    private var todayDateString: String {
        DateFormatting.monthDayKoreanString()
    }

    var body: some View {
        TabView {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    
                    TrainTicketView()
                        .environmentObject(trainTicketViewModel)
                        .padding(.horizontal, 16)
                        .onTapGesture {
                            homeViewModel.resetTodayCheckIn()
                        }
                    
                    // hasCheckedInToday가 false일 때만 streakSection 표시
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
                            }
                        }
                    )
                }
            }
            .scrollIndicators(.hidden)
            .safeAreaPadding(.bottom, 36)
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
                // 매분마다 2시간 이상 지연 상태 체크
                homeViewModel.checkAndHandleFailedState(
                    remainingTimeText: trainTicketViewModel.remainingTimeText,
                    startTimeText: trainTicketViewModel.startTimeText,
                    context: modelContext
                ) { newSleepCount in
                    trainTicketViewModel.sleepCount = newSleepCount
                }
            }
            .task {
                if !authManager.isAuthorized {
                    authManager.requestAuthorization()
                }
            }
            // Mock 기반 동기화는 제거합니다. Stats가 단일 소스이며,
            // 체크인/2시간 초과 로직에서 Stats가 갱신됩니다.
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

            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "ellipsis")
                }
        }
    }
}

private extension HomeView {
    var headerSection: some View {
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
    }
    
    var streakSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            StreakWeekView(
                days: homeViewModel.weekDays,
                currentRemainingTime: trainTicketViewModel.remainingTimeText,
                hasCheckedInToday: homeViewModel.hasCheckedInToday,
                todayCheckInTime: homeViewModel.todayCheckInTime,
                departureTimeString: trainTicketViewModel.startTimeText
            )
        }
        .padding(.horizontal, 16)
    }
}
