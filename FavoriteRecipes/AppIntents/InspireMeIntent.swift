import AppIntents
import SwiftData

/// Picks a random recipe and shows it in the app.
struct InspireMeIntent: AppIntent {
    static let title: LocalizedStringResource = "Inspire Me"
    static let description = IntentDescription("Picks a random recipe from your collection.")
    static let supportedModes: IntentModes = .foreground

    @Dependency private var modelContainer: ModelContainer
    @Dependency private var navigation: AppNavigation

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let recipes = try modelContainer.mainContext.fetch(FetchDescriptor<Recipe>())
        guard let recipe = InspirationPicker.pick(from: recipes, avoiding: nil) else {
            return .result(dialog: IntentDialog(.inspireMeNoRecipes))
        }
        navigation.showRecipe(id: recipe.id)
        return .result(dialog: IntentDialog(.inspireMeDialog(recipe.displayName)))
    }
}
