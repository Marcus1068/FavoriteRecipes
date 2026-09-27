import SwiftUI

/// Category wheel picker.
struct RecipeCategorySection: View {
    @Bindable var recipe: Recipe

    var body: some View {
        Section {
            Picker(.category, selection: $recipe.category) {
                ForEach(RecipeCategory.allCases) { cat in
                    HStack {
                        Text(cat.icon)
                        Text(cat.localizedName)
                    }
                    .tag(cat)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
        } header: {
            Label(.category, systemImage: "tag.fill")
        }
    }
}
