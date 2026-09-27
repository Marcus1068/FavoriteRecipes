import SwiftUI
import SwiftData

@main
struct FavoriteRecipesApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let sharedModelContainer: ModelContainer

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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
