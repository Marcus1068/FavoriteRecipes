import SwiftUI

/// A form section holding one free-text field, e.g. preparation or notes.
struct RecipeTextSection: View {
    let title: LocalizedStringResource
    let systemImage: String
    let placeholder: LocalizedStringResource
    @Binding var text: String?

    var body: some View {
        Section {
            PlaceholderTextEditor(placeholder: placeholder, text: $text)
        } header: {
            Label(title, systemImage: systemImage)
        }
    }
}
