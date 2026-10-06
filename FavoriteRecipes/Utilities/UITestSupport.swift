import Foundation
import SwiftData

/// A fixed, predictable app state for UI tests. It is switched on by launch arguments only
/// and never changes how the app behaves for people.
///
/// - `-ui-testing`: in-memory store without iCloud, onboarding skipped, no notification prompt.
/// - `-ui-empty`: start without recipes instead of the sample recipes.
/// - `-ui-onboarding`: show the introduction.
enum UITestSupport {
    static var isActive: Bool { CommandLine.arguments.contains("-ui-testing") }
    private static var startsEmpty: Bool { CommandLine.arguments.contains("-ui-empty") }
    private static var showsOnboarding: Bool { CommandLine.arguments.contains("-ui-onboarding") }

    /// Resets the settings the tests depend on.
    static func prepareDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(!showsOnboarding, forKey: "hasSeenOnboarding")
        defaults.removeObject(forKey: "recipeSort")
        defaults.removeObject(forKey: "unitSystem")
        defaults.set(false, forKey: "inspireMeIncludesFavorites")
    }

    /// A shopping list that starts empty and is kept apart from the real one.
    static func makeShoppingStore() -> ShoppingStore {
        let defaults = UserDefaults(suiteName: "ui-testing") ?? .standard
        defaults.removePersistentDomain(forName: "ui-testing")
        return ShoppingStore(defaults: defaults)
    }

    static func makeContainer(schema: Schema) -> ModelContainer? {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        guard let container = try? ModelContainer(for: schema, configurations: [configuration]) else { return nil }
        if !startsEmpty {
            seed(container.mainContext)
        }
        return container
    }

    /// Three recipes with known names, ratings, tags and creation dates:
    /// Carbonara is the newest, Apple Pie the best rated.
    private static func seed(_ context: ModelContext) {
        let now = Date.now

        let carbonara = Recipe(name: "Carbonara", category: .noodles)
        carbonara.createdAt = now
        carbonara.rating = 4
        carbonara.servings = 4
        carbonara.tags = ["weeknight"]
        carbonara.ingredientsText = "400 g spaghetti\n150 g guanciale\n4 egg yolks"
        carbonara.instructions = "1. Boil the pasta\n2. Fry the guanciale for 10 minutes\n3. Mix everything"

        let pie = Recipe(name: "Apple Pie", category: .cake)
        pie.createdAt = now.addingTimeInterval(-86_400)
        pie.rating = 5
        pie.tags = ["baking"]
        pie.ingredientsText = "6 apples\n200 g flour\n2 egg yolks"
        pie.instructions = "1. Peel the apples\n2. Bake for 45 minutes"

        let risotto = Recipe(name: "Mushroom Risotto", category: .vegetarian)
        risotto.createdAt = now.addingTimeInterval(-2 * 86_400)
        risotto.rating = 3
        risotto.ingredientsText = "350 g arborio rice\n300 g mushrooms"

        for recipe in [carbonara, pie, risotto] {
            context.insert(recipe)
        }
        try? context.save()
    }
}

/// Timer notifications are not scheduled in UI tests, so no permission prompt appears.
struct SilentTimerNotifier: TimerNotifying {
    func schedule(id: UUID, title: String, endDate: Date) async {}
    func cancel(id: UUID) async {}
}
