import SwiftUI

struct FavoritesSection: View {
    let recipes: [Recipe]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text(.favorites)
                    .font(.title3.bold())
                Spacer()
                Text("\(recipes.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.15), in: Capsule())
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(recipes) { recipe in
                        FavoriteRecipeCard(recipe: recipe)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 4)
            }
        }
    }
}

struct FavoriteRecipeCard: View {
    @Bindable var recipe: Recipe
    @State private var showDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                if let data = recipe.recipeImageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 112, height: 112)
                        .clipped()
                } else {
                    recipe.category.color.opacity(0.25)
                    Text(recipe.category.icon)
                        .font(.system(size: 36))
                }
            }
            .frame(width: 112, height: 112)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .topTrailing) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(5)
                    .background(.ultraThinMaterial, in: Circle())
                    .padding(5)
            }

            Text(recipe.name.isEmpty ? String(localized: .untitled) : recipe.name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .frame(width: 112, alignment: .leading)

            Text(recipe.category.localizedName)
                .font(.caption2)
                .foregroundStyle(recipe.category.color)
                .frame(width: 112, alignment: .leading)
        }
        .onTapGesture { showDetail = true }
        .contextMenu {
            Button {
                withAnimation(.spring()) { recipe.isFavorite = false }
            } label: {
                Label(.removeFromFavorites, systemImage: "heart.slash")
            }
            Button { showDetail = true } label: {
                Label(.editRecipe, systemImage: "pencil")
            }
        }
        .sheet(isPresented: $showDetail) {
            RecipeDetailView(recipe: recipe)
        }
    }
}
