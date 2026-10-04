import SwiftUI

/// Short introduction to the app's main features, shown on first launch
/// and available again from Options.
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text(.onboardingTitle)
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)

                OnboardingFeatureRow(
                    systemImage: "camera.viewfinder",
                    title: .onboardingScanTitle,
                    message: .onboardingScanMessage
                )
                OnboardingFeatureRow(
                    systemImage: "globe",
                    title: .onboardingWebTitle,
                    message: .onboardingWebMessage
                )
                OnboardingFeatureRow(
                    systemImage: "frying.pan",
                    title: .onboardingCookTitle,
                    message: .onboardingCookMessage
                )
                OnboardingFeatureRow(
                    systemImage: "sparkles",
                    title: .onboardingInspireTitle,
                    message: .onboardingInspireMessage
                )
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Button(.onboardingStart) { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.bar)
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    OnboardingView()
}
