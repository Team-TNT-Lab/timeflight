//
//  SleepTrainWidgetLiveActivity.swift
//  SleepTrainWidget
//
//  Created by 양시준 on 9/23/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SleepTrainWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SleepTrainWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepTrainWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SleepTrainWidgetAttributes {
    fileprivate static var preview: SleepTrainWidgetAttributes {
        SleepTrainWidgetAttributes(name: "World")
    }
}

extension SleepTrainWidgetAttributes.ContentState {
    fileprivate static var smiley: SleepTrainWidgetAttributes.ContentState {
        SleepTrainWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SleepTrainWidgetAttributes.ContentState {
         SleepTrainWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SleepTrainWidgetAttributes.preview) {
   SleepTrainWidgetLiveActivity()
} contentStates: {
    SleepTrainWidgetAttributes.ContentState.smiley
    SleepTrainWidgetAttributes.ContentState.starEyes
}
