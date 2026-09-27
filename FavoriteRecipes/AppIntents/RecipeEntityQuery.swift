import AppIntents
import SwiftData

/// Looks up recipes for App Intents. Reads through the main context,
/// the same one the UI uses, so results match what the user sees.
struct RecipeEntityQuery: EntityStringQuery {
    @Dependency private var modelContainer: ModelContainer

    func entities(for identifiers: [RecipeEntity.ID]) async throws -> [RecipeEntity] {
        try await MainActor.run {
            let descriptor = FetchDescriptor<Recipe>(predicate: #Predicate { identifiers.contains($0.id) })
            return try modelContainer.mainContext.fetch(descriptor).map(RecipeEntity.init(recipe:))
        }
    }

    func entities(matching string: String) async throws -> [RecipeEntity] {
        try await MainActor.run {
            try modelContainer.mainContext.fetch(FetchDescriptor<Recipe>())
                .filter { $0.matches(searchText: string) }
                .map(RecipeEntity.init(recipe:))
        }
    }

    func suggestedEntities() async throws -> [RecipeEntity] {
        try await MainActor.run {
            let descriptor = FetchDescriptor<Recipe>(sortBy: [SortDescriptor(\.name)])
            return try modelContainer.mainContext.fetch(descriptor).map(RecipeEntity.init(recipe:))
        }
    }
}
