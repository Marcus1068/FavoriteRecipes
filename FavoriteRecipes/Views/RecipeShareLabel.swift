import SwiftUI

/// Capsule "Share" label used on recipe cards.
struct RecipeShareLabel: View {
    var body: some View {
        Label(.share, systemImage: "square.and.arrow.up")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: .capsule)
            .foregroundStyle(.white)
            // The capsule stays small; the tappable area reaches the 44 pt minimum.
            .frame(minHeight: 44)
            .contentShape(.rect)
    }
}
