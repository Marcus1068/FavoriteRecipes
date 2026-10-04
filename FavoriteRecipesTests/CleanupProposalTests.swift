import Testing
@testable import FavoriteRecipes

struct CleanupProposalTests {
    private func recipe() -> Recipe {
        let recipe = Recipe(name: "Spaghetti Carbonara400 g Spaghetti")
        recipe.ingredientsText = "400 g Spaghetti\n150 g Guanciale\nSalywasser"
        recipe.instructions = "1. Nudeln kochen\n2. Guanciale braten"
        return recipe
    }

    @Test func proposesOnlyRealChanges() {
        let cleaned = RecipeTextFields(
            name: "Spaghetti Carbonara",
            ingredients: ["400 g Spaghetti", "150 g Guanciale", "Salzwasser"],
            steps: ["1. Nudeln kochen", "2. Guanciale braten"]
        )
        let proposal = CleanupProposal.make(for: recipe(), cleaned: cleaned)
        #expect(proposal.name == "Spaghetti Carbonara")
        #expect(proposal.ingredients == "400 g Spaghetti\n150 g Guanciale\nSalzwasser")
        #expect(proposal.instructions == nil, "Unchanged steps are not proposed")
    }

    @Test func ignoresWhitespaceOnlyDifferences() {
        let cleaned = RecipeTextFields(
            name: "  Spaghetti Carbonara400 g Spaghetti ",
            ingredients: [" 400 g Spaghetti", "150 g Guanciale ", "", "Salywasser"],
            steps: ["1. Nudeln kochen", "2. Guanciale braten"]
        )
        #expect(CleanupProposal.make(for: recipe(), cleaned: cleaned).isEmpty)
    }

    @Test func neverWipesTextWithAnEmptyAnswer() {
        let cleaned = RecipeTextFields(name: "", ingredients: [], steps: [])
        #expect(CleanupProposal.make(for: recipe(), cleaned: cleaned).isEmpty)
    }

    @Test func rejectsAnswerThatDroppedMostLines() {
        let cleaned = RecipeTextFields(name: "", ingredients: ["400 g Spaghetti"], steps: [])
        #expect(CleanupProposal.make(for: recipe(), cleaned: cleaned).ingredients == nil)
    }

    @Test func proposesTitleForUntitledRecipe() {
        let untitled = Recipe()
        untitled.ingredientsText = "400 g Spaghetti"
        let cleaned = RecipeTextFields(name: "Spaghetti", ingredients: ["400 g Spaghetti"], steps: [])
        #expect(CleanupProposal.make(for: untitled, cleaned: cleaned).name == "Spaghetti")
    }

    @Test func applyChangesOnlyProposedFields() {
        let recipe = recipe()
        recipe.apply(CleanupProposal(name: "Carbonara", ingredients: nil, instructions: nil))
        #expect(recipe.name == "Carbonara")
        #expect(recipe.ingredientsText == "400 g Spaghetti\n150 g Guanciale\nSalywasser")
        #expect(recipe.instructions == "1. Nudeln kochen\n2. Guanciale braten")
    }
}

@MainActor
struct RecipeCleanupModelTests {
    private func recipe() -> Recipe {
        let recipe = Recipe(name: "Pasta")
        recipe.ingredientsText = "2 Eir"
        return recipe
    }

    @Test func offersCorrectionsForReview() async {
        let model = RecipeCleanupModel { _ in
            RecipeTextFields(name: "Pasta", ingredients: ["2 Eier"], steps: [])
        }
        await model.run(on: recipe())
        #expect(model.proposal?.ingredients == "2 Eier")
        #expect(model.notice == nil)
        #expect(!model.isWorking)
    }

    @Test func reportsWhenNothingNeedsFixing() async {
        let model = RecipeCleanupModel { $0 }
        await model.run(on: recipe())
        #expect(model.proposal == nil)
        #expect(model.notice != nil)
    }

    @Test func reportsFailures() async {
        let model = RecipeCleanupModel { _ in throw CancellationError() }
        await model.run(on: recipe())
        #expect(model.proposal == nil)
        #expect(model.notice != nil)
        #expect(!model.isWorking)
    }

    @Test func reportsTooLongRecipes() async {
        let model = RecipeCleanupModel { _ in throw RecipeAssistant.CleanupError.tooLong }
        await model.run(on: recipe())
        #expect(model.notice != nil)
    }
}

struct OnboardingNavigationTests {
    @MainActor
    @Test func introductionIsHiddenByDefault() {
        #expect(AppNavigation().isShowingOnboarding == false)
    }
}
