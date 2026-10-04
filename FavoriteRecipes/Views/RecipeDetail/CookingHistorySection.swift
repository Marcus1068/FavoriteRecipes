import SwiftUI

/// "Cooked 3 times, last on …" with the list of entries and a button to add one.
struct CookingHistorySection: View {
    @Bindable var recipe: Recipe
    /// Asks the parent to show the log sheet; the editor presents all of its sheets itself.
    let onLog: () -> Void

    var body: some View {
        Section {
            LabeledContent(.cookedTimes) {
                Text(recipe.cookedCount, format: .number)
            }
            if let last = recipe.lastCookedAt {
                LabeledContent(.lastCooked) {
                    Text(last, format: .dateTime.day().month().year())
                }
            }

            ForEach(recipe.cookHistory.reversed()) { entry in
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.date, format: .dateTime.day().month().year())
                    if let note = entry.note {
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .swipeActions {
                    Button(.delete, systemImage: "trash", role: .destructive) {
                        recipe.removeCookEntry(entry)
                    }
                }
            }

            Button(.logCooking, systemImage: "checkmark.circle", action: onLog)
        } header: {
            Label(.cookingHistory, systemImage: "frying.pan")
        }
    }
}
