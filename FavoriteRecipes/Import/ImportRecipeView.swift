import SwiftUI

/// Asks for a recipe web address and hands back an unsaved draft.
struct ImportRecipeView: View {
    let onImport: (Recipe) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var model = ImportRecipeModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(.sourcePlaceholder, text: $model.urlText)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .onSubmit(runImport)
                    PasteButton(payloadType: String.self) { strings in
                        if let first = strings.first { model.urlText = first }
                    }
                } footer: {
                    Text(.importFromWebMessage)
                }

                if let error = model.errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .disabled(model.isImporting)
            .overlay {
                if model.isImporting {
                    ProgressView(.importing)
                        .padding()
                        .background(.regularMaterial, in: .rect(cornerRadius: 12))
                }
            }
            .navigationTitle(.importFromWeb)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.import, action: runImport)
                        .disabled(!model.canImport)
                }
            }
        }
    }

    private func runImport() {
        guard model.canImport else { return }
        Task {
            if let draft = await model.importRecipe() {
                onImport(draft)
                dismiss()
            }
        }
    }
}
