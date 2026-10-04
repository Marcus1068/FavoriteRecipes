import SwiftUI
import SwiftData

/// Small square card in the favorites strip; tap to open, long-press for options.
struct FavoriteRecipeCard: View {
    @Bindable var recipe: Recipe
    @Environment(\.modelContext) private var modelContext
    @State private var showDetail = false
    @State private var copyToEdit: Recipe?
    @State private var recipeToCook: Recipe?

    @ScaledMetric(relativeTo: .largeTitle) private var placeholderIconSize = 36
    @ScaledMetric private var side: CGFloat = 112

    var body: some View {
        Button { showDetail = true } label: {
            VStack(alignment: .leading, spacing: 6) {
                ZStack {
                    if let data = recipe.recipeImageData {
                        DownsampledImage(data: data, id: recipe.id.uuidString, maxPointSize: side)
                            .scaledToFill()
                            .frame(width: side, height: side)
                            .clipped()
                    } else {
                        recipe.category.color.opacity(0.25)
                        Text(recipe.category.icon)
                            .font(.system(size: placeholderIconSize))
                    }
                }
                .frame(width: side, height: side)
                .clipShape(.rect(cornerRadius: 16))
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(5)
                        .background(.ultraThinMaterial, in: .circle)
                        .padding(5)
                }
                .accessibilityHidden(true)

                Text(recipe.name.isEmpty ? String(localized: .untitled) : recipe.name)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .frame(width: side, alignment: .leading)

                Text(recipe.category.localizedName)
                    .font(.caption)
                    .foregroundStyle(recipe.category.color)
                    .frame(width: side, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .contextMenu {
            Button {
                withAnimation(.spring()) { recipe.isFavorite = false }
            } label: {
                Label(.removeFromFavorites, systemImage: "heart.slash")
            }
            Button { recipeToCook = recipe } label: {
                Label(.cookingMode, systemImage: "frying.pan")
            }
            Button { showDetail = true } label: {
                Label(.editRecipe, systemImage: "pencil")
            }
            Button { copyToEdit = recipe.duplicate(in: modelContext) } label: {
                Label(.duplicate, systemImage: "plus.square.on.square")
            }
        }
        .sheet(item: $copyToEdit) { copy in
            RecipeDetailView(recipe: copy)
        }
        .cookingModeCover(item: $recipeToCook)
        .sheet(isPresented: $showDetail) {
            RecipeDetailView(recipe: recipe)
        }
    }
}
