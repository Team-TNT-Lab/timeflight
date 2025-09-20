//
//  SettingView.swift
//  timeflight
//
//  Created by bishoe01 on 9/19/25.
//

import SwiftUI

struct SettingView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(Array(ViewConstants.SettingRouter.tabLists.enumerated()), id: \.offset) { idx, item in
                        NavigationLink {
                            switch idx {
                            case 0: AppLockSettingView()
                            default: Text("3")
                            }

                        } label: {
                            Text(item)
                        }
                    }
                }
                Section {
                    Text("피드백")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("설정")
        }
    }
}

#Preview {
    SettingView()
}
