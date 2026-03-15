import SwiftUI
import SwiftData

@main
struct FavoriteRecipesApp: App {

    @Environment(\.scenePhase) private var scenePhase

    let sharedModelContainer: ModelContainer

    init() {
        let schema = Schema([Recipe.self])

        // Attempt CloudKit-backed storage; fall back to local; fall back to
        // in-memory.  Never crash — a degraded experience is better than
        // a launch crash, especially on Mac where entitlements or sandbox
        // restrictions may prevent persistent storage on first run.
        if let container = ModelContainer.make(schema: schema) {
            sharedModelContainer = container
        } else {
            // Last resort: in-memory container so the app at least opens.
            sharedModelContainer = try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
#if targetEnvironment(macCatalyst)
                .onAppear {
                    MacWindowManager.configure()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .inactive || phase == .background {
                        MacWindowManager.saveFrame()
                    }
                }
#endif
        }
        .modelContainer(sharedModelContainer)
    }
}
