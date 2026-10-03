import SwiftUI

/// Five tappable stars. Tapping the current rating again clears it.
struct RatingPicker: View {
    @Binding var rating: Int

    var body: some View {
        HStack {
            ForEach(1...5, id: \.self) { star in
                Button {
                    rating = rating == star ? 0 : star
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundStyle(star <= rating ? .yellow : .secondary)
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .sensoryFeedback(.selection, trigger: rating)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(.rating))
        .accessibilityValue(rating == 0 ? Text(.notRated) : Text(.ratingValue(rating)))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: rating = min(5, rating + 1)
            case .decrement: rating = max(0, rating - 1)
            @unknown default: break
            }
        }
    }
}
