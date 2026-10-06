import SwiftUI

/// Servings, units and "add to shopping list" above the ingredients in cooking mode.
struct CookingIngredientsHeader: View {
    @Bindable var model: CookingModel
    @Binding var unitSystem: UnitSystem

    @Environment(ShoppingStore.self) private var shoppingStore

    var body: some View {
        Section {
            if model.canScale {
                Stepper(value: $model.servings, in: 1...100) {
                    LabeledContent(.servingsScale) {
                        Text(model.servings, format: .number)
                            .accessibilityIdentifier("servingsValue")
                    }
                }
                .accessibilityIdentifier("servingsStepper")
            }

            Picker(.unitsTitle, selection: $unitSystem) {
                ForEach(UnitSystem.allCases) { system in
                    Text(system.localizedName).tag(system)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("unitSystemPicker")

            if let recipeID = model.recipeID {
                let isOnList = shoppingStore.recipes.contains { $0.id == recipeID }
                Button {
                    if let recipe = model.shoppingRecipe() { shoppingStore.add(recipe) }
                } label: {
                    if isOnList {
                        Label(.onShoppingList, systemImage: "checkmark.circle.fill")
                    } else {
                        Label(.addToShoppingList, systemImage: "cart.badge.plus")
                    }
                }
                .sensoryFeedback(.success, trigger: shoppingStore.addedCount)
                .accessibilityIdentifier("addToShoppingListButton")
                .accessibilityHint(isOnList ? Text(.updateShoppingListHint) : Text(verbatim: ""))
            }
        }
    }
}
