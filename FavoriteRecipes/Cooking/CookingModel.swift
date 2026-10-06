import Foundation
import Observation

/// State for cooking mode: the recipe's steps, which step is shown,
/// and which ingredients have been ticked off.
@MainActor
@Observable
final class CookingModel {
    let steps: [String]
    let ingredients: [String]
    /// Used to name the timers started from a step.
    let recipeName: String
    /// The servings the recipe is written for; nil when it does not say.
    let baseServings: Int?
    let recipeID: UUID?
    /// The ingredient lines read into amount, unit and name.
    let parsedIngredients: [Ingredient]
    /// The servings the cook wants; amounts are scaled to this.
    var servings: Int
    var currentStep = 0
    private(set) var checkedIngredients: Set<Int> = []

    init(steps: [String], ingredients: [String], recipeName: String = "", baseServings: Int? = nil, recipeID: UUID? = nil) {
        self.steps = steps
        self.ingredients = ingredients
        self.recipeName = recipeName
        self.baseServings = baseServings
        self.recipeID = recipeID
        self.parsedIngredients = ingredients.map(IngredientParser.parse)
        self.servings = baseServings ?? 0
    }

    convenience init(recipe: Recipe) {
        self.init(
            steps: CookingParser.steps(from: recipe.instructions),
            ingredients: CookingParser.ingredients(from: recipe.ingredientsText),
            recipeName: recipe.displayName,
            baseServings: recipe.servings,
            recipeID: recipe.id
        )
    }

    // MARK: - Servings and units

    /// Scaling needs to know what the recipe is written for.
    var canScale: Bool { (baseServings ?? 0) > 0 }

    var scaleFactor: Double {
        guard let base = baseServings, base > 0 else { return 1 }
        return Double(servings) / Double(base)
    }

    /// The ingredient lines for the chosen servings and unit system.
    func displayLines(system: UnitSystem, locale: Locale = .current) -> [String] {
        parsedIngredients.map { $0.display(factor: scaleFactor, system: system, locale: locale) }
    }

    /// The recipe for the shopping list, with amounts for the chosen servings.
    func shoppingRecipe() -> ShoppingRecipe? {
        guard let recipeID else { return nil }
        return ShoppingRecipe(
            id: recipeID,
            title: recipeName,
            servings: canScale ? servings : baseServings,
            ingredients: parsedIngredients.map { $0.scaled(by: scaleFactor) }
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
