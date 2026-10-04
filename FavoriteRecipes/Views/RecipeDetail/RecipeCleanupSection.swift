import SwiftUI

/// Button that asks Apple Intelligence to fix typos and tidy the title,
/// then lets the user review the changes before they are applied.
struct RecipeCleanupSection: View {
    @Bindable var recipe: Recipe
    @State private var model = RecipeCleanupModel()

    var body: some View {
        Section {
            Button {
                Task { await model.run(on: recipe) }
            } label: {
                if model.isWorking {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text(.cleanUpWorking)
                    }
                } else {
                    Label(.cleanUpWithAI, systemImage: "sparkles")
                }
            }
            .disabled(model.isWorking)
            .sheet(item: $model.proposal) { proposal in
                CleanupReviewView(proposal: proposal, recipe: recipe) { recipe.apply(proposal) }
            }

            if let notice = model.notice {
                Label(notice, systemImage: "info.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
