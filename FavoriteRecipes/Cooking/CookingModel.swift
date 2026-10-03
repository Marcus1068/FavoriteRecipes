import Foundation
import Observation

/// State for cooking mode: the recipe's steps, which step is shown,
/// and which ingredients have been ticked off.
@MainActor
@Observable
final class CookingModel {
    let steps: [String]
    let ingredients: [String]
    var currentStep = 0
    private(set) var checkedIngredients: Set<Int> = []

    init(steps: [String], ingredients: [String]) {
        self.steps = steps
        self.ingredients = ingredients
    }

    convenience init(recipe: Recipe) {
        self.init(
            steps: CookingParser.steps(from: recipe.instructions),
            ingredients: CookingParser.ingredients(from: recipe.ingredientsText)
        )
    }

    var isFirstStep: Bool { currentStep == 0 }
    var isLastStep: Bool { currentStep >= steps.count - 1 }

    func nextStep() {
        guard !isLastStep else { return }
        currentStep += 1
    }

    func previousStep() {
        guard !isFirstStep else { return }
        currentStep -= 1
    }

    func isChecked(_ index: Int) -> Bool {
        checkedIngredients.contains(index)
    }

    func toggleIngredient(_ index: Int) {
        guard ingredients.indices.contains(index) else { return }
        if !checkedIngredients.insert(index).inserted {
            checkedIngredients.remove(index)
        }
    }
}
