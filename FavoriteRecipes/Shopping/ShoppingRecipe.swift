import Foundation

/// A recipe on the shopping list, with its ingredients already scaled to the servings the user wants.
struct ShoppingRecipe: Codable, Equatable, Identifiable {
    /// The recipe's id, so adding the same recipe again replaces it instead of doubling it.
    var id: UUID
    var title: String
    var servings: Int?
    var ingredients: [Ingredient]
}

/// One line of the merged shopping list.
struct ShoppingItem: Equatable, Identifiable {
    /// Identifies the ingredient across recipes (name and kind of unit).
    var id: String
    var text: String
}
