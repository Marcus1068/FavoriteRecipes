import SwiftUI

/// A capsule button for one category in the filter bar.
struct FilterChip: View {
    let title: LocalizedStringResource
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(icon)
                    .font(.subheadline)
                    .accessibilityHidden(true)
                Text(title).font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color.secondary.opacity(0.12), in: .capsule)
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
    }
}
