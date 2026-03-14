import SwiftUI

/// A single recipe card used inside the main carousel.
struct RecipeCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recipe: Recipe

    @State private var showDetail = false
    @State private var shareItem: ShareItem?
    @State private var isExtracting = false
    @State private var favoriteAnimating = false

    var body: some View {
        ZStack(alignment: .bottom) {
            recipeBackground

            VStack(spacing: 0) {
                // Top row – favorite badge
                HStack {
                    Spacer()
                    if recipe.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.title3)
                            .padding(9)
                            .background(.ultraThinMaterial, in: Circle())
                            .padding(12)
                            .scaleEffect(favoriteAnimating ? 1.45 : 1.0)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Spacer()

                // Bottom info strip
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 3) {
                            Label(recipe.category.rawValue, systemImage: "tag.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.85))
                            Text(recipe.name.isEmpty ? "Untitled Recipe" : recipe.name)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .lineLimit(2)
                        }
                        Spacer()
                        Text(recipe.category.icon)
                            .font(.system(size: 38))
                    }

                    HStack(spacing: 10) {
                        // Share button
                        Button {
                            guard !isExtracting else { return }
                            isExtracting = true
                            Task {
                                let text = await TextExtractor.extract(from: recipe)
                                await MainActor.run {
                                    isExtracting = false
                                    shareItem = ShareItem(text: text)
                                }
                            }
                        } label: {
                            HStack(spacing: 5) {
                                if isExtracting {
                                    ProgressView().scaleEffect(0.7).tint(.white)
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                Text(isExtracting ? "Extracting…" : "Share")
                            }
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(.ultraThinMaterial, in: Capsule())
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // Edit button
                        Button { showDetail = true } label: {
                            Image(systemName: "pencil")
                                .font(.caption.weight(.medium))
                                .padding(8)
                                .background(.ultraThinMaterial, in: Circle())
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.78)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .contextMenu {
            Button {
                toggleFavorite()
            } label: {
                Label(
                    recipe.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: recipe.isFavorite ? "heart.slash" : "heart"
                )
            }
            Button { showDetail = true } label: {
                Label("Edit Recipe", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                modelContext.delete(recipe)
            } label: {
                Label("Delete Recipe", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showDetail) {
            RecipeDetailView(recipe: recipe)
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.text])
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var recipeBackground: some View {
        if let data = recipe.recipeImageData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [recipe.category.color.opacity(0.85), recipe.category.color.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Text(recipe.category.icon)
                    .font(.system(size: 95))
                    .opacity(0.35)
                    .offset(x: 40, y: -40)
            }
        }
    }

    // MARK: - Favorite Toggle

    private func toggleFavorite() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            recipe.isFavorite.toggle()
            favoriteAnimating = true
        }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            withAnimation { favoriteAnimating = false }
        }
    }
}

// MARK: - Share Item wrapper

struct ShareItem: Identifiable {
    let id = UUID()
    let text: String
}
