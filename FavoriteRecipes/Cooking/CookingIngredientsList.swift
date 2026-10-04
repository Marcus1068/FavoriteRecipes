import SwiftUI

/// Ingredients with a checkbox each, so the cook can tick off what is ready.
struct CookingIngredientsList: View {
    let model: CookingModel

    var body: some View {
        if model.ingredients.isEmpty {
            ContentUnavailableView {
                Label(.noIngredientsTitle, systemImage: "list.bullet")
            } description: {
                Text(.noIngredientsMessage)
            }
        } else {
            List(model.ingredients.indices, id: \.self) { index in
                let isChecked = model.isChecked(index)
                Button {
                    model.toggleIngredient(index)
                } label: {
                    Label {
                        Text(model.ingredients[index])
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
            .sensoryFeedback(.selection, trigger: model.checkedIngredients)
        }
    }
}
