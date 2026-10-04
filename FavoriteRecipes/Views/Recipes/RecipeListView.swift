import SwiftUI
import SwiftData

/// Recipes as a plain list. Used instead of the card carousel at accessibility text sizes,
/// where fixed-size cards cannot hold the larger text.
struct RecipeListView: View {
    let recipes: [Recipe]
    let inspirationCandidates: [Recipe]
    let onPick: (Recipe) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(UndoDeleteModel.self) private var undoDelete
    @State private var recipeToEdit: Recipe?
    @State private var recipeToCook: Recipe?
    @State private var recipeToDelete: Recipe?

    var body: some View {
        List {
            // A row rather than an overlay, so it never covers recipes at large text sizes.
            InspireMeButton(candidates: inspirationCandidates, current: nil, onPick: onPick)
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            ForEach(recipes) { recipe in
                RecipeListRow(recipe: recipe) { recipeToEdit = recipe }
                    .swipeActions(edge: .trailing) {
                        Button(.deleteRecipe, systemImage: "trash", role: .destructive) {
                            recipeToDelete = recipe
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button(.cookingMode, systemImage: "frying.pan") { recipeToCook = recipe }
                            .tint(.orange)
                    }
                    .contextMenu {
                        Button(
                            recipe.isFavorite ? .removeFromFavorites : .addToFavorites,
                            systemImage: recipe.isFavorite ? "heart.slash" : "heart"
                        ) { recipe.isFavorite.toggle() }
                        Button(.cookingMode, systemImage: "frying.pan") { recipeToCook = recipe }
                        Button(.editRecipe, systemImage: "pencil") { recipeToEdit = recipe }
                        Divider()
                        Button(.deleteRecipe, systemImage: "trash", role: .destructive) {
                            recipeToDelete = recipe
                        }
                    }
            }
        }
        .scrollContentBackground(.hidden)
        .sheet(item: $recipeToEdit) { recipe in
            RecipeDetailView(recipe: recipe)
        }
        .cookingModeCover(item: $recipeToCook)
        .confirmDeletion(of: $recipeToDelete) { recipe in
            undoDelete.delete(recipe, from: modelContext)
        }
    }
}
