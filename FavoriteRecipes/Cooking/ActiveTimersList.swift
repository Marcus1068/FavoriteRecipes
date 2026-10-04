import SwiftUI

/// All running timers, shown in cooking mode and on the recipes screen.
struct ActiveTimersList: View {
    @Environment(TimerCenter.self) private var timerCenter

    var body: some View {
        if timerCenter.hasTimers {
            VStack(spacing: 8) {
                ForEach(timerCenter.timers) { timer in
                    ActiveTimerRow(timer: timer)
                }
            }
            .padding()
            .background(.regularMaterial, in: .rect(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}
