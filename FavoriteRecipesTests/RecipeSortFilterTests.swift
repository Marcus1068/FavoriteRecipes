import Foundation
import Testing
@testable import FavoriteRecipes

struct RecipeSortFilterTests {
    private func recipe(_ name: String, daysAgo: Double, rating: Int = 0, tags: [String] = [],
                        cooked: Double? = nil, favorite: Bool = false) -> Recipe {
        let recipe = Recipe(name: name, isFavorite: favorite)
        recipe.createdAt = Date(timeIntervalSinceReferenceDate: 1_000_000 - daysAgo * 86_400)
        recipe.rating = rating
        recipe.tags = tags
        if let cooked {
            recipe.markCooked(on: Date(timeIntervalSinceReferenceDate: 1_000_000 - cooked * 86_400))
        }
        return recipe
    }

    private var sample: [Recipe] {
        [
            recipe("Banana Bread", daysAgo: 10, rating: 3, tags: ["baking"], cooked: 1),
            recipe("apple pie", daysAgo: 5, rating: 5, tags: ["baking", "guests"], cooked: 7),
            recipe("Carbonara", daysAgo: 1, rating: 4, tags: ["weeknight"]),
            recipe("Dumplings", daysAgo: 20, rating: 5, tags: [], favorite: true),
        ]
    }

    private func names(_ recipes: [Recipe]) -> [String] { recipes.map(\.name) }

    @Test func sortsNewestAndOldest() {
        #expect(names(RecipeSort.newest.sorted(sample)) == ["Carbonara", "apple pie", "Banana Bread", "Dumplings"])
        #expect(names(RecipeSort.oldest.sorted(sample)) == ["Dumplings", "Banana Bread", "apple pie", "Carbonara"])
    }

    @Test func sortsByNameIgnoringCase() {
        #expect(names(RecipeSort.name.sorted(sample)) == ["apple pie", "Banana Bread", "Carbonara", "Dumplings"])
    }

    @Test func sortsByRatingWithNewestAsTieBreak() {
        #expect(names(RecipeSort.rating.sorted(sample)) == ["apple pie", "Dumplings", "Carbonara", "Banana Bread"])
    }

    @Test func sortsRecentlyCookedFirstAndNeverCookedLast() {
        #expect(names(RecipeSort.recentlyCooked.sorted(sample)) == ["Banana Bread", "apple pie", "Carbonara", "Dumplings"])
    }

    @Test func filtersByMinimumRating() {
        let filter = RecipeFilter(minimumRating: 4)
        #expect(Set(names(filter.regular(in: sample))) == ["apple pie", "Carbonara"])
        #expect(names(filter.favorites(in: sample)) == ["Dumplings"])
    }

    @Test func filtersByTagIgnoringCase() {
        let filter = RecipeFilter(tag: "BAKING")
        #expect(Set(names(filter.regular(in: sample))) == ["Banana Bread", "apple pie"])
    }

    @Test func combinesFiltersAndSort() {
        var filter = RecipeFilter(minimumRating: 4, tag: "baking")
        filter.sort = .name
        #expect(names(filter.regular(in: sample)) == ["apple pie"])
    }

    @Test func reportsExtraFilters() {
        #expect(!RecipeFilter().hasExtraFilters)
        #expect(RecipeFilter(minimumRating: 1).hasExtraFilters)
        #expect(RecipeFilter(tag: "x").hasExtraFilters)
        #expect(!RecipeFilter(category: .soup).hasExtraFilters)
    }

    @Test func filterAppliesSortToFavoritesToo() {
        let favorites = [recipe("B", daysAgo: 1, favorite: true), recipe("A", daysAgo: 2, favorite: true)]
        #expect(names(RecipeFilter(sort: .name).favorites(in: favorites)) == ["A", "B"])
    }
}
