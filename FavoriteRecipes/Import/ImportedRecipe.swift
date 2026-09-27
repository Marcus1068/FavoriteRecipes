import Foundation

/// Recipe data read from a web page, before it becomes a `Recipe`.
nonisolated struct ImportedRecipe: Equatable, Sendable {
    var name = ""
    var ingredients: [String] = []
    var instructions: [String] = []
    var servings: Int?
    var prepMinutes: Int?
    var cookMinutes: Int?
    var imageURL: URL?
    var sourceURL: URL?
    /// Free-text hints such as `recipeCategory`, `recipeCuisine` and `keywords`.
    var categoryHints: [String] = []
}
