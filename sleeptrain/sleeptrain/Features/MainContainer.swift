//
//  MainContainer.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/27/25.
//
import SwiftData
import SwiftUI

struct MainContainer: View {
    var body: some View {
        TabView {
            TransitView()
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
