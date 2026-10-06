import Foundation

extension RecipeFile {
    /// The file contents for a recipe. Photos are shared by reference, so this is cheap to build.
    init(_ recipe: Recipe) {
        self.init(
            name: recipe.displayName,
            category: recipe.category.rawValue,
            ingredientsType: recipe.ingredientsType.rawValue,
            ingredientsText: recipe.ingredientsText,
            instructions: recipe.instructions,
            notes: recipe.notes,
            sourceURLString: recipe.sourceURLString,
            servings: recipe.servings,
            prepMinutes: recipe.prepMinutes,
            cookMinutes: recipe.cookMinutes,
            rating: recipe.rating,
            tags: recipe.tags,
            recipeImageData: recipe.recipeImageData,
            ingredientsImageData: recipe.ingredientsImageData,
            ingredientsPDFData: recipe.ingredientsPDFData
        )
    }

    /// An unsaved draft for the user to review. Unknown or out-of-range values are replaced with safe ones;
    /// the recipe is never a favorite, has no cooking history, and gets a new identity.
    func makeDraft() -> Recipe {
        let recipe = Recipe(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: RecipeCategory(rawValue: category) ?? .meat
        )
        recipe.ingredientsType = IngredientsType(rawValue: ingredientsType) ?? .text
        recipe.ingredientsText = Self.cleaned(ingredientsText)
        recipe.instructions = Self.cleaned(instructions)
        recipe.notes = Self.cleaned(notes)
        recipe.sourceURLString = Self.webAddress(sourceURLString)
        recipe.servings = Self.clamped(servings, to: 0...1_000)
        recipe.prepMinutes = Self.clamped(prepMinutes, to: 0...100_000)
        recipe.cookMinutes = Self.clamped(cookMinutes, to: 0...100_000)
        recipe.rating = min(5, max(0, rating))
        recipe.tags = TagList.normalize(Array(tags.prefix(50)).map { String($0.prefix(60)) })
        recipe.recipeImageData = recipeImageData
        recipe.ingredientsImageData = ingredientsImageData
        recipe.ingredientsPDFData = ingredientsPDFData
        return recipe
    }

    private static func cleaned(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return trimmed
    }

    /// Only http(s) addresses are kept as the source link.
    private static func webAddress(_ text: String?) -> String? {
        guard let text = cleaned(text), let url = URL(string: text),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return nil }
        return text
    }

    private static func clamped(_ value: Int?, to range: ClosedRange<Int>) -> Int? {
        guard let value, value > 0 else { return nil }
        return min(range.upperBound, max(range.lowerBound, value))
    }
}
