import SwiftUI
import SwiftData

/// 3-D perspective carousel.
///
/// Card sizing strategy
/// ────────────────────
/// RecipesView gives the carousel ALL remaining vertical space via
/// `.frame(maxHeight: .infinity)`.  The internal GeometryReader reads
/// that exact height (`geo.size.height`) and derives card dimensions from it:
///
///   cardH = geo.size.height - 8            (4 pt breathing room top & bottom)
///   cardW = min(cardH * 0.75, geo.width * widthFraction)
///
/// Using height as the primary dimension means cards never overflow the
/// allocated area regardless of device or orientation.  The `* 0.75` cap
/// ensures cards on very tall layouts (large iPad portrait) keep a sensible
/// aspect ratio without becoming narrow slivers.
///
/// contextMenu lives on the stable ZStack — never on individual cards — to
/// prevent UIKit gesture-recogniser orphaning when a card is removed while
/// a long-press is in progress.
struct CarouselView: View {
    let recipes: [Recipe]
    @Binding var currentIndex: Int

    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @GestureState private var dragOffset: CGFloat = 0
    @State private var recipeToEdit: Recipe?

    private var safeIndex: Int {
        guard !recipes.isEmpty else { return 0 }
        return max(0, min(currentIndex, recipes.count - 1))
    }

    var body: some View {
        GeometryReader { geo in
            // ── Card dimensions ─────────────────────────────────────────────
            let isRegular  = hSizeClass == .regular          // iPad / Mac
            // Width fraction of the container width for center card
            let wFraction: CGFloat = isRegular ? 0.55 : 0.84
            // Card height fills the allocated carousel height (minus 8 pt margin)
            let cardH = geo.size.height - 8
            // Card width: use fraction of container OR a portrait-aspect cap so
            // cards on very wide/tall screens don't become unnaturally narrow.
            let cardW = min(geo.size.width * wFraction,
                            cardH * 0.80,                    // max 4:5 portrait ratio
                            isRegular ? 520 : 400)           // absolute pixel cap
            let spacing: CGFloat = isRegular ? 32 : 20
            let step = cardW + spacing

            ZStack {
                ForEach(Array(recipes.enumerated()), id: \.element.id) { i, recipe in
                    let delta     = CGFloat(i - safeIndex) * step + dragOffset
                    let absNorm   = abs(delta) / step
                    let scale     = max(0.84, 1.0 - absNorm * 0.09)
                    let rotY      = Double(delta / (cardW * 1.6)) * 13.0
                    let opacity   = max(0.42, 1.0 - absNorm * 0.42)
                    let isCurrent = i == safeIndex

                    RecipeCardView(
                        recipe: recipe,
                        cardWidth: cardW,
                        cardHeight: cardH,
                        showContextMenu: false
                    )
                    .scaleEffect(scale)
                    .rotation3DEffect(
                        .degrees(rotY),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.45
                    )
                    .shadow(
                        color: recipe.category.color.opacity(isCurrent ? 0.48 : 0.12),
                        radius: isCurrent ? 24 : 8,
                        x: 0,
                        y: isCurrent ? 18 : 5
                    )
                    .opacity(opacity)
                    .offset(x: delta)
                    .zIndex(isCurrent ? 100 : Double(recipes.count - abs(i - safeIndex)))
                    .animation(
                        .interactiveSpring(response: 0.30, dampingFraction: 0.86),
                        value: dragOffset
                    )
                    .animation(
                        .spring(response: 0.42, dampingFraction: 0.82),
                        value: currentIndex
                    )
                }
            }
            // ZStack fills full allocated width; height = cardH (not geo.size.height)
            // so the clip mask never hides the card edges.
            .frame(width: geo.size.width, height: cardH)
            // Vertically centre the card frame within the allocated carousel space.
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .clipped()
            .contentShape(Rectangle())
            // ── Context menu on the stable ZStack ───────────────────────────
            .contextMenu {
                if let recipe = recipes[safe: safeIndex] {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                            recipe.isFavorite.toggle()
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Label(
                            recipe.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: recipe.isFavorite ? "heart.slash" : "heart"
                        )
                    }

                    Button { recipeToEdit = recipe } label: {
                        Label("Edit Recipe", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        if safeIndex >= recipes.count - 1 {
                            withAnimation { currentIndex = max(0, recipes.count - 2) }
                        }
                        modelContext.delete(recipe)
                    } label: {
                        Label("Delete Recipe", systemImage: "trash")
                    }
                }
            }
            // simultaneousGesture lets drag co-exist with contextMenu long-press.
            .simultaneousGesture(
                DragGesture(minimumDistance: 12, coordinateSpace: .local)
                    .updating($dragOffset) { value, state, _ in
                        let atStart = safeIndex == 0 && value.translation.width > 0
                        let atEnd   = safeIndex == recipes.count - 1 && value.translation.width < 0
                        state = (atStart || atEnd)
                            ? value.translation.width * 0.28
                            : value.translation.width
                    }
                    .onEnded { value in
                        let extra     = value.predictedEndTranslation.width - value.translation.width
                        let effective = value.translation.width + extra * 0.35
                        let threshold = step * 0.28

                        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                            if effective < -threshold, safeIndex < recipes.count - 1 {
                                currentIndex = safeIndex + 1
                            } else if effective > threshold, safeIndex > 0 {
                                currentIndex = safeIndex - 1
                            }
                        }
                    }
            )
            .sheet(item: $recipeToEdit) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
    }
}
