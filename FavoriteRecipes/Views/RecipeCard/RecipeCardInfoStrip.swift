import SwiftUI

/// Name, category, Share and Edit at the bottom of a recipe card.
struct RecipeCardInfoStrip: View {
    @Bindable var recipe: Recipe
    let onEdit: () -> Void
    let onCook: () -> Void
    let onDuplicate: () -> Void
    let onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Label(recipe.category.localizedName, systemImage: "tag.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(recipe.displayName)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityValue(recipe.isFavorite ? Text(.favorite) : Text(verbatim: ""))
                .accessibilityAction(named: recipe.isFavorite ? Text(.removeFromFavorites) : Text(.addToFavorites)) {
                    recipe.isFavorite.toggle()
                }
                .accessibilityAction(named: Text(.editRecipe), onEdit)
                .accessibilityAction(named: Text(.cookingMode), onCook)
                .accessibilityAction(named: Text(.duplicate), onDuplicate)
                .accessibilityActions {
                    if let onDelete {
                        Button(.deleteRecipe, role: .destructive, action: onDelete)
                    }
                }

                Spacer()

                Text(recipe.category.icon)
                    .font(.largeTitle)
                    .accessibilityHidden(true)
            }

            HStack(spacing: 10) {
                // Share — name, ingredients, preparation, notes and source as text.
                RecipeShareButton(recipe: recipe)
                    .buttonStyle(.plain)

                Spacer()

                Button(.cookingMode, systemImage: "frying.pan", action: onCook)
                    .labelStyle(.iconOnly)
                    .font(.subheadline.weight(.semibold))
                    .padding(9)
                    .background(.ultraThinMaterial, in: .circle)
                    .foregroundStyle(.white)
                    .buttonStyle(.plain)

                Button(.editRecipe, systemImage: "pencil", action: onEdit)
                    .labelStyle(.iconOnly)
                    .font(.subheadline.weight(.semibold))
                    .padding(9)
                    .background(.ultraThinMaterial, in: .circle)
                    .foregroundStyle(.white)
                    .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.80)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
