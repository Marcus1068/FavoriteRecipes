import SwiftUI

/// Red heart in the card's top-right corner. Decorative: the card's
/// accessibility value already says "Favorite".
struct FavoriteBadge: View {
    var body: some View {
        Image(systemName: "heart.fill")
            .foregroundStyle(.red)
            .font(.title3)
            .padding(9)
            .background(.ultraThinMaterial, in: .circle)
            .padding(12)
            .accessibilityHidden(true)
    }
}
