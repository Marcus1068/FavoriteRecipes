import Foundation
import SwiftData
import Testing
@testable import FavoriteRecipes

struct RecipeWebImporterTests {
    @Test func normalizesAddresses() {
        #expect(
            RecipeWebImporter.normalizedURL(from: "example.com/recipe")?.absoluteString == "https://example.com/recipe"
        )
        #expect(RecipeWebImporter.normalizedURL(from: "  http://example.com  ")?.absoluteString == "http://example.com")
        #expect(RecipeWebImporter.normalizedURL(from: "HTTPS://Example.com/a")?.host() == "Example.com")
    }

    @Test(arguments: ["", "   ", "not a url", "localhost", "ftp://example.com"])
    func rejectsInvalidAddresses(input: String) {
        #expect(RecipeWebImporter.normalizedURL(from: input) == nil)
    }

    @Test func buildsAnUnsavedDraft() {
        var imported = ImportedRecipe()
        imported.name = "Vegan Chocolate Cake"
        imported.ingredients = ["Flour", "Cocoa"]
        imported.instructions = ["Mix", "Bake"]
        imported.servings = 8
        imported.prepMinutes = 20
        imported.sourceURL = URL(string: "https://example.com/cake")
        imported.categoryHints = ["Dessert", "vegan, cake"]

        let draft = RecipeWebImporter.makeDraft(from: imported, imageData: nil)

        #expect(draft.name == "Vegan Chocolate Cake")
        #expect(draft.category == .cake)
        #expect(draft.ingredientsType == .text)
        #expect(draft.ingredientsText == "Flour\nCocoa")
        #expect(draft.instructions == "1. Mix\n2. Bake")
        #expect(draft.servings == 8)
        #expect(draft.prepMinutes == 20)
        #expect(draft.cookMinutes == nil)
        #expect(draft.sourceURLString == "https://example.com/cake")
        #expect(draft.modelContext == nil, "Drafts are only inserted when the user taps Add")
    }
}
