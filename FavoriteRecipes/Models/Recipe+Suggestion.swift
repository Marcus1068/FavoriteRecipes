import Foundation

extension Recipe {
    /// "1. First\n2. Second" from a list of steps, skipping blank entries.
    static func numberedSteps(_ steps: [String]) -> String? {
        let cleaned = steps
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !cleaned.isEmpty else { return nil }
        return cleaned.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
    }

    /// Merges a structured suggestion into the recipe without overwriting
    /// anything the user typed: name and preparation are only filled when empty.
    /// The category is only changed when `updatingCategory` is true (new drafts).
    func applySuggestion(
        name suggestedName: String,
        category suggestedCategory: RecipeCategory,
        ingredients: [String],
        steps: [String],
        updatingCategory: Bool
    ) {
        let cleanedIngredients = ingredients
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !cleanedIngredients.isEmpty {
            ingredientsText = cleanedIngredients.joined(separator: "\n")
        }
        if instructions?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            instructions = Self.numberedSteps(steps) ?? instructions
        }
        let trimmedName = suggestedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !trimmedName.isEmpty {
            name = trimmedName
        }
        if updatingCategory {
            category = suggestedCategory
        }
    }
}
