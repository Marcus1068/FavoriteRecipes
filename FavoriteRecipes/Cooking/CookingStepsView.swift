import SwiftUI

/// One preparation step at a time in large type, with previous/next buttons.
struct CookingStepsView: View {
    @Bindable var model: CookingModel

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

                CookingStepButtons(model: model)
                    .padding()
            }
            .sensoryFeedback(.selection, trigger: model.currentStep)
        }
    }
}
