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
    @State private var registeredCards: [String] = [] // 등록된 카드 목록
    @State private var showingAddCard = false
    @State private var showingDeleteAlert = false
    @State private var cardToDelete: String?
    
    let nfcScanManager = NFCManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            VStack(alignment: .leading, spacing: 12) {
                Text("카드 관리")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
            
            Spacer()
            
            if registeredCards.isEmpty {
                // 카드가 없을 때 - 등록 버튼
                VStack(spacing: 20) {
                    // 카드 플레이스홀더
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "creditcard")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text("등록된 카드가 없습니다")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        )
                        .padding(.horizontal, 20)
                    
                    // 카드 추가 버튼
                    Button(action: {
                        showingAddCard = true
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
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                // 카드가 있을 때 - 카드 표시 및 삭제 버튼
                VStack(spacing: 20) {
                    // 등록된 카드 표시
                    ForEach(registeredCards, id: \.self) { cardId in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 120)
                            .overlay(
                                HStack {
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("드림 카드")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Text("등록됨")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                            )
                            .padding(.horizontal, 20)
                    }
                    
                    // 카드 삭제 버튼
                    Button(action: {
                        if let firstCard = registeredCards.first {
                            cardToDelete = firstCard
                            showingDeleteAlert = true
                        }
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
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            Spacer()
        }
        .navigationTitle("카드 관리")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            UITabBar.appearance().isHidden = true
            loadRegisteredCards()
        }
        .onDisappear {
            UITabBar.appearance().isHidden = false
        }
        .alert("카드 삭제", isPresented: $showingDeleteAlert) {
            Button("삭제", role: .destructive) {
                if let cardId = cardToDelete {
                    deleteCard(cardId)
                }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("등록된 카드를 삭제하시겠습니까?")
        }
        .sheet(isPresented: $showingAddCard) {
            AddCardView { cardId in
                registeredCards.append(cardId)
            }
        }
    }
    
    private func loadRegisteredCards() {
        // 실제로는 UserSettings나 별도 모델에서 등록된 카드 정보를 불러옴
        // 현재는 Mock 데이터
        registeredCards = [] // 빈 배열로 시작 (카드 없음 상태)
    }
    
    private func deleteCard(_ cardId: String) {
        registeredCards.removeAll { $0 == cardId }
        // 실제로는 데이터베이스에서도 삭제
    }
}

// 카드 등록 뷰
struct AddCardView: View {
    @Environment(\.dismiss) private var dismiss
    let onCardRegistered: (String) -> Void
    
    @State private var isImageVisible = false
    let nfcScanManager = NFCManager()
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer().frame(height: 40)
                
                VStack(spacing: 14) {
                    Text("카드를 등록해주세요")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("아이폰의 상단 부분에 카드를 태그하면 돼요")
                        .font(.system(size: 13, weight: .thin))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image("NfcTagImage")
                    .resizable()
                    .scaledToFit()
                    .opacity(isImageVisible ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.0)) {
                            isImageVisible = true
                        }
                    }
                
                Spacer()
                
                VStack(spacing: 17) {
                    Button("카드 등록하기") {
                        nfcScanManager.startNFCScan(alertMessage: "카드 등록 완료!") { _ in
                            // 카드 ID 생성 (실제로는 NFC 태그에서 읽어온 ID 사용)
                            let cardId = "card_\(Int.random(in: 100...999))"
                            onCardRegistered(cardId)
                            dismiss()
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button("취소") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .navigationTitle("카드 등록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CardManagementView()
        .modelContainer(for: [UserSettings.self], inMemory: true)
}
