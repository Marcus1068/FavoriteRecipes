import SwiftUI

/// Records that a recipe was cooked, with a date and an optional note.
struct CookLogSheet: View {
    let recipe: Recipe

    @Environment(\.dismiss) private var dismiss
    @State private var date = Date.now
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker(.cookedOn, selection: $date, in: ...Date.now, displayedComponents: .date)
                Section {
                    TextField(.cookNotePlaceholder, text: $note, axis: .vertical)
                        .lineLimit(3...)
                } header: {
                    Text(.cookNote)
                }
            }
            .navigationTitle(.logCooking)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.save, action: save)
                        .accessibilityIdentifier("cookLog.save")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        recipe.markCooked(on: date, note: note)
        dismiss()
    }
}
