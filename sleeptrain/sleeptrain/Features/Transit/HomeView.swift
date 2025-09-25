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
    
    // 임시 사용(3분) 관련 상태
    @State private var showTemporaryUseAlert = false
    @State private var hasUsedTemporaryUseThisRide = false
    @State private var temporaryUnlockTask: Task<Void, Never>?
    
    private var todayDateString: String {
        DateFormatting.monthDayKoreanString()
    }
    
    private var canTapTemporaryUse: Bool {
        trainTicketViewModel.isRideActive && !hasUsedTemporaryUseThisRide
    }

    var body: some View {
        TabView {
            mainTab
                .toolbar(trainTicketViewModel.isRideActive ? .hidden : .visible, for: .tabBar)
                .tabItem {
                    Label("운행", systemImage: "train.side.front.car")
                }
            
            recordTab
                .toolbar(trainTicketViewModel.isRideActive ? .hidden : .visible, for: .tabBar)
                .tabItem {
                    Label("기록", systemImage: "bed.double.fill")
                }

            settingsTab
                .toolbar(trainTicketViewModel.isRideActive ? .hidden : .visible, for: .tabBar)
                .tabItem {
                    Label("설정", systemImage: "ellipsis")
                }
        }
        // 운행 시작/종료에 따른 1회 사용 상태/타이머 관리
        .onChange(of: trainTicketViewModel.isRideActive) { _, isActive in
            if isActive {
                hasUsedTemporaryUseThisRide = false
            } else {
                temporaryUnlockTask?.cancel()
                temporaryUnlockTask = nil
                screenTimeManager.lockApps(with: screenTimeManager.selection)
            }
        }
        // Alert: 확인 시 3분간 임시 해제(운행 중 1회만)
        .alert("앱 잠시 사용하기", isPresented: $showTemporaryUseAlert) {
            Button("취소", role: .cancel) {}
            Button("사용하기", role: .none) {
                guard canTapTemporaryUse else { return }
                hasUsedTemporaryUseThisRide = true
                // 3분간 임시 해제
                screenTimeManager.unlockApps()
                temporaryUnlockTask?.cancel()
                temporaryUnlockTask = Task {
                    try? await Task.sleep(nanoseconds: 180 * 1_000_000_000)
                    if Task.isCancelled { return }
                    screenTimeManager.lockApps(with: screenTimeManager.selection)
                }
            }
        } message: {
            Text("비행중 등 한 번, 3분간 사용 가능해요.")
        }
    }
}

private extension HomeView {
    // MARK: - 탭 분리(타입체커 부담 완화)
    var mainTab: some View {
        VStack(spacing: 16) {
            if !trainTicketViewModel.isRideActive {
                headerSection
            }
            
            TrainTicketView()
                .environmentObject(trainTicketViewModel)
                .padding(.horizontal, 16)
            
            if !homeViewModel.hasCheckedInToday {
                streakSection
            }
            
            Spacer()
            
            bannerView
                .padding(.bottom, 16)
            
            temporaryUseButton
        }
        .scrollIndicators(.hidden)
        .padding(.bottom, 16)
        .background {
            BackgroundGradientLayer()
                .ignoresSafeArea()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            // 매분마다 2시간 이상 지연 상태 체크
            homeViewModel.checkAndHandleFailedState(
                remainingTimeText: trainTicketViewModel.remainingTimeText,
                startTimeText: trainTicketViewModel.startTimeText,
                context: modelContext
            ) { newSleepCount in
                trainTicketViewModel.sleepCount = newSleepCount
            }
            // 오늘 체크인 상태를 저장소에서 동기화
            homeViewModel.refreshTodayCheckInState(context: modelContext)
            // 진행 바의 체크인 기준 시간 동기화
            trainTicketViewModel.setCheckInDate(homeViewModel.todayCheckInTime)
        }
        .task {
            if !authManager.isAuthorized {
                authManager.requestAuthorization()
            }
            homeViewModel.refreshDisplayDays()
            
            homeViewModel.backfillMissedDays(context: modelContext)
            
            homeViewModel.checkAndHandleFailedState(
                remainingTimeText: trainTicketViewModel.remainingTimeText,
                startTimeText: trainTicketViewModel.startTimeText,
                context: modelContext
            ) { newSleepCount in
                trainTicketViewModel.sleepCount = newSleepCount
            }
            
            trainTicketViewModel.sleepCount = homeViewModel.getCurrentStreak(context: modelContext)
            
            homeViewModel.refreshTodayCheckInState(context: modelContext)
            
            trainTicketViewModel.setCheckInDate(homeViewModel.todayCheckInTime)
        }
        .onChange(of: trainTicketViewModel.remainingTimeText) { _, _ in
            trainTicketViewModel.sleepCount = homeViewModel.getCurrentStreak(context: modelContext)
            homeViewModel.refreshTodayCheckInState(context: modelContext)
            trainTicketViewModel.setCheckInDate(homeViewModel.todayCheckInTime)
        }
        .onChange(of: trainTicketViewModel.startTimeText) { _, _ in
            homeViewModel.refreshDisplayDays()
            trainTicketViewModel.sleepCount = homeViewModel.getCurrentStreak(context: modelContext)
            homeViewModel.refreshTodayCheckInState(context: modelContext)
            trainTicketViewModel.setCheckInDate(homeViewModel.todayCheckInTime)
        }
        .onChange(of: homeViewModel.todayCheckInTime) { _, newValue in
            trainTicketViewModel.setCheckInDate(newValue)
        }
    }
    
    var recordTab: some View {
        RecordView()
            .background {
                BackgroundGradientLayer()
                    .ignoresSafeArea()
            }
    }
    
    var settingsTab: some View {
        SettingsView()
            .background {
                BackgroundGradientLayer()
                    .ignoresSafeArea()
            }
    }
    
    // MARK: - 쪼갠 서브뷰들
    var bannerView: some View {
        let remaining = trainTicketViewModel.remainingTimeText
        let start = trainTicketViewModel.startTimeText
        let end = trainTicketViewModel.endTimeText
        let checked = homeViewModel.hasCheckedInToday
        
        return CheckInBannerView(
            remainingTimeText: remaining,
            startTimeText: start,
            endTimeText: end,
            hasCheckedInToday: checked,
            performCheckIn: { handlePerformCheckIn() },
            performEmergencyStop: { handleEmergencyStop() }
        )
    }
    
    var temporaryUseButton: some View {
        Group {
            if trainTicketViewModel.isRideActive {
                VStack(spacing: 0) {
                    Text("앱 잠시 사용하기")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(canTapTemporaryUse ? .white : .white.opacity(0.4))
                        .onTapGesture {
                            if canTapTemporaryUse {
                                showTemporaryUseAlert = true
                            }
                        }
                        .accessibilityAddTraits(.isButton)
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
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
            StreakWeekView(days: homeViewModel.weekDays)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Actions (분리하여 타입체커 부담 완화)
    func handlePerformCheckIn() {
        homeViewModel.performCheckIn(
            taggedAt: Date(),
            remainingTimeText: trainTicketViewModel.remainingTimeText,
            startTimeText: trainTicketViewModel.startTimeText,
            context: modelContext
        ) { newSleepCount in
            trainTicketViewModel.sleepCount = newSleepCount
            trainTicketViewModel.setCheckInDate(homeViewModel.todayCheckInTime ?? Date())
        }
    }
    
    func handleEmergencyStop() {

        homeViewModel.emergencyStopToday(context: modelContext) { newSleepCount in
            trainTicketViewModel.sleepCount = newSleepCount
        }
        trainTicketViewModel.setCheckInDate(nil)
        trainTicketViewModel.updateTime()
        
        trainTicketViewModel.advanceToNextSchedule()
        
        temporaryUnlockTask?.cancel()
        temporaryUnlockTask = nil
        screenTimeManager.lockApps(with: screenTimeManager.selection)
    }
}
