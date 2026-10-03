import SwiftUI

/// A multi-line text field that grows with its content and shows a placeholder while empty.
struct PlaceholderTextEditor: View {
    let placeholder: LocalizedStringResource
    @Binding var text: String?
    var minLines = 5

    var body: some View {
        TextField(placeholder, text: Binding(emptyAsNil: $text), axis: .vertical)
            .lineLimit(minLines...)
    }
}
