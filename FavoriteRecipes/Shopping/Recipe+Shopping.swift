import Foundation

extension Recipe {
    /// This recipe for the shopping list, at the servings it is written for.
    var shoppingRecipe: ShoppingRecipe {
        ShoppingRecipe(id: id, title: displayName, servings: servings, ingredients: IngredientParser.parseLines(ingredientsText))
    }
}
