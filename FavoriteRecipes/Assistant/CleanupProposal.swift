import Foundation

/// The changes the cleanup step suggests. A field is nil when nothing should change.
struct CleanupProposal: Identifiable {
    let id = UUID()
    var name: String?
    var ingredients: String?
    var instructions: String?

    var isEmpty: Bool {
        name == nil && ingredients == nil && instructions == nil
    }

    /// Compares the model's answer with the recipe and keeps only real changes.
    /// An empty answer, or one that dropped more than half of the lines, is ignored
    /// so a bad response can never wipe out the user's text.
    static func make(for recipe: Recipe, cleaned: RecipeTextFields) -> CleanupProposal {
        var proposal = CleanupProposal()

        let newName = cleaned.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !newName.isEmpty, newName != recipe.name.trimmingCharacters(in: .whitespacesAndNewlines) {
            proposal.name = newName
        }
        proposal.ingredients = change(from: recipe.ingredientsText, to: cleaned.ingredients)
        proposal.instructions = change(from: recipe.instructions, to: cleaned.steps)
        return proposal
    }

    private static func change(from original: String?, to cleaned: [String]) -> String? {
        let before = RecipeTextFields.lines(of: original)
        let after = cleaned
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !after.isEmpty, after.count * 2 >= before.count, after != before else { return nil }
        return after.joined(separator: "\n")
    }
}
