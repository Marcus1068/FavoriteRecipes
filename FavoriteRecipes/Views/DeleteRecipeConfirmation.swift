import SwiftUI

/// Asks for confirmation before a recipe is deleted.
///
/// Set the bound recipe to show the dialog; it is reset to `nil` when the
/// dialog closes. `onConfirm` runs only when the user confirms.
struct DeleteRecipeConfirmation: ViewModifier {
    @Binding var recipe: Recipe?
    let onConfirm: (Recipe) -> Void

    private var isPresented: Binding<Bool> {
        Binding(
            get: { recipe != nil },
            set: { if !$0 { recipe = nil } }
        )
    }

    private var title: String {
        guard let recipe else { return "" }
        return String(localized: .deleteRecipeConfirmTitle(recipe.displayName))
    }

    func body(content: Content) -> some View {
        content.confirmationDialog(
            title,
            isPresented: isPresented,
            titleVisibility: .visible,
            presenting: recipe
        ) { recipe in
            Button(.deleteRecipe, role: .destructive) { onConfirm(recipe) }
            Button(.cancel, role: .cancel) {}
        } message: { _ in
            Text(.deleteRecipeConfirmMessage)
        }
    }
}

extension View {
    /// Shows a delete confirmation whenever `recipe` is non-nil.
    func confirmDeletion(of recipe: Binding<Recipe?>, onConfirm: @escaping (Recipe) -> Void) -> some View {
        modifier(DeleteRecipeConfirmation(recipe: recipe, onConfirm: onConfirm))
    }
}
