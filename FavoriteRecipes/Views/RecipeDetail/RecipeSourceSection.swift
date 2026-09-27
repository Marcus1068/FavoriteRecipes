import SwiftUI

/// The web address a recipe came from, with a link to open it.
struct RecipeSourceSection: View {
    @Bindable var recipe: Recipe

    var body: some View {
        Section {
            TextField(.sourcePlaceholder, text: Binding(emptyAsNil: $recipe.sourceURLString))
                .keyboardType(.URL)
                .textContentType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if let url = recipe.sourceURL {
                Link(destination: url) {
                    Label(.openSource, systemImage: "safari")
                }
            }
        } header: {
            Label(.source, systemImage: "link")
        }
    }
}
