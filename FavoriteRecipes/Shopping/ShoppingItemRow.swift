import SwiftUI

/// One merged shopping item with a checkbox.
struct ShoppingItemRow: View {
    let item: ShoppingItem
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Label {
                Text(item.text)
                    .strikethrough(isChecked)
                    .foregroundStyle(isChecked ? .secondary : .primary)
            } icon: {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isChecked ? Color.accentColor : .secondary)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("shoppingItem")
        .accessibilityValue(isChecked ? Text(.ingredientReady) : Text(verbatim: ""))
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }
}
