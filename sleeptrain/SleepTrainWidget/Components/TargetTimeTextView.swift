//
//  TargetTimeTextView.swift
//  sleeptrain
//
//  Created by 양시준 on 9/23/25.
//

import SwiftUI

struct TargetTimeTextView: View {
    var time: Date
    
    var body: some View {
        Text(time.formatted(Date.FormatStyle(date: .omitted, time: .shortened)))
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(.white)
    }
}
