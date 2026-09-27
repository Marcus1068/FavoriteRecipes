import Foundation
import Testing
@testable import FavoriteRecipes

struct RecipeTests {
    @Test func emptyDraftHasNoContent() {
        #expect(Recipe().hasContent == false)
        let whitespace = Recipe(name: "   ")
        whitespace.ingredientsText = "\n"
        #expect(whitespace.hasContent == false)
    }

    @Test func anyEnteredDataCountsAsContent() {
        #expect(Recipe(name: "Soup").hasContent)
        let photo = Recipe()
        photo.recipeImageData = Data([0xFF])
        #expect(photo.hasContent)
        let steps = Recipe()
        steps.instructions = "Stir"
        #expect(steps.hasContent)
    }

    @Test func displayNameFallsBackToPlaceholder() {
        #expect(Recipe(name: "Soup").displayName == "Soup")
        #expect(Recipe().displayName == String(localized: .untitledRecipe))
    }

    @Test func sourceURLOnlyAcceptsWebLinks() {
        let recipe = Recipe()
        recipe.sourceURLString = " https://example.com/r "
        #expect(recipe.sourceURL == URL(string: "https://example.com/r"))
        recipe.sourceURLString = "javascript:alert(1)"
        #expect(recipe.sourceURL == nil)
        recipe.sourceURLString = "not a url"
        #expect(recipe.sourceURL == nil)
    }

    @Test func shareTextContainsFilledSectionsOnly() {
        let recipe = Recipe(name: "Soup")
        recipe.ingredientsText = "Water"
        recipe.sourceURLString = "https://example.com"
        let text = recipe.shareText
        #expect(text.hasPrefix("Soup\n\n"))
        #expect(text.contains(String(localized: .ingredients) + ":\nWater"))
        #expect(text.contains(String(localized: .source) + ": https://example.com"))
        #expect(text.contains(String(localized: .instructions)) == false)
        #expect(text.contains(String(localized: .notes)) == false)
    }
}
