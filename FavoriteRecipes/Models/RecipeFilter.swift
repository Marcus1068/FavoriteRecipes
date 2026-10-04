import Foundation

/// Splits recipes into favorites and regular recipes, applying the category, tag and
/// rating filters, the search text and the sort order. Kept free of SwiftUI so it can be tested.
struct RecipeFilter: Equatable {
    var category: RecipeCategory?
    var searchText = ""
    var minimumRating = 0
    var tag: String?
    var sort = RecipeSort.newest

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// True when anything besides the category narrows the list, so the UI can show a hint.
    var hasExtraFilters: Bool {
        minimumRating > 0 || tag != nil
    }

    func includes(_ recipe: Recipe) -> Bool {
        if let category, recipe.category != category { return false }
        if recipe.rating < minimumRating { return false }
        if let tag, !recipe.tags.contains(where: { $0.localizedCaseInsensitiveCompare(tag) == .orderedSame }) {
            return false
        }
        return recipe.matches(searchText: searchText)
    }

    func favorites(in recipes: [Recipe]) -> [Recipe] {
        sort.sorted(recipes.filter { $0.isFavorite && includes($0) })
    }

    func regular(in recipes: [Recipe]) -> [Recipe] {
        sort.sorted(recipes.filter { !$0.isFavorite && includes($0) })
    }
}
