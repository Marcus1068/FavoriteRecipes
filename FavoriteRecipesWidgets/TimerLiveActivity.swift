import ActivityKit
import SwiftUI
import WidgetKit

/// The kitchen timer on the lock screen and in the Dynamic Island.
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            TimerLockScreenView(title: context.attributes.title, state: context.state)
                .activityBackgroundTint(.black.opacity(0.35))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.isFinished ? "bell.fill" : "timer")
                        .font(.title2)
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.title)
                        .font(.subheadline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerCountdownText(state: context.state)
                        .font(.title2.monospacedDigit().bold())
                }
            } compactLeading: {
                Image(systemName: context.state.isFinished ? "bell.fill" : "timer")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                TimerCountdownText(state: context.state)
                    .monospacedDigit()
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: context.state.isFinished ? "bell.fill" : "timer")
                    .foregroundStyle(.orange)
            }
        }
    }
}

/// The remaining time, drawn by the system so it counts down without app updates.
/// Once the timer is finished it says so instead.
struct TimerCountdownText: View {
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        if state.isFinished {
            Text("0:00")
                .foregroundStyle(.red)
        } else {
            Text(timerInterval: Date.now...max(Date.now, state.endDate), countsDown: true)
        }
    }
}

/// The lock screen banner.
struct TimerLockScreenView: View {
    let title: String
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: state.isFinished ? "bell.fill" : "timer")
                .font(.title)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .lineLimit(2)
                TimerCountdownText(state: state)
                    .font(.largeTitle.monospacedDigit().bold())
            }
            Spacer()
        }
        .padding()
    }
}
