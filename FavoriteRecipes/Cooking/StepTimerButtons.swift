import SwiftUI

/// "Start 10 min timer" buttons for the durations mentioned in the current step.
struct StepTimerButtons: View {
    let step: String
    let recipeName: String

    @Environment(TimerCenter.self) private var timerCenter

    var body: some View {
        let suggestions = StepTimerParser.suggestions(in: step)
        if !suggestions.isEmpty {
            FlowLayout {
                ForEach(suggestions) { suggestion in
                    let length = Duration.seconds(suggestion.seconds)
                        .formatted(.units(allowed: [.hours, .minutes, .seconds], width: .abbreviated))
                    Button(length, systemImage: "timer") {
                        timerCenter.start(seconds: suggestion.seconds, title: "\(recipeName) · \(length)")
                    }
                    .labelStyle(.titleAndIcon)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .accessibilityLabel(Text(.startTimerLabel(length)))
                }
            }
            .padding(.horizontal)
        }
    }
}
