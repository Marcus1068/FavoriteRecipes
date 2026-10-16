import UniformTypeIdentifiers

extension UTType {
    /// A recipe saved as a file (`.favoriterecipe`). Declared in Info.plist so the app opens these files.
    nonisolated static let favoriteRecipe = UTType(exportedAs: "de.marcus-deuss.FavoriteRecipes.recipe")
}
