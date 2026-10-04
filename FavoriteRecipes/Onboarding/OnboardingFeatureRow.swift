import SwiftUI

/// An icon with a headline and a short description.
struct OnboardingFeatureRow: View {
    let systemImage: String
    let title: LocalizedStringResource
    let message: LocalizedStringResource

    /// Fixed icon column so every text block lines up, whatever the symbol's width.
    @ScaledMetric private var iconWidth = 56

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: systemImage)
                .font(.title)
                .foregroundStyle(.tint)
                .frame(width: iconWidth)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
