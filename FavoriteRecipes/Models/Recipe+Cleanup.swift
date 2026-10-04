import Foundation

extension Recipe {
    /// The text the cleanup step reads.
    var textFields: RecipeTextFields {
        RecipeTextFields(
            name: name,
            ingredients: RecipeTextFields.lines(of: ingredientsText),
            steps: RecipeTextFields.lines(of: instructions)
        )
    }

    /// Applies the accepted corrections.
    func apply(_ proposal: CleanupProposal) {
        if let newName = proposal.name { name = newName }
        if let newIngredients = proposal.ingredients { ingredientsText = newIngredients }
        if let newInstructions = proposal.instructions { instructions = newInstructions }
    }
}
