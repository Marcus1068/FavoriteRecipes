import AppIntents

/// Opens the web import for a recipe page. Meant for Shortcuts: add it to a shortcut that accepts
/// links from the share sheet to send a recipe page from Safari straight into the app.
struct ImportRecipeIntent: AppIntent {
    static let title: LocalizedStringResource = "Import Recipe from Link"
    static let description = IntentDescription("Opens FavoriteRecipes and imports the recipe on a web page.")
    static let openAppWhenRun = true

    @Parameter(title: "Link")
    var link: URL

    @Dependency private var navigation: AppNavigation

    @MainActor
    func perform() async throws -> some IntentResult {
        navigation.request(.importRecipe(address: link.absoluteString))
        return .result()
    }
}
