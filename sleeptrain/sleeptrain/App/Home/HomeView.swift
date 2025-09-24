//
//  HomeView.swift
//
//
//  Created by bishoe01 on 9/18/25.
//

import SwiftUI
import Foundation

struct HomeView: View {
    @EnvironmentObject var authManager: AuthorizationManager
    @EnvironmentObject var screenTimeManager: ScreenTimeManager

    @StateObject private var trainTicketViewModel = TrainTicketViewModel()
    @StateObject private var homeViewModel = HomeViewModel()
    
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
                    
                    streakSection
                    

                    CheckInBannerView(
                        remainingTimeText: trainTicketViewModel.remainingTimeText,
                        startTimeText: trainTicketViewModel.startTimeText,
                        hasCheckedInToday: homeViewModel.hasCheckedInToday,
                        performCheckIn: {
                            homeViewModel.performCheckIn(
                                remainingTimeText: trainTicketViewModel.remainingTimeText,
                                startTimeText: trainTicketViewModel.startTimeText
                            ) { newSleepCount in
                                trainTicketViewModel.sleepCount = newSleepCount
                            }
                        }
                    )
                }
            }
            .scrollIndicators(.hidden)
            .safeAreaPadding(.bottom, 36)
            .onAppear {
                let current = homeViewModel.syncCurrentStreak(
                    remainingTimeText: trainTicketViewModel.remainingTimeText,
                    startTimeText: trainTicketViewModel.startTimeText
                )
                trainTicketViewModel.sleepCount = current
            }
            .task {
                if !authManager.isAuthorized {
                    authManager.requestAuthorization()
                }
            }
            .onChange(of: trainTicketViewModel.remainingTimeText) { _ in
                // 시나리오 변경 시 오늘 체크인 초기화 및 스트릭 재계산
                homeViewModel.resetForScenarioChange()
                let current = homeViewModel.syncCurrentStreak(
                    remainingTimeText: trainTicketViewModel.remainingTimeText,
                    startTimeText: trainTicketViewModel.startTimeText
                )
                trainTicketViewModel.sleepCount = current
            }
            .onChange(of: trainTicketViewModel.startTimeText) { _ in
                // 출발 시각 변경 시 스트릭/상태 동기화
                let current = homeViewModel.syncCurrentStreak(
                    remainingTimeText: trainTicketViewModel.remainingTimeText,
                    startTimeText: trainTicketViewModel.startTimeText
                )
                trainTicketViewModel.sleepCount = current
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
