import Foundation
import SwiftData
import Testing
@testable import FavoriteRecipes

@MainActor
struct UndoDeleteModelTests {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Recipe.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func richRecipe() -> Recipe {
        let recipe = Recipe(name: "Carbonara", category: .noodles, isFavorite: true)
        recipe.recipeImageData = Data([1, 2, 3])
        recipe.ingredientsType = .photo
        recipe.ingredientsImageData = Data([4, 5])
        recipe.ingredientsText = "400 g Spaghetti"
        recipe.instructions = "1. Boil"
        recipe.servings = 4
        recipe.prepMinutes = 10
        recipe.cookMinutes = 20
        recipe.sourceURLString = "https://example.com"
        recipe.notes = "Less salt"
        recipe.rating = 5
        return recipe
    }

    @Test func snapshotKeepsEveryField() {
        let original = richRecipe()
        let copy = RecipeSnapshot(original).makeRecipe()
        #expect(copy.id == original.id)
        #expect(copy.name == original.name)
        #expect(copy.category == original.category)
        #expect(copy.isFavorite)
        #expect(copy.recipeImageData == original.recipeImageData)
        #expect(copy.ingredientsType == .photo)
        #expect(copy.ingredientsImageData == original.ingredientsImageData)
        #expect(copy.ingredientsText == original.ingredientsText)
        #expect(copy.createdAt == original.createdAt)
        #expect(copy.instructions == original.instructions)
        #expect(copy.servings == 4 && copy.prepMinutes == 10 && copy.cookMinutes == 20)
        #expect(copy.sourceURLString == original.sourceURLString)
        #expect(copy.notes == original.notes)
        #expect(copy.rating == 5)
    }

    @Test func deleteThenUndoRestoresTheRecipe() throws {
        let context = try makeContext()
        let recipe = richRecipe()
        let id = recipe.id
        context.insert(recipe)
        try context.save()

        let model = UndoDeleteModel()
        model.delete(recipe, from: context)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<Recipe>()) == 0)
        #expect(model.canUndo)

        model.undo(in: context)
        let restored = try context.fetch(FetchDescriptor<Recipe>())
        #expect(restored.count == 1)
        #expect(restored.first?.id == id)
        #expect(restored.first?.name == "Carbonara")
        #expect(!model.canUndo)
    }

    @Test func undoRestoresEveryRecipeOfADeleteAll() throws {
        let context = try makeContext()
        let recipes = [Recipe(name: "A"), Recipe(name: "B"), Recipe(name: "C")]
        recipes.forEach(context.insert)
        try context.save()

        let model = UndoDeleteModel()
        model.delete(recipes, from: context)
        try context.save()
        #expect(model.deleted.count == 3)

        model.undo(in: context)
        let names = try context.fetch(FetchDescriptor<Recipe>()).map(\.name).sorted()
        #expect(names == ["A", "B", "C"])
    }

    @Test func aNewDeletionReplacesTheOldOne() throws {
        let context = try makeContext()
        let first = Recipe(name: "First")
        let second = Recipe(name: "Second")
        context.insert(first)
        context.insert(second)

        let model = UndoDeleteModel()
        model.delete(first, from: context)
        let firstID = model.deletionID
        model.delete(second, from: context)
        #expect(model.deletionID != firstID)
        #expect(model.deleted.map(\.name) == ["Second"])
    }

    @Test func dismissForgetsTheDeletion() throws {
        let context = try makeContext()
        let recipe = Recipe(name: "X")
        context.insert(recipe)
        let model = UndoDeleteModel()
        model.delete(recipe, from: context)
        model.dismiss()
        #expect(!model.canUndo)
    }

    @Test func deletingNothingOffersNoUndo() throws {
        let model = UndoDeleteModel()
        model.delete([], from: try makeContext())
        #expect(!model.canUndo)
    }
}
