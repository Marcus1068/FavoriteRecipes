import SwiftUI
import SwiftData
import AppIntents

@main
struct FavoriteRecipesApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let sharedModelContainer: ModelContainer
    @State private var navigation: AppNavigation
    @State private var undoDelete = UndoDeleteModel()

    init() {
        let schema = Schema([Recipe.self])
        if let container = ModelContainer.make(schema: schema) {
            sharedModelContainer = container
        } else {
            // An in-memory store is the last resort; there is nothing left to fall back to.
            // swiftlint:disable:next force_try
            sharedModelContainer = try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
            )
        }

        // App Intents (Siri, Shortcuts, Spotlight) use the same store and navigation as the UI.
        let container = sharedModelContainer
        let navigation = AppNavigation()
        _navigation = State(initialValue: navigation)
        AppDependencyManager.shared.add(dependency: container)
        AppDependencyManager.shared.add(dependency: navigation)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(navigation)
                .environment(undoDelete)
        }
        .modelContainer(sharedModelContainer)
    }
}
