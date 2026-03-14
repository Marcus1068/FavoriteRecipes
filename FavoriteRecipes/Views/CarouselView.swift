import SwiftUI

/// 3-D perspective carousel driven by drag gesture.
struct CarouselView: View {
    let recipes: [Recipe]
    @Binding var currentIndex: Int

    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let cardW  = geo.size.width * 0.72
            let cardH  = cardW * 1.45
            let spacing: CGFloat = 22
            let step   = cardW + spacing

            ZStack {
                ForEach(Array(recipes.enumerated()), id: \.element.id) { i, recipe in
                    let delta     = CGFloat(i - currentIndex) * step + dragOffset
                    let absNorm   = abs(delta) / step
                    let scale     = max(0.83, 1.0 - absNorm * 0.10)
                    let rotY      = Double(delta / (cardW * 1.5)) * 14.0
                    let opacity   = max(0.4, 1.0 - absNorm * 0.45)
                    let isCurrent = i == currentIndex

                    RecipeCardView(recipe: recipe)
                        .frame(width: cardW, height: cardH)
                        .scaleEffect(scale)
                        .rotation3DEffect(
                            .degrees(rotY),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.45
                        )
                        .shadow(
                            color: recipe.category.color.opacity(isCurrent ? 0.50 : 0.15),
                            radius: isCurrent ? 24 : 8,
                            x: 0,
                            y: isCurrent ? 18 : 5
                        )
                        .opacity(opacity)
                        .offset(x: delta)
                        .zIndex(isCurrent ? 100 : Double(recipes.count - abs(i - currentIndex)))
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
            .frame(width: geo.size.width, height: cardH)
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 12, coordinateSpace: .local)
                    .updating($dragOffset) { value, state, _ in
                        let atStart = currentIndex == 0 && value.translation.width > 0
                        let atEnd   = currentIndex == recipes.count - 1 && value.translation.width < 0
                        state = (atStart || atEnd)
                            ? value.translation.width * 0.28
                            : value.translation.width
                    }
                    .onEnded { value in
                        let extra     = value.predictedEndTranslation.width - value.translation.width
                        let effective = value.translation.width + extra * 0.35
                        let threshold = cardW * 0.28

                        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                            if effective < -threshold, currentIndex < recipes.count - 1 {
                                currentIndex += 1
                            } else if effective > threshold, currentIndex > 0 {
                                currentIndex -= 1
                            }
                        }
                    }
            )
        }
    }
}
