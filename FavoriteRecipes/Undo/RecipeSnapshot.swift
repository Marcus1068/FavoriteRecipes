import Foundation

/// A copy of everything stored in a recipe, so a deleted recipe can be brought back.
struct RecipeSnapshot {
    let id: UUID
    let name: String
    let category: RecipeCategory
    let recipeImageData: Data?
    let isFavorite: Bool
    let ingredientsType: IngredientsType
    let ingredientsImageData: Data?
    let ingredientsPDFData: Data?
    let ingredientsText: String?
    let createdAt: Date
    let instructions: String?
    let servings: Int?
    let prepMinutes: Int?
    let cookMinutes: Int?
    let sourceURLString: String?
    let notes: String?
    let rating: Int
    let tags: [String]
    let cookHistoryData: Data?

    init(_ recipe: Recipe) {
        id = recipe.id
        name = recipe.name
        category = recipe.category
        recipeImageData = recipe.recipeImageData
        isFavorite = recipe.isFavorite
        ingredientsType = recipe.ingredientsType
        ingredientsImageData = recipe.ingredientsImageData
        ingredientsPDFData = recipe.ingredientsPDFData
        ingredientsText = recipe.ingredientsText
        createdAt = recipe.createdAt
        instructions = recipe.instructions
        servings = recipe.servings
        prepMinutes = recipe.prepMinutes
        cookMinutes = recipe.cookMinutes
        sourceURLString = recipe.sourceURLString
        notes = recipe.notes
        rating = recipe.rating
        tags = recipe.tags
        cookHistoryData = recipe.cookHistoryData
    }

    /// A new, unsaved recipe with the same contents and the same id.
    func makeRecipe() -> Recipe {
        let recipe = Recipe(name: name, category: category, isFavorite: isFavorite)
        recipe.id = id
        recipe.recipeImageData = recipeImageData
        recipe.ingredientsType = ingredientsType
        recipe.ingredientsImageData = ingredientsImageData
        recipe.ingredientsPDFData = ingredientsPDFData
        recipe.ingredientsText = ingredientsText
        recipe.createdAt = createdAt
        recipe.instructions = instructions
        recipe.servings = servings
        recipe.prepMinutes = prepMinutes
        recipe.cookMinutes = cookMinutes
        recipe.sourceURLString = sourceURLString
        recipe.notes = notes
        recipe.rating = rating
        recipe.tags = tags
        recipe.cookHistoryData = cookHistoryData
        return recipe
    }
}
