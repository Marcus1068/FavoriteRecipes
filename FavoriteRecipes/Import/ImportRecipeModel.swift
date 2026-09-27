import Foundation
import Observation

/// State and logic for importing a recipe from a web address.
@MainActor
@Observable
final class ImportRecipeModel {
    var urlText = ""
    private(set) var isImporting = false
    private(set) var errorMessage: String?

    var canImport: Bool {
        !isImporting && !urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
}
