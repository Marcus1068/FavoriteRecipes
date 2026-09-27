import SwiftUI

/// Heavily blurred photo of the current recipe behind the carousel.
struct RecipesBackground: View {
    let recipe: Recipe?

    var body: some View {
        if let recipe, let data = recipe.recipeImageData {
            // Blurred by 60 pt, so a tiny decode is indistinguishable from full size.
            DownsampledImage(data: data, id: recipe.id.uuidString, maxPointSize: 120)
                .scaledToFill()
                .blur(radius: 60)
                .opacity(0.22)
                .ignoresSafeArea()
                .id(recipe.id)
                .transition(.opacity)
                .accessibilityHidden(true)
        } else {
            Color(.systemBackground).ignoresSafeArea()
        }
    }
}
