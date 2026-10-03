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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var dragOffset: CGFloat = 0
    @State private var recipeToEdit: Recipe?
    @State private var recipeToCook: Recipe?
    @State private var recipeToDelete: Recipe?
    /// Incremented on each favorite toggle to drive haptic feedback.
    @State private var favoriteToggles = 0

    private var safeIndex: Int {
        guard !recipes.isEmpty else { return 0 }
        return max(0, min(currentIndex, recipes.count - 1))
    }

    var body: some View {
        GeometryReader { geo in
            // ── Card dimensions ─────────────────────────────────────────────
            let isRegular  = hSizeClass == .regular          // iPad / Mac
            // Width fraction of the container width for center card.
            // Regular is wider so the selected card dominates the frame.
            let wFraction: CGFloat = isRegular ? 0.62 : 0.84
            // Card height: fills allocated height but is capped so cards never
            // become unreasonably tall on large iPad / Mac windows.
            let cardH = min(geo.size.height - 8, isRegular ? 580 : 560)
            // Card width: fraction of container OR aspect cap so cards on very
            // wide/tall screens keep a sensible ratio.
            // Regular uses a wider 9:10 ratio so cards are more square/prominent.
            let cardW = min(geo.size.width * wFraction,
                            cardH * (isRegular ? 0.90 : 0.80),
                            isRegular ? 540 : 400)
            // Larger spacing on regular so shrunken adjacent cards don't crowd
            // the dominant center card.
            let spacing: CGFloat = isRegular ? 44 : 20
            let step = cardW + spacing

            ZStack {
                ForEach(recipes.enumerated(), id: \.element.id) { i, recipe in
                    let delta     = CGFloat(i - safeIndex) * step + dragOffset
                    let absNorm   = abs(delta) / step
                    // Regular (iPad/Mac): steeper scale falloff so the selected
                    // card is noticeably larger than its neighbours.
                    // Compact (iPhone): subtle falloff to keep the gentle feel.
                    let scaleShrink: CGFloat = isRegular ? 0.14 : 0.09
                    let scaleFloor: CGFloat  = isRegular ? 0.70 : 0.84
                    // Reduce Motion: no scaling or 3-D tilt, neighbours only fade.
                    let scale     = reduceMotion ? 1.0 : max(scaleFloor, 1.0 - absNorm * scaleShrink)
                    let rotY      = reduceMotion ? 0.0 : Double(delta / (cardW * 1.6)) * (isRegular ? 16.0 : 13.0)
                    let opacity   = max(0.42, 1.0 - absNorm * 0.42)
                    let isCurrent = i == safeIndex

                    RecipeCardView(
                        recipe: recipe,
                        cardWidth: cardW,
                        cardHeight: cardH,
                        onDelete: { recipeToDelete = recipe }
                    )
                    // Only the centre card is on screen for VoiceOver; the page
                    // indicator below is adjustable to move between recipes.
                    .accessibilityHidden(!isCurrent)
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
                    .animation(.carouselPaging(reduceMotion: reduceMotion), value: currentIndex)
                }
            }
            // ZStack fills full allocated width; height = cardH (not geo.size.height)
            // so the clip mask never hides the card edges.
            .frame(width: geo.size.width, height: cardH)
            // Vertically centre the card frame within the allocated carousel space.
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .clipped()
            .contentShape(.rect)
            .sensoryFeedback(.impact(weight: .medium), trigger: favoriteToggles)
            // ── Context menu on the stable ZStack ───────────────────────────
            .contextMenu {
                if let recipe = recipes[safe: safeIndex] {
                    Button {
                        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.6)) {
                            recipe.isFavorite.toggle()
                        }
                        favoriteToggles += 1
                    } label: {
                        Label(
                            recipe.isFavorite ? .removeFromFavorites : .addToFavorites,
                            systemImage: recipe.isFavorite ? "heart.slash" : "heart"
                        )
                    }

                    Button { recipeToCook = recipe } label: {
                        Label(.cookingMode, systemImage: "frying.pan")
                    }

                    Button { recipeToEdit = recipe } label: {
                        Label(.editRecipe, systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        recipeToDelete = recipe
                    } label: {
                        Label(.deleteRecipe, systemImage: "trash")
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

                        withAnimation(.carouselPaging(reduceMotion: reduceMotion)) {
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
            .cookingModeCover(item: $recipeToCook)
            .confirmDeletion(of: $recipeToDelete) { recipe in
                if safeIndex >= recipes.count - 1 {
                    withAnimation { currentIndex = max(0, recipes.count - 2) }
                }
                modelContext.delete(recipe)
            }
        }
    }
}
