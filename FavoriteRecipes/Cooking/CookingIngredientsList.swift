import SwiftUI

/// Ingredients with a checkbox each, so the cook can tick off what is ready.
/// Amounts follow the chosen servings and unit system.
struct CookingIngredientsList: View {
    @Bindable var model: CookingModel
    @AppStorage("unitSystem") private var unitSystemName = UnitSystem.original.rawValue

    private var unitSystem: Binding<UnitSystem> {
        Binding(
            get: { UnitSystem(rawValue: unitSystemName) ?? .original },
            set: { unitSystemName = $0.rawValue }
        )
    }

    var body: some View {
        if model.ingredients.isEmpty {
            ContentUnavailableView {
                Label(.noIngredientsTitle, systemImage: "list.bullet")
            } description: {
                Text(.noIngredientsMessage)
            }
        } else {
            let lines = model.displayLines(system: unitSystem.wrappedValue)
            List {
                CookingIngredientsHeader(model: model, unitSystem: unitSystem)

                Section {
                    ForEach(lines.indices, id: \.self) { index in
                        let isChecked = model.isChecked(index)
                        Button {
                            model.toggleIngredient(index)
                        } label: {
                            Label {
                                Text(lines[index])
                                    .strikethrough(isChecked)
                                    .foregroundStyle(isChecked ? .secondary : .primary)
                            } icon: {
                                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isChecked ? Color.accentColor : .secondary)
                                    .accessibilityHidden(true)
                            }
                            .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("ingredientRow")
                        .accessibilityValue(isChecked ? Text(.ingredientReady) : Text(verbatim: ""))
                        .accessibilityAddTraits(isChecked ? .isSelected : [])
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: model.checkedIngredients)
        }
    }
}
