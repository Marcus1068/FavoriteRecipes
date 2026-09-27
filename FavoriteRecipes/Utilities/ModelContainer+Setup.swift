import OSLog
import SwiftData

extension ModelContainer {
    /// Must match `com.apple.developer.icloud-container-identifiers` in FavoriteRecipes.entitlements.
    static let cloudKitContainerID = "iCloud.de.marcus-deuss.FavoriteRecipes"

    private static let logger = Logger(subsystem: "de.marcus-deuss.FavoriteRecipes", category: "Storage")

    /// Tries CloudKit-backed storage, then local persistent storage.
    /// Returns nil only if both fail (caller should fall back to in-memory).
    static func make(schema: Schema) -> ModelContainer? {
        // 1 — CloudKit (synced across devices)
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .private(cloudKitContainerID)
                )]
            )
            logger.info("Using CloudKit store (\(cloudKitContainerID, privacy: .public))")
            return container
        } catch {
            // Without this, a signing or entitlement problem silently disables sync.
            logger.error("CloudKit store unavailable, falling back to local storage: \(error, privacy: .public)")
        }

        // 2 — Local persistent storage (no sync)
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false
                )]
            )
            logger.warning("Using local store; recipes will not sync")
            return container
        } catch {
            logger.fault("Local store unavailable: \(error, privacy: .public)")
            return nil
        }
    }
}
