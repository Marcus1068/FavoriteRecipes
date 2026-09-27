import SwiftUI

struct AboutView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize = 84

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "–"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: iconSize))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                VStack(spacing: 6) {
                    Text(verbatim: "FavoriteRecipes")
                        .font(.largeTitle.bold())
                    Text(.aboutVersion(version, build))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(.aboutDescription)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 36)

                Spacer()
            }
            .padding(.top, 56)
            .navigationTitle(.about)
        }
    }
}

#Preview {
    AboutView()
}
