import SwiftUI

/// A recipe on the shopping list, with the servings it was added for.
struct ShoppingRecipeRow: View {
    let recipe: ShoppingRecipe

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(recipe.title)
            if let servings = recipe.servings {
                Text(.shoppingForServings(servings))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("shoppingRecipe")
    }
}
