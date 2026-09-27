import AppIntents
import CoreSpotlight

/// Keeps Spotlight and Siri's recipe suggestions in sync with the collection.
enum SpotlightIndexer {
    /// Replaces the whole index; recipe collections are small, so this stays cheap.
    static func reindex(_ recipes: [Recipe]) async {
        let entities = recipes.map(RecipeEntity.init(recipe:))
        let index = CSSearchableIndex.default()
        try? await index.deleteAppEntities(ofType: RecipeEntity.self)
        try? await index.indexAppEntities(entities)
        FavoriteRecipesShortcuts.updateAppShortcutParameters()
    }

    /// Changes whenever something Spotlight shows or searches changes.
    static func signature(of recipes: [Recipe]) -> Int {
        var hasher = Hasher()
        for recipe in recipes {
            hasher.combine(recipe.id)
            hasher.combine(recipe.name)
            hasher.combine(recipe.category)
            hasher.combine(recipe.ingredientsText)
            hasher.combine(recipe.instructions)
        }
        return hasher.finalize()
    }
}
