import SwiftUI

/// Horizontally scrolling category chips; tapping the selected chip clears the filter.
struct CategoryFilterView: View {
    @Binding var selected: RecipeCategory?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                FilterChip(title: .all, icon: "🍽️", color: .accentColor, isSelected: selected == nil) {
                    withAnimation(.spring(response: 0.3)) { selected = nil }
                }
                ForEach(RecipeCategory.allCases) { cat in
                    FilterChip(
                        title: cat.localizedName,
                        icon: cat.icon,
                        color: cat.color,
                        isSelected: selected == cat
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selected = (selected == cat) ? nil : cat
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
    }
}
