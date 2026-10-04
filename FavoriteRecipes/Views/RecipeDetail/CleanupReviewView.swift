import SwiftUI

/// Shows each suggested correction next to the current text so the user can accept or discard them.
struct CleanupReviewView: View {
    let proposal: CleanupProposal
    let recipe: Recipe
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    init(proposal: CleanupProposal, recipe: Recipe, onApply: @escaping () -> Void) {
        self.proposal = proposal
        self.recipe = recipe
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            List {
                if let name = proposal.name {
                    CleanupChangeSection(title: .name, before: recipe.name, after: name)
                }
                if let ingredients = proposal.ingredients {
                    CleanupChangeSection(title: .ingredients, before: recipe.ingredientsText ?? "", after: ingredients)
                }
                if let instructions = proposal.instructions {
                    CleanupChangeSection(title: .instructions, before: recipe.instructions ?? "", after: instructions)
                }
            }
            .navigationTitle(.cleanUpReviewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.apply) {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }
}
