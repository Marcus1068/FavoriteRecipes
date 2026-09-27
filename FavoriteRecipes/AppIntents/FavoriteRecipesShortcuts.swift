import AppIntents

/// Phrases for Siri and the Shortcuts app. German phrases live in AppShortcuts.xcstrings.
struct FavoriteRecipesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: InspireMeIntent(),
            phrases: [
                "Inspire me with \(.applicationName)",
                "What should I cook with \(.applicationName)"
            ],
            shortTitle: "Inspire Me",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: OpenRecipeIntent(),
            phrases: [
                "Open \(\.$target) in \(.applicationName)",
                "Show \(\.$target) in \(.applicationName)"
            ],
            shortTitle: "Open Recipe",
            systemImageName: "fork.knife"
        )
    }
}
