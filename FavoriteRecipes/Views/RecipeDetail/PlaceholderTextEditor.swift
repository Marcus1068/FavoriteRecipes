import SwiftUI

/// A multi-line text editor that shows a placeholder while empty.
struct PlaceholderTextEditor: View {
    let placeholder: LocalizedStringResource
    @Binding var text: String?
    var minHeight: CGFloat = 120

    var body: some View {
        ZStack(alignment: .topLeading) {
            if (text ?? "").isEmpty {
                Text(placeholder)
                    .foregroundStyle(.secondary)
                    .allowsHitTesting(false)
                    .padding(.top, 8)
                    .padding(.leading, 5)
                    .accessibilityHidden(true)
            }
            TextEditor(text: Binding(emptyAsNil: $text))
                .frame(minHeight: minHeight)
                .accessibilityLabel(Text(placeholder))
        }
    }
}
