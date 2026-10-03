import SwiftUI
import SwiftData

/// A single recipe card for the main carousel.
///
/// Image display strategy
/// ──────────────────────
/// Every image — landscape OR portrait — is rendered as:
///   1. Blurred, darkened `scaledToFill` layer   → fills the card visually
///   2. Sharp `scaledToFit`   overlay            → shows the COMPLETE photo
///
/// Because `scaledToFit` never crops, the full food photo is always visible
/// regardless of its aspect ratio.  The bottom strip (Share / Edit) sits at
/// a hard-coded position at the bottom of the explicit `cardWidth × cardHeight`
/// frame, so it is *always* reachable.
///
/// Card dimensions are supplied by CarouselView, which derives them from the
/// space SwiftUI actually allocates to the carousel.
struct RecipeCardView: View {
    @Bindable var recipe: Recipe

    var cardWidth: CGFloat = 300
    var cardHeight: CGFloat = 400
    /// Offered to VoiceOver as an action; the carousel confirms before deleting.
    var onDelete: (() -> Void)?

    @State private var showDetail = false
    @State private var cookingRecipe: Recipe?

    var body: some View {
        ZStack(alignment: .bottom) {
            RecipeCardPhoto(recipe: recipe, width: cardWidth, height: cardHeight)
            if recipe.isFavorite {
                FavoriteBadge()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .transition(.scale.combined(with: .opacity))
            }
            RecipeCardInfoStrip(
                recipe: recipe,
                onEdit: { showDetail = true },
                onCook: { cookingRecipe = recipe },
                onDelete: onDelete
            )
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(.rect(cornerRadius: 24))
        .sheet(isPresented: $showDetail) { RecipeDetailView(recipe: recipe) }
        .cookingModeCover(item: $cookingRecipe)
    }
}

// MARK: - Previews

@MainActor
private func previewPhoto(size: CGSize, colors: [Color], label: String) -> Data? {
    let renderer = ImageRenderer(
        content: LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
            .frame(width: size.width, height: size.height)
            .overlay { Text(label).font(.largeTitle.bold()).foregroundStyle(.white) }
    )
    return renderer.uiImage?.jpegData(compressionQuality: 0.9)
}

#Preview("Landscape 16:9") {
    let recipe = Recipe(name: "Salmon Pasta", category: .fish)
    recipe.recipeImageData = previewPhoto(
        size: CGSize(width: 640, height: 360), colors: [.blue, .indigo], label: "LANDSCAPE 16:9"
    )
    return RecipeCardView(recipe: recipe, cardWidth: 300, cardHeight: 360)
        .modelContainer(for: Recipe.self, inMemory: true)
}

#Preview("Portrait 9:16") {
    let recipe = Recipe(name: "Beef Steak", category: .meat)
    recipe.isFavorite = true
    recipe.recipeImageData = previewPhoto(
        size: CGSize(width: 360, height: 640), colors: [.orange, .red], label: "PORTRAIT 9:16"
    )
    return RecipeCardView(recipe: recipe, cardWidth: 300, cardHeight: 360)
        .modelContainer(for: Recipe.self, inMemory: true)
}
