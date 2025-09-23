//
//  SleepTrainWidgetBundle.swift
//  SleepTrainWidget
//
//  Created by 양시준 on 9/23/25.
//

import WidgetKit
import SwiftUI

@main
struct SleepTrainWidgetBundle: WidgetBundle {
    var body: some Widget {
        SleepTrainWidget()
        SleepTrainWidgetControl()
        SleepTrainWidgetLiveActivity()
    }
}
