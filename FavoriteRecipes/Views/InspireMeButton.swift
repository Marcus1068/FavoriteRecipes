import SwiftUI

/// Gradient button that picks a random recipe from `candidates`.
struct InspireMeButton: View {
    let candidates: [Recipe]
    /// The recipe currently shown, so the pick is always a different one.
    let current: Recipe?
    let onPick: (Recipe) -> Void

    @State private var isSpinning = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            guard let recipe = InspirationPicker.pick(from: candidates, avoiding: current) else { return }
            isSpinning = true
            onPick(recipe)
            Task {
                try? await Task.sleep(for: .milliseconds(650))
                isSpinning = false
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.headline)
                    .rotationEffect(.degrees(isSpinning && !reduceMotion ? 360 : 0))
                    .animation(isSpinning ? .linear(duration: 0.65) : .default, value: isSpinning)
                Text(.inspireMe)
                    .font(.headline)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 13)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.50, green: 0.20, blue: 0.90),
                        Color(red: 0.90, green: 0.28, blue: 0.52),
                        Color(red: 1.00, green: 0.60, blue: 0.20)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(.capsule)
            .shadow(color: Color(red: 0.50, green: 0.20, blue: 0.90).opacity(0.45), radius: 14, y: 7)
        }
        .scaleEffect(isSpinning && !reduceMotion ? 0.94 : 1.0)
        .animation(.spring(response: 0.2), value: isSpinning)
        .sensoryFeedback(.selection, trigger: isSpinning) { _, spinning in spinning }
        .disabled(candidates.count <= 1)
    }
}
