import Foundation
import Observation
import SwiftData

/// Deletes recipes and remembers the most recent deletion so it can be undone.
/// Only the latest deletion is kept; a new one replaces it.
@MainActor
@Observable
final class UndoDeleteModel {
    /// The recipes removed by the latest deletion. Empty when there is nothing to undo.
    private(set) var deleted: [RecipeSnapshot] = []
    /// Changes with every deletion, so the banner can restart its timer.
    private(set) var deletionID = UUID()

    var canUndo: Bool { !deleted.isEmpty }

    /// Removes the recipes from the store and offers to undo it.
    func delete(_ recipes: [Recipe], from context: ModelContext) {
        guard !recipes.isEmpty else { return }
        deleted = recipes.map(RecipeSnapshot.init)
        deletionID = UUID()
        for recipe in recipes {
            context.delete(recipe)
        }
    }

    func delete(_ recipe: Recipe, from context: ModelContext) {
        delete([recipe], from: context)
    }

    /// Puts the recipes of the latest deletion back.
    func undo(in context: ModelContext) {
        for snapshot in deleted {
            context.insert(snapshot.makeRecipe())
        }
        deleted = []
    }

    /// Forgets the latest deletion, e.g. when the banner times out.
    func dismiss() {
        deleted = []
    }
}
