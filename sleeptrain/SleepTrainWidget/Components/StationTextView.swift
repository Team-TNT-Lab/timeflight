//
//  StationTextView.swift
//  sleeptrain
//
//  Created by 양시준 on 9/23/25.
//

import SwiftUI

struct StationTextView: View {
    var stationString: String
    
    var body: some View {
        Text(stationString)
            .font(.system(size: 30, weight: .bold))
            .foregroundStyle(.white)
    }
}
