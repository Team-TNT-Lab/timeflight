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
    @Query private var userSettings: [UserSettings]

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
                                startTimeText: trainTicketViewModel.startTimeText
                            ) { newSleepCount in
                                trainTicketViewModel.sleepCount = newSleepCount
                            }
                        },
                        isGuestUser: userSettings.first?.isGuestUser ?? true
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
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
                // 매분마다 2시간 이상 지연 상태 체크 및 sleepCount 업데이트
                homeViewModel.checkAndHandleFailedState(
                    remainingTimeText: trainTicketViewModel.remainingTimeText,
                    startTimeText: trainTicketViewModel.startTimeText
                ) { newSleepCount in
                    trainTicketViewModel.sleepCount = newSleepCount
                }
            }
            .task {
                if !authManager.isAuthorized {
                    authManager.requestAuthorization()
                }
            }
            .onChange(of: trainTicketViewModel.remainingTimeText) { _, _ in
                // 시나리오 변경 시 오늘 체크인 초기화 및 스트릭 재계산
                homeViewModel.resetForScenarioChange()
                let current = homeViewModel.syncCurrentStreak(
                    remainingTimeText: trainTicketViewModel.remainingTimeText,
                    startTimeText: trainTicketViewModel.startTimeText
                )
                trainTicketViewModel.sleepCount = current
            }
            .onChange(of: trainTicketViewModel.startTimeText) { _, _ in
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

private extension HomeView {
    var headerSection: some View {
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
