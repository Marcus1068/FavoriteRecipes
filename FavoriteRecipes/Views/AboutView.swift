import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 84))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)

                VStack(spacing: 6) {
                    Text("FavoriteRecipes")
                        .font(.largeTitle.bold())
                    Text(.aboutVersion)
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
