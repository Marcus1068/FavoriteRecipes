import SwiftUI

/// Full-screen view for cooking along: tick off ingredients, then step through the preparation.
/// On wide screens (iPad, Mac) the ingredients and the steps are shown side by side.
/// The screen stays awake while it is shown.
struct CookingModeView: View {
    let recipe: Recipe

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var model: CookingModel
    @State private var tab = CookingTab.ingredients
    @State private var isLogging = false

    init(recipe: Recipe) {
        self.recipe = recipe
        _model = State(initialValue: CookingModel(recipe: recipe))
        // Recipes without ingredients text go straight to the steps.
        _tab = State(initialValue: CookingParser.ingredients(from: recipe.ingredientsText).isEmpty ? .steps : .ingredients)
    }

    var body: some View {
        NavigationStack {
            Group {
                if horizontalSizeClass == .regular {
                    HStack(alignment: .top, spacing: 0) {
                        CookingIngredientsList(model: model)
                            .containerRelativeFrame(.horizontal) { width, _ in width * 0.38 }
                        Divider()
                        CookingStepsView(model: model, onFinish: { isLogging = true })
                    }
                } else {
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
                            CookingStepsView(model: model, onFinish: { isLogging = true })
                        }
                    }
                }
            }
            .navigationTitle(recipe.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.logCooking, systemImage: "checkmark.circle") { isLogging = true }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.done) { dismiss() }
                }
            }
            .sheet(isPresented: $isLogging) {
                CookLogSheet(recipe: recipe)
            }
        }
        .keepScreenAwake()
        .tracksPresentation()
    }
}
