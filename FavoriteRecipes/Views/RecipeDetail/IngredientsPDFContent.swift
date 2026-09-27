import SwiftUI

/// An attached ingredients PDF, with remove / replace controls.
struct IngredientsPDFContent: View {
    @Bindable var recipe: Recipe
    let onChoosePDF: () -> Void

    var body: some View {
        if let data = recipe.ingredientsPDFData {
            HStack(spacing: 12) {
                Image(systemName: "doc.richtext.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(.pdfLoaded)
                        .font(.headline)
                    Text(Int64(data.count), format: .byteCount(style: .file))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            Button(role: .destructive) {
                recipe.ingredientsPDFData = nil
            } label: {
                Label(.removePDF, systemImage: "xmark.circle")
            }
        }
        Button(action: onChoosePDF) {
            Label(
                recipe.ingredientsPDFData == nil ? .choosePDF : .replacePDF,
                systemImage: "doc.badge.plus"
            )
        }
    }
}
