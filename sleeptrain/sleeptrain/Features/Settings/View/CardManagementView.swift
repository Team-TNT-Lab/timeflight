//
//  CardManagementView.swift
//  sleeptrain
//
//  Created by go on 9/26/25.
//

import SwiftUI
import SwiftData

struct CardManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    @StateObject private var userSettingsManager = UserSettingsManager()
    @State private var showingDeleteAlert = false
    @State private var isGuestUserState: Bool = true
    
    let nfcScanManager = NFCManager()
    
    var body: some View {
        VStack(spacing: 0) {
            if isGuestUserState {
                VStack(spacing: 20) {
                    Image("nocard")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    Button(action: {
                        print("카드 등록 버튼 클릭됨")
                        nfcScanManager.startNFCScan(alertMessage: "카드 등록 완료!") { message in
                            print("NFC 스캔 완료 - 메시지: \(message ?? "nil")")
                            if message != nil {
                                print("NFC 스캔 성공 - toggleGuestUser 호출")
                                toggleGuestUser()
                            } else {
                                print("NFC 스캔 실패")
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            
                            Text("카드 추가")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                Image("card")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "trash")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        Text("카드 삭제")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.red.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .navigationTitle("카드 관리")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            UITabBar.appearance().isHidden = true
            isGuestUserState = userSettings.first?.isGuestUser ?? true
        }
        .onDisappear {
            UITabBar.appearance().isHidden = false
        }
        .alert("카드 삭제", isPresented: $showingDeleteAlert) {
            Button("삭제", role: .destructive) {
                toggleGuestUser()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("등록된 카드를 삭제하시겠습니까?")
        }
    }
    
    private func toggleGuestUser() {
        do {
            try userSettingsManager.ToggleGuestUser(context: modelContext, userSettings: userSettings)
            try modelContext.save()
            isGuestUserState = !isGuestUserState
        } catch {
            print("게스트 유저 토글 실패 \(error)")
        }
    }
}

#Preview {
    CardManagementView()
        .modelContainer(for: [UserSettings.self], inMemory: true)
}
