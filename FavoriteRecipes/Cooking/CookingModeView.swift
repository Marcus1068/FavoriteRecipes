import SwiftUI

/// Full-screen view for cooking along: tick off ingredients, then step through the preparation.
/// The screen stays awake while it is shown.
struct CookingModeView: View {
    let recipe: Recipe

    @Environment(\.dismiss) private var dismiss
    @State private var model: CookingModel
    @State private var tab = CookingTab.ingredients

    init(recipe: Recipe) {
        self.recipe = recipe
        _model = State(initialValue: CookingModel(recipe: recipe))
        // Recipes without ingredients text go straight to the steps.
        _tab = State(initialValue: CookingParser.ingredients(from: recipe.ingredientsText).isEmpty ? .steps : .ingredients)
    }

    var body: some View {
        NavigationStack {
            VStack {
                Picker(.cookingMode, selection: $tab) {
                    Text(.ingredients).tag(CookingTab.ingredients)
                    Text(.instructions).tag(CookingTab.steps)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch tab {
                case .ingredients:
                    CookingIngredientsList(model: model)
                case .steps:
                    CookingStepsView(model: model)
                }
            }
            .navigationTitle(recipe.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.done) { dismiss() }
                }
            }
        }
        .keepScreenAwake()
    }
}
