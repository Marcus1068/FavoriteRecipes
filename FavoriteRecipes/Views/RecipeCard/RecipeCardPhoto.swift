import SwiftUI

/// Blurred fill (visual interest) + sharp fit (full photo always visible),
/// or a category-colored gradient when the recipe has no photo.
struct RecipeCardPhoto: View {
    let recipe: Recipe
    let width: CGFloat
    let height: CGFloat

    @ScaledMetric(relativeTo: .largeTitle) private var placeholderIconSize = 90

    var body: some View {
        if let data = recipe.recipeImageData {
            ZStack {
                // ① Blurred fill — hides letterbox bars; heavily blurred, so a small decode suffices.
                DownsampledImage(data: data, id: recipe.id.uuidString, maxPointSize: 160)
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
                    .blur(radius: 22)
                    .saturation(0.70)
                    .brightness(-0.12)

                // ② Full image — always the complete photo, never cropped
                DownsampledImage(data: data, id: recipe.id.uuidString, maxPointSize: max(width, height))
                    .scaledToFit()
                    .frame(width: width, height: height)
            }
            .frame(width: width, height: height)
            .accessibilityHidden(true)
        } else {
            LinearGradient(
                colors: [recipe.category.color.opacity(0.85),
                         recipe.category.color.opacity(0.40)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: width, height: height)
            .overlay {
                Text(recipe.category.icon)
                    .font(.system(size: placeholderIconSize))
                    .opacity(0.30)
                    .offset(x: 36, y: -36)
            }
            .accessibilityHidden(true)
        }
    }
}
