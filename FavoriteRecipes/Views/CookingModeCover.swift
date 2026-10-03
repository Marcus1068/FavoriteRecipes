import SwiftUI

extension View {
    /// Presents cooking mode full screen for the bound recipe.
    func cookingModeCover(item recipe: Binding<Recipe?>) -> some View {
        fullScreenCover(item: recipe) { recipe in
            CookingModeView(recipe: recipe)
        }
    }
}
