import SwiftUI

/// Dots (or "3 of 14" for long lists) under the carousel.
/// For VoiceOver it is an adjustable control: swipe up/down to change recipe.
struct PageIndicatorView: View {
    let count: Int
    @Binding var current: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if count > 11 {
                Text(.pageIndicator(current + 1, count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<count, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(i == current ? Color.accentColor : Color.secondary.opacity(0.38))
                            .frame(width: i == current ? 20 : 7, height: 7)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: current)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(.recipes))
        .accessibilityValue(Text(.pageIndicator(current + 1, count)))
        .accessibilityAdjustableAction { direction in
            withAnimation(.carouselPaging(reduceMotion: reduceMotion)) {
                switch direction {
                case .increment: current = min(count - 1, current + 1)
                case .decrement: current = max(0, current - 1)
                @unknown default: break
                }
            }
        }
    }
}
