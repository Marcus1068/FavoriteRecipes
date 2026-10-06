import SwiftUI
import SwiftData
import AppIntents

@main
struct FavoriteRecipesApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let sharedModelContainer: ModelContainer
    @State private var navigation: AppNavigation
    @State private var undoDelete = UndoDeleteModel()
    @State private var shoppingStore: ShoppingStore
    @State private var timerCenter = UITestSupport.isActive
        ? TimerCenter(notifier: SilentTimerNotifier(), activities: NoTimerActivities())
        : TimerCenter()

    init() {
        let schema = Schema([Recipe.self])
        if UITestSupport.isActive { UITestSupport.prepareDefaults() }
        let preparedContainer = UITestSupport.isActive
            ? UITestSupport.makeContainer(schema: schema)
            : ModelContainer.make(schema: schema)
        if let preparedContainer {
            sharedModelContainer = preparedContainer
        } else {
            // An in-memory store is the last resort; there is nothing left to fall back to.
            // swiftlint:disable:next force_try
            sharedModelContainer = try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
            )
        }

        _shoppingStore = State(initialValue: UITestSupport.isActive ? UITestSupport.makeShoppingStore() : ShoppingStore())

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
                .environment(shoppingStore)
                .environment(timerCenter)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            // Keyboard shortcuts for iPad and Mac.
            CommandGroup(replacing: .newItem) {
                Button(.newRecipeMenu, systemImage: "square.and.pencil") {
                    navigation.request(.newRecipe)
                }
                .keyboardShortcut("n")
                Button(.importFromWeb, systemImage: "globe") {
                    navigation.request(.importRecipe(address: nil))
                }
                .keyboardShortcut("i")
            }
        }
    }
}
