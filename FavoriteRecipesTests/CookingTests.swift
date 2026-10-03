import Testing
@testable import FavoriteRecipes

struct CookingParserTests {
    @Test func stepsDropNumberingAndBullets() {
        let text = "1. Boil water\n2) Cook pasta\n- Mix\n• Serve\n\n  "
        #expect(CookingParser.steps(from: text) == ["Boil water", "Cook pasta", "Mix", "Serve"])
    }

    @Test func stepsKeepUnnumberedLines() {
        #expect(CookingParser.steps(from: "Stir well\nBake 20 min") == ["Stir well", "Bake 20 min"])
    }

    @Test func ingredientsKeepQuantities() {
        let text = "4 Eggs\n- 200 ml milk\n\n100 g flour"
        #expect(CookingParser.ingredients(from: text) == ["4 Eggs", "200 ml milk", "100 g flour"])
    }

    @Test func missingTextGivesNoLines() {
        #expect(CookingParser.steps(from: nil).isEmpty)
        #expect(CookingParser.ingredients(from: "  \n ").isEmpty)
    }
}

@MainActor
struct CookingModelTests {
    @Test func stepsStayWithinBounds() {
        let model = CookingModel(steps: ["a", "b"], ingredients: [])
        model.previousStep()
        #expect(model.currentStep == 0)
        model.nextStep()
        #expect(model.currentStep == 1 && model.isLastStep)
        model.nextStep()
        #expect(model.currentStep == 1)
    }

    @Test func togglesIngredients() {
        let model = CookingModel(steps: [], ingredients: ["a", "b"])
        model.toggleIngredient(1)
        #expect(model.isChecked(1) && !model.isChecked(0))
        model.toggleIngredient(1)
        #expect(!model.isChecked(1))
        model.toggleIngredient(5)
        #expect(model.checkedIngredients.isEmpty)
    }

    @Test func buildsFromRecipe() {
        let recipe = Recipe(name: "Pasta")
        recipe.ingredientsText = "200 g pasta\n1 onion"
        recipe.instructions = "1. Boil\n2. Serve"
        let model = CookingModel(recipe: recipe)
        #expect(model.ingredients.count == 2)
        #expect(model.steps == ["Boil", "Serve"])
    }
}
