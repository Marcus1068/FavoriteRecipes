import SwiftUI

/// One field's current text above its corrected text.
struct CleanupChangeSection: View {
    let title: LocalizedStringResource
    let before: String
    let after: String

    var body: some View {
        Section {
            LabeledContent(.cleanUpBefore) {
                Text(before.isEmpty ? "—" : before)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            LabeledContent(.cleanUpAfter) {
                Text(after)
                    .multilineTextAlignment(.trailing)
            }
        } header: {
            Text(title)
        }
    }
}
