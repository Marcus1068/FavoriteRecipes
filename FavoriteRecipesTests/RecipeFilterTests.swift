import Testing
@testable import FavoriteRecipes

struct RecipeFilterTests {
    private let pasta: Recipe = {
        let recipe = Recipe(name: "Spaghetti Carbonara", category: .noodles)
        recipe.ingredientsText = "Spaghetti\nPancetta\nEggs"
        return recipe
    }()
    private let salmon = Recipe(name: "Grilled Salmon", category: .fish, isFavorite: true)
    private let soup: Recipe = {
        let recipe = Recipe(name: "Tomato Soup", category: .soup)
        recipe.notes = "Great with basil"
        return recipe
    }()

    private var all: [Recipe] { [pasta, salmon, soup] }

    @Test func separatesFavoritesFromRegularRecipes() {
        let filter = RecipeFilter()
        #expect(filter.favorites(in: all) == [salmon])
        #expect(filter.regular(in: all) == [pasta, soup])
    }

    @Test func filtersByCategory() {
        let filter = RecipeFilter(category: .soup)
        #expect(filter.regular(in: all) == [soup])
        #expect(filter.favorites(in: all).isEmpty)
    }

    @Test func searchMatchesNameIngredientsAndNotes() {
        #expect(RecipeFilter(searchText: "carbo").regular(in: all) == [pasta])
        #expect(RecipeFilter(searchText: "pancetta").regular(in: all) == [pasta])
        #expect(RecipeFilter(searchText: "BASIL").regular(in: all) == [soup])
        #expect(RecipeFilter(searchText: "salmon").favorites(in: all) == [salmon])
    }

    @Test func searchIgnoresDiacriticsAndSurroundingWhitespace() {
        let recipe = Recipe(name: "Crème brûlée", category: .cake)
        #expect(RecipeFilter(searchText: "  creme brulee ").regular(in: [recipe]) == [recipe])
    }

    @Test func blankSearchIsNotSearching() {
        #expect(RecipeFilter(searchText: "   ").isSearching == false)
        #expect(RecipeFilter(searchText: "x").isSearching)
    }

    @Test func categoryAndSearchCombine() {
        let filter = RecipeFilter(category: .noodles, searchText: "soup")
        #expect(filter.regular(in: all).isEmpty)
    }
}
