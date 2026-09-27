import Testing
@testable import FavoriteRecipes

struct RecipeSuggestionTests {
    @Test func fillsEmptyFields() {
        let recipe = Recipe()
        recipe.applySuggestion(
            name: " Pancakes ",
            category: .cake,
            ingredients: ["2 eggs", " ", "200 ml milk"],
            steps: ["Whisk", "", "Fry"],
            updatingCategory: true
        )
        #expect(recipe.name == "Pancakes")
        #expect(recipe.category == .cake)
        #expect(recipe.ingredientsText == "2 eggs\n200 ml milk")
        #expect(recipe.instructions == "1. Whisk\n2. Fry")
    }

    @Test func keepsWhatTheUserAlreadyEntered() {
        let recipe = Recipe(name: "Grandma's Pancakes", category: .cookies)
        recipe.instructions = "My own steps"
        recipe.ingredientsText = "raw OCR text"
        recipe.applySuggestion(
            name: "Pancakes",
            category: .cake,
            ingredients: ["2 eggs"],
            steps: ["Whisk"],
            updatingCategory: false
        )
        #expect(recipe.name == "Grandma's Pancakes")
        #expect(recipe.category == .cookies)
        #expect(recipe.instructions == "My own steps")
        #expect(recipe.ingredientsText == "2 eggs", "Structured ingredients replace the raw OCR text")
    }

    @Test func keepsRawTextWhenTheModelFindsNoIngredients() {
        let recipe = Recipe()
        recipe.ingredientsText = "raw OCR text"
        recipe.applySuggestion(name: "", category: .meat, ingredients: [], steps: [], updatingCategory: false)
        #expect(recipe.ingredientsText == "raw OCR text")
        #expect(recipe.instructions == nil)
    }

    @Test func numbersSteps() {
        #expect(Recipe.numberedSteps(["a", " b "]) == "1. a\n2. b")
        #expect(Recipe.numberedSteps([" ", ""]) == nil)
    }
}
