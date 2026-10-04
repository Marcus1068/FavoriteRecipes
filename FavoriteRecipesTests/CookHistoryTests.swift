import Foundation
import Testing
@testable import FavoriteRecipes

struct CookHistoryTests {
    @Test func startsEmpty() {
        let recipe = Recipe(name: "X")
        #expect(recipe.cookHistory.isEmpty)
        #expect(recipe.cookedCount == 0)
        #expect(recipe.lastCookedAt == nil)
        #expect(recipe.cookHistoryData == nil)
    }

    @Test func recordsEntriesAndFindsTheLatest() {
        let recipe = Recipe(name: "X")
        let early = Date(timeIntervalSinceReferenceDate: 1_000)
        let late = Date(timeIntervalSinceReferenceDate: 9_000)
        recipe.markCooked(on: late, note: "  less salt  ")
        recipe.markCooked(on: early)
        #expect(recipe.cookedCount == 2)
        #expect(recipe.lastCookedAt == late)
        #expect(recipe.cookHistory.first?.note == "less salt")
        #expect(recipe.cookHistory.last?.note == nil)
    }

    @Test func blankNotesAreNotStored() {
        let recipe = Recipe(name: "X")
        recipe.markCooked(note: "   ")
        #expect(recipe.cookHistory.first?.note == nil)
    }

    @Test func removesOneEntry() {
        let recipe = Recipe(name: "X")
        recipe.markCooked(note: "a")
        recipe.markCooked(note: "b")
        let first = recipe.cookHistory[0]
        recipe.removeCookEntry(first)
        #expect(recipe.cookHistory.map(\.note) == ["b"])
        recipe.removeCookEntry(recipe.cookHistory[0])
        #expect(recipe.cookHistoryData == nil)
    }

    @Test func survivesEncodingRoundTrip() {
        let recipe = Recipe(name: "X")
        recipe.markCooked(on: Date(timeIntervalSinceReferenceDate: 500), note: "good")
        let data = recipe.cookHistoryData
        let other = Recipe(name: "Y")
        other.cookHistoryData = data
        #expect(other.cookHistory == recipe.cookHistory)
    }
}

struct RecipeCopyTests {
    @Test func copyKeepsContentButNotIdentityOrHistory() {
        let original = Recipe(name: "Soup", category: .soup, isFavorite: true)
        original.ingredientsText = "water"
        original.instructions = "1. Boil"
        original.tags = ["quick"]
        original.rating = 5
        original.servings = 4
        original.markCooked(note: "ok")

        let copy = original.makeCopy(named: "Soup (copy)")
        #expect(copy.id != original.id)
        #expect(copy.name == "Soup (copy)")
        #expect(copy.category == .soup)
        #expect(copy.ingredientsText == "water")
        #expect(copy.instructions == "1. Boil")
        #expect(copy.tags == ["quick"])
        #expect(copy.servings == 4)
        #expect(!copy.isFavorite)
        #expect(copy.rating == 0)
        #expect(copy.cookHistory.isEmpty)
        #expect(copy.createdAt >= original.createdAt)
    }

    @Test func snapshotKeepsTagsAndHistory() {
        let original = Recipe(name: "Soup")
        original.tags = ["a", "b"]
        original.markCooked(note: "n")
        let restored = RecipeSnapshot(original).makeRecipe()
        #expect(restored.tags == ["a", "b"])
        #expect(restored.cookHistory == original.cookHistory)
        #expect(restored.id == original.id)
    }
}
