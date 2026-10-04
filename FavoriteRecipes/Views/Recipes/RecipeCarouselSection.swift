import SwiftUI

/// The carousel with its page dots and Inspire Me button, plus arrow-key paging.
struct RecipeCarouselSection: View {
    let recipes: [Recipe]
    let inspirationCandidates: [Recipe]
    @Binding var currentIndex: Int
    let isKeyboardEnabled: Bool
    let onPick: (Recipe) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        CarouselView(recipes: recipes, currentIndex: $currentIndex)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minHeight: 220)
            // Arrow-key navigation via UIKit pressesBegan.
            // See KeyboardNavigationHandler.swift for the rationale
            // behind this approach vs onKeyPress / keyboardShortcut.
            .overlay {
                KeyboardNavigationHandler(
                    isEnabled: isKeyboardEnabled,
                    onLeft: { move(by: -1) },
                    onRight: { move(by: 1) }
                )
                .accessibilityHidden(true)
            }

        // Page dots — always below the carousel
        PageIndicatorView(count: recipes.count, current: $currentIndex)

        // Inspire Me — always visible at the bottom
        InspireMeButton(
            candidates: inspirationCandidates,
            current: recipes[safe: currentIndex],
            onPick: onPick
        )
        .padding(.bottom, 20)
    }

    private func move(by delta: Int) {
        guard let index = CarouselPaging.index(from: currentIndex, moving: delta, count: recipes.count) else { return }
        withAnimation(.carouselPaging(reduceMotion: reduceMotion)) {
            currentIndex = index
        }
    }
}
