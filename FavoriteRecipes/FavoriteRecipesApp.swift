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
