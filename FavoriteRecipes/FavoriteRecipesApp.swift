import SwiftUI
import SwiftData

@main
struct FavoriteRecipesApp: App {

    let sharedModelContainer: ModelContainer

    init() {
        let schema = Schema([Recipe.self])

        // Attempt CloudKit-backed storage; fall back to local if unavailable.
        // NOTE: Enable iCloud + CloudKit capabilities in the project target
        // and create container "iCloud.com.marcus.FavoriteRecipes" in the
        // Apple Developer portal for sync to be active.
        do {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.marcus.FavoriteRecipes")
            )
            sharedModelContainer = try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            // CloudKit not configured or unavailable — use local storage.
            do {
                let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                sharedModelContainer = try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
