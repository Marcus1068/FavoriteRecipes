import Foundation
import Observation

/// State and logic for importing a recipe from a web address,
/// with a fallback that builds a draft from pasted page text.
@MainActor
@Observable
final class ImportRecipeModel {
    var urlText: String
    var pastedText = ""
    private(set) var isImporting = false
    private(set) var errorMessage: String?

    private let isAssistantAvailable: () -> Bool
    private let organize: (String) async throws -> RecipeSuggestion

    init(
        urlText: String = "",
        isAssistantAvailable: @escaping () -> Bool = { RecipeAssistant.isAvailable },
        organize: @escaping (String) async throws -> RecipeSuggestion = { try await RecipeAssistant.structure($0) }
    ) {
        self.urlText = urlText
        self.isAssistantAvailable = isAssistantAvailable
        self.organize = organize
    }

    var canImport: Bool {
        !isImporting && !urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The paste fallback is offered once the web import has failed.
    var offersPasteFallback: Bool { errorMessage != nil }

    var canUsePastedText: Bool {
        !isImporting && !pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns an unsaved draft, or nil and sets `errorMessage`.
    func importRecipe() async -> Recipe? {
        errorMessage = nil
        guard let url = RecipeWebImporter.normalizedURL(from: urlText) else {
            errorMessage = RecipeWebImporter.ImportError.invalidURL.errorDescription
            return nil
        }
        isImporting = true
        defer { isImporting = false }
        do {
            let (imported, imageData) = try await RecipeWebImporter.fetch(from: url)
            return RecipeWebImporter.makeDraft(from: imported, imageData: imageData)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// Builds a draft from text the user pasted from the page. With Apple Intelligence the text is
    /// organized into name, ingredients and steps; otherwise it is kept as the ingredients text.
    func draftFromPastedText() async -> Recipe? {
        let text = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        isImporting = true
        defer { isImporting = false }

        let recipe = Recipe()
        recipe.ingredientsType = .text
        recipe.ingredientsText = text
        recipe.sourceURLString = RecipeWebImporter.normalizedURL(from: urlText)?.absoluteString

        if isAssistantAvailable(), let suggestion = try? await organize(text) {
            recipe.applySuggestion(
                name: suggestion.name,
                category: suggestion.category.recipeCategory,
                ingredients: suggestion.ingredients,
                steps: suggestion.steps,
                updatingCategory: true
            )
        }
        return recipe
    }
}
