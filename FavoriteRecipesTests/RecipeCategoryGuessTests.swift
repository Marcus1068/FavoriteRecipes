import Testing
@testable import FavoriteRecipes

struct RecipeCategoryGuessTests {
    struct Example: Sendable, CustomTestStringConvertible {
        let hints: [String]
        let name: String
        let expected: RecipeCategory?

        var testDescription: String { "\(hints) \(name) → \(expected.map { "\($0)" } ?? "nil")" }
    }

    @Test(arguments: [
        Example(hints: ["Dessert", "vegan, cake"], name: "", expected: .cake),
        Example(hints: ["Backen", "Kuchen"], name: "", expected: .cake),
        Example(hints: [], name: "Hähnchen mit Reis", expected: .meat),
        Example(hints: [], name: "Lachs aus dem Ofen", expected: .fish),
        Example(hints: [], name: "Kürbissuppe", expected: .soup),
        Example(hints: ["Cocktail"], name: "Mojito", expected: .drinks),
        Example(hints: [], name: "Spaghetti Carbonara", expected: .noodles),
        Example(hints: [], name: "Avocado Toast", expected: nil)
    ])
    func guessesCategories(example: Example) {
        #expect(RecipeCategory.guess(hints: example.hints, name: example.name) == example.expected)
    }

    @Test func hintsTakePrecedenceOverTheName() {
        #expect(RecipeCategory.guess(hints: ["Soup"], name: "Chicken Noodle") == .soup)
    }
}
