import SwiftData

extension ModelContainer {
    /// Tries CloudKit-backed storage, then local persistent storage.
    /// Returns nil only if both fail (caller should fall back to in-memory).
    static func make(schema: Schema) -> ModelContainer? {
        // 1 — CloudKit (synced across devices)
        if let container = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.marcus.FavoriteRecipes")
            )]
        ) { return container }

        // 2 — Local persistent storage (no sync)
        if let container = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )]
        ) { return container }

        return nil
    }
}
