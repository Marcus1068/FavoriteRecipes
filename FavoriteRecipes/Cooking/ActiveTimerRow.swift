import SwiftUI

/// One running or finished timer with a countdown and buttons to extend or stop it.
struct ActiveTimerRow: View {
    let timer: CookingTimer

    @Environment(TimerCenter.self) private var timerCenter

    var body: some View {
        let isFinished = timerCenter.isFinished(timer)
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(timer.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if isFinished {
                    Text(.timerFinished)
                        .font(.title2.bold())
                        .foregroundStyle(.red)
                } else {
                    let start = Date.now
                    Text(timerInterval: start...max(start, timer.endDate), countsDown: true)
                        .font(.title2.monospacedDigit().bold())
                }
            }
            Spacer()
            Button(.addMinute) { timerCenter.addMinute(to: timer) }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("addMinuteButton")
            Button(isFinished ? .dismissTimer : .stopTimer, role: .destructive) {
                timerCenter.remove(timer)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("stopTimerButton")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("timerRow")
        .sensoryFeedback(.success, trigger: isFinished) { _, finished in finished }
    }
}
