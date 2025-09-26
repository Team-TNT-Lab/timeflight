//
//  SettingsView.swift
//  sleeptrain
//
//  Created by Dean_SSONG on 9/24/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                // 앱 설정 섹션 (통합)
                Section {
                    // 수면 시간
                    NavigationLink(value: "timeSetting") {
                        HStack {
                            Image(systemName: "clock")
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("수면 시간")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text(currentTimeRange)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // 앱 차단
                    NavigationLink(value: "appBlocking") {
                        HStack {
                            Image(systemName: "app.badge.checkmark")
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("앱 차단")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text("수면 시간에 차단할 앱 선택")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // 카드 관리
                    NavigationLink(value: "cardManagement") {
                        HStack {
                            Image(systemName: "creditcard")
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("카드 관리")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text("드림 카드 등록 및 삭제")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("앱 설정")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // 정보 섹션
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("앱 정보")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("버전 1.0.0")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
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
        .background {
            BackgroundGradientLayer()
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
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserSettings.self], inMemory: true)
}
