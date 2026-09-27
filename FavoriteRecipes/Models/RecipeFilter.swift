import Foundation

/// Splits recipes into favorites and regular recipes, applying the
/// category filter and search text. Kept free of SwiftUI so it can be tested.
struct RecipeFilter: Equatable {
    var category: RecipeCategory?
    var searchText = ""

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func includes(_ recipe: Recipe) -> Bool {
        if let category, recipe.category != category { return false }
        return recipe.matches(searchText: searchText)
    }

    func favorites(in recipes: [Recipe]) -> [Recipe] {
        recipes.filter { $0.isFavorite && includes($0) }
    }

    func regular(in recipes: [Recipe]) -> [Recipe] {
        recipes.filter { !$0.isFavorite && includes($0) }
    }
}
