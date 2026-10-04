import SwiftUI

/// Recipe name and star rating.
struct RecipeNameSection: View {
    @Bindable var recipe: Recipe

    var body: some View {
        Section {
            TextField(.recipeNamePlaceholder, text: $recipe.name)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
            LabeledContent(.rating) {
                RatingPicker(rating: $recipe.rating)
            }
        } header: {
            Label(.name, systemImage: "textformat")
        }
    }
}
