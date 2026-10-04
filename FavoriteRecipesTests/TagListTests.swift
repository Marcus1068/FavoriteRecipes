import Testing
@testable import FavoriteRecipes

struct TagListTests {
    @Test func parseSplitsTrimsAndDropsDuplicates() {
        #expect(TagList.parse("quick, kids ,Quick,, ") == ["quick", "kids"])
    }

    @Test func duplicatesIgnoreCaseAndAccents() {
        #expect(TagList.normalize(["Café", "cafe", "Tea"]) == ["Café", "Tea"])
    }

    @Test func parseAlsoSplitsOnNewlines() {
        #expect(TagList.parse("a\nb, c") == ["a", "b", "c"])
    }

    @Test func allCollectsTagsFromEveryRecipe() {
        let a = Recipe(name: "A")
        a.tags = ["Weeknight", "kids"]
        let b = Recipe(name: "B")
        b.tags = ["weeknight", "Guests"]
        #expect(TagList.all(in: [a, b]) == ["Guests", "kids", "Weeknight"])
    }
}

struct RecipeTagSearchTests {
    @Test func searchFindsRecipesByTag() {
        let recipe = Recipe(name: "Stew")
        recipe.tags = ["Winter"]
        #expect(recipe.matches(searchText: "wint"))
        #expect(!recipe.matches(searchText: "summer"))
    }
}
