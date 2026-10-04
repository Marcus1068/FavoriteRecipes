import SwiftUI

/// Back and Next buttons for cooking mode. They sit side by side, or stack when the text is too large.
struct CookingStepButtons: View {
    let model: CookingModel

    var body: some View {
        ViewThatFits {
            HStack {
                Button(.previousStep, systemImage: "chevron.left", action: goBack)
                    .disabled(model.isFirstStep)
                Spacer()
                Button(.nextStep, systemImage: "chevron.right", action: goForward)
                    .labelStyle(.titleAndIcon)
                    .disabled(model.isLastStep)
            }
            VStack {
                Button(.nextStep, systemImage: "chevron.right", action: goForward)
                    .labelStyle(.titleAndIcon)
                    .disabled(model.isLastStep)
                Button(.previousStep, systemImage: "chevron.left", action: goBack)
                    .labelStyle(.titleAndIcon)
                    .disabled(model.isFirstStep)
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private func goBack() {
        withAnimation { model.previousStep() }
    }

    private func goForward() {
        withAnimation { model.nextStep() }
    }
}
