import SwiftUI

/// One preparation step at a time in large type, with previous/next buttons.
struct CookingStepsView: View {
    @Bindable var model: CookingModel
    /// Called when the cook taps "Done Cooking" on the last step.
    var onFinish: () -> Void = {}

    var body: some View {
        if model.steps.isEmpty {
            ContentUnavailableView {
                Label(.noStepsTitle, systemImage: "list.number")
            } description: {
                Text(.noStepsMessage)
            }
        } else {
            VStack {
                TabView(selection: $model.currentStep) {
                    ForEach(model.steps.indices, id: \.self) { index in
                        ScrollView {
                            Text(model.steps[index])
                                .font(.title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Text(.stepProgress(model.currentStep + 1, model.steps.count))
                    .font(.headline)
                    .foregroundStyle(.secondary)

                if model.isLastStep {
                    Button(.finishCooking, systemImage: "checkmark.circle.fill", action: onFinish)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }

                CookingStepButtons(model: model)
                    .padding()
            }
            .sensoryFeedback(.selection, trigger: model.currentStep)
        }
    }
}
