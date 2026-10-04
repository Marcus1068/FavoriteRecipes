import SwiftUI
import SwiftData

/// "Recipe deleted — Undo" banner at the top of the screen. It hides itself after a few seconds.
struct UndoDeleteBanner: View {
    let model: UndoDeleteModel

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let visibleTime = Duration.seconds(7)

    var body: some View {
        VStack {
            if model.canUndo {
                HStack {
                    Label(message, systemImage: "trash")
                        .font(.subheadline)
                    Spacer()
                    Button(.undo) {
                        model.undo(in: modelContext)
                    }
                    .bold()
                    .accessibilityIdentifier("undoButton")
                }
                .padding()
                .glassEffect(.regular, in: .rect(cornerRadius: 20))
                .padding(.horizontal)
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .animation(.default, value: model.canUndo)
        .task(id: model.deletionID) {
            guard model.canUndo else { return }
            AccessibilityNotification.Announcement(String(localized: message)).post()
            try? await Task.sleep(for: visibleTime)
            model.dismiss()
        }
        .allowsHitTesting(model.canUndo)
    }

    private var message: LocalizedStringResource {
        model.deleted.count == 1 ? .recipeDeleted : .recipesDeleted(model.deleted.count)
    }
}
