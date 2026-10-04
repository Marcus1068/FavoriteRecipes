import SwiftUI

/// One recipe in the list shown at accessibility text sizes: name, category and favorite state.
struct RecipeListRow: View {
    let recipe: Recipe
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.displayName)
                        .font(.headline)
                    Label {
                        Text(recipe.category.localizedName)
                    } icon: {
                        Text(recipe.category.icon)
                            .accessibilityHidden(true)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                if recipe.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .accessibilityLabel(Text(.favorite))
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("recipeListRow")
    }
}
