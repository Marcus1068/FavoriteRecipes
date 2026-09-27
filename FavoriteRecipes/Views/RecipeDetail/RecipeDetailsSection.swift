import SwiftUI

/// Servings and prep/cook times. Zero means "not set" and is stored as nil.
struct RecipeDetailsSection: View {
    @Bindable var recipe: Recipe

    var body: some View {
        Section {
            Stepper(value: Binding(zeroAsNil: $recipe.servings), in: 0...50) {
                LabeledContent(.servings) {
                    if let servings = recipe.servings {
                        Text(servings, format: .number)
                    } else {
                        Text(.notSet)
                    }
                }
            }
            Stepper(value: Binding(zeroAsNil: $recipe.prepMinutes), in: 0...600, step: 5) {
                LabeledContent(.prepTime) { DurationText(minutes: recipe.prepMinutes) }
            }
            Stepper(value: Binding(zeroAsNil: $recipe.cookMinutes), in: 0...600, step: 5) {
                LabeledContent(.cookTime) { DurationText(minutes: recipe.cookMinutes) }
            }
        } header: {
            Label(.details, systemImage: "clock")
        }
    }
}
