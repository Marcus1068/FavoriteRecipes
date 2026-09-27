import SwiftUI

/// Shown when the collection has no recipes at all.
struct EmptyCarouselView: View {
    let onAdd: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize = 76

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: iconSize))
                .foregroundStyle(.secondary.opacity(0.45))
                .accessibilityHidden(true)

            Text(.noRecipesYet)
                .font(.title2.bold())

            Text(.noRecipesYetMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onAdd) {
                Label(.addRecipe, systemImage: "plus")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor, in: .capsule)
                    .foregroundStyle(.white)
                    .font(.headline)
            }
        }
        .padding(40)
    }
}
