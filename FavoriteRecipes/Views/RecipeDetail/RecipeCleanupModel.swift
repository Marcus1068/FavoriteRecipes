import Foundation
import Observation

/// Runs the Apple Intelligence cleanup for one recipe and holds its outcome.
/// The assistant is injected so the flow can be tested without the language model.
@MainActor
@Observable
final class RecipeCleanupModel {
    private(set) var isWorking = false
    /// Set when there are corrections to review; the review sheet is shown for it.
    var proposal: CleanupProposal?
    /// Shown after a run that produced nothing to review.
    private(set) var notice: LocalizedStringResource?

    private let clean: (RecipeTextFields) async throws -> RecipeTextFields

    init(clean: @escaping (RecipeTextFields) async throws -> RecipeTextFields = { try await RecipeAssistant.cleanUp($0) }) {
        self.clean = clean
    }

    func run(on recipe: Recipe) async {
        notice = nil
        isWorking = true
        defer { isWorking = false }
        do {
            let cleaned = try await clean(recipe.textFields)
            let result = CleanupProposal.make(for: recipe, cleaned: cleaned)
            if result.isEmpty {
                notice = .cleanUpNoChanges
            } else {
                proposal = result
            }
        } catch is RecipeAssistant.CleanupError {
            notice = .cleanUpTooLong
        } catch {
            notice = .cleanUpFailed
        }
    }
}
