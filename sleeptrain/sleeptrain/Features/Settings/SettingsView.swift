//
//  SettingsView.swift
//  sleeptrain
//
//  Created by Dean_SSONG on 9/24/25.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    @State private var navigationPath = NavigationPath()
    @State private var showingSleepTimeAlert: Bool = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                Section {
                    NavigationLink(value: "timeSetting") {
                        HStack {
                            Image(systemName: "clock")
                                .frame(width: 24)
                                .foregroundStyle(isSleepTimeRestricted() ? .secondary : .primary)
                                
                            VStack(alignment: .leading, spacing: 2) {
                                Text("수면 시간")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(isSleepTimeRestricted() ? .secondary : .primary)
                                    
                                Text(currentTimeRange)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(isSleepTimeRestricted())
                    .onTapGesture {
                        if isSleepTimeRestricted() {
                            showingSleepTimeAlert = true
                        }
                    }
                        
                    NavigationLink(value: "appBlocking") {
                        HStack {
                            Image(systemName: "app.badge.checkmark")
                                .frame(width: 24)
                                
                            VStack(alignment: .leading, spacing: 2) {
                                Text("앱 차단")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.primary)
                                    
                                Text("수면 시간에 차단할 앱 선택")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                        
                    NavigationLink(value: "cardManagement") {
                        HStack {
                            Image(systemName: "creditcard")
                                .frame(width: 24)
                                
                            VStack(alignment: .leading, spacing: 2) {
                                Text("카드 관리")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.primary)
                                    
                                Text("드림 카드 등록 및 삭제")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("앱 설정")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                    
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .frame(width: 24)
                            
                        VStack(alignment: .leading, spacing: 2) {
                            Text("앱 정보")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.primary)
                                
                            Text("버전 1.0.0")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                            
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("정보")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(.mainContainerBackground)
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "timeSetting":
                    TimeSettingView({
                        navigationPath.removeLast()
                    }, buttonText: "완료", hideTabBar: true)
                case "appBlocking":
                    AppSelectionView({
                        navigationPath.removeLast()
                    }, showNextButton: false, hideTabBar: true)
                case "cardManagement":
                    CardManagementView()
                default:
                    EmptyView()
                }
            }
        }
        .alert("수면 시간 변경 불가", isPresented: $showingSleepTimeAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("현재는 수면 시간을 변경할 수 없습니다.\n수면 시간(20시~04시) 외에 다시 시도해주세요.")
        }
    }
    
    private var currentTimeRange: String {
        guard let settings = userSettings.first else {
            return "23:00 - 07:00"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let departure = formatter.string(from: settings.targetDepartureTime)
        let arrival = formatter.string(from: settings.targetArrivalTime)
        
        return "\(departure) - \(arrival)"
    }
    
    /// 시간에 따라 수면시간 파악해주는 함수, 나중에 옮기면 좋겠습니다!
    private func isSleepTimeRestricted() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        return hour >= 20 || hour <= 4
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserSettings.self], inMemory: true)
}
