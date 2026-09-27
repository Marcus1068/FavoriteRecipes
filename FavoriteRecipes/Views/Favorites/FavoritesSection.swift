import SwiftUI

/// Horizontal strip of favorite recipes above the carousel.
struct FavoritesSection: View {
    let recipes: [Recipe]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                    .accessibilityHidden(true)
                Text(.favorites)
                    .font(.title3.bold())
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(recipes.count, format: .number)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.15), in: .capsule)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(recipes) { recipe in
                        FavoriteRecipeCard(recipe: recipe)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 4)
            }
            .scrollIndicators(.hidden)
        }
    }
}
