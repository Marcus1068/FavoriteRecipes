import AppIntents

/// Opens a recipe in the app, e.g. from a Spotlight result or Siri.
struct OpenRecipeIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Recipe"

    @Parameter(title: "Recipe")
    var target: RecipeEntity

    @Dependency private var navigation: AppNavigation

    @MainActor
    func perform() async throws -> some IntentResult {
        navigation.showRecipe(id: target.id)
        return .result()
    }
}
